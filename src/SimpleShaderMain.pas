unit SimpleShaderMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, StrUtils, Math,
  FMX.Memo.Types, FMX.StdCtrls, FMX.Controls.Presentation, FMX.ScrollBox,
  FMX.Memo, FMX.TabControl, Skia, Skia.FMX, FMX.Layouts, FMX.MultiView,
  FMX.ListBox, FMX.Ani, FMX.Effects, FMX.Objects, FMX.Edit, FMX.EditBox,
  FMX.NumberBox, FMX.SpinBox, FMX.Menus;

type
  TShaderRec = Record
    Effect: ISkRuntimeEffect;
    Paint: ISkPaint;
    ShaderCode: TStringList;
  end;

  TfrmShaderView = class(TForm)
    pnlContainer: TPanel;
    pnlImages: TPanel;
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

    skpbLayer: TSkPaintBox;
    skpbGrid: TSkPaintBox;

    OpenDialog1: TOpenDialog;
    MainMenu1: TMainMenu;
    FileMenu: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;

    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure TrackBar2Change(Sender: TObject);
    procedure skpbLayerDraw(ASender: TObject; const ACanvas: ISkCanvas;
      const ADest: TRectF; const AOpacity: Single);
    procedure skpbGridDraw(ASender: TObject; const ACanvas: ISkCanvas;
      const ADest: TRectF; const AOpacity: Single);
    procedure MenuItem5Click(Sender: TObject);
  private
    { Private declarations }
    FImWidth: Single;
    FImHeight: Single;

    FEffect: ISkRuntimeEffect;
    FPaint: ISkPaint;
    ShaderCode: TStringList;

    FEffect2: ISkRuntimeEffect;
    FPaint2: ISkPaint;
    ShaderCode2: TStringList;

    procedure ResizeImagePanels;
    procedure AddGrid;
    procedure AddLayer;
    procedure LoadLayerShader(const AShaderFile: String);
    procedure LoadGridShader(const AShaderFile: String);
    procedure AddTexture(var SkRuntimeEffect: ISkRuntimeEffect; const TextureIdentifier: String; const TextureFIle: String);
  public
    { Public declarations }
  end;

var
  frmShaderView: TfrmShaderView;

implementation

{$R *.fmx}

uses
  IOUtils, System.DateUtils, System.Generics.Collections,
  System.Generics.Defaults;

const
  ShaderExt = '.sksl';

function FitInsideContainer(const AContainerWidth: Single;
  const AContentWidth: Single; const AContainerHeight: Single;
  const AContentHeight: Single): Single;
begin
  Result := Min(AContainerWidth / AContentWidth, AContainerHeight / AContentHeight);
end;

function BoolToInt(const AValue: Boolean): Integer;
begin
  Result := 0;
  if AValue then
    Result := 1;

end;

