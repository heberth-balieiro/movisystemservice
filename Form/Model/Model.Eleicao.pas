unit Model.Eleicao;

interface

type
  TEleicaoEnvioDTO = class
  private
    FIdEleicao  : Integer;
    FCodigo     : Integer;
    FNome       : string;
    FDescricao  : string;
    FAno        : Integer;
    FAnoFim     : Integer;
    FAtivo      : string;
    FTipo       : string;
    FSituacao   : string;
    FGuidEmpresa: string;
    FAPIKey     : string;
    Foperacao: string;
  public
    property IdEleicao   : Integer read FIdEleicao   write FIdEleicao;
    property Codigo      : Integer read FCodigo      write FCodigo;
    property Nome        : string  read FNome        write FNome;
    property Descricao   : string  read FDescricao   write FDescricao;
    property Ano         : Integer read FAno         write FAno;
    property AnoFim      : Integer read FAnoFim      write FAnoFim;
    property Ativo       : string  read FAtivo       write FAtivo;
    property Tipo        : string  read FTipo        write FTipo;
    property Situacao    : string  read FSituacao    write FSituacao;
    property GuidEmpresa : string  read FGuidEmpresa write FGuidEmpresa;
    property APIKey      : string  read FAPIKey      write FAPIKey;
    property operacao    : string  read Foperacao    write Foperacao;
  end;

implementation

end.
