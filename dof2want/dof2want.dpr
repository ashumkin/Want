(****************************************************************************
 * dof2want - A convert utility for Want                                    *
 * Copyright (c) 2003 Mike Johnson.                                         *
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

    @author Mike Johnson
}
program dof2want;

{$APPTYPE CONSOLE}



uses
  SysUtils,
  dofCompilerFlags,
  dofDirectoriesFlags,
  dofLinkerFlags,
  dofreader in 'dofreader.pas',
  wantWriter in 'wantWriter.pas',
  typ_dofReader in 'typ_dofReader.pas',
  const_dofReader in 'const_dofReader.pas';

procedure outputStr(str : string);
  begin
    writeln(str);
  end;
  procedure usage;
  begin
    outputStr('dof2want delphiproject.dof');
  end;

  procedure CreateWantFile(dofFilename : string);
  const
    StandardOutputName = 'want_compile.xml';
  var
    reader : TDelphiDofReader;
    wantWriter : TWantCompileWriter;
  begin
    outputStr('Converting '+DofFilename+' ==> '+StandardOutputName);
    reader := TDelphiDofReader.create;
    try
       try
         reader.LoadFromFile(dofFilename);
         wantWriter := TWantCompileWriter.create;
         wantWriter.NameOfProject := ChangeFileExt(dofFilename,'.dpr');
         wantWriter.writeFile(reader,StandardOutputName);
         outputStr('Conversion Completed Successfully.');
       except
         outputStr('could not recognize '+dofFilename+' as a valid delphi .dof file');
       end;
       
    finally
      reader.free;
    end;
  end;

  procedure Banner;
  begin
    outputStr('.Dof 2 Want Converter v.1.2');
    outputStr('');
  end;
begin
  Banner;
  if paramCount <1 then
    begin
      outputStr('not enough parameters');
      usage;
    end
  else  
  if not fileExists(paramstr(1)) then
     begin
        outputStr('project file not found');
        usage;
     end
  else
    begin
      CreateWantFile(ExpandFilename(paramStr(1)));
    end;   
end.
