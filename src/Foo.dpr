program Foo;

uses
  Vcl.Forms,
  Main in 'Main.pas' {fMain},
  DatasetLoop in 'DatasetLoop.pas' {fDatasetLoop},
  ClienteServidor in 'ClienteServidor.pas' {fClienteServidor},
  ClasseExcessoes in 'ClasseExcessoes.pas',
  Threads in 'Threads.pas' {fThreads};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfMain, fMain);
  Application.CreateForm(TfClienteServidor, fClienteServidor);
  Application.CreateForm(TfDatasetLoop, fDatasetLoop);
  Application.CreateForm(TfThreads, fThreads);
  Application.Run;
end.

