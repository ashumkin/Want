(****************************************************************************
 * WANT - A build management tool.                                          *
 * Copyright (c) 1995-2003 Juancarlo Anez, Caracas, Venezuela.              *
 * All rights reserved.                                                     *
 *                                                                          *
 * This library is free software; you can redistribute it and/or            *
 * modify it under the terms of the GNU Lesser General Public               *
 * License as published by the Free Software Foundation; either             *
 * version 2.1 of the License, or (at your option) any later version.       *
 *                                                                          *
 * This library is distributed in the hope that it will be useful,          *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU        *
 * Lesser General Public License for more details.                          *
 *                                                                          *
 * You should have received a copy of the GNU Lesser General Public         *
 * License along with this library; if not, write to the Free Software      *
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA *
 ****************************************************************************)
{
    @brief 

    @author Juancarlo Añez
}

unit JalMessages;
interface
uses
  Windows,
  SysUtils,
  Classes,
  Math,
  
  JalUtils,
  JalCRT,
  JalStrings,
  JALCollections;

resourcestring
  msg_Error = 'Internal Error %0:4.4s at %1:p';
  msg_OEMError = 'Internal Error %0:4.4s at %1:p';


var
   hResourceInstance :tHandle = 0;  {handle to get resources from }
   msgf_MessageFont: tHandle = 0;


const
  nation_LatinAmerican = 1;
  nation_English       = 2;
  nation_Base :Longint = nation_LatinAmerican;
  nation_Space         = 2000;


type
 TAnswer  =
   (
   ans_Null,
   ans_Ok,
   ans_Cancel,
   ans_Abort,
   ans_Retry,
   ans_Ignore,
   ans_Yes,
   ans_No
   );

  IMessageHandler = interface
    procedure alert(msg :string);
    procedure status(msg :string);
    procedure progress(msg :string; progress :single); overload;
    procedure progress(progress :single);              overload;
    procedure clearStatus;
    function  question(msg: string; what: Integer): TAnswer;
    procedure sysAlert(msg: String);
  end;

  TMessageHandler = class(TObject, IMessageHandler)
    procedure alert(msg :string);                             virtual;
    procedure status(msg :string);                            virtual;
    procedure progress(msg :string; progress :single);        overload; virtual;
    procedure progress(progress :single);                     overload; virtual;
    procedure clearStatus;                                    virtual;
    function  question(msg: string; what: Integer): TAnswer;  virtual;
    procedure sysAlert(msg: String);                          virtual;
  protected
    _prevProgress  :integer;
    _progressStart :TDateTime;
    function _AddRef: Integer;  stdcall;
    function _Release: Integer; stdcall;
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
  end;

  TNullMessageHandler = class(TMessageHandler)
    procedure alert(msg :string);                             override;
    procedure status(msg :string);                            override;
    procedure progress(msg :string; progress :single);        override;
    procedure clearStatus;                                    override;
    function  question(msg: string; what: Integer): TAnswer;  override;
    procedure sysAlert(msg: String);                          override
    ;
  end;

  procedure nalert(no :Longint);
  procedure nstatus(no :Longint);

  procedure abort(Tit, Mess: string);
  { abortar programa con mensaje}

  function msgNoId(no :Longint):Integer;

  procedure ShowException(ExceptObject: SYSTEM.TObject);
  function BuildExceptMsg(ExceptObject: SYSTEM.TObject; ExceptAddr: Pointer):string;
  function setResourceInstance(hinstance :tHandle):tHandle;
  function FormatId(fmtId :Longint; const args :array of const):String;
  procedure AlertFmt(const fmt :String; const args :array of const);
  procedure StatusFmt(const fmt :String; const args :array of const);
  procedure AlertFmtId(fmtId :Longint; const args :array of const);
  procedure StatusFmtId(fmtId :Longint; const args :array of const);

  function dlgNo(n :Longint):PChar;
  function messageBox(parent:HWnd; txt:String; title:String; mode:Longint):Longint;
  function loadString(id:Longint):String;

  function AskYesNoCancel(msgId :Longint; const args :array of const):tAnswer;
  function AskYesNo(msgId :Longint; const args :array of const) :Boolean;
  function AskOkCancel(msg :String;const args :array of const) :Boolean;

  procedure ErrorMess(tit, msg :string);
  procedure StatusMess(tit, msg :string);

  procedure alert(msg :string);
  procedure status(msg :string);
  procedure progress(msg :string; progress :single); overload;
  procedure progress(progress :single);              overload;
  procedure clearStatus;
  function  question(msg: string; what: Integer): TAnswer;
  function  nmsg(msgNo :Longint):string;
  procedure sysAlert(msg: String);

  function  MessageHandler :TMessageHandler;
  procedure PushMessageHandler(handler :TMessageHandler);
  function  PopMessageHandler(handler :TMessageHandler = nil): TMessageHandler;


