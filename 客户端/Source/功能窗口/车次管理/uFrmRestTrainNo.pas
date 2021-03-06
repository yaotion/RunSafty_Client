unit uFrmRestTrainNo;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ActnList, Buttons, ComCtrls, StdCtrls, Mask, RzEdit, ExtCtrls;

type

  //操作状态
  TButtonState = (bsNormal{正常},bsAdd{添加},bsEdit{修改});

  TFrmRestTrainNo = class(TForm)
    Panel1: TPanel;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label3: TLabel;
    Label2: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    edtTrainNo: TEdit;
    edtStartTime: TRzDateTimeEdit;
    radioSingle: TRadioButton;
    radioDouble: TRadioButton;
    CombArea: TComboBox;
    edtSigninTime: TRzDateTimeEdit;
    edtOutDutyTime: TRzDateTimeEdit;
    edtCallTime: TRzDateTimeEdit;
    Panel2: TPanel;
    lvTrainNo: TListView;
    StatusBar1: TStatusBar;
    Panel3: TPanel;
    btnClose: TSpeedButton;
    btnCancel: TSpeedButton;
    btnSave: TSpeedButton;
    btnUpdate: TSpeedButton;
    btnAdd: TSpeedButton;
    btnDelete: TSpeedButton;
    ActionList1: TActionList;
    actClose: TAction;
    procedure btnDeleteClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnUpdateClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure actCloseExecute(Sender: TObject);
    procedure lvTrainNoChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
  private
    { Private declarations }
    isFirst : boolean;
    m_BtnState : TButtonState;
    //刷新列表
    procedure RefreshTrainNos;
    //刷新选中的数据
    procedure RefreshSelectTrainNos;
    //设置窗体当前的操作状态
    procedure SetBtnState(bs : TButtonState);
  end;

var
  FrmRestTrainNo: TFrmRestTrainNo;

implementation
uses
  ADODB,uTrainNoOpt,uGlobalDM,DateUtils;

{$R *.dfm}

procedure TFrmRestTrainNo.actCloseExecute(Sender: TObject);
begin
  btnClose.Click;
end;

procedure TFrmRestTrainNo.btnAddClick(Sender: TObject);
begin
  edtTrainNo.Text := '';
  edtSigninTime.text := '';
  edtCallTime.Text := '';
  edtOutDutyTime.Text := '';
  edtStartTime.Text := '';
  SetBtnState(bsAdd);
end;

procedure TFrmRestTrainNo.btnCancelClick(Sender: TObject);
begin
  SetBtnState(bsNormal);
  RefreshSelectTrainNos;
end;

procedure TFrmRestTrainNo.btnCloseClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TFrmRestTrainNo.btnDeleteClick(Sender: TObject);
var
  traino : string;
begin
  if lvTrainNo.Selected = nil then exit;
  if Application.MessageBox('确定要删除此车次吗？','提示',MB_OKCANCEL)
     = mrCancel then
    exit;
  traino := lvTrainNo.Selected.SubItems[0];
  if TTrainNoOpt.DeleteTrainNo(traino) then
    Application.MessageBox('删除成功.','提示',MB_OK + MB_ICONINFORMATION)
  else
    Application.MessageBox('删除失败.','提示',MB_OK + MB_ICONINFORMATION);
  RefreshTrainNos;
end;

procedure TFrmRestTrainNo.btnSaveClick(Sender: TObject);
var
  trainNo : RTrainNo;
  strTrainNo : string;
  signinTime,callTime,outdutyTime,startTime : TDateTime;
begin
  if edtTrainNo.Text = '' then
  begin
    Application.MessageBox('车次不能为空。','提示',MB_OK+ MB_ICONINFORMATION);
    edtTrainNo.SetFocus;
    exit;
  end;

  if not TryStrToTime(edtSigninTime.Text,signinTime) then
  begin
    Application.MessageBox('强休时间不能为空。','提示',MB_OK+ MB_ICONINFORMATION);
    edtSigninTime.SetFocus;
    exit;
  end;
  if not TryStrToTime(edtCallTime.Text,callTime) then
  begin
    Application.MessageBox('叫班时间不能为空。','提示',MB_OK+ MB_ICONINFORMATION);
    edtCallTime.SetFocus;
    exit;
  end;
  if not TryStrToTime(edtOutDutyTime.Text,outdutyTime) then
  begin
    Application.MessageBox('出勤时间不能为空。','提示',MB_OK+ MB_ICONINFORMATION);
    edtOutDutyTime.SetFocus;
    exit;
  end;
  if not TryStrToTime(edtStartTime.Text,startTime) then
  begin
    Application.MessageBox('开车时间不能为空。','提示',MB_OK+ MB_ICONINFORMATION);
    edtStartTime.SetFocus;
    exit;
  end;

