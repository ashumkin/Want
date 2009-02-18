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
    @author Radim Novotny <radimnov@seznam.cz>
}

unit LoadFileTasks;

interface

uses
  SysUtils,
  Classes,
  WantClasses;

type
  TLoadFileTask = class(TTask)
  private
    FFailOnError :boolean;
    FProperty    :string;
    FSrcFile     :string;
  public
    constructor Create;

    procedure Init;    override;
    procedure Execute; override;
  published
    property srcfile   :string read FSrcfile  write FSrcfile;
    property _property :string read FProperty write FProperty;
    {  property encoding is not supported until Synapse or other
       third-party library with character set transltion will be
       included in WANT
    }
    // property encoding : string read fencoding write fencoding;
    property failonerror: boolean read FFailOnError write FFailOnError;
  end;

implementation

uses
  FilterElements;

{ TLoadFileTask }

constructor TLoadFileTask.Create;
begin
  FFailOnError := True;
end;

procedure TLoadFileTask.Execute;
var
  i    : integer;
  j    : integer;
  bSL  : TStringList;
  bFCE : TFilterChainElement;
begin
  inherited;
  bSL := TStringList.Create;
  try
    try
      bSL.LoadFromFile(ToSystemPath(FSrcFile));
    except
      if FFailOnError then
        raise;
    end;
    // process filterchains
    for i := 0 to ChildCount - 1 do
    begin
      if Children[i] is TFilterChainElement then
      begin
        // filterchain element does not have any attributes, only nested tags
        bFCE := Children[i] as TFilterChainElement;
        for j := 0 to bFCE.ChildCount - 1 do
        begin
          if bFCE.Children[j] is TCustomFilterElement then
          begin
            bSL.Text := (bFCE.Children[j] as TCustomFilterElement).ExecuteFilter(bSL.Text);
          end;
        end;
      end;
    end;
    if Assigned(Owner) then 
    begin
      Project.SetProperty(FProperty, bSL.Text);
    end;
  finally
    bSL.Free;
  end;
end;

procedure TLoadFileTask.Init;
begin
  inherited;
  RequireAttributes(['srcfile', 'property']);
end;

initialization
  RegisterTask(TLoadFileTask);
end.
