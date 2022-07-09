unit MainUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, StrUtils, Math,
  FMX.Memo.Types, FMX.StdCtrls, FMX.Controls.Presentation, FMX.ScrollBox,
  FMX.Memo, FMX.TabControl, Skia, Skia.FMX, FMX.Layouts, FMX.MultiView,
  FMX.ListBox, FMX.Ani, FMX.Effects, FMX.Objects, FMX.Menus,
  Shaders;

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
  if Assigned(Layer) then
    Layer.iOriginalColors := CheckBox1.IsChecked;
end;

procedure TfrmShaderView.CheckBox2Change(Sender: TObject);
begin
  if Assigned(Layer) then
    Layer.iPreserveTransparency := CheckBox2.IsChecked;
end;

procedure TfrmShaderView.CheckBox3Change(Sender: TObject);
begin
  if Assigned(Layer) then
    Layer.iInvertAlpha := CheckBox3.IsChecked;
end;

procedure TfrmShaderView.CheckBox4Change(Sender: TObject);
begin
  if Assigned(Grid) then
    Grid.Visible := CheckBox4.IsChecked;
end;

procedure TfrmShaderView.CheckBox5Change(Sender: TObject);
begin
  if Assigned(Layer) then
    Layer.Visible := CheckBox5.IsChecked;
end;

procedure TfrmShaderView.CheckBox6Change(Sender: TObject);
begin
  if Assigned(Layer2) then
    Layer2.Visible := CheckBox6.IsChecked;
end;

procedure TfrmShaderView.TrackBar1Change(Sender: TObject);
begin
  Label5.Text := FormatFloat('0.00', (TrackBar1.Value / TrackBar1.Max) * 100);
  if Assigned(Layer) then
    Layer.fStyleWeight := (TrackBar1.Value / TrackBar1.Max);
end;

procedure TfrmShaderView.TrackBar2Change(Sender: TObject);
begin
  Label6.Text := FormatFloat('0.00', (TrackBar2.Value / TrackBar2.Max) * 100);
  if Assigned(Layer) then
    Layer.fAlphaThreshold := (TrackBar2.Value / TrackBar2.Max);
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


      CheckBox1.IsChecked := False;
      CheckBox2.IsChecked := True;
      CheckBox3.IsChecked := False;
      CheckBox4.IsChecked := True;
      CheckBox5.IsChecked := True;
      CheckBox6.IsChecked := True;
      TrackBar1.Value := TrackBar1.Max;
      TrackBar2.Value := TrackBar2.Max * 0.95;

      Container := TAspectLayout.Create(DrawSpace);

      Grid := TGridShader.Create(Container);
      Grid.iGridSize := 64;
      Grid.cBack := [1, 0.333, 0.333, 1];
      Grid.cFront := [1, 0.666, 0.666, 1];
      Grid.AddShader(TPath.Combine(ShaderPath,'grid.sksl'));

      Layer := TLayerShader.Create(Container);
      Layer.iOriginalColors := CheckBox1.IsChecked;
      Layer.iPreserveTransparency := CheckBox2.IsChecked;
      Layer.iInvertAlpha := CheckBox3.IsChecked;
      Layer.AddShader(TPath.Combine(ShaderPath,'original_colors.sksl'),
        TPath.Combine(MediaPath, 'fermin-6.jpg'),
        TPath.Combine(MediaPath, 'fermin-rembg.png'));

      Layer2 := TLayerShader.Create(Container);
      Layer2.iOriginalColors := False;
      Layer2.iPreserveTransparency := True;
      Layer2.iInvertAlpha := False;
      Layer2.AddShader(TPath.Combine(ShaderPath,'original_colors.sksl'),
        TPath.Combine(MediaPath, 'digitalman.jpg'),'');
{
      Container.FitToContainer;
      Container.Width := 408;
      Container.Height := 510;
}

      MenuItem5.ShortCut := TextToShortCut('Alt+X');
    end;
end;

procedure TfrmShaderView.ShowInfo;
begin
  if Assigned(Layer) then
    begin
      Label7.Text := 'C MWidth = ' + IntToStr(Container.ChildMaxImWidth);
      Label8.Text := 'C MHeight = ' + IntToStr(Container.ChildMaxImHeight);
      Label13.Text := 'C MScale = ' + FormatFloat('#0.00000', Container.ChildMaxImScale);

      Label9.Text := 'C Width = ' + FloatToStr(Container.Size.Width);
      Label10.Text := 'C Height = ' + FloatToStr(Container.Size.Height);
      Label14.Text := 'C Left = ' + FloatToStr(Container.Position.X);
      Label15.Text := 'C Top = ' + FloatToStr(Container.Position.Y);

      Label11.Text := 'L Width = ' + FloatToStr(DrawSpace.Width);
      Label12.Text := 'L Height = ' + FloatToStr(DrawSpace.Height);
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


end.
