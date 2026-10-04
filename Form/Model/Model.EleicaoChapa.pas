unit Model.EleicaoChapa;

interface

type
  TEleicaoChapaEnvioDTO = class
  private
    FIdChapa    : Integer;
    FCodigo     : Integer;
    FIdEleicao  : Integer;
    FSituacao   : string;
    FNumChapa   : Integer;
    FNomeChapa  : string;
    FSlogan     : string;
    FObs        : string;
    FAtivo      : string;
    FGuidEmpresa: string;
    FAPIKey     : string;
  public
    property IdChapa    : Integer read FIdChapa write FIdChapa;
    property Codigo     : Integer read FCodigo write FCodigo;
    property IdEleicao  : Integer read FIdEleicao write FIdEleicao;
    property Situacao   : string read FSituacao write FSituacao;
    property NumChapa   : Integer read FNumChapa write FNumChapa;
    property NomeChapa  : string read FNomeChapa write FNomeChapa;
    property Slogan     : string read FSlogan write FSlogan;
    property Obs        : string read FObs write FObs;
    property Ativo      : string read FAtivo write FAtivo;
    property GuidEmpresa: string read FGuidEmpresa write FGuidEmpresa;
    property APIKey     : string read FAPIKey write FAPIKey;
  end;

implementation

end.