function ShaderPath: string;
begin
  {$IFDEF MSWINDOWS}
  Result := TPath.GetFullPath('Shaders\');
  {$ELSEIF DEFINED(IOS) or DEFINED(ANDROID)}
  Result := TPath.GetDocumentsPath;
  {$ELSEIF defined(MACOS)}
  Result := TPath.GetFullPath('Resources/');
  {$ELSE}
  Result := ExtractFilePath(ParamStr(0));
  {$ENDIF}
  if (Result <> '') and not Result.EndsWith(PathDelim) then
    Result := Result + PathDelim;
end;

function MediaPath: string;
begin
  {$IFDEF MSWINDOWS}
  Result := TPath.GetFullPath('media\');
  {$ELSEIF DEFINED(IOS) or DEFINED(ANDROID)}
  Result := TPath.Combine(TPath.GetDocumentsPath, 'media');
  {$ELSEIF defined(MACOS)}
  Result := TPath.Combine(TPath.GetFullPath('Resources/'), 'media');
  {$ELSE}
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'media');
  {$ENDIF}
  if (Result <> '') and not Result.EndsWith(PathDelim) then
    Result := Result + PathDelim;
end;

procedure TfrmShaderView.AddTexture(var SkRuntimeEffect: ISkRuntimeEffect;
  const TextureIdentifier: String;
  const TextureFile: String);
var
  Scale: Single;
  FImImageInfo: TSkImageInfo;
begin
  if SkRuntimeEffect.ChildExists(TextureIdentifier) then
  begin
    var TexImage: ISkImage := TSkImage.MakeFromEncodedFile(TextureFile);

    if Assigned(TexImage) then
    begin
      SkRuntimeEffect.ChildrenShaders[TextureIdentifier] := TexImage.MakeShader(TSKSamplingOptions.High);
      if SkRuntimeEffect.UniformExists(TextureIdentifier + 'Resolution') then
        case SkRuntimeEffect.UniformType[TextureIdentifier + 'Resolution'] of
          TSkRuntimeEffectUniformType.Float2:
            SkRuntimeEffect.SetUniform(TextureIdentifier + 'Resolution', TSkRuntimeEffectFloat2.Create(TexImage.Width, TexImage.Height));
          TSkRuntimeEffectUniformType.Float3:
            SkRuntimeEffect.SetUniform(TextureIdentifier + 'Resolution', TSkRuntimeEffectFloat3.Create(TexImage.Width, TexImage.Height, 0));
          TSkRuntimeEffectUniformType.Int2:
            SkRuntimeEffect.SetUniform(TextureIdentifier + 'Resolution', TSkRuntimeEffectInt2.Create(TexImage.Width, TexImage.Height));
          TSkRuntimeEffectUniformType.Int3:
            SkRuntimeEffect.SetUniform(TextureIdentifier + 'Resolution', TSkRuntimeEffectInt3.Create(TexImage.Width, TexImage.Height, 0));
        end;

      FImImageInfo := TexImage.ImageInfo;
      FImWidth := FImImageInfo.Width;
      FImHeight := FImImageInfo.Height;
      Label4.Text := FloatToStr(FImWidth) + ' x ' + FloatToStr(FImHeight);
      ResizeImagePanels;
    end;
  end;
end;

procedure TfrmShaderView.AddGrid;
begin
  skpbGrid.Enabled := False;
  FEffect2 := nil;
  FPaint2 := nil;
  var AErrorText2 := '';
  FEffect2 := TSkRuntimeEffect.MakeForShader(ShaderCode2.Text, AErrorText2);
  if AErrorText2 <> '' then
    raise Exception.Create(AErrorText2);

  FPaint2 := TSkPaint.Create;
  FPaint2.Shader := FEffect2.MakeShader(True);
  skpbGrid.Enabled := True;
end;

procedure TfrmShaderView.AddLayer;
begin
  skpbLayer.Enabled := False;
  FEffect := nil;
  FPaint := nil;
  var AErrorText := '';
  FEffect := TSkRuntimeEffect.MakeForShader(ShaderCode.Text, AErrorText);
  if AErrorText <> '' then
    raise Exception.Create(AErrorText);

  AddTexture(FEffect, 'iImage1', TPath.Combine(MediaPath, 'fermin-6.jpg'));
  AddTexture(FEffect, 'iImage2', TPath.Combine(MediaPath, 'fermin-rembg.png'));
//  AddTexture(Feffect, 'iImage2', TPath.Combine(MediaPath, 'fermin-7.jpg'));
//  AddTexture(FEffect, 'iImage1', TPath.Combine(MediaPath, 'fns-test-flowers-4.png'));
//  AddTexture(FEffect, 'iImage1', TPath.Combine(MediaPath, 'haywain-moz1-vgg16.jpg'));
//  AddTexture(FEffect, 'iImage2', TPath.Combine(MediaPath, 'haywain.jpg'));

  FPaint := TSkPaint.Create;
  FPaint.Shader := FEffect.MakeShader(False);
  skpbLayer.Enabled := True;
end;

procedure TfrmShaderView.skpbLayerDraw(ASender: TObject;
  const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
begin
  if Assigned(FEffect) and Assigned(FPaint) then
  begin
    if FEffect.UniformExists('iResolution') then
    begin
      if FEffect.UniformType['iResolution'] = TSkRuntimeEffectUniformType.Float3 then
        FEffect.SetUniform('iResolution', [Single(ADest.Width), Single(ADest.Height), Single(0)])
      else if FEffect.UniformType['iResolution'] = TSkRuntimeEffectUniformType.Float2 then
        FEffect.SetUniform('iResolution', PointF(ADest.Width, ADest.Height))
      else
        FEffect.SetUniform('iResolution', [Int(ADest.Width), Int(ADest.Height)]);
    end;
    if FEffect.UniformExists('fStyleWeight') then
      FEffect.SetUniform('fStyleWeight', (TrackBar1.Value / TrackBar1.Max));
    if FEffect.UniformExists('fAlphaThreshold') then
      FEffect.SetUniform('fAlphaThreshold', (TrackBar2.Value / TrackBar2.Max));

    if FEffect.UniformExists('iOriginalColors') then
      FEffect.SetUniform('iOriginalColors', BoolToInt(CheckBox1.IsChecked));
    if FEffect.UniformExists('iPreserveTransparency') then
      FEffect.SetUniform('iPreserveTransparency', BoolToInt(CheckBox2.IsChecked));
    if FEffect.UniformExists('iInvertAlpha') then
      FEffect.SetUniform('iInvertAlpha', BoolToInt(CheckBox3.IsChecked));

    ACanvas.DrawRect(ADest, FPaint);
  end;
end;

procedure TfrmShaderView.skpbGridDraw(ASender: TObject;
  const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
begin
  if Assigned(FEffect2) and Assigned(FPaint2) then
  begin
    if FEffect2.UniformExists('iResolution') then
    begin
      if FEffect2.UniformType['iResolution'] = TSkRuntimeEffectUniformType.Float3 then
        FEffect2.SetUniform('iResolution', [Single(ADest.Width), Single(ADest.Height), Single(0)])
      else if FEffect2.UniformType['iResolution'] = TSkRuntimeEffectUniformType.Float2 then
        FEffect2.SetUniform('iResolution', PointF(ADest.Width, ADest.Height))
      else
        FEffect2.SetUniform('iResolution', [Int(ADest.Width), Int(ADest.Height)]);
    end;
    if FEffect2.UniformExists('iGridSize') then
      FEffect2.SetUniform('iGridSize', 64 );
    if FEffect2.UniformExists('cBack') then
      FEffect2.SetUniform('cBack', [0.333, 0.333, 0.333, 1]);
    if FEffect2.UniformExists('cFront') then
      FEffect2.SetUniform('cFront', [0.666, 0.666, 0.666, 1]);
    ACanvas.DrawRect(ADest, FPaint2);
  end;
end;

procedure TfrmShaderView.LoadLayerShader(const AShaderFile: string);
begin
  if FileExists(AShaderFile) then
    begin
      ShaderCode.LoadFromFile(AShaderFile);
      ShaderCode.Text := ShaderCode.Text.Replace(#9, #32);
    end
  else
    begin
      ShowMessage('Can''t find shader ''' + AShaderFile + '''');
      Application.Terminate;
      Exit;
    end;
  AddLayer;
end;

procedure TfrmShaderView.LoadGridShader(const AShaderFile: String);
begin
  if FileExists(AShaderFile) then
    begin
      ShaderCode2.LoadFromFile(AShaderFile);
      ShaderCode2.Text := ShaderCode2.Text.Replace(#9, #32);
    end
  else
    begin
      ShowMessage('Can''t find shader ''' + AShaderFile + '''');
      Application.Terminate;
      Exit;
    end;
  AddGrid;
end;

procedure TfrmShaderView.MenuItem5Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfrmShaderView.FormCreate(Sender: TObject);
begin
// ..\bin\$(Platform)\$(Config)
  if not DirectoryExists('shaders') then
    begin
      ShowMessage('Can''t find shaders directory');
      Application.Terminate;
    end
  else
    begin
      FImWidth := 1;
      FImHeight := 1;

      skpbGrid.Align := TAlignLayout.Client;
      skpbGrid.Visible := True;

      skpbLayer.Align := TAlignLayout.Client;
      skpbLayer.Visible := True;

      CheckBox1.IsChecked := False;
      CheckBox2.IsChecked := False;
      CheckBox3.IsChecked := False;
      TrackBar1.Value := TrackBar1.Max;
      TrackBar2.Value := TrackBar2.Max * 0.95;
      ShaderCode := TStringList.Create;
      ShaderCode2 := TStringList.Create;

      LoadLayerShader(TPath.Combine(ShaderPath,'original_colors.sksl'));
      LoadGridShader(TPath.Combine(ShaderPath,'grid.sksl'));

      MenuItem5.ShortCut := TextToShortCut('Alt+X');
    end;
end;

procedure TfrmShaderView.ResizeImagePanels;
var
  Scale: Single;
begin
  Scale := FitInsideContainer(pnlContainer.Width, FImWidth,
    pnlContainer.Height, FImHeight);
  pnlImages.Width := FImWidth * Scale;
  pnlImages.Height := FImHeight * Scale;
  pnlImages.Position.X := Floor((pnlContainer.Width - pnlImages.Width) / 2);
  pnlImages.Position.Y := Floor((pnlContainer.Height - pnlImages.Height) / 2);
end;

procedure TfrmShaderView.FormResize(Sender: TObject);
begin
  ResizeImagePanels;
end;

procedure TfrmShaderView.TrackBar1Change(Sender: TObject);
begin
  Label5.Text := FormatFloat('0.00', (TrackBar1.Value / TrackBar1.Max) * 100);
end;

procedure TfrmShaderView.TrackBar2Change(Sender: TObject);
begin
  Label6.Text := FormatFloat('0.00', (TrackBar2.Value / TrackBar2.Max) * 100);
end;

end.
