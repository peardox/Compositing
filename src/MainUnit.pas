unit MainUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, StrUtils, Math,
  FMX.Memo.Types, FMX.StdCtrls, FMX.Controls.Presentation, FMX.ScrollBox,
  FMX.Memo, FMX.TabControl, Skia, Skia.FMX, FMX.Layouts, FMX.MultiView,
  FMX.ListBox, FMX.Ani, FMX.Effects, FMX.Objects, FMX.Menus,
  Skia.FMX.Graphics, Shaders;

type
  TfrmShaderView = class(TForm)
    pnlContainer: TPanel;
    pnlToolBox: TPanel;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    TrackBar1: TTrackBar;
    TrackBar2: TTrackBar;

    OpenDialog1: TOpenDialog;
    MainMenu1: TMainMenu;
    FileMenu: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    CheckBox4: TCheckBox;
    CheckBox5: TCheckBox;
    VertScrollBox1: TVertScrollBox;
    Label7: TLabel;
    Label8: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    DrawSpace: TRectangle;
    CheckBox6: TCheckBox;
    Label16: TLabel;
    Label17: TLabel;
    SaveDialog1: TSaveDialog;
    Label18: TLabel;
    Label19: TLabel;
    ComboBox1: TComboBox;

    procedure FormCreate(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure TrackBar2Change(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure CheckBox4Change(Sender: TObject);
    procedure CheckBox5Change(Sender: TObject);
    procedure CheckBox1Change(Sender: TObject);
    procedure CheckBox2Change(Sender: TObject);
    procedure CheckBox3Change(Sender: TObject);
    procedure ShowInfo;
    procedure DrawSpaceResize(Sender: TObject);
    procedure CheckBox6Change(Sender: TObject);
    procedure SaveLayers(Sender: TObject);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
  private
    FSaveInNextPaint: Boolean;
    FPaintCount: Int64;
    FstopWatch: TDateTime;
    procedure DoSaveLayers;
  public
    { Public declarations }
    Grid: TGridShader;
    Layer: TLayerShader;
    Layer2: TLayerShader;
    Container: TAspectLayout;
  end;

var
  frmShaderView: TfrmShaderView;

implementation

{$R *.fmx}

uses
  IOUtils, System.DateUtils, System.Generics.Collections,
  System.Generics.Defaults, FunctionLibrary;

const
  ShaderExt = '.sksl';

procedure TfrmShaderView.CheckBox1Change(Sender: TObject);
begin
  if Assigned(Layer) and (ComboBox1.ItemIndex = 0) then
    Layer.iOriginalColors := CheckBox1.IsChecked;
  if Assigned(Layer2) and (ComboBox1.ItemIndex = 1) then
    Layer2.iOriginalColors := CheckBox1.IsChecked;
  ShowInfo;
end;

procedure TfrmShaderView.CheckBox2Change(Sender: TObject);
begin
  if Assigned(Layer) and (ComboBox1.ItemIndex = 0) then
    Layer.iPreserveTransparency := CheckBox2.IsChecked;
  if Assigned(Layer2) and (ComboBox1.ItemIndex = 1) then
    Layer2.iPreserveTransparency := CheckBox2.IsChecked;
  ShowInfo;
end;

procedure TfrmShaderView.CheckBox3Change(Sender: TObject);
begin
  if Assigned(Layer) and (ComboBox1.ItemIndex = 0) then
    Layer.iInvertAlpha := CheckBox3.IsChecked;
  if Assigned(Layer2) and (ComboBox1.ItemIndex = 1) then
    Layer2.iInvertAlpha := CheckBox3.IsChecked;
  ShowInfo;
end;

procedure TfrmShaderView.CheckBox4Change(Sender: TObject);
begin
  if Assigned(Grid) then
    Grid.Visible := CheckBox4.IsChecked;
  ShowInfo;
end;

procedure TfrmShaderView.CheckBox5Change(Sender: TObject);
begin
  if Assigned(Layer) then
    Layer.Visible := CheckBox5.IsChecked;
  ShowInfo;
end;

procedure TfrmShaderView.CheckBox6Change(Sender: TObject);
begin
  if Assigned(Layer2) then
    Layer2.Visible := CheckBox6.IsChecked;
  ShowInfo;
end;

procedure TfrmShaderView.TrackBar1Change(Sender: TObject);
begin
  Label5.Text := FormatFloat('0.00', (TrackBar1.Value / TrackBar1.Max) * 100);
  if Assigned(Layer) and (ComboBox1.ItemIndex = 0) then
    Layer.fStyleWeight := (TrackBar1.Value / TrackBar1.Max);
  if Assigned(Layer2) and (ComboBox1.ItemIndex = 1) then
    Layer2.fStyleWeight := (TrackBar1.Value / TrackBar1.Max);
  ShowInfo;
end;

procedure TfrmShaderView.TrackBar2Change(Sender: TObject);
begin
  Label6.Text := FormatFloat('0.00', (TrackBar2.Value / TrackBar2.Max) * 100);
  if Assigned(Layer) and (ComboBox1.ItemIndex = 0) then
    Layer.fAlphaThreshold := (TrackBar2.Value / TrackBar2.Max);
  if Assigned(Layer2) and (ComboBox1.ItemIndex = 1) then
    Layer2.fAlphaThreshold := (TrackBar2.Value / TrackBar2.Max);
  ShowInfo;
end;

procedure TfrmShaderView.MenuItem5Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfrmShaderView.FormCreate(Sender: TObject);
begin
  if not DirectoryExists('shaders') then
    begin
      ShowMessage('Can''t find shaders directory');
      Application.Terminate;
    end
  else
    begin
      DrawSpace.Scale.X := 1;
      DrawSpace.Scale.Y := 1;


      CheckBox1.IsChecked := False; // Original Colours
      CheckBox2.IsChecked := False; // Preserve Transparency
      CheckBox3.IsChecked := False; // Invert Transparency
      CheckBox4.IsChecked := True;  // Show Grid
      CheckBox5.IsChecked := False;  // Show Layer 1
      CheckBox6.IsChecked := False;  // Show Layer 2
      TrackBar1.Value := TrackBar1.Max; // Style Weight
      TrackBar2.Value := TrackBar2.Max * 0.95;  // Transparency Threshold

      Container := TAspectLayout.Create(DrawSpace);

      Grid := TGridShader.Create(Container);


      Layer := TLayerShader.Create(Container);
      Layer.AddImage(Styled, TPath.Combine(MediaPath, 'haywain-wall.jpg'));
      Layer.AddImage(Original, TPath.Combine(MediaPath, 'haywain.jpg'));
      CheckBox5.IsChecked := True;  // Show Layer 1

      Layer2 := TLayerShader.Create(Container);
      Layer2.AddImage(Styled, TPath.Combine(MediaPath, 'fermin-6.jpg'));
      Layer2.AddImage(Original, TPath.Combine(MediaPath, 'fermin-rembg.png'));
      CheckBox6.IsChecked := True;  // Show Layer 2

{
      Layer2.fImScale := 0.625;
      Layer.fImScale := 1;
      Layer.fImOffsetX := 0;
      Layer.fImOffsetY := 1000;
}
      MenuItem5.ShortCut := TextToShortCut('Alt+X');
    end;
end;

procedure TfrmShaderView.FormPaint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  if FSaveInNextPaint then
    DoSaveLayers;
  if FPaintCount = 0 then
  begin
    FstopWatch := now;
  end;
  inc(FPaintCount);
  var LFps := FPaintCount / ((now - FstopWatch) * (1 / OneSecond));
  Label19.Text := Format('%3.2f fps', [LFps]);
end;

procedure TfrmShaderView.ShowInfo;
begin
  if Assigned(Layer) then
    begin
      if Assigned(Layer) and (ComboBox1.ItemIndex = 0) then
        Label4.Text := IntToStr(Layer.ImWidth) +
          ' x ' + IntToStr(Layer.ImHeight)
          {
           +
          ' - ' + Layer.GetColorType(Styled) +
          ' - ' + Layer.GetColorType(Original)
          }
      else if Assigned(Layer2) and (ComboBox1.ItemIndex = 1) then
        Label4.Text := IntToStr(Layer2.ImWidth) +
          ' x ' + IntToStr(Layer2.ImHeight)
          { +
          ' - ' + Layer2.GetColorType(Styled) +
          ' - ' + Layer2.GetColorType(Original)
          }
      else
        Label4.Text := '';

      Label7.Text := 'C MWidth = ' + IntToStr(Container.ChildMaxImWidth);
      Label8.Text := 'C MHeight = ' + IntToStr(Container.ChildMaxImHeight);
      Label13.Text := 'C MScale = ' + FormatFloat('#0.00000', Container.ChildMaxImScale);

      Label9.Text := 'C Width = ' + FloatToStr(Container.Size.Width);
      Label10.Text := 'C Height = ' + FloatToStr(Container.Size.Height);
      Label14.Text := 'C Left = ' + FloatToStr(Container.Position.X);
      Label15.Text := 'C Top = ' + FloatToStr(Container.Position.Y);

      Label11.Text := 'L Width = ' + FloatToStr(DrawSpace.Width);
      Label12.Text := 'L Height = ' + FloatToStr(DrawSpace.Height);
      if Assigned(Layer2) then
        begin
          Label16.Text := 'L2 X = ' + FloatToStr(Layer2.Position.X);
          Label17.Text := 'L2 Y = ' + FloatToStr(Layer2.Position.Y);
        end;

      Label18.Text := 'Layers = ' + IntToStr(Container.ChildrenCount);
    end;
end;

procedure TfrmShaderView.DrawSpaceResize(Sender: TObject);
begin
  if Assigned(Container) then
    begin
      Container.FitToContainer;
      ShowInfo;
    end;
end;

procedure TfrmShaderView.SaveLayers(Sender: TObject);
begin
  if SaveDialog1.Execute then
  begin
    FSaveInNextPaint := True;
    Invalidate;
  end;
end;

procedure TfrmShaderView.DoSaveLayers;
var
  AWidth, AHeight: Integer;
  LSurface: ISkSurface;
  Elapsed: Cardinal;
  Seconds: Double;
  IDX: Integer;
begin
  FSaveInNextPaint := False;

  AWidth := Container.ChildMaxImWidth;
  AHeight := Container.ChildMaxImHeight;

  if (Self.Canvas is TGrCanvasCustom) and Assigned(TGrCanvasCustom(Self.Canvas).Context) then
    LSurface := TSkSurface.MakeRenderTarget(TGrCanvasCustom(Self.Canvas).Context, False, TSkImageInfo.Create(AWidth, AHeight))
  else
    LSurface := TSkSurface.MakeRaster(AWidth, AHeight);
  LSurface.Canvas.Clear(TAlphaColors.Null);

  Elapsed := TThread.GetTickCount;
  if Assigned(Container) and (Container.ChildrenCount > 1) then
    begin
      for IDX := 0 to Container.ChildrenCount - 1 do
        begin
          if Assigned(Container.Children[IDX]) and (Container.Children[IDX] is TLayerShader) then
            begin
              var ThisLayer: TLayerShader := Container.Children[IDX] as TLayerShader;
              ThisLayer.OnDraw(ThisLayer, LSurface.Canvas, RectF(0, 0, AWidth, AHeight), 1);
            end;
        end;
    end;
{
  if Assigned(Layer) and Assigned(Layer.OnDraw) then
    Layer.OnDraw(Layer, LSurface.Canvas, RectF(0, 0, AWidth, AHeight), 1);

  if Assigned(Layer2) and Assigned(Layer2.OnDraw) then
    Layer2.OnDraw(Layer2, LSurface.Canvas, RectF(0, 0, AWidth, AHeight), 1);
}
  LSurface.MakeImageSnapshot.EncodeToFile(SaveDialog1.FileName);

  Elapsed := TThread.GetTickCount - Elapsed;
  Seconds := Elapsed / 1000;

  Label4.Text := 'T = ' + FloatToStr(Seconds);
  FPaintCount := 0;

end;


end.