//  if IncMinute(signinTime,Round(DMGlobal.MinRestLength*60)) >  callTime then
//  begin
//    Application.MessageBox('休息时间小于最小强休时间。','提示',MB_OK+ MB_ICONINFORMATION);
//    edtStartTime.SetFocus;
//    exit;
//  end;

  if Application.MessageBox('您确定要继续吗？','提示',MB_OKCANCEL + MB_ICONQUESTION) = mrCancel then
    exit;
  try
    if lvTrainNo.Selected <> nil then
      strTrainNo := lvTrainNo.Selected.SubItems[0];
    case m_BtnState of
      bsAdd:
      begin
        if TTrainNoOpt.IsExistTrainNo(edtTrainNo.Text) then
        begin
          Application.MessageBox('车次已经存在。','提示',MB_OK+ MB_ICONINFORMATION);
          exit;
        end;
        trainNo.strTrainNo := edtTrainNo.Text;
        trainNo.dtSigninTime := StrToDateTime('1900-01-01 ' +  edtSigninTime.Text);
        trainNo.dtCallTime := StrToDateTime('1900-01-01 ' +  edtCallTime.Text);
        trainNo.dtOutDutyTime := StrToDateTime('1900-01-01 ' +  edtOutDutyTime.Text);
        trainNo.dtStartTime := StrToDateTime('1900-01-01 ' +  edtStartTime.Text);
        trainNo.nTrainmanType := 2;
        if radioSingle.Checked then
          trainNo.nTrainmanType := 1;
        trainNo.strAreaGUID := '' ;
        if TTrainNoOpt.AddTrainNo(trainNo) then
          Application.MessageBox('添加成功。','提示',MB_OK+ MB_ICONINFORMATION)
        else
          Application.MessageBox('添加失败。','提示',MB_OK+ MB_ICONINFORMATION);
        RefreshTrainNos;
      end;
      bsEdit:
      begin
        trainNo.strTrainNo := edtTrainNo.Text;
        trainNo.dtSigninTime := StrToDateTime('1900-01-01 ' +  edtSigninTime.Text);
        trainNo.dtCallTime := StrToDateTime('1900-01-01 ' +  edtCallTime.Text);
        trainNo.dtOutDutyTime := StrToDateTime('1900-01-01 ' +  edtOutDutyTime.Text);
        trainNo.dtStartTime := StrToDateTime('1900-01-01 ' +  edtStartTime.Text);
        trainNo.nTrainmanType := 2;
        if radioSingle.Checked then
          trainNo.nTrainmanType := 1;
        trainNo.strAreaGUID := '' ;
        if TTrainNoOpt.UpdateTrainNo(trainNo) then
          Application.MessageBox('修改成功。','提示',MB_OK+ MB_ICONINFORMATION)
        else
          Application.MessageBox('修改失败。','提示',MB_OK+ MB_ICONINFORMATION);
        RefreshTrainNos;  
      end;
    end;
  finally
    SetBtnState(bsNormal);
  end;
end;

procedure TFrmRestTrainNo.btnUpdateClick(Sender: TObject);
begin
  SetBtnState(bsEdit);
end;

procedure TFrmRestTrainNo.FormActivate(Sender: TObject);
begin
  if isFirst then exit;
  isFirst := true;
  RefreshTrainNos;
  SetBtnState(bsNormal);
end;

procedure TFrmRestTrainNo.FormCreate(Sender: TObject);
begin
  ;
end;

procedure TFrmRestTrainNo.FormDestroy(Sender: TObject);
begin
  ;
end;

procedure TFrmRestTrainNo.lvTrainNoChange(Sender: TObject; Item: TListItem;
  Change: TItemChange);
begin
  RefreshSelectTrainNos;
end;

