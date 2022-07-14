program Compositing;



uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Types,
  Skia.FMX,
  MainUnit in 'MainUnit.pas' {frmShaderView},
  FunctionLibrary in 'FunctionLibrary.pas',
  Shaders in 'Shaders.pas';

{$R *.res}

begin
  GlobalUseSkia := True;
  ReportMemoryLeaksOnShutdown := True;
  //For macOS/iOS
  GlobalUseMetal := True;

  // GPU is priorty everywhere but Windows,
  // this line improves Windows shader performance
  GlobalUseSkiaRasterWhenAvailable := False;

  Application.Initialize;
  Application.CreateForm(TfrmShaderView, frmShaderView);
  Application.Run;
end.
