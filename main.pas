unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Menus,
  ExtCtrls, Buttons, StdCtrls, Spin, Math, Types,
  about, tools, figures, transform, constants, history;

type

  { TMainForm }

  TMainForm = class(TForm)
    MEdit: TMenuItem;
    MEditDelete: TMenuItem;
    MEditUp: TMenuItem;
    MEditDown: TMenuItem;
    MenuItem1: TMenuItem;
    MEditRedo: TMenuItem;
    MEditUndo: TMenuItem;
    MEditCopy: TMenuItem;
    MEditPaste: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MFileClose: TMenuItem;
    MFileOpen: TMenuItem;
    MFileSaveAs: TMenuItem;
    MFileSave: TMenuItem;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    ScaleSpin: TFloatSpinEdit;
    HorScrollBar: TScrollBar;
    ScaleLabel: TLabel;
    MainMenu: TMainMenu;
    MFile: TMenuItem;
    MFileExit: TMenuItem;
    MHelp: TMenuItem;
    MHelpAbout: TMenuItem;
    ScalePanel: TPanel;
    ParametersPanel: TPanel;
    VerScrollBar: TScrollBar;
    ImageList: TImageList;
    PaintBox: TPaintBox;
    ToolsButtons: TPanel;
    ToolsPanel: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure MEditCopyClick(Sender: TObject);
    procedure MEditDeleteClick(Sender: TObject);
    procedure MEditDownClick(Sender: TObject);
    procedure MEditPasteClick(Sender: TObject);
    procedure MEditRedoClick(Sender: TObject);
    procedure MEditUpClick(Sender: TObject);
    procedure MEditUndoClick(Sender: TObject);
    procedure MFileCloseClick(Sender: TObject);
    procedure MFileOpenClick(Sender: TObject);
    procedure MFileSaveAsClick(Sender: TObject);
    procedure MFileSaveClick(Sender: TObject);
    procedure MHelpAboutClick(Sender: TObject);
    procedure MFileExitClick(Sender: TObject);
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure PaintBoxMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure PaintBoxMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure PaintBoxPaint(Sender: TObject);
    procedure OnClickTool(Sender: TObject);
    procedure PaintBoxResize(Sender: TObject);
    procedure ScaleSpinChange(Sender: TObject);
    procedure SetScrollBars;
    procedure ScrollBarScroll(Sender: TObject; ScrollCode: TScrollCode;
      var ScrollPos: integer);
    procedure SavePicture;
  end;

var
  MainForm: TMainForm;
  currentTool: TTool;
  openedFile: String;

implementation

{$R *.lfm}

procedure TMainForm.MFileExitClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.MHelpAboutClick(Sender: TObject);
begin
  AboutForm.Show;
end;

procedure TMainForm.MEditDeleteClick(Sender: TObject);
var i, j: integer;
begin
  j := 0;
  if currentTool is TActionTool then begin
    for i := Low(CanvasFigures) to High(CanvasFigures) do
      if CanvasFigures[i].Selected then begin
        (currentTool as TActionTool).RemoveAnchors(CanvasFigures[i]);
        CanvasFigures[i].Free;
      end else begin
        CanvasFigures[j] := CanvasFigures[i];
        j := j + 1;
      end;
    SetLength(CanvasFigures, j);
  end;
  AddStateToHistory(GetAppState);
  PaintBox.Invalidate;
end;

procedure TMainForm.MEditDownClick(Sender: TObject);
var temp: TFigureBase; i: integer;
begin
  // TODO
  if (currentTool is TSelectionTool) and (Length(CanvasFigures) > 0) then begin
    for i := Low(CanvasFigures) + 1 to High(CanvasFigures) do
      if CanvasFigures[i].Selected then begin
        temp := CanvasFigures[i];
        CanvasFigures[i] := CanvasFigures[i-1];
        CanvasFigures[i-1] := temp;
      end
  end;
  AddStateToHistory(GetAppState);
  PaintBox.Invalidate;
end;

procedure TMainForm.MEditCopyClick(Sender: TObject);
begin
  CopySelected(PaintBox);
end;

procedure TMainForm.MEditPasteClick(Sender: TObject);
begin
  PasteSelected(PaintBox);
end;

procedure TMainForm.MEditRedoClick(Sender: TObject);
begin
  Redo(PaintBox);
end;

