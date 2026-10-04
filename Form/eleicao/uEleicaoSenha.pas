unit uEleicaoSenha;

interface

uses
  System.SysUtils;

function GerarSenhaAPI(const ASenha: string): string;

implementation

uses
  System.Hash,
  System.NetEncoding,
  System.Classes,
  Winapi.Windows;

const
  ALGO_TAG   = 'pbkdf2$sha256';
  ITERATIONS = 100000;
  SALT_LEN   = 16;
  DK_LEN     = 32;
  BCRYPT_USE_SYSTEM_PREFERRED_RNG = $00000002;

function BCryptGenRandom(hAlgorithm: Pointer; pbBuffer: PByte; cbBuffer: ULONG; dwFlags: ULONG): ULONG; stdcall;
  external 'bcrypt.dll' name 'BCryptGenRandom';

function CryptoRandomBytes(const ALen: Integer): TBytes;
var
  Status: ULONG;
begin
  if ALen <= 0 then Exit(nil);

  SetLength(Result,ALen);
  Status := BCryptGenRandom(nil,@Result[0],ALen,BCRYPT_USE_SYSTEM_PREFERRED_RNG);

  if Status <> 0 then
    raise Exception.CreateFmt('BCryptGenRandom falhou. Status=%d',[Status]);
end;

function IntToBytesBE(const Value: Cardinal): TBytes;
begin
  SetLength(Result,4);
  Result[0] := Byte((Value shr 24) and $FF);
  Result[1] := Byte((Value shr 16) and $FF);
  Result[2] := Byte((Value shr 8) and $FF);
  Result[3] := Byte(Value and $FF);
end;

function PBKDF2_HMAC_SHA256(const Password, Salt: TBytes; const Iterations, DKLen: Integer): TBytes;
var
  I, J, K, L, R, HLen, X: Integer;
  U, T, SaltBlock, BlockIndex: TBytes;
begin
  HLen := 32;
  L := (DKLen + HLen - 1) div HLen;
  R := DKLen - (L - 1) * HLen;

  SetLength(Result,DKLen);
  SetLength(SaltBlock,Length(Salt) + 4);

  if Length(Salt) > 0 then Move(Salt[0],SaltBlock[0],Length(Salt));

  K := 0;

  for I := 1 to L do
  begin
    BlockIndex := IntToBytesBE(I);
    Move(BlockIndex[0],SaltBlock[Length(Salt)],4);

    U := THashSHA2.GetHMACAsBytes(SaltBlock,Password,THashSHA2.TSHA2Version.SHA256);
    T := Copy(U,0,Length(U));

    for J := 2 to Iterations do
    begin
      U := THashSHA2.GetHMACAsBytes(U,Password,THashSHA2.TSHA2Version.SHA256);

      for X := 0 to High(T) do
        T[X] := T[X] xor U[X];
    end;

    if I = L then
      Move(T[0],Result[K],R)
    else
    begin
      Move(T[0],Result[K],HLen);
      Inc(K,HLen);
    end;
  end;
end;

function GerarSenhaAPI(const ASenha: string): string;
var
  Salt, DK: TBytes;
begin
  if Trim(ASenha).IsEmpty then
    raise Exception.Create('Senha não informada.');

  Salt := CryptoRandomBytes(SALT_LEN);

  DK := PBKDF2_HMAC_SHA256(
    TEncoding.UTF8.GetBytes(ASenha),
    Salt,
    ITERATIONS,
    DK_LEN
  );

  Result := Format('%s$%d$%s$%s',[
    ALGO_TAG,
    ITERATIONS,
    TNetEncoding.Base64.EncodeBytesToString(Salt),
    TNetEncoding.Base64.EncodeBytesToString(DK)
  ]);
end;

end.
