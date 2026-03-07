/// <summary>
/// DX.Comply.UnitResolver
/// First-pass implementation of composition evidence resolution.
/// </summary>
///
/// <remarks>
/// This resolver intentionally keeps the first slice small. It builds the
/// composition evidence envelope, propagates metadata and warnings, and leaves
/// the unit list empty until the actual unit-closure logic is implemented.
/// </remarks>
///
/// <copyright>
/// Copyright © 2026 Olaf Monien
/// Licensed under MIT
/// </copyright>

unit DX.Comply.UnitResolver;

interface

uses
  System.Generics.Collections,
  DX.Comply.Engine.Intf,
  DX.Comply.BuildEvidence.Intf;

type
  /// <summary>
  /// Implementation of IUnitResolver for the first composition evidence slice.
  /// </summary>
  TUnitResolver = class(TInterfacedObject, IUnitResolver)
  private
    /// <summary>
    /// Copies unique warning entries from the source list into the target list.
    /// </summary>
    procedure CopyUniqueWarnings(const ASource, ATarget: TList<string>);
    /// <summary>
    /// Adds unique map-derived units to the composition evidence result.
    /// </summary>
    procedure AddMapDerivedUnits(const ABuildEvidence: TBuildEvidence;
      var ACompositionEvidence: TCompositionEvidence);
  public
    /// <summary>
    /// Resolves the first-pass composition evidence envelope.
    /// </summary>
    function Resolve(const AProjectInfo: TProjectInfo;
      const ABuildEvidence: TBuildEvidence): TCompositionEvidence;
  end;

implementation

uses
  System.DateUtils,
  System.SysUtils;

procedure TUnitResolver.CopyUniqueWarnings(const ASource, ATarget: TList<string>);
var
  LWarning: string;
begin
  if not Assigned(ASource) or not Assigned(ATarget) then
    Exit;

  for LWarning in ASource do
  begin
    if not ATarget.Contains(LWarning) then
      ATarget.Add(LWarning);
  end;
end;

procedure TUnitResolver.AddMapDerivedUnits(const ABuildEvidence: TBuildEvidence;
  var ACompositionEvidence: TCompositionEvidence);
var
  LEvidenceItem: TBuildEvidenceItem;
  LResolvedUnit: TResolvedUnitInfo;
  LExistingResolvedUnit: TResolvedUnitInfo;
  LIsDuplicate: Boolean;
begin
  for LEvidenceItem in ABuildEvidence.EvidenceItems do
  begin
    if (LEvidenceItem.SourceKind <> besMapFile) or (Trim(LEvidenceItem.UnitName) = '') then
      Continue;

    LIsDuplicate := False;
    for LExistingResolvedUnit in ACompositionEvidence.Units do
    begin
      if SameText(LExistingResolvedUnit.UnitName, LEvidenceItem.UnitName) then
      begin
        LIsDuplicate := True;
        Break;
      end;
    end;

    if LIsDuplicate then
      Continue;

    LResolvedUnit := Default(TResolvedUnitInfo);
    LResolvedUnit.UnitName := LEvidenceItem.UnitName;
    LResolvedUnit.EvidenceKind := uekUnknown;
    LResolvedUnit.OriginKind := uokUnknown;
    LResolvedUnit.Confidence := rcStrong;
    LResolvedUnit.ContainerPath := LEvidenceItem.FilePath;
    LResolvedUnit.EvidenceSources := [besMapFile];
    ACompositionEvidence.Units.Add(LResolvedUnit);
  end;
end;

function TUnitResolver.Resolve(const AProjectInfo: TProjectInfo;
  const ABuildEvidence: TBuildEvidence): TCompositionEvidence;
begin
  Result := TCompositionEvidence.Create;
  Result.ProjectName := AProjectInfo.ProjectName;
  Result.ProjectVersion := AProjectInfo.Version;
  Result.Platform := AProjectInfo.Platform;
  Result.Configuration := AProjectInfo.Configuration;
  Result.GeneratedAt := DateToISO8601(Now, False);

  CopyUniqueWarnings(AProjectInfo.Warnings, Result.Warnings);
  CopyUniqueWarnings(ABuildEvidence.Warnings, Result.Warnings);
  AddMapDerivedUnits(ABuildEvidence, Result);
end;

end.