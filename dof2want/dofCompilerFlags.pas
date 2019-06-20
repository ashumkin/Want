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
unit dofCompilerFlags;
{
Unit        : dofCompilerFlags

Description : extracts information from the compiler flags

Programmer  : mike

Date        : 10-Dec-2002
}

interface

uses
  classes,
  dccflags,
  dofFlagExtractor,
  dofReader;
  
type

 TCompilerFlag = record
   flagSymbol : string;
   flagDefault : boolean;
 end;

const

  DCCCompilerFlags : array[TVerboseFlagEnum] of string =
  (
  ('O'), {vfOptimization    }
  ('W'), {vfStackFrames     }
  ('U'), {vfSaveDivide	    }
  ('R'), {vfRangeChecks     }
  ('I'), {vfIOChecks        }
  ('Q'), {vfOverflowchecks  }
  ('V'), {vfVarStringChecks }
  ('B'), {vfBoolEval	       }
  ('X'), {vfExtendedSyntax  }
  ('T'), {vfTypedAddress    }
  ('P'), {vfOpenStrings     }
  ('H'), {vfLongStrings     }
  ('J'), {vfWriteableConst  }
  ('D'), {vfDebugInfo       }
  ('L'), {vfLocalSymbols    }
  ('U'), {vfDefinitionInfo  }
  ('C')  {vfAssertions      }
  );
     
type                      
  TCompilerFlagExtractor = class(TDOFFlagExtractor)
  public
    procedure ExtractValues; override;
  end;

implementation

uses
  typ_dofReader,
  sysUtils;
  
const
  dof_ShowHints    = 'ShowHints';
  dof_ShowWarnings = 'ShowWarnings';
  dcc_warnings     = 'warnings';
  
procedure TCompilerFlagExtractor.ExtractValues;
const
  BoolToStr : array[boolean] of string =
  (
   'False',
   'True'
  );
var
 sectionFlag : TVerboseFlagEnum;
 flagValue : string;
 flagState : boolean;
begin
  fvalues.clear;
  
  freader.DofSection := tsCompiler;
  for sectionFlag := low(TVerboseFlagEnum) to high(TVerboseFlagEnum) do
    begin
      flagValue := freader.sectionValues.Values[DCCCompilerFlags[sectionFlag]];
      flagState := Boolean(StrToInt(flagValue));
      if flagState <> VerboseFlagDescription[sectionFlag].flagDefault then
        begin
          try
          fvalues.Values[VerboseFlagDescription[sectionFlag].flagDescription] := BoolToStr[flagState];
          except
          end;
        end;
    end;
  try
    flagValue := freader.sectionValues.Values[dof_ShowWarnings];       
    flagState := Boolean(StrToInt(flagValue));
    fvalues.Values[dcc_warnings] := BoolToStr[flagState];
  except
  end;  
end;

end.
