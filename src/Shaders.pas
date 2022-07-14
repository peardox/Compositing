unit Shaders;

interface

uses
  System.Classes, System.Types, FMX.Types, FMX.Controls, FMX.Objects, FMX.Layouts, Skia, Skia.FMX;

type
  TAspectLayout = class(TRectangle)
  public
    ChildMaxImWidth: Integer;
    ChildMaxImHeight: Integer;
    ChildMaxImScale: Single;
    constructor Create(AOwner: TComponent); override;
    procedure FitToContainer;
    procedure Resize; override;
  end;

  TBaseShader = class(TSkPaintBox)
  protected
    Effect: ISkRuntimeEffect;
    Painter: ISkPaint;
    ShaderText: String;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TGridShader = class(TBaseShader)
  private
    frame_count: Integer;
    procedure DoDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
  public
    iGridSize: Integer;
    cFront: TArray<Single>;
    cBack: TArray<Single>;
    constructor Create(AOwner: TComponent); override;
    procedure AddShader;
  end;

  TLayerShader = class(TBaseShader)
  private
    procedure DoDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
  public
    ImWidth: Integer;
    ImHeight: Integer;
    fImScale: Single;
    fImOffsetX: Integer;
    fImOffsetY: Integer;
    fStyleWeight: Single;
    fAlphaThreshold: Single;
    iOriginalColors: Boolean;
    iPreserveTransparency: Boolean;
    iInvertAlpha: Boolean;
    constructor Create(AOwner: TComponent); override;
    procedure AddShader;
    function AddTexture(const TextureIdentifier: String; const TextureFIle: String): Boolean;
  published
    property OnDraw;
  end;

implementation

uses
  System.SysUtils, System.UITypes, FMX.Dialogs,
  Math, IOUtils, FunctionLibrary, MainUnit;

constructor TAspectLayout.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  if Assigned(AOwner) then
    TFmxObject(AOwner).AddObject(Self);
  Fill.Color := TAlphaColors.Blue;
  ClipChildren := True;
  Width := 0;
  Height := 0;
end;

procedure TAspectLayout.Resize;
begin
  FitToContainer;
end;

procedure TAspectLayout.FitToContainer;
var
  Scale: Single;
begin
  if Assigned(Owner) and (Owner is TControl) and (ChildMaxImWidth > 0) and (ChildMaxImHeight > 0) then
    begin
      Scale := FitInsideContainer(TControl(Owner).Width, ChildMaxImWidth,
        TControl(Owner).Height, ChildMaxImHeight);
      if (Scale > 0) then
        begin
          ChildMaxImScale := Scale;
          Width := ChildMaxImWidth * Scale;
          Height := ChildMaxImHeight * Scale;
          Position.X := Floor((TControl(Owner).Width - Width) / 2);
          Position.Y := Floor((TControl(Owner).Height - Height) / 2);
        end;
    end;
end;

constructor TBaseShader.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Enabled := False;
  if Assigned(AOwner) then
    TFmxObject(AOwner).AddObject(Self);
  Align := TAlignLayout.Client;
end;

constructor TGridShader.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  iGridSize := 128;
  cBack := [0.333, 0.333, 0.333, 1];
  cFront := [0.666, 0.666, 0.666, 1];
  AddShader;
end;

procedure TGridShader.AddShader;
begin
  Enabled := False;
  ShaderText := LoadShader(TPath.Combine(ShaderPath,'grid.sksl'));

  var AErrorText := '';
  Effect := TSkRuntimeEffect.MakeForShader(ShaderText, AErrorText);
  if AErrorText <> '' then
    raise Exception.Create(AErrorText);

  Painter := TSkPaint.Create;
  Painter.Shader := Effect.MakeShader(True);

  OnDraw := DoDraw;

end;

procedure TGridShader.DoDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
begin
  if Assigned(Effect) and Assigned(Painter) then
  begin
    if Effect.UniformExists('iResolution') then
    begin
      if Effect.UniformType['iResolution'] = TSkRuntimeEffectUniformType.Float3 then
        Effect.SetUniform('iResolution', [Single(TAspectLayout(Parent).ChildMaxImWidth), Single(TAspectLayout(Parent).ChildMaxImHeight), Single(0)])
      else if Effect.UniformType['iResolution'] = TSkRuntimeEffectUniformType.Float2 then
        Effect.SetUniform('iResolution', PointF(TAspectLayout(Parent).ChildMaxImWidth, TAspectLayout(Parent).ChildMaxImHeight))
      else
        Effect.SetUniform('iResolution', [TAspectLayout(Parent).ChildMaxImWidth, TAspectLayout(Parent).ChildMaxImHeight]);
    end;
    if Effect.UniformExists('sResolution') then
    begin
      if Effect.UniformType['sResolution'] = TSkRuntimeEffectUniformType.Float3 then
        Effect.SetUniform('sResolution', [Single(ADest.Width), Single(ADest.Height), Single(0)])
      else if Effect.UniformType['sResolution'] = TSkRuntimeEffectUniformType.Float2 then
        Effect.SetUniform('sResolution', PointF(ADest.Width, ADest.Height))
      else
        Effect.SetUniform('sResolution', [Int(ADest.Width), Int(ADest.Height)]);
    end;
    if Effect.UniformExists('iGridSize') then
      Effect.SetUniform('iGridSize', iGridSize ); // 64
    if Effect.UniformExists('cBack') then
      Effect.SetUniform('cBack', cBack); // [0.333, 0.333, 0.333, 1]
    if Effect.UniformExists('cFront') then
      Effect.SetUniform('cFront', cFront); // [0.666, 0.666, 0.666, 1]
    ACanvas.DrawRect(ADest, Painter);
  Inc(frame_count);
  end;
end;

