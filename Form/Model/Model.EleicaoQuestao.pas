unit Model.EleicaoQuestao;

interface

type
  TEleicaoQuestaoEnvioDTO = class
  private
    Ftitulo: string;
    FAPIKey: string;
    Fativo: string;
    Ftipo_resposta: string;
    Fdescricao: string;
    Fid_questao: Integer;
    FGuidEmpresa: string;
    Fordem: Integer;
    Fid_eleicao: Integer;
    Fobrigatoria: string;

  public
    property id_questao       : Integer     read Fid_questao write Fid_questao;
    property id_eleicao       : Integer     read Fid_eleicao write Fid_eleicao;
    property titulo           : string      read Ftitulo write Ftitulo;
    property descricao        : string      read Fdescricao write Fdescricao;
    property ordem            : Integer     read Fordem write Fordem;
    property tipo_resposta    : string      read Ftipo_resposta write Ftipo_resposta;
    property obrigatoria      : string      read Fobrigatoria write Fobrigatoria;
    property ativo            : string      read Fativo write Fativo;
    property GuidEmpresa      : string read FGuidEmpresa write FGuidEmpresa;
    property APIKey           : string read FAPIKey write FAPIKey;
end;

type
  TEleicaoQuestaoOpcaoEnvioDTO = class
  private
    FAPIKey: string;
    Fativo: string;
    Fdescricao: string;
    Fid_questao: Integer;
    FGuidEmpresa: string;
    Fid_opcao: Integer;
    Fordem: Integer;
    Fid_eleicao: Integer;

  public
    property id_opcao     : Integer read Fid_opcao write Fid_opcao;
    property id_questao   : Integer read Fid_questao write Fid_questao;
    property id_eleicao   : Integer read Fid_eleicao write Fid_eleicao;
    property ordem        : Integer read Fordem write Fordem;
    property descricao    : string read Fdescricao write Fdescricao;
    property ativo        : string read Fativo write Fativo;
    property GuidEmpresa  : string read FGuidEmpresa write FGuidEmpresa;
    property APIKey       : string read FAPIKey write FAPIKey;
end;

implementation

end.
