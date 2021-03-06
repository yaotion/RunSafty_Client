unit uCallUtils;

interface
uses
  Classes, Windows, uCallRecord;
type
  TCallThread = class(TThread)
  private
    m_CallData: TCallData;
    m_bIsRecall: boolean;
  protected
    procedure Execute(); override;
    procedure CallRoom(callData: TCallData; recall: boolean);
  public
    property CallData: TCallData read m_CallData write m_CallData;
    property IsRecall: boolean read m_bIsRecall write m_bIsRecall;
  end;

  TCallFunction = class
  public
    //判断当前是否处于最后一次叫班中
    class function InCallWaitingTime(lastCallTime, dtNow: TDateTime; callWaiting: Cardinal): boolean;
    //判断叫班数据是否已过期
    class function HasExpired(callTime,appTime : TDateTime;ExpiredDelay:Word) : boolean;
    //能否叫班
    class function CanCall(callData : TCallData;nowTime : TDateTime;callDelay:Word) : boolean;
    class function CalRecall(callData : TCallData;nowTime : TDateTime;callDelay:Word) : boolean;
  end;
implementation

{ TCallThread }
uses
  uGlobalDM,uCallRoomDM, SysUtils, MMSystem, uFrmMain_RoomSign, uLogs, DateUtils;

procedure TCallThread.CallRoom(callData: TCallData; recall: boolean);
//功能：自动叫班
var
  i, devID, maxCallCount, errorCode, lParam: Integer;
  callSucceed: boolean;
begin
  TLog.SaveLog(now,'TCallThread.CallRoom');
  lParam := 0;
  if recall then lParam := 1;
  
  PostMessage(frmMain_RoomSign.Handle, WM_MSGCallBegin, 0, lParam);
  devID := callData.nDeviceID;
  maxCallCount := 0;
  callSucceed := false;
  try
    DMCallRoom.CloseMic;
    errorCode := 1;
    TLog.SaveLog(now, '开始打开串口');
    {$REGION '连接呼叫，如果失败则重复10此'}
    //闫 先挂断一下
    DMCallRoom.HangCall;
    
    repeat
      Sleep(500);
      try
        errorCode := DMCallRoom.CallRoom(devID);
        if errorCode > 0 then
        begin
          TLog.SaveLog(now, 'DMCallRoom.CallRoom(devID) 错误');
          Inc(maxCallCount);
        end else begin
          TLog.SaveLog(now, 'DMCallRoom.CallRoom(devID) 成功');
          maxCallCount := 1000;
          callSucceed := true;
        end;
      except
        TLog.SaveLog(now, 'DMCallRoom.CallRoom(devID) except 错误');
        Inc(maxCallCount);
      end;
    until (maxCallCount >= 10);
    {$ENDREGION '连接呼叫，如果失败则重复10此'}

    if not callSucceed then
    begin
      TLog.SaveLog(now, '开始打开失败');
      PostMessage(frmMain_RoomSign.Handle, WM_MSGCallEnd, errorCode, lParam);
      DMCallRoom.Comming := False;

      //远程叫班模式（闫）
      if not DMCallRoom.bCallModel then
        DMCallRoom.UDPControl.SendCommand('#0:' + callData.strRoomNumber + '#');

      exit;
    end;

    PostMessage(frmMain_RoomSign.Handle, WM_MSGRecordBegin, 0, 0);
    try
      {$REGION '播放叫班音乐'}
      if callSucceed then
      begin
        if not recall then
        begin
          TLog.SaveLog(now, '开始播放叫班音乐');
          DMCallRoom.PlayFirstCall(callData.strRoomNumber, callData.strTrainNo,
            FormatDateTime('yyyy-mm-dd hh:nn:ss',callData.dtDutyTime));
          TLog.SaveLog(now, '播放叫班音乐结束');
          if DMCallRoom.WaitforConfirm then
          begin
            DMCallRoom.WaitingForConfirm := true;
            PostMessage(frmMain_RoomSign.Handle,WM_MSGWaitingForConfirm,StrToInt(callData.strRoomNumber),0);
            while DMCallRoom.WaitingForConfirm do
            begin
              Sleep(10);
            end;
          end else begin
            //等待司机回答，6秒等待
            for i := 1 to 30 do
            begin
              Sleep(200);
            end;
          end;
        end
        else
          DMCallRoom.PlaySecondCall(callData.strRoomNumber, callData.strTrainNo);
      end
      else begin
        DMCallRoom.CallControl.SetPlayMode(2);
        PlaySound(PChar(GlobalDM.AppPath + 'Sounds\叫班失败.wav'), 0, SND_FILENAME or SND_SYNC);
      end;
    finally
      PostMessage(frmMain_RoomSign.Handle, WM_MSGRecordEnd, 0, 0);
      PostMessage(frmMain_RoomSign.Handle, WM_MSGCallEnd, 0, lParam);
    end;
    {$ENDREGION '播放叫班音乐'}

      //远程叫班模式（闫）
    if not DMCallRoom.bCallModel then
    begin
      if recall then
        DMCallRoom.UDPControl.SendCommand('#3:' + callData.strRoomNumber + ':' +
        callData.strGUID + '#')// 催叫完成
      else
        DMCallRoom.UDPControl.SendCommand('#2:' + callData.strRoomNumber + ':' +
        callData.strGUID + '#');//首叫完成
    end;

  finally
    DMCallRoom.HangCall();
    DMCallRoom.OpenMic;
  end;
end;

procedure TCallThread.Execute;
begin
  TLog.SaveLog(now,'TCallThread.Execute');
  DMCallRoom.Comming := True;
  CallRoom(m_CallData, m_bIsRecall);
  DMCallRoom.Comming := False;
end;

{ TCallFunction }

class function TCallFunction.CalRecall(callData: TCallData; nowTime: TDateTime;
  callDelay: Word): boolean;
begin
  Result := false;
end;

class function TCallFunction.CanCall(callData : TCallData; nowTime: TDateTime;
  callDelay: Word): boolean;
begin
  Result := false;
  if callData.nCallState <> 0 then exit;
  if nowTime < callData.dtCallTime then exit;
  if (MinutesBetween(callData.dtCallTime, nowTime) < callDelay)  then
    Result := true;
end;

class function TCallFunction.HasExpired(callTime,appTime: TDateTime;
  ExpiredDelay: Word): boolean;
begin
  Result := (IncMinute(callTime,ExpiredDelay) < appTime);
end;

class function TCallFunction.InCallWaitingTime(
  lastCallTime, dtNow: TDateTime; callWaiting: Cardinal): boolean;
begin
  Result := false;
  if YearOf(lastCallTime) = 9999 then
  begin
    Result := true;
    exit;
  end;

  if IncSecond(lastCallTime, callWaiting) >= now then
  begin
    Result := true;
  end;
end;

end.

