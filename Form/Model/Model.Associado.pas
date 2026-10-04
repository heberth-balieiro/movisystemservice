unit Model.Associado;

interface

type
  TAssociadoEnvioDTO = class
  private
    FIdSocio: Integer;
    FCodigo: Integer;
    FMatricula: Integer;
    FAtivo: string;
    FNome: string;
    FApelido: string;
    FTelefone: string;
    FCelular: string;
    FWhatsApp: string;
    FCPF: string;
    FNascimento: TDateTime;
    FEmail: string;
    FCidade: string;
    FSecretaria: string;
    FProfissao: string;
    FLotacao: string;
    FLocalTrabalho: string;
    FFuncao: string;
    FNaturalDe: string;
    FRG: string;
    FDataFiliacao: TDateTime;
    FPai: string;
    FMae: string;
    FFoto: string;
    FBloqueado: string;
    FExcluido: Integer;
    FGuidEmpresa: string;
    FAPIKey: string;
  public
    property IdSocio: Integer read FIdSocio write FIdSocio;
    property Codigo: Integer read FCodigo write FCodigo;
    property Matricula: Integer read FMatricula write FMatricula;
    property Ativo: string read FAtivo write FAtivo;
    property Nome: string read FNome write FNome;
    property Apelido: string read FApelido write FApelido;
    property Telefone: string read FTelefone write FTelefone;
    property Celular: string read FCelular write FCelular;
    property WhatsApp: string read FWhatsApp write FWhatsApp;
    property CPF: string read FCPF write FCPF;
    property Nascimento: TDateTime read FNascimento write FNascimento;
    property Email: string read FEmail write FEmail;
    property Cidade: string read FCidade write FCidade;
    property Secretaria: string read FSecretaria write FSecretaria;
    property Profissao: string read FProfissao write FProfissao;
    property Lotacao: string read FLotacao write FLotacao;
    property LocalTrabalho: string read FLocalTrabalho write FLocalTrabalho;
    property Funcao: string read FFuncao write FFuncao;
    property NaturalDe: string read FNaturalDe write FNaturalDe;
    property RG: string read FRG write FRG;
    property DataFiliacao: TDateTime read FDataFiliacao write FDataFiliacao;
    property Pai: string read FPai write FPai;
    property Mae: string read FMae write FMae;
    property Foto: string read FFoto write FFoto;
    property Bloqueado: string read FBloqueado write FBloqueado;
    property Excluido: Integer read FExcluido write FExcluido;
    property GuidEmpresa: string read FGuidEmpresa write FGuidEmpresa;
    property APIKey: string read FAPIKey write FAPIKey;
  end;

implementation

end.
