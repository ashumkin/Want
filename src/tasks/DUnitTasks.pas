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
    @brief 

    @author Juancarlo Añez
}

unit DUnitTasks;

interface
uses
  SysUtils,
  Classes,

  JclSysUtils,

  WildPaths,
  WantClasses,
  TestFramework,
  TestModules;

type
  TDUnitTask = class(TTask, ITestListener)
  // implement IInterface
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  // implement the ITestListener interface
  protected
    procedure AddSuccess(test: ITest); virtual;
    procedure AddError(error: TTestFailure); virtual;
    procedure AddFailure(failure: TTestFailure); virtual;
    function  ShouldRunTest(test :ITest) :boolean;  virtual;
    procedure StartSuite(suite: ITest);
    procedure StartTest(test: ITest); virtual;
    procedure EndTest(test: ITest); virtual;
    procedure EndSuite(suite: ITest);
    procedure TestingStarts; virtual;
    procedure TestingEnds(testResult: TTestResult); virtual;
    procedure Status(test :ITest; const Msg :string); virtual;
    procedure Warning(test: ITest; const Msg: string);

 // implement the task
  protected
    FTestLib :TPath;
  public
    procedure Init; override;
    procedure Execute; override;
  published
    property basedir;
    property dir: TPath     read GetBaseDir  write SetBaseDir;
    property testlib :TPath read FTestLib write FTestLib;
  end;

implementation

{ TDUnitTask }

function TDUnitTask.QueryInterface(const IID: TGUID; out Obj): HResult;
const
  E_NOINTERFACE = $80004002;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := HResult(E_NOINTERFACE);
end;

function TDUnitTask._AddRef: Integer;
begin
  Result := MaxInt;
end;

function TDUnitTask._Release: Integer;
begin
  Result := MaxInt;
end;

procedure TDUnitTask.AddError(error: TTestFailure);
begin
  Log(vlErrors,  '! %s: "%s" at %s', [ error.FailedTest.Name,
                                       error.ThrownExceptionMessage,
                                       PointerToLocationInfo(error.ThrownExceptionAddress)
                                       ]);
end;

procedure TDUnitTask.AddFailure(failure: TTestFailure);
begin
  Log(vlWarnings, '- %s: "%s" at %s', [ failure.FailedTest.Name,
                                        failure.ThrownExceptionMessage,
                                        PointerToLocationInfo(failure.ThrownExceptionAddress)
                                        //PointerToAddressInfo(failure.ThrownExceptionAddress)
                                        ]);
end;

procedure TDUnitTask.AddSuccess(test: ITest);
begin
  Log(vlVerbose, '+ ' + test.Name);
end;

function TDUnitTask.ShouldRunTest(test: ITest): boolean;
begin
  Result := true;
end;

procedure TDUnitTask.StartTest(test: ITest);
begin
  Log(vlDebug, '[ %s', [test.Name]);
end;

procedure TDUnitTask.EndTest(test: ITest);
begin
  Log(vlDebug, '] %s', [test.Name]);
end;

procedure TDUnitTask.TestingStarts;
begin
  Log(vlVerbose, 'start');
end;

procedure TDUnitTask.TestingEnds(testResult: TTestResult);
begin
  Log(vlVerbose, 'done');
  if testResult.WasSuccessful then
    Log(vlVerbose, '%4d Tests OK', [testResult.RunCount])
  else
  begin
    Log(vlVerbose, '%4d Run', [testResult.RunCount]);
    if testResult.FailureCount > 0 then
      Log(vlWarnings, '%4d Failures', [testResult.FailureCount]);
    if testResult.ErrorCount > 0 then
      Log(vlErrors, '%4d Errors',   [testResult.ErrorCount]);
  end;
end;

procedure TDUnitTask.Init;
begin
  inherited Init;
  RequireAttribute('testlib');
end;

procedure TDUnitTask.Execute;
var
  Test :ITest;
begin
  inherited Execute;
  Log(ToRelativePath(testlib));
  try
    Test := LoadModuleTests(ToSystemPath(testlib)) as ITest;
    try
      if not TestFramework.RunTest(Test, [Self]).WasSuccessful then
        TaskFailure('tests failed');
    finally
      Test := nil;
    end;
  except
    on e :EWantException do
      raise;
    on e :Exception do
      TaskError(e.Message, ExceptAddr);
  end;
end;

procedure TDUnitTask.Status(test: ITest; const Msg: string);
begin
  Log(vlVerbose, Format('%s: %s', [test.Name, Msg]));
end;

procedure TDUnitTask.Warning(test: ITest; const Msg: string);
begin
  Log(vlWarnings, Format('%s: %s', [test.Name, Msg]));
end;

procedure TDUnitTask.StartSuite(suite: ITest);
begin

end;

procedure TDUnitTask.EndSuite(suite: ITest);
begin

end;

initialization
  RegisterTask(TDUnitTask);
finalization
  UnloadTestModules;
end.
