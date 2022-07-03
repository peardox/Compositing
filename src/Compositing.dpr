program Compositing;



uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Types,
  Skia.FMX,
  Compositing in 'Compositing.pas' {frmShaderView};

{$R *.res}

begin
  GlobalUseSkia := True;

  //For macOS/iOS
  GlobalUseMetal := True;

  // GPU is priorty everywhere but Windows,
  // this line improves Windows shader performance
  GlobalUseSkiaRasterWhenAvailable := False;

  Application.Initialize;
  Application.CreateForm(TfrmShaderView, frmShaderView);
  Application.Run;
end.
