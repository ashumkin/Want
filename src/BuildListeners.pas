(****************************************************************************
 * WANT - A build management tool.                                          *
 * Copyright (c) 2001-2003 Juancarlo Anez, Caracas, Venezuela.              *
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
    @brief Build listeners for project

    @author Juancarlo Añez
}
  
unit BuildListeners;

interface
uses
  Classes,
  JclStrings,
  WantClasses;

const
  rcs_id :string = '#(@)$Id: BuildListeners.pas 706 2003-05-14 22:13:46Z hippoman $';

type
  TBasicListener = class(TBuildListener)
  protected
    FErrors   :boolean;
    FFailures :boolean;

    procedure LogLine(Msg: string; Level: TLogLevel = vlNormal);    virtual;
  public
    constructor Create;

    procedure Log(Level: TLogLevel; Msg: string = '');              override;

    procedure BuildFileLoaded(Project :TProject; FileName :string); override;

    procedure BuildStarted;                                         override;
    procedure BuildFinished;                                        override;
    procedure BuildFailed(Project :TProject; Msg :string = '');     override;

    procedure ProjectStarted(Project :TProject);                    override;
    procedure ProjectFinished(Project :TProject);                   override;

    procedure TargetStarted(Target :TTarget);                       override;
    procedure TargetFinished(Target :TTarget);                      override;

    procedure TaskStarted( Task :TTask);                            override;
    procedure TaskFinished(Task :TTask);                            override;
    procedure TaskFailed(  Task :TTask; Msg :string);               override;

    property Failures :boolean read FFailures;
    property Errors   :boolean read FErrors;
  end;

implementation

{ TBasicListener }

procedure TBasicListener.BuildFileLoaded(Project: TProject; FileName: string);
begin

end;

procedure TBasicListener.ProjectStarted(Project: TProject);
begin

end;

procedure TBasicListener.ProjectFinished(Project: TProject);
begin

end;

procedure TBasicListener.BuildFailed(Project: TProject; Msg :string);
begin
  FErrors   := True;
  FFailures := True;
end;

procedure TBasicListener.TargetStarted(Target: TTarget);
begin

end;

procedure TBasicListener.TargetFinished(Target: TTarget);
begin

end;

procedure TBasicListener.TaskStarted(Task: TTask);
begin

end;

procedure TBasicListener.TaskFinished(Task: TTask);
begin

end;

procedure TBasicListener.Log(Level: TLogLevel; Msg: string);
var
  Lines     :TStringList;
  i         :Integer;
begin
  if (Self.Level >= Level) then
  begin
    Lines := TStringList.Create;
    try
      Msg := Msg + ' ';
      JclStrings.StrToStrings(Msg, #10, Lines);
      for i := 0 to Lines.Count-1 do
      begin
        LogLine(Lines[i], Level);
      end;
    finally
      Lines.Free;
    end;
  end;
end;

procedure TBasicListener.TaskFailed(Task: TTask; Msg :string);
begin
  FFailures := True;
end;

procedure TBasicListener.LogLine(Msg: string; Level: TLogLevel);
begin
  // do nothing
end;

constructor TBasicListener.Create;
begin
  inherited Create;
  FLevel := vlNormal;
end;

procedure TBasicListener.BuildStarted;
begin

end;

procedure TBasicListener.BuildFinished;
begin

end;

end.
