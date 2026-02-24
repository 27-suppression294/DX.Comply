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
/// The scanner uses MSBuild-style XML parsing to handle various .dproj formats.
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
  System.Variants,
  Xml.XMLDoc,
  Xml.XMLIntf,
  System.IOUtils,
  System.Generics.Collections,
  DX.Comply.Engine.Intf;

type
  /// <summary>
  /// Implementation of IProjectScanner for scanning .dproj files.
  /// </summary>
  TProjectScanner = class(TInterfacedObject, IProjectScanner)
  private
    const
      cDefaultPlatform = 'Win32';
      cDefaultConfig = 'Debug';
  private
    FXmlDoc: IXMLDocument;
    FCurrentPlatform: string;
    FCurrentConfig: string;
    function FindPropertyGroup(const ACondition: string): IXMLNode;
    function GetPropertyValue(const AName: string; const ADefault: string = ''): string;
    function GetPlatformProperty(const APlatform, AName: string; const ADefault: string = ''): string;
    function GetConfigProperty(const AConfig, AName: string; const ADefault: string = ''): string;
    function ExtractRuntimePackages: TList<string>;
    function NormalizePath(const APath: string): string;
  public
    /// <summary>
    /// Creates a new TProjectScanner instance.
    /// </summary>
    constructor Create;
    /// <summary>
    /// Destroys the TProjectScanner instance.
    /// </summary>
    destructor Destroy; override;
    // IProjectScanner
    function Scan(const AProjectPath, APlatform, AConfiguration: string): TProjectInfo;
    function Validate(const AProjectPath: string): Boolean;
  end;

implementation

{ TProjectScanner }

constructor TProjectScanner.Create;
begin
  inherited Create;
  FXmlDoc := TXMLDocument.Create(nil);
  FXmlDoc.Options := [doNodeAutoIndent];
end;

destructor TProjectScanner.Destroy;
begin
  FXmlDoc := nil;
  inherited;
end;

function TProjectScanner.FindPropertyGroup(const ACondition: string): IXMLNode;
var
  LNode: IXMLNode;
  LCondition: string;
  I: Integer;
begin
  Result := nil;
  if not Assigned(FXmlDoc.DocumentElement) then
    Exit;

  for I := 0 to FXmlDoc.DocumentElement.ChildNodes.Count - 1 do
  begin
    LNode := FXmlDoc.DocumentElement.ChildNodes[I];
    if LNode.NodeName = 'PropertyGroup' then
    begin
      LCondition := VarToStrDef(LNode.Attributes['Condition'], '');
      // Match condition containing the search term
      if (ACondition = '') or (Pos(UpperCase(ACondition), UpperCase(LCondition)) > 0) then
      begin
        Result := LNode;
        Exit;
      end;
    end;
  end;
end;

function TProjectScanner.GetPropertyValue(const AName, ADefault: string): string;
var
  LBaseNode, LPlatformNode, LConfigNode: IXMLNode;
  LNode: IXMLNode;
begin
  Result := ADefault;

  // First check Base PropertyGroup
  LBaseNode := FindPropertyGroup('$(Base)');
  if Assigned(LBaseNode) then
  begin
    LNode := LBaseNode.ChildNodes.FindNode(AName);
    if Assigned(LNode) and (VarToStrDef(LNode.NodeValue, '') <> '') then
      Result := VarToStrDef(LNode.NodeValue, '');
  end;

  // Then check platform-specific PropertyGroup (overrides base)
  if FCurrentPlatform <> '' then
  begin
    LPlatformNode := FindPropertyGroup('$(Base_' + FCurrentPlatform + ')');
    if Assigned(LPlatformNode) then
    begin
      LNode := LPlatformNode.ChildNodes.FindNode(AName);
      if Assigned(LNode) and (VarToStrDef(LNode.NodeValue, '') <> '') then
        Result := VarToStrDef(LNode.NodeValue, '');
    end;
  end;

  // Then check config-specific PropertyGroup (overrides platform)
  if FCurrentConfig <> '' then
  begin
    LConfigNode := FindPropertyGroup('$(Cfg_' + FCurrentConfig + ')');
    if Assigned(LConfigNode) then
    begin
      LNode := LConfigNode.ChildNodes.FindNode(AName);
      if Assigned(LNode) and (VarToStrDef(LNode.NodeValue, '') <> '') then
        Result := VarToStrDef(LNode.NodeValue, '');
    end;
  end;
