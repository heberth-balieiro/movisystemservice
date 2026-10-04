unit Model.Empresa;

interface

type
  TEmpresaModel = class
  private
    FIdEmpresa             : Integer;
    FUUID                  : string;
    FRazao                 : string;
    FFantasia              : string;
    FTelefone              : string;
    FAtivo                 : string;
    FCPFCNPJ               : string;
    FWhatsAppURL           : string;
    FWhatsAppInstancia     : string;
    FWhatsAppToken         : string;
    FEasyOneAPIKey         : string;
    FEasyOneIntegracaoAtivo: string;
  public
    property IdEmpresa             : Integer read FIdEmpresa              write FIdEmpresa;
    property UUID                  : string  read FUUID                   write FUUID;
    property Razao                 : string  read FRazao                  write FRazao;
    property Fantasia              : string  read FFantasia               write FFantasia;
    property Telefone              : string  read FTelefone               write FTelefone;
    property Ativo                 : string  read FAtivo                  write FAtivo;
    property CPFCNPJ               : string  read FCPFCNPJ                write FCPFCNPJ;
    property WhatsAppURL           : string  read FWhatsAppURL            write FWhatsAppURL;
    property WhatsAppInstancia     : string  read FWhatsAppInstancia      write FWhatsAppInstancia;
    property WhatsAppToken         : string  read FWhatsAppToken          write FWhatsAppToken;
    property EasyOneAPIKey         : string  read FEasyOneAPIKey          write FEasyOneAPIKey;
    property EasyOneIntegracaoAtivo: string  read FEasyOneIntegracaoAtivo write FEasyOneIntegracaoAtivo;
  end;

implementation

end.
