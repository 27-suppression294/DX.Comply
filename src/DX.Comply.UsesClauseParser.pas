/// <summary>
/// DX.Comply.UsesClauseParser
/// Recursive uses-clause parser for transitive dependency discovery.
/// </summary>
///
/// <remarks>
/// Provides a fallback evidence source for LLVM-based Delphi targets (iOS,
/// Android, macOS, Linux, Win ARM64) where the classic linker MAP file is
/// unavailable. Parses uses clauses from Delphi source files and recursively
/// walks the dependency graph to discover all transitively referenced units.
/// </remarks>
///
/// <copyright>
/// Copyright © 2026 Olaf Monien
/// Licensed under MIT
/// </copyright>

unit DX.Comply.UsesClauseParser;

interface

uses
  System.Generics.Collections;

type
  /// <summary>
  /// State machine states for comment and string literal stripping.
  /// </summary>
  TStripState = (ssNormal, ssInLineComment, ssInBraceComment, ssInParenStarComment, ssInString);

  /// <summary>
  /// Extracts unit names from Delphi uses clauses in source file content.
  /// Handles interface uses, implementation uses, and program/library uses.
  /// </summary>
  TUsesClauseParser = class
  public
    /// <summary>
    /// Strips all comments, compiler directives, and string literals from
    /// Delphi source content, replacing them with spaces to preserve token
    /// boundaries.
    /// </summary>
    class function StripCommentsAndStrings(const AContent: string): string;
    /// <summary>
    /// Extracts unit names from all uses clauses in the given source content.
    /// Returns a deduplicated array of unit names.
    /// </summary>
    class function ExtractUsedUnits(const AContent: string): TArray<string>;
  end;

  /// <summary>
  /// Recursively walks the Delphi uses-clause dependency graph starting from
  /// a root source file, discovering all transitively referenced units.
  /// </summary>
  TUsesClauseWalker = class
  private
    class function ResolveUnitSourcePath(const AUnitName: string;
      const ASearchPaths, AGlobalSearchPaths, AUnitScopeNames: TList<string>): string;
    class function TryFindPasFile(const AFileName: string;
      const ASearchPaths: TList<string>): string;
    class function ReadSourceFile(const AFilePath: string): string;
    class procedure WalkRecursive(const AUnitName, ASourcePath: string;
      const ASearchPaths, AGlobalSearchPaths, AUnitScopeNames: TList<string>;
      const AVisited: TDictionary<string, string>;
      ACurrentDepth, AMaxDepth: Integer);
  public
    /// <summary>
    /// Recursively discovers all transitively referenced units starting from
    /// the given root source file. Returns a flat list of discovered unit names.
    /// Units with no .pas source (DCU-only) are included but recursion stops
    /// on that branch.
    /// </summary>
    class function WalkDependencies(const ARootSourcePath: string;
      const ASearchPaths, AGlobalSearchPaths, AUnitScopeNames: TList<string>;
      AMaxDepth: Integer = 100): TArray<string>;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.RegularExpressions,
  System.SysUtils;

{ TUsesClauseParser }

class function TUsesClauseParser.StripCommentsAndStrings(const AContent: string): string;
var
  I, LLen: Integer;
  LState: TStripState;
  LResult: TStringBuilder;
  LCurrent, LNext: Char;
