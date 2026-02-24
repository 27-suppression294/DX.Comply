/// <summary>
/// DX.Comply.ProjectScanner
/// Scans and parses Delphi .dproj project files.
/// </summary>
///
/// <remarks>
/// This unit provides TProjectScanner which extracts metadata from .dproj files:
/// - Project name and version
/// - Platform and configuration settings
/// - Output directories
/// - Runtime package dependencies
///
/// Uses a lightweight regex-based XML reader that works in all environments
/// (IDE, CLI, test runners) without requiring MSXML or COM registration.
/// </remarks>
///
/// <copyright>
/// Copyright © 2026 Olaf Monien
/// Licensed under MIT
/// </copyright>

unit DX.Comply.ProjectScanner;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.RegularExpressions,
  System.Generics.Collections,
  DX.Comply.Engine.Intf;

type
  /// <summary>
  /// Implementation of IProjectScanner for scanning .dproj files.
  /// Uses regex-based parsing — no MSXML or COM dependencies.
  /// </summary>
  TProjectScanner = class(TInterfacedObject, IProjectScanner)
  private
    const
      cDefaultPlatform = 'Win32';
      cDefaultConfig = 'Debug';
  private
    FXmlText: string;
    FCurrentPlatform: string;
    FCurrentConfig: string;
    /// <summary>
    /// Returns the text content of the first PropertyGroup whose Condition
    /// attribute contains ACondition (case-insensitive). Empty string = any.
    /// </summary>
    function GetPropertyGroupContent(const ACondition: string): string;
    /// <summary>
    /// Reads the text content of element AName from AXmlBlock.
    /// </summary>
    function GetElementValue(const AXmlBlock, AName: string): string;
    /// <summary>
    /// Reads AName from property groups matching Base, platform, and config
    /// (later groups override earlier ones).
    /// </summary>
    function GetPropertyValue(const AName: string; const ADefault: string = ''): string;
    /// <summary>
    /// Extracts runtime packages from the DCC_UsePackage / RuntimePackage element.
    /// </summary>
    function ExtractRuntimePackages: TList<string>;
    /// <summary>
    /// Replaces MSBuild variable tokens with actual platform/config values.
    /// </summary>
    function NormalizePath(const APath: string): string;
  public
    // IProjectScanner
    function Scan(const AProjectPath, APlatform, AConfiguration: string): TProjectInfo;
    function Validate(const AProjectPath: string): Boolean;
  end;

implementation

{ TProjectScanner }

function TProjectScanner.GetPropertyGroupContent(const ACondition: string): string;
var
  LPattern: string;
  LMatch: TMatch;
  LConditionMatch: TMatch;
  LMatches: TMatchCollection;
begin
  Result := '';
  // Match every <PropertyGroup ...>...</PropertyGroup> block
  LPattern := '<PropertyGroup(?:\s[^>]*)?>.*?</PropertyGroup>';
  LMatches := TRegEx.Matches(FXmlText, LPattern, [roIgnoreCase, roSingleLine]);

  for LMatch in LMatches do
  begin
    if ACondition = '' then
    begin
      Result := LMatch.Value;
      Exit;
    end;

    // Check if the Condition attribute contains ACondition (case-insensitive)
    LConditionMatch := TRegEx.Match(LMatch.Value,
      'Condition\s*=\s*"([^"]*)"', [roIgnoreCase]);
    if LConditionMatch.Success then
    begin
      if Pos(UpperCase(ACondition), UpperCase(LConditionMatch.Groups[1].Value)) > 0 then
      begin
        Result := LMatch.Value;
        Exit;
      end;
    end;
  end;
end;

function TProjectScanner.GetElementValue(const AXmlBlock, AName: string): string;
var
  LPattern: string;
  LMatch: TMatch;
begin
  Result := '';
  if AXmlBlock = '' then
    Exit;

  // Match <Name>value</Name> — handles optional namespace prefix
  LPattern := '<(?:\w+:)?' + TRegEx.Escape(AName) +
              '(?:\s[^>]*)?>([^<]*)</(?:\w+:)?' + TRegEx.Escape(AName) + '>';
  LMatch := TRegEx.Match(AXmlBlock, LPattern, [roIgnoreCase]);
  if LMatch.Success then
    Result := Trim(LMatch.Groups[1].Value);
end;

function TProjectScanner.GetPropertyValue(const AName, ADefault: string): string;
var
  LBlock, LValue: string;
