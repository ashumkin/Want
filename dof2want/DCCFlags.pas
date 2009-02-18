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
unit dccFlags;

interface

uses
  classes;

type
  TVerboseFlagEnum = (vfOptimization, vfStackFrames, vfSaveDivide,
    vfRangeChecks, vfIOChecks, vfOverflowchecks,
    vfVarStringChecks, vfBoolEval, vfExtendedSyntax,
    vfTypedAddress, vfOpenStrings, vfLongStrings,
    vfWriteableConst, vfDebugInfo, vfLocalSymbols,
    vfDefinitionInfo, vfAssertions);

  TVerboseFlagDescription = record
    flagSymbol: string;
    flagDefault: boolean;
    flagDescription: string;
  end;

const

  VerboseFlagDescription: array[TVerboseFlagEnum] of TVerboseFlagDescription =
  (
    (flagSymbol: '$O'; flagDefault: true; flagDescription: 'Optimization'), {vfOptimization    }
    (flagSymbol: '$W'; flagDefault: false; flagDescription: 'StackFrames'), {vfStackFrames     }
    (flagSymbol: '$U'; flagDefault: false; flagDescription: 'SaveDivide'), {vfSaveDivide	    }
    (flagSymbol: '$R'; flagDefault: false; flagDescription: 'RangeChecks'), {vfRangeChecks     }
    (flagSymbol: '$I'; flagDefault: true; flagDescription: 'IOChecks'), {vfIOChecks        }
    (flagSymbol: '$Q'; flagDefault: false; flagDescription: 'Overflowchecks'), {vfOverflowchecks  }
    (flagSymbol: '$V'; flagDefault: true; flagDescription: 'VarStringChecks'), {vfVarStringChecks }
    (flagSymbol: '$B'; flagDefault: false; flagDescription: 'BoolEval'), {vfBoolEval	       }
    (flagSymbol: '$X'; flagDefault: true; flagDescription: 'ExtendedSyntax'), {vfExtendedSyntax  }
    (flagSymbol: '$T'; flagDefault: false; flagDescription: 'TypedAddress'), {vfTypedAddress    }
    (flagSymbol: '$P'; flagDefault: true; flagDescription: 'OpenStrings'), {vfOpenStrings     }
    (flagSymbol: '$H'; flagDefault: true; flagDescription: 'LongStrings'), {vfLongStrings     }
    (flagSymbol: '$J'; flagDefault: false; flagDescription: 'WriteableConst'), {vfWriteableConst  }
    (flagSymbol: '$D'; flagDefault: true; flagDescription: 'DebugInfo'), {vfDebugInfo       }
    (flagSymbol: '$L'; flagDefault: true; flagDescription: 'LocalSymbols'), {vfLocalSymbols    }
    (flagSymbol: '$U'; flagDefault: true; flagDescription: 'DefinitionInfo'), {vfDefinitionInfo  }
    (flagSymbol: '$C'; flagDefault: true; flagDescription: 'Assertions') {vfAssertions      }
    );
implementation

end.


