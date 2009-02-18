{#(@)$Id: LoggingTests.pas 726 2003-06-05 13:50:45Z juanco $}
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

unit LoggingTests;

interface
uses
  TestFramework,
  JalLogging;

type
  TLoggerTests = class(TTestCase, ILogHandler)
  protected
    FLog :ILogger;
    FLastEntry :TLogEntry;
    FCount     :Integer;

    procedure SetUp;    override;
    procedure TearDown; override;

    procedure Log(const Entry :TLogEntry);

    procedure DoLogs;
  published
    procedure BasicTest;
    procedure LevelTests;
    procedure HierarchicalLevelTests;
    procedure ClassHierarchyTests;
  end;

implementation

{ TLoggerTests }

procedure TLoggerTests.Log(const Entry: TLogEntry);
begin
  FLastEntry := Entry;
  Inc(FCount);
end;

procedure TLoggerTests.DoLogs;
begin
  FLog.Error('an error');
  FLog.Warning('a warning');
  FLog.Info('an info');
end;

procedure TLoggerTests.SetUp;
begin
  inherited;
  FillChar(FLastEntry, SizeOf(FLastEntry), 0);
  ClearLoggers;
  FLog := Logger;
  FLog.Handler := self;
  FCount := 0;
end;

procedure TLoggerTests.TearDown;
begin
  inherited;
  FLog := nil;
end;

procedure TLoggerTests.BasicTest;
begin
  FLog.Level := logALL;

  FLog.Info('an info');
  CheckEquals(1, FCount, 'count');
  CheckEquals(1, FLastEntry.Seq, 'sequence number');
  CheckEquals(Ord(logINFO), Ord(FLastEntry.Level));
  CheckEquals('an info', FLastEntry.Msg, 'message');
  CheckEquals('', FLastEntry.Who, 'logger name');

  FLog.Warning('a warning');
  CheckEquals(2, FCount, 'count');
  CheckEquals(2, FLastEntry.Seq, 'sequence number');
  CheckEquals(Ord(logWARNING), Ord(FLastEntry.Level), 'level');
  CheckEquals('a warning', FLastEntry.Msg, 'message');
  CheckEquals('', FLastEntry.Who, 'logger name');

  FLog.Error('an error');
  CheckEquals(3, FCount, 'count');
  CheckEquals(3, FLastEntry.Seq, 'sequence number');
  CheckEquals(Ord(logERROR), Ord(FLastEntry.Level), 'level');
  CheckEquals('an error', FLastEntry.Msg, 'message');
  CheckEquals('', FLastEntry.Who, 'logger name');
end;

procedure TLoggerTests.LevelTests;
begin
  FLog.Level := logNONE;
  DoLogs;
  CheckEquals(0, FCount, 'count');
  CheckEquals(0, FLastEntry.Seq, 'sequence number');

  FLog.Level := logERROR;
  DoLogs;
  CheckEquals(1, FCount, 'count');
  CheckEquals(1, FLastEntry.Seq, 'sequence number');
  CheckEquals(Ord(logERROR), Ord(FLastEntry.Level), 'level');
  CheckEquals('an error', FLastEntry.Msg, 'message');

  FLog.Level := logWARNING;
  DoLogs;
  CheckEquals(3, FCount, 'count');
  CheckEquals(3, FLastEntry.Seq, 'sequence number');
  CheckEquals(Ord(logWARNING), Ord(FLastEntry.Level), 'level');
  CheckEquals('a warning', FLastEntry.Msg, 'message');

  FLog.Level := logINFO;
  DoLogs;
  CheckEquals(6, FCount, 'count');
  CheckEquals(6, FLastEntry.Seq, 'sequence number');
  CheckEquals(Ord(logINFO), Ord(FLastEntry.Level));
  CheckEquals('an info', FLastEntry.Msg, 'message');
end;

procedure TLoggerTests.HierarchicalLevelTests;
var
  P, L :ILogger;
begin
  L := Logger('top.bottom');
  P := Logger('top');

  FLog.Level := logNONE;

  L.Warning('bottom level warning');
  CheckEquals(0, FCount, 'count');
  CheckEquals(0, FLastEntry.Seq, 'sequence number');

  P.Level := logWARNING;
  L.Warning('bottom level warning');
  CheckEquals(1, FCount, 'count');
  CheckEquals(1, FLastEntry.Seq, 'sequence number');
  CheckEquals(Ord(logWARNING), Ord(FLastEntry.Level), 'level');
  CheckEquals('bottom level warning', FLastEntry.Msg, 'message');
  CheckEquals('top.bottom', FLastEntry.Who, 'logger name');

  L.Handler := TNullLogHandler.Create;
  L.Warning('bottom level warning');
  CheckEquals(2, FCount, 'count');
  CheckEquals(2, FLastEntry.Seq, 'sequence number');

  L.Handler := self;
  L.Warning('bottom level warning');
  CheckEquals(4, FCount, 'count');
  CheckEquals(3, FLastEntry.Seq, 'sequence number');
end;

procedure TLoggerTests.ClassHierarchyTests;
var
  L :ILogger;
begin
  L := Logger(self.ClassType);
  L.Level := logINFO;
  L.Info('by class logging');
  CheckEquals(1, FLastEntry.Seq, 'sequence number');
  CheckEquals(Ord(logINFO), Ord(FLastEntry.Level), 'level');
  CheckEquals('by class logging', FLastEntry.Msg, 'message');
  CheckEquals('TObject.TInterfacedObject.TAbstractTest.TTestCase.TLoggerTests',
              FLastEntry.Who, 'logger name');
end;

initialization
  RegisterTest(TLoggerTests.Suite);
end.