procedure TFrmRestTrainNo.RefreshSelectTrainNos;
begin
  edtTrainNo.Text := '';
  edtSigninTime.Text := '';
  edtCallTime.Text := '';
  edtOutDutyTime.Text := '';
  edtStartTime.Text := '';
  if lvTrainNo.Selected = nil  then exit;
  edtTrainNo.Text := lvTrainNo.Selected.SubItems[0];
  edtSigninTime.Time := StrToTime(lvTrainNo.Selected.SubItems[1]);
  edtCallTime.Time := StrToTime(lvTrainNo.Selected.SubItems[2]);
  edtOutDutyTime.Time := StrToTime(lvTrainNo.Selected.SubItems[3]);
  edtStartTime.Time := StrToTime(lvTrainNo.Selected.SubItems[4]);
  radioDouble.Checked := true;
  if lvTrainNo.Selected.SubItems[3] = '单司机' then
     radioSingle.Checked := true;
  //CombArea.ItemIndex := CombArea.Items.IndexOf(lvTrainNo.Selected.SubItems[6]);
end;

procedure TFrmRestTrainNo.RefreshTrainNos;
var
  ado : TADOQuery;
  i : Integer;
  item : TListItem;
begin
  lvTrainNo.Items.Clear;
  i := 0;
  TTrainNoOpt.GetTrainNos(GlobalDM.LocalArea,ado);
  try
    with ado do
    begin
      First;
      while not eof do
      begin
        i := i + 1;
        item := lvTrainNo.Items.Add;
        item.Caption := Format('%d',[i]);
        item.SubItems.Add(FieldByName('strTrainNo').AsString);
        item.SubItems.Add(FormatDateTime('HH:nn',FieldByName('dtSigninTime').AsDateTime));
        item.SubItems.Add(FormatDateTime('HH:nn',FieldByName('dtCallTime').AsDateTime));
        item.SubItems.Add(FormatDateTime('HH:nn',FieldByName('dtOutDutyTime').AsDateTime));
        item.SubItems.Add(FormatDateTime('HH:nn',FieldByName('dtStartTime').AsDateTime));                
        item.SubItems.Add(FieldByName('strTrainmanTypeName').AsString);
        next;
      end;
    end;
  finally
    ado.Free;
  end;
  StatusBar1.Panels[0].Text := '共'+IntToStr(lvTrainNo.Items.Count)+'条';
end;

procedure TFrmRestTrainNo.SetBtnState(bs: TButtonState);
begin
  if bs = bsEdit then
  begin
    if lvTrainNo.Selected = nil then
    begin
       Application.MessageBox('清选择要修改的车次。','提示',
        MB_OK+ MB_ICONINFORMATION);
       exit;        
    end;
  end;
  m_BtnState := bs;
  //编辑框
  edtTrainNo.Enabled := false;
  edtTrainNo.Color := clBtnFace;
  edtSigninTime.Enabled :=false;
  edtCallTime.Enabled := false;
  edtOutDutyTime.Enabled := false;
  edtStartTime.Enabled := false;
  //按钮
  btnAdd.Enabled :=false;
  btnUpdate.Enabled := false;
  btnDelete.Enabled := false;
  btnSave.Enabled := false;
  btnCancel.Enabled := false;
  //列表
  lvTrainNo.Enabled := false;
  case bs of
    bsNormal:
    begin
      btnAdd.Enabled :=true;
      btnUpdate.Enabled := true;
      btnDelete.Enabled := true;
      lvTrainNo.Enabled := true;
      StatusBar1.Panels[1].Text := '当前状态：浏览';
    end;
    bsAdd:
    begin
      edtTrainNo.Enabled := true;
      edtTrainNo.Color := clWhite;
      edtSigninTime.Enabled :=true;
      edtCallTime.Enabled := true;
      edtOutDutyTime.Enabled := true;
      edtStartTime.Enabled := true;
      btnSave.Enabled := true;
      btnCancel.Enabled := true;
      StatusBar1.Panels[1].Text := '当前状态：添加';
    end;
    bsEdit:
    begin
      edtSigninTime.Enabled :=true;
      edtCallTime.Enabled := true;
      edtOutDutyTime.Enabled := true;
      edtStartTime.Enabled := true;
      btnSave.Enabled := true;
      btnCancel.Enabled := true;
      StatusBar1.Panels[1].Text := '当前状态：修改';
    end;
  end;
end;

end.