begin
  LLen := Length(AContent);
  if LLen = 0 then
    Exit('');

  LResult := TStringBuilder.Create(LLen);
  try
    LState := ssNormal;
    I := 1;
    while I <= LLen do
    begin
      LCurrent := AContent[I];
      if I < LLen then
        LNext := AContent[I + 1]
      else
        LNext := #0;

      case LState of
        ssNormal:
          begin
            if (LCurrent = '/') and (LNext = '/') then
            begin
              LState := ssInLineComment;
              LResult.Append(' ');
              Inc(I, 2);
              Continue;
            end
            else if (LCurrent = '{') then
            begin
              LState := ssInBraceComment;
              LResult.Append(' ');
              Inc(I);
              Continue;
            end
            else if (LCurrent = '(') and (LNext = '*') then
            begin
              LState := ssInParenStarComment;
              LResult.Append(' ');
              Inc(I, 2);
              Continue;
            end
            else if LCurrent = '''' then
            begin
              LState := ssInString;
              LResult.Append(' ');
              Inc(I);
              Continue;
            end
            else
              LResult.Append(LCurrent);
          end;

        ssInLineComment:
          begin
            if (LCurrent = #13) or (LCurrent = #10) then
            begin
              LState := ssNormal;
              LResult.Append(LCurrent);
            end
            else
              LResult.Append(' ');
          end;

        ssInBraceComment:
          begin
            if LCurrent = '}' then
              LState := ssNormal;
            LResult.Append(' ');
          end;

        ssInParenStarComment:
          begin
            if (LCurrent = '*') and (LNext = ')') then
            begin
              LState := ssNormal;
              LResult.Append('  ');
              Inc(I, 2);
              Continue;
            end;
            LResult.Append(' ');
          end;

        ssInString:
          begin
            if LCurrent = '''' then
            begin
              if LNext = '''' then
              begin
                LResult.Append('  ');
                Inc(I, 2);
                Continue;
              end
              else
                LState := ssNormal;
            end;
            LResult.Append(' ');
          end;
      end;

      Inc(I);
    end;

    Result := LResult.ToString;
  finally
    LResult.Free;
  end;
end;

class function TUsesClauseParser.ExtractUsedUnits(const AContent: string): TArray<string>;
var
  LStripped: string;
  LMatch: TMatch;
  LUsesBlock: string;
  LParts: TArray<string>;
  LPart, LUnitName, LTrimmed, LLower: string;
  LNames: TList<string>;
  LSpacePos: Integer;
begin
  Result := nil;
  if AContent = '' then
    Exit;

  LStripped := StripCommentsAndStrings(AContent);
  LNames := TList<string>.Create;
  try
    LMatch := TRegEx.Match(LStripped, '\buses\b\s+(.*?);',
      [roIgnoreCase, roSingleLine]);

    while LMatch.Success do
    begin
      LUsesBlock := LMatch.Groups[1].Value;
      LParts := LUsesBlock.Split([',']);

      for LPart in LParts do
      begin
        LTrimmed := Trim(LPart);
        if LTrimmed = '' then
          Continue;

        // Handle 'UnitName in ''path'' {hint}' syntax — extract just the unit name
        LSpacePos := Pos(' ', LTrimmed);
        if LSpacePos > 0 then
          LUnitName := Trim(Copy(LTrimmed, 1, LSpacePos - 1))
        else
          LUnitName := LTrimmed;

        // Clean up any remaining whitespace/newlines in the unit name
        LUnitName := Trim(LUnitName);
        if LUnitName = '' then
          Continue;

        // Validate: unit names contain only letters, digits, dots, underscores
        if not TRegEx.IsMatch(LUnitName, '^[A-Za-z_][A-Za-z0-9_.]*$') then
          Continue;

        // Deduplicate (case-insensitive)
        LLower := LowerCase(LUnitName);
        if not LNames.Contains(LLower) then
        begin
          LNames.Add(LLower);
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)] := LUnitName;
        end;
      end;

      LMatch := LMatch.NextMatch;
    end;
  finally
    LNames.Free;
  end;
end;

{ TUsesClauseWalker }

class function TUsesClauseWalker.ReadSourceFile(const AFilePath: string): string;
var
  LLines: TStringList;
begin
  Result := '';
  if not TFile.Exists(AFilePath) then
    Exit;

  LLines := TStringList.Create;
  try
    try
      LLines.LoadFromFile(AFilePath, TEncoding.UTF8);
    except
      try
        LLines.LoadFromFile(AFilePath);
      except
        Exit;
      end;
    end;
    Result := LLines.Text;
  finally
    LLines.Free;
  end;
end;

class function TUsesClauseWalker.TryFindPasFile(const AFileName: string;
  const ASearchPaths: TList<string>): string;
var
  LSearchPath, LCandidate: string;
begin
  Result := '';
  if not Assigned(ASearchPaths) then
    Exit;

  for LSearchPath in ASearchPaths do
  begin
    if LSearchPath = '' then
      Continue;
    LCandidate := TPath.Combine(LSearchPath, AFileName);
    if TFile.Exists(LCandidate) then
      Exit(LCandidate);
  end;
end;

class function TUsesClauseWalker.ResolveUnitSourcePath(const AUnitName: string;
  const ASearchPaths, AGlobalSearchPaths, AUnitScopeNames: TList<string>): string;
var
  LPasFileName, LShortName, LScopeName: string;
  LDotPos: Integer;
begin
  Result := '';
  if AUnitName = '' then
    Exit;

  LPasFileName := AUnitName + '.pas';

  // 1. Try full unit name in project search paths
  Result := TryFindPasFile(LPasFileName, ASearchPaths);
  if Result <> '' then
    Exit;

  // 2. Try short name (last dot-segment) in project search paths
  LDotPos := LastDelimiter('.', AUnitName);
  if LDotPos > 0 then
  begin
    LShortName := Copy(AUnitName, LDotPos + 1, MaxInt) + '.pas';
    Result := TryFindPasFile(LShortName, ASearchPaths);
    if Result <> '' then
      Exit;
  end;

  // 3. Try with unit scope name prefixes in project search paths
  if Assigned(AUnitScopeNames) then
  begin
    for LScopeName in AUnitScopeNames do
    begin
      if LScopeName = '' then
        Continue;
      Result := TryFindPasFile(LScopeName + '.' + AUnitName + '.pas', ASearchPaths);
      if Result <> '' then
        Exit;
    end;
  end;

  // 4. Repeat all strategies in global search paths
  Result := TryFindPasFile(LPasFileName, AGlobalSearchPaths);
  if Result <> '' then
    Exit;

  if LDotPos > 0 then
  begin
    Result := TryFindPasFile(LShortName, AGlobalSearchPaths);
    if Result <> '' then
      Exit;
  end;

  if Assigned(AUnitScopeNames) then
  begin
    for LScopeName in AUnitScopeNames do
    begin
      if LScopeName = '' then
        Continue;
      Result := TryFindPasFile(LScopeName + '.' + AUnitName + '.pas', AGlobalSearchPaths);
      if Result <> '' then
        Exit;
    end;
  end;
end;

class procedure TUsesClauseWalker.WalkRecursive(const AUnitName, ASourcePath: string;
  const ASearchPaths, AGlobalSearchPaths, AUnitScopeNames: TList<string>;
  const AVisited: TDictionary<string, string>;
  ACurrentDepth, AMaxDepth: Integer);
var
  LContent: string;
  LUsedUnits: TArray<string>;
  LUsedUnit, LResolvedPath, LLowerName: string;
begin
  LLowerName := LowerCase(AUnitName);
  if AVisited.ContainsKey(LLowerName) then
    Exit;

  if ACurrentDepth >= AMaxDepth then
  begin
    AVisited.AddOrSetValue(LLowerName, '');
    Exit;
  end;

  if ASourcePath = '' then
  begin
    // No .pas source available — record unit name but stop recursion
    AVisited.AddOrSetValue(LLowerName, '');
    Exit;
  end;

  AVisited.AddOrSetValue(LLowerName, ASourcePath);

  LContent := ReadSourceFile(ASourcePath);
  if LContent = '' then
    Exit;

  LUsedUnits := TUsesClauseParser.ExtractUsedUnits(LContent);
  for LUsedUnit in LUsedUnits do
  begin
    if AVisited.ContainsKey(LowerCase(LUsedUnit)) then
      Continue;

    LResolvedPath := ResolveUnitSourcePath(LUsedUnit, ASearchPaths,
      AGlobalSearchPaths, AUnitScopeNames);
    WalkRecursive(LUsedUnit, LResolvedPath, ASearchPaths, AGlobalSearchPaths,
      AUnitScopeNames, AVisited, ACurrentDepth + 1, AMaxDepth);
  end;
end;

class function TUsesClauseWalker.WalkDependencies(const ARootSourcePath: string;
  const ASearchPaths, AGlobalSearchPaths, AUnitScopeNames: TList<string>;
  AMaxDepth: Integer): TArray<string>;
var
  LVisited: TDictionary<string, string>;
  LContent: string;
  LUsedUnits: TArray<string>;
  LUsedUnit, LResolvedPath: string;
  LKey: string;
begin
  Result := nil;
  if (ARootSourcePath = '') or not TFile.Exists(ARootSourcePath) then
    Exit;

  LVisited := TDictionary<string, string>.Create;
  try
    LContent := ReadSourceFile(ARootSourcePath);
    if LContent = '' then
      Exit;

    LUsedUnits := TUsesClauseParser.ExtractUsedUnits(LContent);
    for LUsedUnit in LUsedUnits do
    begin
      LResolvedPath := ResolveUnitSourcePath(LUsedUnit, ASearchPaths,
        AGlobalSearchPaths, AUnitScopeNames);
      WalkRecursive(LUsedUnit, LResolvedPath, ASearchPaths, AGlobalSearchPaths,
        AUnitScopeNames, LVisited, 1, AMaxDepth);
    end;

    SetLength(Result, LVisited.Count);
    var LIndex := 0;
    for LKey in LVisited.Keys do
    begin
      Result[LIndex] := LKey;
      Inc(LIndex);
    end;
  finally
    LVisited.Free;
  end;
end;

end.