end;

function TProjectScanner.GetPlatformProperty(const APlatform, AName, ADefault: string): string;
var
  LNode: IXMLNode;
  LPlatformNode: IXMLNode;
begin
  Result := ADefault;
  LPlatformNode := FindPropertyGroup('$(Base_' + APlatform + ')');
  if Assigned(LPlatformNode) then
  begin
    LNode := LPlatformNode.ChildNodes.FindNode(AName);
    if Assigned(LNode) and (VarToStrDef(LNode.NodeValue, '') <> '') then
      Result := VarToStrDef(LNode.NodeValue, '');
  end;
end;

function TProjectScanner.GetConfigProperty(const AConfig, AName, ADefault: string): string;
var
  LNode: IXMLNode;
  LConfigNode: IXMLNode;
begin
  Result := ADefault;
  LConfigNode := FindPropertyGroup('$(Cfg_' + AConfig + ')');
  if Assigned(LConfigNode) then
  begin
    LNode := LConfigNode.ChildNodes.FindNode(AName);
    if Assigned(LNode) and (VarToStrDef(LNode.NodeValue, '') <> '') then
      Result := VarToStrDef(LNode.NodeValue, '');
  end;
end;

function TProjectScanner.ExtractRuntimePackages: TList<string>;
var
  LPackages: TList<string>;
  LNode: IXMLNode;
  LPackageStr: string;
  LPackageArray: TArray<string>;
  I: Integer;
begin
  LPackages := TList<string>.Create;

  // Check for RuntimePackage property
  LNode := nil;
  if Assigned(FXmlDoc.DocumentElement) then
  begin
    LNode := FXmlDoc.DocumentElement.ChildNodes.FindNode('RuntimePackage');
    if not Assigned(LNode) then
      LNode := FindPropertyGroup('$(Base)');
    if Assigned(LNode) then
      LNode := LNode.ChildNodes.FindNode('RuntimePackage');
  end;

  if Assigned(LNode) and (VarToStrDef(LNode.NodeValue, '') <> '') then
  begin
    LPackageStr := VarToStrDef(LNode.NodeValue, '');
    // Runtime packages are typically semicolon-separated
    LPackageArray := LPackageStr.Split([';']);
    for I := 0 to High(LPackageArray) do
    begin
      LPackageStr := Trim(LPackageArray[I]);
      if LPackageStr <> '' then
        LPackages.Add(LPackageStr);
    end;
  end;

  Result := LPackages;
end;

function TProjectScanner.NormalizePath(const APath: string): string;
var
  LPath: string;
begin
  LPath := StringReplace(APath, '$(Platform)', FCurrentPlatform, [rfIgnoreCase]);
  LPath := StringReplace(LPath, '$(Config)', FCurrentConfig, [rfIgnoreCase]);
  LPath := StringReplace(LPath, '/', '\', [rfReplaceAll]);
  Result := LPath;
end;

function TProjectScanner.Scan(const AProjectPath, APlatform, AConfiguration: string): TProjectInfo;
var
  LProjectDir: string;
  LOutputDir: string;
begin
  Result := TProjectInfo.Create;
  try
    Result.ProjectPath := AProjectPath;
    Result.ProjectDir := TPath.GetDirectoryName(AProjectPath);
    Result.ProjectName := TPath.GetFileNameWithoutExtension(AProjectPath);

  // Set platform and config
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

  // Load XML document
  FXmlDoc.LoadFromFile(AProjectPath);
  FXmlDoc.Active := True;

  // Extract version info
  Result.Version := GetPropertyValue('VerInfo_Keys', '');
  if Result.Version = '' then
    Result.Version := GetPropertyValue('MajorVer', '1') + '.' +
                      GetPropertyValue('MinorVer', '0') + '.' +
                      GetPropertyValue('Release', '0') + '.' +
                      GetPropertyValue('Build', '0');

  // Extract output directory
  LOutputDir := GetPropertyValue('DCC_ExeOutput', '');
  if LOutputDir = '' then
    LOutputDir := GetPropertyValue('DCC_DcuOutput', '');
  if LOutputDir = '' then
    LOutputDir := '.\$(Platform)\$(Config)';

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
