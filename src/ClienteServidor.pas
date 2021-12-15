unit ClienteServidor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Datasnap.DBClient, Data.DB,
  Vcl.Grids, Vcl.DBGrids, Vcl.Buttons;


type
  TServidor = class
  private
    FPathServidor: String;
  public
    constructor Create;
    //Tipo do parâmetro não pode ser alterado
    function SalvarArquivos(AData: OleVariant; zRegistro: Integer; Chamada: String): Boolean;
  end;

  TfClienteServidor = class(TForm)
    ProgressBar: TProgressBar;
    btEnviarSemErros: TButton;
    btEnviarComErros: TButton;
    btEnviarParalelo: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btEnviarSemErrosClick(Sender: TObject);
    procedure btEnviarComErrosClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);

  private
    FPathCliente: String;
    FServidor: TServidor;

    function InitDataset: TClientDataset;
  public
  end;

var
  fClienteServidor: TfClienteServidor;

const
  QTD_ARQUIVOS_ENVIAR = 100;
  cPastaServidor = 'Servidor';

implementation

uses
  IOUtils, ClasseExcessoes;

{$R *.dfm}

procedure TfClienteServidor.btEnviarComErrosClick(Sender: TObject);
var
  cds: TClientDataset;
  i: Integer;
  Sucesso: Boolean;
  zArqSalvos: array of integer;
  FileName, PathServidor: string;
begin
  ProgressBar.Max := QTD_ARQUIVOS_ENVIAR;
  ProgressBar.Position := 0;
  Sucesso := True;

  Try
    for i := 0 to QTD_ARQUIVOS_ENVIAR do
    begin
      cds := InitDataset;
      cds.Append;
      TBlobField(cds.FieldByName('Arquivo')).LoadFromFile(FPathCliente);
      cds.Post;

      if not FServidor.SalvarArquivos(cds.Data, i+1, TButton(Sender).Caption) then
        Sucesso := False;

      SetLength(zArqSalvos, i+1);
      zArqSalvos[i] := i+1;

      cds.Close;
      FreeAndNil(cds);
      ProgressBar.Position := ProgressBar.Position + 1;

      {$REGION Simulação de erro, não alterar }
      if i = (QTD_ARQUIVOS_ENVIAR/2) then
        if not FServidor.SalvarArquivos(NULL, i+1, TButton(Sender).Caption) then
        begin
          Sucesso := False;
          ProgressBar.Position := ProgressBar.Max;
          Break;
        end;
      {$ENDREGION}

    end;
  Except
    on E : Exception do
    begin
      TClasseExcecoes.TratarExcecao(E, TButton(Sender).Caption);
      Sucesso := False;
    end;    
  End;

  if Sucesso then
    Application.MessageBox('Envio realizado com sucesso!', 'Processo Finalizado', 64)
  else
  begin
    { Caso ocorra algum erro, excluido todos arquivos salvos no lote }
    PathServidor := ExtractFilePath(ParamStr(0)) + cPastaServidor + '\';
    for i := 0 to High(zArqSalvos) do
    begin
      FileName := PathServidor + IntToStr(i+1) + '.pdf';
      if TFile.Exists(FileName) then
        TFile.Delete(FileName);
    end;
  end;
end;

procedure TfClienteServidor.btEnviarSemErrosClick(Sender: TObject);
var
  cds: TClientDataset;
  i: Integer;
  Sucesso: Boolean;
begin
  Sucesso := True;
  ProgressBar.Max := QTD_ARQUIVOS_ENVIAR;
  ProgressBar.Position := 0;

  for i := 0 to QTD_ARQUIVOS_ENVIAR do
  begin
    try
      cds := InitDataset;
      cds.Append;
      TBlobField(cds.FieldByName('Arquivo')).LoadFromFile(FPathCliente);
      cds.Post;

      if not FServidor.SalvarArquivos(cds.Data, i+1, TButton(Sender).Caption) then
      begin
        Sucesso := False;
        Break;
      end;

      cds.Close;
      FreeAndNil(cds);
      ProgressBar.Position := ProgressBar.Position + 1;
    Except
      on E : Exception do
      begin
        TClasseExcecoes.TratarExcecao(E, TButton(Sender).Caption);
        Sucesso := False;
      end;    
    end;
  end;

  if Sucesso then
    Application.MessageBox('Envio realizado com sucesso!', 'Processo Finalizado', 64)
  else
    Application.MessageBox('Ocorreu erro durante envio, verifique arquivo de log!', 'Processo Cancelado', 48);
end;

procedure TfClienteServidor.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  FreeAndNil(FServidor);
end;

procedure TfClienteServidor.FormCreate(Sender: TObject);
begin
  inherited;
  FPathCliente := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'pdf.pdf';
  FServidor := TServidor.Create;
end;

function TfClienteServidor.InitDataset: TClientDataset;
begin
  Result := TClientDataset.Create(nil);
  Result.FieldDefs.Add('Arquivo', ftBlob);
  Result.CreateDataSet;
end;

{ TServidor }
constructor TServidor.Create;
begin
  FPathServidor := ExtractFilePath(ParamStr(0)) + cPastaServidor + '\';
  ForceDirectories(FPathServidor);
end;

function TServidor.SalvarArquivos(AData: OleVariant; zRegistro: Integer; Chamada: String): Boolean;
var
  cds: TClientDataSet;
  FileName: string;
begin
  Try
    try
      cds := TClientDataset.Create(nil);
      cds.Data := AData;

      {$REGION Simulação de erro, não alterar}
      if cds.RecordCount = 0 then
        begin
          Result := False;
          Exit;
        end;
      {$ENDREGION}

      cds.First;

      while not cds.Eof do
      begin
        FileName := FPathServidor + IntToStr(zRegistro) {cds.RecNo.ToString} + '.pdf';
        if TFile.Exists(FileName) then
          TFile.Delete(FileName);

        TBlobField(cds.FieldByName('Arquivo')).SaveToFile(FileName);
        cds.Next;
      end;

      Result := True;
    except
      on E : Exception do
      begin
        TClasseExcecoes.TratarExcecao(E, Chamada);
        Result := False;
      end;
    end;
  Finally
    cds.Close;
    FreeAndNil(cds);
  End;
end;

end.
