unit uFrmProgressEx;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, RzPrgres, StdCtrls, ExtCtrls, RzPanel, pngimage, uTFRotationPicture;

type
  TfrmProgressEx = class(TForm)
    RzPanel1: TRzPanel;
    ProgressBar: TRzProgressBar;
    LblText: TLabel;
    TFRotationPicture1: TTFRotationPicture;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    class procedure DisplayProgess(Index,Count : integer);
    class procedure CreateProgress();
    class procedure SetHint(TextHint : string);
    { Public declarations }
    class procedure ShowProgress(TextHint : string;Index,Count : integer;Delay: integer = 0);
    class procedure CloseProgress();
  end;

var
  frmProgressEx : TfrmProgressEx;

implementation


{$R *.dfm}

class procedure TfrmProgressEx.CloseProgress;
begin
  if frmProgressEx <> nil then
  begin
    FreeAndNil(frmProgressEx);
  end;
end;

class procedure TfrmProgressEx.CreateProgress();
begin
  if frmProgressEx = nil then
  begin
    frmProgressEx := TfrmProgressEx.Create(nil);
  end;
end;

class procedure TfrmProgressEx.DisplayProgess(Index, Count: integer);
begin
  if frmProgressEx = nil then
    Exit ;
  frmProgressEx.ProgressBar.Percent := Round((Index * 100)/Count);
  frmProgressEx.Show;
  Application.ProcessMessages;
  sleep(0);  
end;

procedure TfrmProgressEx.FormCreate(Sender: TObject);
begin
  RzPanel1.DoubleBuffered := true;
end;

class procedure TfrmProgressEx.SetHint(TextHint: string);
begin
  if frmProgressEx = nil then
    Exit ;
  frmProgressEx.LblText.Caption := TextHint;
end;

class procedure TfrmProgressEx.ShowProgress(TextHint: string; Index,
  Count: integer;Delay: integer);
begin
  if frmProgressEx = nil then
  begin
    frmProgressEx := TfrmProgressEx.Create(nil);
  end;
  frmProgressEx.LblText.Caption := TextHint;
  frmProgressEx.ProgressBar.Percent := Round((Index * 100)/Count);
  frmProgressEx.Show;
  Application.ProcessMessages;
  sleep(Delay);
end;


end.
