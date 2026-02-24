/// <summary>
/// DX.Comply.HashService
/// Provides cryptographic hash computation for files.
/// </summary>
///
/// <remarks>
/// This unit provides THashService which computes cryptographic hashes:
/// - SHA-256 (default for CycloneDX)
/// - SHA-512 (recommended by BSI TR-03183-2)
///
/// Uses System.Hash for efficient, streaming hash computation.
/// </remarks>
///
/// <copyright>
/// Copyright © 2026 Olaf Monien
/// Licensed under MIT
/// </copyright>

unit DX.Comply.HashService;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Hash,
  DX.Comply.Engine.Intf;

type
  /// <summary>
  /// Hash algorithm selection for internal use.
  /// </summary>
  THashAlgo = (haSHA256, haSHA512);

  /// <summary>
  /// Implementation of IHashService using System.Hash.
  /// </summary>
  THashService = class(TInterfacedObject, IHashService)
  private
    const
      /// <summary>Buffer size for file reading (64 KB).</summary>
      cBufferSize = 65536;
  private
    function ComputeHash(const AFilePath: string; AAlgorithm: THashAlgo): string;
  public
    // IHashService
    function ComputeSha256(const AFilePath: string): string;
    function ComputeSha512(const AFilePath: string): string;
  end;

implementation

{ THashService }

function THashService.ComputeHash(const AFilePath: string; AAlgorithm: THashAlgo): string;
var
  LStream: TFileStream;
  LBuffer: TBytes;
  LBytesRead: Integer;
  LHash: THashSHA2;
begin
  Result := '';
  if not FileExists(AFilePath) then
    Exit;

  LStream := nil;
  try
    LStream := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyNone);
    SetLength(LBuffer, cBufferSize);

    case AAlgorithm of
      haSHA256:
        LHash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
      haSHA512:
        LHash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA512);
    else
      LHash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
    end;

    repeat
      LBytesRead := LStream.Read(LBuffer[0], cBufferSize);
      if LBytesRead > 0 then
        LHash.Update(LBuffer, LBytesRead);
    until LBytesRead < cBufferSize;

    Result := LHash.HashAsString;
  finally
    LStream.Free;
  end;
end;

function THashService.ComputeSha256(const AFilePath: string): string;
begin
  Result := ComputeHash(AFilePath, haSHA256);
end;

function THashService.ComputeSha512(const AFilePath: string): string;
begin
  Result := ComputeHash(AFilePath, haSHA512);
end;

end.
