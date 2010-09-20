unit upcretest;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, uperlre;

type
  TForm1 = class(TForm)
    edregex1: TEdit;
    edtext1: TEdit;
    Button1: TButton;
    lbresult: TLabel;
    Memo: TMemo;
    edregex2: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    edtext2: TEdit;
    Button2: TButton;
    Label4: TLabel;
    Label5: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;


implementation

{$R *.DFM}


procedure TForm1.Button1Click(Sender: TObject);
var i:integer;
begin
  memo.lines.clear;
  Try
    regex.compile( edregex1.text);
  except
    on e: exception do
    begin
      lbresult.caption:=e.message; exit;
    end;
  end;
  if regex.Match( edtext1.text) then
  begin
    lbResult.caption:='** Match ** #' + IntToStr(regex.SubExpCount);
    for i:=0 to regex.SubExpCount do
      memo.lines.add( regex.SubExp[i].Text);
  end else lbResult.caption:='no match';
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  memo.lines.clear;
  lbResult.caption:='';
  Try
    regex.split( edregex2.text, edtext2.text, memo.lines);
  except
    on e: exception do
    begin
      lbResult.caption:=e.message; exit;
    end;
  end;
end;

end.