procedure TMainForm.MEditUpClick(Sender: TObject);
var temp: TFigureBase; i: integer;
begin
  // TODO
  if currentTool is TSelectionTool then begin
    for i := Low(CanvasFigures) to High(CanvasFigures) - 1 do
      if CanvasFigures[i].Selected then begin
        temp := CanvasFigures[i];
        CanvasFigures[i] := CanvasFigures[i+1];
        CanvasFigures[i+1] := temp;
      end
  end;
  AddStateToHistory(GetAppState);
  PaintBox.Invalidate;
end;

procedure TMainForm.MEditUndoClick(Sender: TObject);
begin
  Undo(PaintBox);
end;

procedure TMainForm.MFileCloseClick(Sender: TObject);
begin
  ClearAppState;
  ClearHistory;
  openedFile:='';
  PaintBox.Invalidate;
end;

procedure TMainForm.MFileOpenClick(Sender: TObject);
var
  f: text;
  state, s: String;
begin
  if openedFile <> '' then MFileClose.Click;;
  OpenDialog.Filter := 'GraphicEditor files|*.ge';
  if (OpenDialog.Execute) then begin
    try
      openedFile := OpenDialog.FileName;
      System.Assign(f, openedFile);
      System.Reset(f);
      while not EOF(f) do begin
        ReadLn(f, s);
        state := state + s;
      end;
      LoadAppState(state);
      System.Close(f);
    except
      ShowMessage('Error while opening file');
      MFileClose.Click;
    end;
  end;
  PaintBox.Invalidate;
end;

procedure TMainForm.MFileSaveAsClick(Sender: TObject);
begin
  SaveDialog.DefaultExt := 'ge';
  SaveDialog.Filter := 'GraphicEditor files|*.ge';
  SaveDialog.Execute;
  openedFile := SaveDialog.FileName;
  SavePicture;
end;

procedure TMainForm.MFileSaveClick(Sender: TObject);
begin
  if (openedFile = '') then
    MFileSaveAs.Click
  else SavePicture;
end;

procedure TMainForm.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
  currentTool.MouseDown(Point(X, Y), Button, Shift);
  PaintBox.Invalidate;
end;

procedure TMainForm.PaintBoxMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: integer);
begin
  if currentTool.isDrawing then
    currentTool.MouseMove(Point(X, Y));
  SetScrollBars;
  PaintBox.Invalidate;
end;

procedure TMainForm.PaintBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
  currentTool.MouseUp(Point(X, Y), Button);
  ScaleSpin.Value := Scale * 100;
  SetScrollBars;
  PaintBox.Invalidate;
end;

procedure TMainForm.PaintBoxMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if WheelDelta > 0 then ZoomPoint(MousePos, Scale + 0.2)
  else ZoomPoint(MousePos, Scale - 0.2);
  ScaleSpin.Value := Scale * 100;
  SetScrollBars;
  PaintBox.Invalidate;
end;

procedure TMainForm.PaintBoxPaint(Sender: TObject);
var element: TFigureBase; p1, p2: TPoint; w: integer;
begin
  PaintBox.Canvas.Brush.Color := clWhite;
  PaintBox.Canvas.FillRect(0, 0, Width, Height);
  for element in CanvasFigures do
    element.Draw(PaintBox.Canvas);

  with PaintBox.Canvas do begin
    Pen.Width := 1;
    Pen.Style := psDash;
    Brush.Style := bsClear;
    for element in CanvasFigures do
      if element.Selected then
        with element do begin
          p1 := WorldToScreen(FindTopLeft);
          p2 := WorldToScreen(FindBottomRight);
          w := (element as TAnchorsOnPointsFigure).PenWidth;
          Frame(
            p1.x - SELECTION_PADDING - w div 2, p1.y - SELECTION_PADDING - w div 2,
            p2.x + SELECTION_PADDING + w div 2, p2.y + SELECTION_PADDING + w div 2
          );
        end;
  end;

  for element in AnchorsFigures do
    element.Draw(PaintBox.Canvas);
end;

procedure TMainForm.OnClickTool(Sender: TObject);
var nextTool: TTool; i: TFigureBase;
begin
  nextTool := ToolsRegister[(Sender as TBitBtn).Tag];
  currentTool.isDrawing := False;
  currentTool.Panel.Visible := False;
  if (currentTool is TActionTool) and not (nextTool is TActionTool) then begin
    for i in CanvasFigures do i.Selected := False;
    for i in AnchorsFigures do i.Free;
    SetLength(AnchorsFigures, 0);
  end;
  currentTool := nextTool;
  currentTool.ShowParameters;
  PaintBox.Invalidate;
