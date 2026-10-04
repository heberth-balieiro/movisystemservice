unit Model.EleicaoConfig;

interface

type
  TEleicaoConfigEnvioDTO = class
  private
    FIdConfig          : Integer;
    FIdEleicao         : Integer;
    FSlug              : string;
    FNomeExibicao      : string;
    FMensagemBoasVindas: string;
    FUrlPublica        : string;
    FEmail             : string;
    FTelefone          : string;
    FCorPrimaria       : string;
    FCorSecundaria     : string;
    FUrlInstagram      : string;
    FUrlFacebook       : string;
    FUrlYoutube        : string;
    FPaginaPublicar    : string;
    FDataHoraInicio    : TDateTime;
    FDataHoraFim       : TDateTime;
    FGuidEmpresa       : string;
    FAPIKey            : string;
    Flogo: String;
    Fbanner: string;
    Fquorum_base: string;
    Fquorum_minimo: integer;
    Fexigir_presenca_votacao: string;
    Ftipo_quorum: string;
    Fvotacao_secreta: string;
    Fquorum_percentual: Double;
    Fencerramento_automatico: string;
    Fabertura_automatica: string;
    Fexibir_resultado_parcial: string;
    Fcontrolar_quorum: string;
    Fpublicacao_resultado: string;
    Fcontrolar_presenca: string;
  public
    property IdConfig          : Integer read FIdConfig write FIdConfig;
    property IdEleicao         : Integer read FIdEleicao write FIdEleicao;
    property Slug              : string read FSlug write FSlug;
    property NomeExibicao      : string read FNomeExibicao write FNomeExibicao;
    property MensagemBoasVindas: string read FMensagemBoasVindas write FMensagemBoasVindas;
    property UrlPublica        : string read FUrlPublica write FUrlPublica;
    property Email             : string read FEmail write FEmail;
    property Telefone          : string read FTelefone write FTelefone;
    property CorPrimaria       : string read FCorPrimaria write FCorPrimaria;
    property CorSecundaria     : string read FCorSecundaria write FCorSecundaria;
    property UrlInstagram      : string read FUrlInstagram write FUrlInstagram;
    property UrlFacebook       : string read FUrlFacebook write FUrlFacebook;
    property UrlYoutube        : string read FUrlYoutube write FUrlYoutube;
    property PaginaPublicar    : string read FPaginaPublicar write FPaginaPublicar;
    property DataHoraInicio    : TDateTime read FDataHoraInicio write FDataHoraInicio;
    property DataHoraFim       : TDateTime read FDataHoraFim write FDataHoraFim;
    property GuidEmpresa       : string read FGuidEmpresa write FGuidEmpresa;
    property APIKey            : string read FAPIKey write FAPIKey;
    property logo              : String read Flogo write Flogo;
    property banner            : string read Fbanner write Fbanner;

    property abertura_automatica        : string read Fabertura_automatica     write Fabertura_automatica;
    property encerramento_automatico    : string read Fencerramento_automatico     write Fencerramento_automatico;
    property votacao_secreta            : string read Fvotacao_secreta     write Fvotacao_secreta;
    property exibir_resultado_parcial   : string read Fexibir_resultado_parcial     write Fexibir_resultado_parcial;
    property publicacao_resultado       : string read Fpublicacao_resultado     write Fpublicacao_resultado;
    property controlar_quorum           : string read Fcontrolar_quorum     write Fcontrolar_quorum;
    property tipo_quorum                : string read Ftipo_quorum     write Ftipo_quorum;
    property quorum_minimo              : Integer read Fquorum_minimo    write Fquorum_minimo;
    property quorum_percentual          : Double read Fquorum_percentual    write Fquorum_percentual;
    property quorum_base                : string read Fquorum_base    write Fquorum_base;
    property controlar_presenca         : string read Fcontrolar_presenca    write Fcontrolar_presenca;
    property exigir_presenca_votacao    : string read Fexigir_presenca_votacao    write Fexigir_presenca_votacao;

  end;

implementation

end.
