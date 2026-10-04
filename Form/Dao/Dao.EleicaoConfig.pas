unit Dao.EleicaoConfig;

interface

uses
  Uni,
  Model.EleicaoConfig;

type
  TDaoEleicaoConfig = class
  public
    class function BuscarParaSincronizacao(AConn: TUniConnection; const AIDRegistro: Integer): TEleicaoConfigEnvioDTO; static;
    class procedure AtualizarSincronizacao(AConn: TUniConnection; const AIDRegistro: Integer); static;
  end;

implementation

uses
  System.SysUtils;

class function TDaoEleicaoConfig.BuscarParaSincronizacao(AConn: TUniConnection;
                            const AIDRegistro: Integer): TEleicaoConfigEnvioDTO;
const
  SQL =
    'SELECT ec.id, ec.id_eleicao, ec.slug, ec.nome_exibicao, ec.mensagem_boas_vindas, ec.url_publica, ec.email,ec.telefone,'+
    ' ec.cor_primaria, ec.cor_secundaria, ec.url_instagram, ec.url_facebook, ec.url_youtube, ec.pagina_publicar,'+
    ' ec.data_hora_inicio, ec.data_hora_fim, e.guid, e.token_api, ec.logo, ec.banner,  '+
    ' ec.abertura_automatica, ec.encerramento_automatico, ec.votacao_secreta, ec.exibir_resultado_parcial, '+
    ' ec.publicacao_resultado, ec.controlar_quorum, ec.tipo_quorum, ec.quorum_minimo, ec.quorum_percentual,   '+
    ' ec.quorum_base, ec.controlar_presenca, ec.exigir_presenca_votacao                                 '+
    ' FROM eleicao_configuracao ec '+
    ' INNER JOIN empresa e '+
    ' ON e.id_empresa = ec.id_empresa '+
    ' WHERE ec.id= :id AND ec.sinc_app=''S'' LIMIT 1';
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := SQL;
    Qry.ParamByName('id').AsInteger := AIDRegistro;
    Qry.Open;

    if Qry.IsEmpty then Exit;

    Result := TEleicaoConfigEnvioDTO.Create;
    try
      Result.IdConfig           := Qry.FieldByName('id').AsInteger;
      Result.IdEleicao          := Qry.FieldByName('id_eleicao').AsInteger;
      Result.Slug               := Trim(Qry.FieldByName('slug').AsString);
      Result.NomeExibicao       := Trim(Qry.FieldByName('nome_exibicao').AsString);
      Result.MensagemBoasVindas := Trim(Qry.FieldByName('mensagem_boas_vindas').AsString);
      Result.UrlPublica         := Trim(Qry.FieldByName('url_publica').AsString);
      Result.Email              := Trim(Qry.FieldByName('email').AsString);
      Result.Telefone           := Trim(Qry.FieldByName('telefone').AsString);
      Result.CorPrimaria        := Trim(Qry.FieldByName('cor_primaria').AsString);
      Result.CorSecundaria      := Trim(Qry.FieldByName('cor_secundaria').AsString);
      Result.UrlInstagram       := Trim(Qry.FieldByName('url_instagram').AsString);
      Result.UrlFacebook        := Trim(Qry.FieldByName('url_facebook').AsString);
      Result.UrlYoutube         := Trim(Qry.FieldByName('url_youtube').AsString);
      Result.PaginaPublicar     := Trim(Qry.FieldByName('pagina_publicar').AsString);

      if not Qry.FieldByName('data_hora_inicio').IsNull then
        Result.DataHoraInicio := Qry.FieldByName('data_hora_inicio').AsDateTime;
      if not Qry.FieldByName('data_hora_fim').IsNull then
        Result.DataHoraFim    := Qry.FieldByName('data_hora_fim').AsDateTime;

      Result.GuidEmpresa := Trim(Qry.FieldByName('guid').AsString);
      Result.APIKey := Trim(Qry.FieldByName('token_api').AsString);

      Result.logo         := Qry.FieldByName('logo').AsString;
      Result.banner       := Qry.FieldByName('banner').AsString;

      Result.abertura_automatica          := Qry.FieldByName('abertura_automatica').AsString;
      Result.encerramento_automatico      := Qry.FieldByName('encerramento_automatico').AsString;
      Result.votacao_secreta              := Qry.FieldByName('votacao_secreta').AsString;
      Result.exibir_resultado_parcial     := Qry.FieldByName('exibir_resultado_parcial').AsString;
      Result.publicacao_resultado         := Qry.FieldByName('publicacao_resultado').AsString;
      Result.controlar_quorum             := Qry.FieldByName('controlar_quorum').AsString;
      Result.tipo_quorum                  := Qry.FieldByName('tipo_quorum').AsString;
      Result.quorum_minimo                := Qry.FieldByName('quorum_minimo').AsInteger;
      Result.quorum_percentual            := Qry.FieldByName('quorum_percentual').AsFloat;
      Result.quorum_base                  := Qry.FieldByName('quorum_base').AsString;
      Result.controlar_presenca           := Qry.FieldByName('controlar_presenca').AsString;
      Result.exigir_presenca_votacao      := Qry.FieldByName('exigir_presenca_votacao').AsString;

    except
      Result.Free;
      raise;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TDaoEleicaoConfig.AtualizarSincronizacao(AConn: TUniConnection; const AIDRegistro: Integer);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'UPDATE eleicao_configuracao SET sinc_app=''N'' WHERE id=:id';
    Qry.ParamByName('id').AsInteger := AIDRegistro;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
