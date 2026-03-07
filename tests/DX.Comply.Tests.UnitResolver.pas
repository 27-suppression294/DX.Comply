/// <summary>
/// DX.Comply.Tests.UnitResolver
/// DUnitX tests for TUnitResolver.
/// </summary>
///
/// <remarks>
/// Verifies the first-pass resolver envelope before real unit-closure logic is
/// added in later slices.
/// </remarks>
///
/// <copyright>
/// Copyright © 2026 Olaf Monien
/// Licensed under MIT
/// </copyright>

unit DX.Comply.Tests.UnitResolver;

interface

uses
  DUnitX.TestFramework,
  DX.Comply.Engine.Intf,
  DX.Comply.BuildEvidence.Intf,
  DX.Comply.UnitResolver;

type
  /// <summary>
  /// DUnitX fixture for the first-pass unit resolver.
  /// </summary>
  [TestFixture]
  TUnitResolverTests = class
  private
    FResolver: IUnitResolver;
  public
    [Setup]
    procedure Setup;

    /// <summary>
    /// Project metadata must be mapped into the composition evidence envelope.
    /// </summary>
    [Test]
    procedure Resolve_MapsProjectMetadata;

    /// <summary>
    /// Project and build evidence warnings must be merged uniquely.
    /// </summary>
    [Test]
    procedure Resolve_MergesWarningsUniquely;

    /// <summary>
    /// The initial resolver slice must not invent unit entries yet.
    /// </summary>
    [Test]
    procedure Resolve_StartsWithEmptyUnits;
  end;

implementation

procedure TUnitResolverTests.Setup;
begin
  FResolver := TUnitResolver.Create;
end;

procedure TUnitResolverTests.Resolve_MapsProjectMetadata;
var
  LBuildEvidence: TBuildEvidence;
  LCompositionEvidence: TCompositionEvidence;
  LProjectInfo: TProjectInfo;
begin
  LProjectInfo := TProjectInfo.Create;
  LBuildEvidence := TBuildEvidence.Create;
  try
    LProjectInfo.ProjectName := 'DX.Comply';
    LProjectInfo.Version := '1.2.3.4';
    LProjectInfo.Platform := 'Win64';
    LProjectInfo.Configuration := 'Release';

    LCompositionEvidence := FResolver.Resolve(LProjectInfo, LBuildEvidence);
    try
      Assert.AreEqual('DX.Comply', LCompositionEvidence.ProjectName,
        'ProjectName must be copied into the composition evidence envelope');
      Assert.AreEqual('1.2.3.4', LCompositionEvidence.ProjectVersion,
        'ProjectVersion must be copied into the composition evidence envelope');
      Assert.AreEqual('Win64', LCompositionEvidence.Platform,
        'Platform must be copied into the composition evidence envelope');
      Assert.AreEqual('Release', LCompositionEvidence.Configuration,
        'Configuration must be copied into the composition evidence envelope');
      Assert.IsTrue(LCompositionEvidence.GeneratedAt <> '',
        'GeneratedAt must be populated by the resolver');
    finally
      LCompositionEvidence.Free;
    end;
  finally
    LBuildEvidence.Free;
    LProjectInfo.Free;
  end;
end;

procedure TUnitResolverTests.Resolve_MergesWarningsUniquely;
var
  LBuildEvidence: TBuildEvidence;
  LCompositionEvidence: TCompositionEvidence;
  LProjectInfo: TProjectInfo;
begin
  LProjectInfo := TProjectInfo.Create;
  LBuildEvidence := TBuildEvidence.Create;
  try
    LProjectInfo.Warnings.Add('Shared warning');
    LProjectInfo.Warnings.Add('Project warning');
    LBuildEvidence.Warnings.Add('Shared warning');
    LBuildEvidence.Warnings.Add('Build warning');

    LCompositionEvidence := FResolver.Resolve(LProjectInfo, LBuildEvidence);
    try
      Assert.AreEqual(3, LCompositionEvidence.Warnings.Count,
        'Warnings from project and build evidence must be merged without duplicates');
      Assert.IsTrue(LCompositionEvidence.Warnings.Contains('Project warning'),
        'Project warnings must be preserved');
      Assert.IsTrue(LCompositionEvidence.Warnings.Contains('Build warning'),
        'Build evidence warnings must be preserved');
    finally
      LCompositionEvidence.Free;
    end;
  finally
    LBuildEvidence.Free;
    LProjectInfo.Free;
  end;
end;

procedure TUnitResolverTests.Resolve_StartsWithEmptyUnits;
var
  LBuildEvidence: TBuildEvidence;
  LCompositionEvidence: TCompositionEvidence;
  LProjectInfo: TProjectInfo;
begin
  LProjectInfo := TProjectInfo.Create;
  LBuildEvidence := TBuildEvidence.Create;
  try
    LCompositionEvidence := FResolver.Resolve(LProjectInfo, LBuildEvidence);
    try
      Assert.AreEqual(0, LCompositionEvidence.Units.Count,
        'The initial resolver slice must return an empty unit list until unit closure logic exists');
    finally
      LCompositionEvidence.Free;
    end;
  finally
    LBuildEvidence.Free;
    LProjectInfo.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TUnitResolverTests);

end.