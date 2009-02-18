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

    @author Juanco Añez
}

unit TimeElements;

interface
uses
  SysUtils,
  WantClasses;

type
  TFormatElement = class(TScriptElement)
  protected
    FProperty :string;
    FPattern  :string;
  public
    procedure Init; override;
  published
    property _property :string read FProperty write FProperty;
    property pattern   :string read FPattern  write FPattern;
  end;

  TTStampElement = class(TScriptElement)
  protected
    FTime :TDateTime;
  public
    procedure Init; override;

    property Time :TDateTime read FTime;
  end;


implementation

{ TTStampElement }


procedure TTStampElement.Init;
begin
  inherited Init;

  FTime := Now;
  Owner.SetProperty('dstamp', FormatDateTime('yyyymmdd',       Time));
  Owner.SetProperty('tstamp', FormatDateTime('hhnn',           Time));
  Owner.SetProperty('today',  FormatDateTime('mmm ddd d yyyy', Time));

  Owner.SetProperty('year',   FormatDateTime('yyyy',     Time));
  Owner.SetProperty('month',  FormatDateTime('mm',       Time));
  Owner.SetProperty('day',    FormatDateTime('dd',       Time));

  Owner.SetProperty('hour',   FormatDateTime('hh',       Time));
  Owner.SetProperty('minute', FormatDateTime('nn',       Time));
  Owner.SetProperty('second', FormatDateTime('ss',       Time));

  Owner.SetProperty('ticks',  Format('%8.8d', [Round(24*60*60*1000*Frac(Time))]));
end;

{ TFormatElement }

procedure TFormatElement.Init;
begin
  inherited Init;
  RequireAttributes(['property', 'pattern']);

  with Owner as TTStampElement do
    Owner.SetProperty(_property, FormatDateTime(pattern, Time));
end;

initialization
  RegisterElement(TTStampElement);
  RegisterElement(TTStampElement, TFormatElement);
end.
