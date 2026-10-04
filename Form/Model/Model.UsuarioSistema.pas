unit Model.UsuarioSistema;

interface

type
  TUsuarioSistemaEnvioDTO = class
  private
    FIdUsuario  : Integer;
    FNome       : string;
    FLogin      : string;
    FSenha      : string;
    FAtivo      : string;
    FEmail      : string;
    FSistema    : string;
    FExcluido   : Integer;
    FGuidEmpresa: string;
    FAPIKey     : string;
  public
    property IdUsuario   : Integer read FIdUsuario write FIdUsuario;
    property Nome        : string read FNome write FNome;
    property Login       : string read FLogin write FLogin;
    property Senha       : string read FSenha write FSenha;
    property Ativo       : string read FAtivo write FAtivo;
    property Email       : string read FEmail write FEmail;
    property Sistema     : string read FSistema write FSistema;
    property Excluido    : Integer read FExcluido write FExcluido;
    property GuidEmpresa : string read FGuidEmpresa write FGuidEmpresa;
    property APIKey      : string read FAPIKey write FAPIKey;

  end;

type
  TUsuarioAPTOSEnvioDTO = class
  private
    FAPIKey: string;
    FEmail: string;
    FAtivo: string;
    Fideleitor: Integer;
    FGuidEmpresa: string;
    FSenha: string;
    FLogin: string;
    FNome: string;
    Fidassociado: integer;

  public
    property ideleitor   : Integer  read Fideleitor   write Fideleitor;
    property Nome        : string   read FNome        write FNome;
    property Login       : string   read FLogin       write FLogin;
    property Senha       : string   read FSenha       write FSenha;
    property Ativo       : string   read FAtivo       write FAtivo;
    property Email       : string   read FEmail       write FEmail;
    property GuidEmpresa : string   read FGuidEmpresa write FGuidEmpresa;
    property APIKey      : string   read FAPIKey      write FAPIKey;
    property idassociado : integer read Fidassociado  write Fidassociado;
  end;

implementation

end.