{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
implementation

  procedure nalert(no :Longint);
   begin
     MessageHandler.alert(nmsg(no))
   end;

  procedure nstatus(no :Longint);
   begin
     MessageHandler.status(nmsg(no))
   end;

  function  question(msg: string; what: Integer): TAnswer;
  begin
     result := MessageHandler.question(msg, what);
  end;

  procedure abort;
  begin
    MessageHandler.alert(Tit+':'+Mess);
    halt(1)
  end;


  function msgNoId(no :Longint):Integer;
   begin
     msgNoId := Integer(no) {Integer(nation_Space*nation_Base+no)}
   end;

   function FormatId(fmtId :Longint; const args :array of const):String;
   begin
     try
        Result := Format(nmsg(fmtId), args)
     except
        Result := nmsg(fmtId)
     end
   end;

  procedure AlertFmt(const fmt :String; const args :array of const);
   begin
     MessageHandler.alert(Format(fmt, args));
   end;

  procedure StatusFmt(const fmt :String; const args :array of const);
   begin
     MessageHandler.status(Format(fmt, args));
   end;

  procedure AlertFmtId(fmtId :Longint; const args :array of const);
   begin
     MessageHandler.alert(FormatId(fmtId, args));
   end;

  procedure StatusFmtId(fmtId :Longint; const args :array of const);
   begin
     MessageHandler.status(FormatId(fmtId, args));
   end;

  function AskYesNoCancel(msgId :Longint; const args :array of const ):tAnswer;
   begin
     Result := Question(FormatId(msgId, args), mb_YesNoCancel)
   end;

  function AskYesNo(msgId :Longint; const args :array of const) :Boolean;
   begin
     Result := Question(FormatId(msgId, args), mb_YesNo) = ans_Yes
   end;

  function AskOkCancel(msg :String;const args :array of const) :Boolean;
   begin
     askOkCancel := Question(Format(msg, args), mb_OkCancel) = ans_Ok
   end;

  function setResourceInstance(hinstance :tHandle):tHandle;
   begin
     setResourceInstance := hResourceInstance;
     if hinstance <> 0 then
       hResourceInstance := hInstance;
   end;


  function dlgNo(n :Longint):PChar;
   begin
     dlgNo := makeIntResource(msgNoId(n))
   end;

  {}
  {}
  function loadString(id:Longint):String;
   var
     len :Integer;
   begin
     len := Windows.loadString(hResourceInstance, Word(id), nil, 0);
     SetLength(Result, len);
     Windows.loadString(hResourceInstance, Word(id), PChar(Result), len);
   end;

  procedure nullProc;
  far;
   begin
   end;

  procedure statusMessage(const msg :String);
  far;
   begin
   end;

  {}
  {}
  function messageBox(parent:HWnd; txt:String; title:String; mode:Longint):Longint;
   begin
       Result := Windows.messageBox(parent, PChar(txt), PChar(title), mode)
   end;

function nmsg(msgNo :Longint):string;
var
  s :string;
begin
  if msgNo = 0 then
    result := ''
  else begin
    s := LoadString(msgNoId(msgNo));
    if length(s) <> 0 then
      result := s
    else
      result := IntToStr(msgNo);
  end
end;

 {}
 {}
 function stdAsk(const Mess : string; what :Longint):TAnswer;
 begin
  if IsConsole then begin
      writeln(Mess);
      readln;
  end;
  stdAsk := ans_Ok
 end;

 procedure StdClearStat;
 far;
 begin
   if IsConsole then
      ClrEOL
 end;


  procedure StdErrorMess(const Mess : string);
   far;
    begin
      writeln;
      writeln(Mess);
      writeln('Oprima cualquier tela para continuar...');
      readln;
    end;

  procedure StdStatusMess(Mess : string); far;
  begin
    if IsConsole then begin
       gotoXY(1, whereY);
       write(Mess);
       clrEol;
    end
  end;

  var
    Prev :Integer = 0;

  function stdMessageNo(msgNo :Longint):String; far;
  begin
   if msgNo = 0 
   then
     Result := ''
   else
     Result := IntToStr(msgNo);
  end;

  function stdMessageNoStr(msgNo :Longint; msg :pChar; mx :Integer):Integer;far;
  var
   s :array [0..20] of Char;
  begin
     Result := 0;
     if IsConsole then begin
         if msgNo = 0 then begin
           strCopy(msg,'');
           Result := 0;
         end
         else begin
           str(msgNo, s);
           strLCopy(msg, '', mx);
           strLCat(msg, '0000', max(0,min(mx, 4-strLen(s))) );
           strCat(msg, s);
           Result := strlen(msg);
         end
     end
  end;

  procedure makeMessageFont;
  var
   font  :tLogFont;
  begin
   with font do begin
     lfHeight         := Integer(hiWord(getDialogBaseUnits)); { negative means points }
     lfWidth          := 0;
     lfEscapement     := 0;
     lfOrientation    := 0;
     lfWeight         := fw_Light;
     lfItalic         := 0;
     lfUnderline      := 0;
     lfStrikeOut      := 0;
     lfCharSet        := ansi_CharSet;
     lfOutPrecision   := out_Default_Precis;
     lfClipPrecision  := clip_Default_Precis;
     lfQuality        := proof_Quality;
     lfPitchAndFamily := ff_Swiss;
     fillChar(lfFaceName, sizeOf(lfFaceName), 0)
   end;
   msgf_MessageFont := createFontIndirect(font);
  end;

  procedure _ShowException(ExceptObject: SYSTEM.TObject; ExceptAddr: Pointer);
  begin
    MessageHandler.alert(BuildExceptMsg(ExceptObject, ExceptAddr));
  end;

  function BuildExceptMsg(ExceptObject: SYSTEM.TObject; ExceptAddr: Pointer):string;
  const
     SException     = '%s in'#10'%s at %p.'#10'%s'#10;
     SMessage       = '%s.';
  var
    ExceptName: string[31];
    ExceptMessage: string[63];
    ModuleName: array[0..15] of Char;
    Buffer: array[0..254] of Char;
  begin
    ExceptName := ExceptObject.ClassName;
    ExceptAddr := ExceptAddr;
    GetModuleFileName(HInstance, Buffer, SizeOf(Buffer));
    StrCopy(ModuleName, StrRScan(Buffer, '\') + 1);
    ExceptMessage := '';
    if ExceptObject is Exception then
    begin
      ExceptMessage := Exception(ExceptObject).Message;
      ExceptMessage := Format(SMessage, [ExceptMessage]);
    end;
    Result := Format(SException, [ExceptName, ModuleName, ExceptAddr, ExceptMessage]);
  end;

  procedure ShowException(ExceptObject: SYSTEM.TObject);
  begin
       if ExceptObject is Exception then
          sysAlert(Format('%s'#13'[%s]', [Exception(ExceptObject).message,ParseULName(ExceptObject.ClassName,['E'])]))
       else
          sysAlert(Format('[%s]', [ParseULName(ExceptObject.ClassName,['E'])]))
  end;

  procedure clearMessageFont;
   begin
     if msgf_MessageFont <> 0 then
        deleteObject(msgf_MessageFont);
   end;

  procedure ErrorMess(tit, msg :string);
  begin
    MessageHandler.alert(tit + ': ' + msg)
  end;

  procedure StatusMess(tit, msg :string);
  begin
    MessageHandler.status(tit + ': ' + msg)
  end;

  {$I-}
  procedure sayError; far;
   var
      Err : Integer;
   begin
       Err := exitCode;
       if  (ErrorAddr<> nil) then begin
           if msg_OEMError <> '' then
              sysAlert(Format(msg_OEMError, [Err,ErrorAddr]))
           else
              sysAlert(Format(msg_Error, [Err,ErrorAddr]));
           ErrorAddr := nil;
        end;
   end;

var
  __handlers :IStack = nil;

procedure init;
var
  handler :TMessageHandler;
begin
  __handlers := TStack.create(TLinkedList.create);
  handler := TNullMessageHandler.Create;
  PushMessageHandler(handler);
  hResourceInstance  := hInstance;
  MakeMessageFont;
end;



procedure alert(msg :string);
begin
  if MessageHandler <> nil then
    MessageHandler.alert(msg);
end;

procedure status(msg :string);
begin
  if MessageHandler <> nil then
    MessageHandler.status(msg);
end;

procedure progress(msg :string; progress :single);
begin
  if MessageHandler <> nil then
    MessageHandler.progress(msg, progress);
end;

procedure progress(progress :single);
begin
  if MessageHandler <> nil then
    MessageHandler.progress(progress);
end;

procedure clearStatus;
begin
  if MessageHandler <> nil then
    MessageHandler.clearStatus;
end;

procedure sysAlert(msg: String);
begin
  if MessageHandler <> nil then
    MessageHandler.sysAlert(msg);
end;

function MessageHandler :TMessageHandler;
begin
  if (__handlers = nil) or (__handlers.isEmpty) then
    result := nil
  else
    result := (__handlers.top as IReference).referent as TMessageHandler;
end;

procedure PushMessageHandler(handler :TMessageHandler);
begin
  PopMessageHandler(handler);
  __handlers.push(iref(handler));
end;

function PopMessageHandler(handler :TMessageHandler): TMessageHandler;
var
  ref :IUnknown;
begin
  result := nil;
  if not __handlers.isEmpty then
  begin
    if handler <> nil then
      ref := __handlers.remove(iref(handler))
    else
      ref := __handlers.pop;
    if ref <> nil then
    begin
      result := (ref as IReference).referent as TMessageHandler;
      if handler =  nil then
        (ref as IReference).referent.Free;
    end
  end;
end;

{ TMessageHandler }

procedure TMessageHandler.alert(msg: string);
var
 flags:Longint;
begin
 flags :=  mb_Ok or mb_IconExclamation;
 messageBeep(flags);
 messageBox(getFocus, msg, 'Error', flags)
end;

procedure TMessageHandler.sysAlert(msg:String);
var
  flags:Longint;
begin
  flags :=  mb_Ok or mb_IconStop or mb_SystemModal;
  messageBeep(flags);
  messageBox(getFocus, msg, 'Error', flags)
end;

function TMessageHandler.question(msg:string; what :Longint):TAnswer;
var
 flags:Longint;
begin
  flags :=  mb_IconQuestion or what;
  messageBeep(flags);
  result := TAnswer(Byte(messageBox(getFocus, msg, '', flags)))
end;

procedure TMessageHandler.progress(msg: string; progress: single);
const
  Len = 30;
  Step : array[0..3] of char = ('-','\','|','/');
var
   N       :Integer;
   elapsed :TDateTime;
begin
  if (progress = 0) or (_progressStart = 0) then
    _progressStart := now;
  N := Round(Len*Progress);
  if N <> _prevProgress then begin
     elapsed := now - _progressStart;
     status(Format('(%s) %20s [%-30s] %s  T-%s', [
                 Step[N mod Length(Step)],
                 Copy(msg,1, Len),
                 StrRepeat('#', N),
                 FormatTime(elapsed),
                 FormatTime((1-progress)*elapsed/progress)
                 ]));
     _prevProgress := N
  end
end;

procedure TMessageHandler.status(msg: string);
begin
  gotoXY(1, whereY);
  write(msg);
  clrEol;
end;

procedure TMessageHandler.clearStatus;
begin
  _prevProgress  := -1;
  _progressStart :=  0;
  Status('');
end;

function TMessageHandler._AddRef: Integer;
begin
  result := -1;
end;

function TMessageHandler._Release: Integer;
begin
  result := -1;
end;

function TMessageHandler.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    result := S_OK
  else
    result := E_NOINTERFACE
end;

procedure TMessageHandler.progress(progress: single);
begin
  self.progress('', progress);
end;

{ TNullMessageHandler }

procedure TNullMessageHandler.alert(msg: string);
begin

end;

procedure TNullMessageHandler.clearStatus;
begin

end;

procedure TNullMessageHandler.progress(msg: string; progress: single);
begin

end;

function TNullMessageHandler.question(msg: string; what: Integer): TAnswer;
begin
  result := ans_Null
end;

procedure TNullMessageHandler.status(msg: string);
begin

end;

procedure TNullMessageHandler.sysAlert(msg: String);
begin

end;

initialization
  init
finalization
  SayError;
  __handlers := nil;
end.
