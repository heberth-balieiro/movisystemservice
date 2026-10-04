object Easybotservice: TEasybotservice
  DisplayName = 'Easybotservice'
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 480
  Width = 640
  object Conn: TUniConnection
    Left = 48
    Top = 200
  end
  object QryMsG: TUniQuery
    Connection = Conn
    Left = 48
    Top = 72
  end
  object UniTransaction: TUniTransaction
    DefaultConnection = Conn
    Left = 80
    Top = 16
  end
  object Provider: TMySQLUniProvider
    Left = 128
    Top = 16
  end
  object TimerEnvio: TTimer
    Enabled = False
    Left = 240
    Top = 256
  end
  object TimerSincronizarAPI: TTimer
    Enabled = False
    Interval = 40000
    Left = 368
    Top = 256
  end
  object QrySincronizar: TUniQuery
    Connection = Conn
    Transaction = UniTransaction
    Left = 128
    Top = 72
  end
  object QryAuxiliar: TUniQuery
    Connection = Conn
    Transaction = UniTransaction
    Left = 304
    Top = 56
  end
  object QryLog: TUniQuery
    Connection = Conn
    Transaction = UniTransaction
    Left = 296
    Top = 104
  end
  object TimerEleicao: TTimer
    Enabled = False
    Interval = 30000
    Left = 232
    Top = 336
  end
end