begin
  Result := ADefault;

  // 1. Base PropertyGroup (Condition contains '$(Base)')
  LBlock := GetPropertyGroupContent('$(Base)');
  if LBlock <> '' then
  begin
    LValue := GetElementValue(LBlock, AName);
    if LValue <> '' then
      Result := LValue;
  end;

  // 2. Platform-specific (Condition contains '$(Base_Win32)' etc.)
  if FCurrentPlatform <> '' then
  begin
    LBlock := GetPropertyGroupContent('$(Base_' + FCurrentPlatform + ')');
    if LBlock <> '' then
    begin
      LValue := GetElementValue(LBlock, AName);
      if LValue <> '' then
        Result := LValue;
    end;
  end;

  // 3. Config-specific — try config name first, then Cfg_1/Cfg_2
  if FCurrentConfig <> '' then
  begin
    LBlock := GetPropertyGroupContent('$(Cfg_');
    if LBlock <> '' then
    begin
      LValue := GetElementValue(LBlock, AName);
      if LValue <> '' then
        Result := LValue;
    end;
  end;
end;

function TProjectScanner.ExtractRuntimePackages: TList<string>;
var
  LPackages: TList<string>;
  LBlock, LPackageStr: string;
  LPackageArray: TArray<string>;
  I: Integer;
begin
  LPackages := TList<string>.Create;

  // DCC_UsePackage in base PropertyGroup
  LBlock := GetPropertyGroupContent('$(Base)');
  LPackageStr := GetElementValue(LBlock, 'DCC_UsePackage');
  if LPackageStr = '' then
    LPackageStr := GetElementValue(FXmlText, 'RuntimePackage');

  if LPackageStr <> '' then
  begin
    LPackageArray := LPackageStr.Split([';']);
    for I := 0 to High(LPackageArray) do
    begin
      LPackageStr := Trim(LPackageArray[I]);
      // Strip MSBuild variable references like $(DCC_UsePackage)
      if (LPackageStr <> '') and (LPackageStr[1] <> '$') then
        LPackages.Add(LPackageStr);
    end;
  end;

  Result := LPackages;
end;

function TProjectScanner.NormalizePath(const APath: string): string;
var
  LPath: string;
begin
  LPath := StringReplace(APath, '$(Platform)', FCurrentPlatform, [rfIgnoreCase, rfReplaceAll]);
  LPath := StringReplace(LPath, '$(Config)', FCurrentConfig, [rfIgnoreCase, rfReplaceAll]);
  LPath := StringReplace(LPath, '/', '\', [rfReplaceAll]);
  Result := LPath;
end;

function TProjectScanner.Scan(const AProjectPath, APlatform, AConfiguration: string): TProjectInfo;
var
  LOutputDir: string;
  LContent: TStringList;
begin
  Result := TProjectInfo.Create;
  try
    Result.ProjectPath := AProjectPath;
    Result.ProjectDir := TPath.GetDirectoryName(AProjectPath);
    Result.ProjectName := TPath.GetFileNameWithoutExtension(AProjectPath);

    if APlatform <> '' then
      FCurrentPlatform := APlatform
    else
      FCurrentPlatform := cDefaultPlatform;

    if AConfiguration <> '' then
      FCurrentConfig := AConfiguration
    else
      FCurrentConfig := cDefaultConfig;

    Result.Platform := FCurrentPlatform;
    Result.Configuration := FCurrentConfig;

    // Load the .dproj file as plain text for regex parsing
    LContent := TStringList.Create;
    try
      LContent.LoadFromFile(AProjectPath, TEncoding.UTF8);
      FXmlText := LContent.Text;
    finally
      LContent.Free;
    end;

    // Extract version — use VerInfo_MajorVer / MinorVer / Release / Build
    Result.Version := GetPropertyValue('MajorVer', '1') + '.' +
                      GetPropertyValue('MinorVer', '0') + '.' +
                      GetPropertyValue('Release', '0') + '.' +
                      GetPropertyValue('Build', '0');

    // Extract output directory from DCC_ExeOutput or DCC_BplOutput
    LOutputDir := GetPropertyValue('DCC_ExeOutput', '');
    if LOutputDir = '' then
      LOutputDir := GetPropertyValue('DCC_BplOutput', '');
    if LOutputDir = '' then
      LOutputDir := GetPropertyValue('DCC_DcuOutput', '');
    if LOutputDir = '' then
      LOutputDir := '..\build\$(Platform)\$(Config)';

    LOutputDir := NormalizePath(LOutputDir);

    // Make path absolute if relative
    if TPath.IsRelativePath(LOutputDir) then
      LOutputDir := TPath.Combine(Result.ProjectDir, LOutputDir);

    Result.OutputDir := TPath.GetFullPath(LOutputDir);

    // Extract runtime packages
    if Assigned(Result.RuntimePackages) then
      Result.RuntimePackages.Free;
    Result.RuntimePackages := ExtractRuntimePackages;
  except
    Result.Free;
    raise;
  end;
end;

function TProjectScanner.Validate(const AProjectPath: string): Boolean;
begin
  Result := TFile.Exists(AProjectPath) and
            (SameText(TPath.GetExtension(AProjectPath), '.dproj'));
end;

end.