constructor TLayerShader.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fImScale := 1;
  fImOffsetX := 0;
  fImOffsetY := 0;
  fStyleWeight := 1;
  fAlphaThreshold := 0.95;
  iOriginalColors := False;
  iPreserveTransparency := False;
  iInvertAlpha := False;
  AddShader;
end;

function TLayerShader.AddTexture(const TextureIdentifier: String;
  const TextureFile: String): Boolean;
var
  ImImageInfo: TSkImageInfo;
  HaveImage: Boolean;
begin
  HaveImage := False;

  if FileExists(TextureFile) and Effect.ChildExists(TextureIdentifier) then
  begin
    var TexImage: ISkImage := TSkImage.MakeFromEncodedFile(TextureFile);

    if Assigned(TexImage) then
    begin
      HaveImage := True;
      Effect.ChildrenShaders[TextureIdentifier] := TexImage.MakeShader(TSKSamplingOptions.High);
      if Effect.UniformExists(TextureIdentifier + 'Resolution') then
        case Effect.UniformType[TextureIdentifier + 'Resolution'] of
          TSkRuntimeEffectUniformType.Float2:
            Effect.SetUniform(TextureIdentifier + 'Resolution', TSkRuntimeEffectFloat2.Create(TexImage.Width, TexImage.Height));
          TSkRuntimeEffectUniformType.Float3:
            Effect.SetUniform(TextureIdentifier + 'Resolution', TSkRuntimeEffectFloat3.Create(TexImage.Width, TexImage.Height, 0));
          TSkRuntimeEffectUniformType.Int2:
            Effect.SetUniform(TextureIdentifier + 'Resolution', TSkRuntimeEffectInt2.Create(TexImage.Width, TexImage.Height));
          TSkRuntimeEffectUniformType.Int3:
            Effect.SetUniform(TextureIdentifier + 'Resolution', TSkRuntimeEffectInt3.Create(TexImage.Width, TexImage.Height, 0));
        end;

      ImImageInfo := TexImage.ImageInfo;
      ImWidth := ImImageInfo.Width;
      ImHeight := ImImageInfo.Height;

      if Owner is TAspectLayout then
        begin
          if (TAspectLayout(Parent).ChildMaxImHeight < ImHeight) or
             (TAspectLayout(Parent).ChildMaxImWidth < ImWidth) then
            begin
              if (TAspectLayout(Parent).ChildMaxImHeight < ImHeight) then
                TAspectLayout(Parent).ChildMaxImHeight := ImHeight;
              if (TAspectLayout(Parent).ChildMaxImWidth < ImWidth) then
                TAspectLayout(Parent).ChildMaxImWidth := ImWidth;
              TAspectLayout(Parent).FitToContainer;
            end;
        end;

    Painter := TSkPaint.Create;
    Painter.Shader := Effect.MakeShader(False);
    end;
  end;
  if Effect.UniformExists(TextureIdentifier + 'Valid') then
    Effect.SetUniform(TextureIdentifier + 'Valid', BoolToInt(HaveImage));
  Result := HaveImage;
end;

procedure TLayerShader.AddShader;
begin
  Enabled := False;
  ShaderText := LoadShader(TPath.Combine(ShaderPath,'original_colors.sksl'));

  var AErrorText := '';
  Effect := TSkRuntimeEffect.MakeForShader(ShaderText, AErrorText);
  if AErrorText <> '' then
    raise Exception.Create('Error creating shader : ' + AErrorText);
  if Effect.UniformExists('iImage1Valid') then
    Effect.SetUniform('iImage1Valid', BoolToInt(False));
  if Effect.UniformExists('iImage2Valid') then
    Effect.SetUniform('iImage2Valid', BoolToInt(False));

  Enabled := True;

  OnDraw := DoDraw;
end;

procedure TLayerShader.DoDraw(ASender: TObject;
  const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
begin
  if Assigned(Effect) and Assigned(Painter) then
  begin
    if Effect.UniformExists('iResolution') then
    begin
      if Effect.UniformType['iResolution'] = TSkRuntimeEffectUniformType.Float3 then
        Effect.SetUniform('iResolution', [Single(ADest.Width), Single(ADest.Height), Single(0)])
      else if Effect.UniformType['iResolution'] = TSkRuntimeEffectUniformType.Float2 then
        Effect.SetUniform('iResolution', PointF(ADest.Width, ADest.Height))
      else
        Effect.SetUniform('iResolution', [Int(ADest.Width), Int(ADest.Height)]);
    end;
    if Effect.UniformExists('fStyleWeight') then
      Effect.SetUniform('fStyleWeight', fStyleWeight);
    if Effect.UniformExists('fAlphaThreshold') then
      Effect.SetUniform('fAlphaThreshold', fAlphaThreshold);

    if Effect.UniformExists('bOriginalColors') then
      Effect.SetUniform('bOriginalColors', BoolToInt(iOriginalColors));
    if Effect.UniformExists('bPreserveTransparency') then
      Effect.SetUniform('bPreserveTransparency', BoolToInt(iPreserveTransparency));
    if Effect.UniformExists('bInvertAlpha') then
      Effect.SetUniform('bInvertAlpha', BoolToInt(iInvertAlpha));
    if Effect.UniformExists('fImScale') then
      begin
        if fImScale > 0 then
          Effect.SetUniform('fImScale', 1 / fImScale)
        else
          Effect.SetUniform('fImScale', 1);
      end;
    if Effect.UniformExists('fImOffset') then
      Effect.SetUniform('fImOffset', TSkRuntimeEffectFloat2.Create(fImOffsetX * (1 / fImScale), fImOffsetY * (1 / fImScale)));

    ACanvas.DrawRect(ADest, Painter);
  end;
end;

end.


