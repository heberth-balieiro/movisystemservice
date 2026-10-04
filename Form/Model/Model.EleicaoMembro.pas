unit Model.EleicaoMembro;

interface

type
  TEleicaoMembroEnvioDTO = class
  private
    FIdMembro: Integer;
    FIdEleicao: Integer;
    FIdChapa: Integer;
    FCodigo: Integer;
    FNome: string;
    FCPF: string;
    FTelefone: string;
    FEmail: string;
    FAtivo: string;
    FCargo: string;
    FTipo: string;
    FObservacao: string;
    FArquivoFoto: string;
    FExtensaoFoto: string;
    FGuidEmpresa: string;
    FAPIKey: string;
  public
    property IdMembro: Integer read FIdMembro write FIdMembro;
    property IdEleicao: Integer read FIdEleicao write FIdEleicao;
    property IdChapa: Integer read FIdChapa write FIdChapa;
    property Codigo: Integer read FCodigo write FCodigo;
    property Nome: string read FNome write FNome;
    property CPF: string read FCPF write FCPF;
    property Telefone: string read FTelefone write FTelefone;
    property Email: string read FEmail write FEmail;
    property Ativo: string read FAtivo write FAtivo;
    property Cargo: string read FCargo write FCargo;
    property Tipo: string read FTipo write FTipo;
    property Observacao: string read FObservacao write FObservacao;
    property ArquivoFoto: string read FArquivoFoto write FArquivoFoto;
    property ExtensaoFoto: string read FExtensaoFoto write FExtensaoFoto;
    property GuidEmpresa: string read FGuidEmpresa write FGuidEmpresa;
    property APIKey: string read FAPIKey write FAPIKey;
  end;

implementation

end.