end;

procedure TMainForm.PaintBoxResize(Sender: TObject);
begin
  PBWidth := PaintBox.Width;
  PBHeight := PaintBox.Height;
  SetScrollBars;
end;

procedure TMainForm.ScaleSpinChange(Sender: TObject);
begin
  with ScaleSpin do begin
    try
      if StrToFloat(Caption) > MaxValue then
        Caption := FloatToStr(MaxValue)
      else if StrToFloat(Caption) < MinValue then
        Caption := FloatToStr(MinValue);
    except on EConvertError do
      Caption := FloatToStr(MinValue);
    end;
    ZoomPoint(Point(PaintBox.Width div 2, PaintBox.Height div 2), Value / 100);
    SetScrollBars;
    PaintBox.Invalidate;
  end;
end;

procedure TMainForm.SetScrollBars;
var
  HMin, HMax, VMin, VMax: integer;
  i: TFigureBase;
  Corner: TDPoint;
begin
  HMin := Round(Min(Offset.x - 10, -10));
  HMax := Round(Max(Offset.x + 10,  10));
  VMin := Round(Min(Offset.y - 10, -10));
  VMax := Round(Max(Offset.y + 10,  10));

  Corner := ScreenToWorld(Point(PBWidth, PBHeight));
  for i in CanvasFigures do begin
    HMin := Min(HMin, Round(i.FindTopLeft.x - 10));
    HMax := Max(HMax, Round(Offset.x + i.FindBottomRight.x - Corner.x + 10));
    VMin := Min(VMin, Round(i.FindTopLeft.y - 10));
    VMax := Max(VMax, Round(Offset.y + i.FindBottomRight.y - Corner.y + 10));
  end;

  HorScrollBar.Min := HMin;
  HorScrollBar.Max := HMax;
  VerScrollBar.Min := VMin;
  VerScrollBar.Max := VMax;
  HorScrollBar.Position := Round(Offset.x);
  VerScrollBar.Position := Round(Offset.y);
  HorScrollBar.PageSize := Round((Corner.x - Offset.x) / (HMax - HMin));
  VerScrollBar.PageSize := Round((Corner.y - Offset.y) / (VMax - VMin));
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  i, k: integer;
  Button: TBitBtn;
begin
  ScaleSpin.Value := Scale * 100;
  ScaleSpin.MinValue := MIN_SCALE * 100;
  ScaleSpin.MaxValue := MAX_SCALE * 100;
  PBHeight := PaintBox.Height;
  PBWidth  := PaintBox.Width;

  for i := Low(ToolsRegister) to High(ToolsRegister) do begin
    ToolsRegister[i].CreateParameters(ParametersPanel);
    Button := TBitBtn.Create(ToolsButtons);
    Button.Parent := ToolsButtons;
    Button.Tag := i;
    Button.Caption := '';
    Button.Top := 32 * (i div 3);
    if (i mod 3 = 0) then k := 2;
    Button.Left := 32 * (i mod 3) + k;
    Button.Width := 30;
    Button.Height := 30;
    Button.Glyph := ToolsRegister[i].Bitmap;
    Button.OnClick := @OnClickTool;
  end;
  if Length(ToolsRegister) mod 3 > 0 then k := 1
  else k := 0;
  ToolsButtons.Height := 32 * ((Length(ToolsRegister)) div 3 + k);
  if Length(ToolsRegister) > 0 then begin
    currentTool := ToolsRegister[0];
    currentTool.ShowParameters;
  end;
end;

procedure TMainForm.ScrollBarScroll(Sender: TObject; ScrollCode: TScrollCode;
  var ScrollPos: integer);
begin
  Offset.x := HorScrollBar.Position;
  Offset.y := VerScrollBar.Position;
  PaintBox.Invalidate;
end;

procedure TMainForm.SavePicture;
var
  f: Text;
  state: String;
begin
  if (openedFile <> '') then begin
    System.Assign(f, openedFile);
    System.Rewrite(f);
    state := StatesHistory[currentState];
    WriteLn(f, state);
    System.Close(f);
  end;
end;

end.
