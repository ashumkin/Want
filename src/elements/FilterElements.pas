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


unit FilterElements;

interface

uses
  WantClasses,
  Classes;

type
  TCustomFilterElement = class(TScriptElement)
  private
    FSL: TStringList;

    function Min(AFirst, ASecond: integer): integer;
  public
    constructor Create(Owner: TScriptElement); override;
    destructor  Destroy; override;

    function ExecuteFilter(AInputString: string): string; virtual; abstract;
  end;

  THeadFilterElement = class(TCustomFilterElement)
  private
    FLines: integer;
  public
    constructor Create(Owner: TScriptElement); override;

    function ExecuteFilter(AInputString: string): string; override;
  published
    property Lines: integer read FLines write FLines;
  end;

  {
    <linecontains>
     <contains value="text"/>
     <contains value="other"/>
    </linecontains>
  }
  TLineContainsContainsElement = class(TScriptElement)
  private
    FValue: string;
  public
    class function TagName: string; override;

    procedure Init; override;
  published
    property Value: string read FValue write FValue;
  end;

  {
    <linecontains contains="text"/>
  }
  TLineContainsElement = class(TCustomFilterElement)
  private
    FContains     :string;
    FContainsList :TList;
  public
    destructor Destroy; override;

    procedure Init; override;
    function  ExecuteFilter(AInputString: string): string; override;
    function  CreateContains: TLineContainsContainsElement;
  published
    property contains: string read FContains write FContains;
  end;

  {
   <linecontainsregexp>
     <regexp value="text"/>
     <regexp value="other"/>
   </linecontainsregexp>
  }
  TLineContainsRegexpRegexpElement = class(TScriptElement)
  private
    fPattern: string;
  public
    procedure Init;                 override;
    class function TagName: string; override;
  published
    property pattern: string read FPattern write FPattern;
  end;

  {
    <linecontainsregexp regexp="text"/>
  }
  TLineContainsRegexpElement = class(TCustomFilterElement)
  private
    FRegExp: string;
    FRegExpList: TList;
  public
    destructor Destroy; override;

    procedure Init;                                            override;
    function  ExecuteFilter(AInputString: string): string;           override;
    function  CreateRegexp: TLineContainsRegexpRegexpElement;
  published
    property regexp: string read FRegExp write FRegExp;
  end;

  TTailFilterElement = class(TCustomFilterElement)
  private
    FLines: integer;
  public
    constructor Create(Owner: TScriptElement); override;

    function ExecuteFilter(AInputString: string): string; override;
  published
    property Lines: integer read FLines write FLines;
  end;

  TPrefixLinesElement = class(TCustomFilterElement)
  private
    FPrefix: string;
  public
    procedure Init; override;
    function  ExecuteFilter(AInputString: string): string; override;
  published
    property prefix: string read FPrefix write FPrefix;
  end;

  TStripLineBreaksElement = class(TCustomFilterElement)
  private
    FLineBreaks: string;
  public
    constructor Create(Owner: TScriptElement); override;

    function ExecuteFilter(AInputString: string): string; override;
  published
    property linebreaks: string read FLineBreaks write FLineBreaks;
  end;

  {
    <striplinecomments>
      <comment value="text"/>
      <comment value="other"/>
    </striplinecomments>
  }
  TStripLineCommentsCommentElement = class(TScriptElement)
  private
    FValue: string;
  public
    procedure Init;                 override;
    class function TagName: string; override;
  published
    property Value: string read FValue write FValue;
  end;

  {
    <striplinecomments comment="text"/>
  }
  TStripLineCommentsElement = class(TCustomFilterElement)
  private
    FComment: string;
    FCommentList: TList;
  public
    destructor Destroy; override;

    procedure Init;                                            override;
    function  ExecuteFilter(AInputString: string): string;           override;
    function  CreateComment: TStripLineCommentsCommentElement;
  published
    property comment: string read FComment write FComment;
  end;

  TTabsToSpacesElement = class(TCustomFilterElement)
  private
    FTabLength: integer;
  public
    constructor Create(Owner: TScriptElement); override;

    function ExecuteFilter(AInputString: string): string; override;
  published
    property tablength: integer read FTabLength write FTabLength;
  end;

  (*
     <replacetokens>
       <token name="DATE" value="${TODAY}"/>
       <token name="TIME" value="${NOW}"/>
     </replacetokens>
  *)
  TReplaceTokensTokenElement = class(TScriptElement)
  private
    FValue: string;
  public
    procedure Init;                 override;
    class function TagName: string; override;
  published
    property Value: string read FValue write FValue;
  end;

  // <replacetokens token="DATE" value="${TODAY}"/>
  TReplaceTokensElement = class(TCustomFilterElement)
  private
    FToken       :string;
    FValue       :string;
    FBeginToken  :string;
    FEndToken    :string;
    FTokenList   :TList;
  public
    constructor Create(Owner: TScriptElement); override;
    destructor  Destroy;                       override;

    procedure Init;                                    override;
    function  ExecuteFilter(AInputString: string): string;   override;
    function  CreateToken: TReplaceTokensTokenElement;
  published
    property token: string read FToken write FToken;
    property Value: string read FValue write FValue;
    property begintoken: string read FBeginToken write FBeginToken;
    property endtoken: string read FEndToken write FEndToken;
  end;

  TExpandPropertiesElement = class(TCustomFilterElement)
  public
    function ExecuteFilter(AInputString: string): string; override;
  end;

  TFilterChainElement = class(TScriptElement)
  published
  end;

implementation

uses
  PerlRE,
  JclStrings,
  SysUtils, StrUtils;

{ THeadFilterElement }

constructor THeadFilterElement.Create(Owner: TScriptElement);
begin
  FLines := 10;
  inherited;
end;

function THeadFilterElement.ExecuteFilter(AInputString: string): string;
var
  i: integer;
begin
  Result   := '';
  FSL.Text := AInputString;
  
  for i := 0 to Min(FLines - 1, FSL.Count) do
    Result := Result + FSL[i] + #13#10;
end;

{ TTailFilterElement }

constructor TTailFilterElement.Create(Owner: TScriptElement);
begin
  FLines := 10;
  inherited;
end;

function TTailFilterElement.ExecuteFilter(AInputString: string): string;
var
  i: integer;
begin
  Result   := '';
  FSL.Text := AInputString;
  if FSL.Count >= FLines then
     for i := FSL.Count - FLines to FSL.Count - 1 do
       Result := Result + FSL[i] + #13#10;
end;

{ TCustomFilterElement }

constructor TCustomFilterElement.Create(Owner: TScriptElement);
begin
  inherited;
  FSL := TStringList.Create;
end;

destructor TCustomFilterElement.Destroy;
begin
  FSL.Free;
  inherited;
end;

function TCustomFilterElement.Min(aFirst, aSecond: integer): integer;
begin
  Result := ASecond;
  if AFirst < ASecond then Result := AFirst;
end;

{ TLineContainsElement }

function TLineContainsElement.CreateContains: TLineContainsContainsElement;
begin
  if not Assigned(FContainsList) then
    FContainsList := TList.Create;

  Result := TLineContainsContainsElement.Create(self);
  FContainsList.Add(Result);
end;

destructor TLineContainsElement.Destroy;
begin
  FContainsList.Free;
  inherited;
end;

function TLineContainsElement.ExecuteFilter(AInputString: string): string;
var
  i: integer;
  j: integer;
begin
  Result   := '';
  FSL.Text := AInputString;
  
  for i := 0 to FSL.Count - 1 do
  begin
    if GetAttribute('contains') <> '' then
    begin
      if Pos(FContains, FSL[i]) > 0 then
      begin
        Result := Result + FSL[i] + #13#10;
        continue;
      end;
    end;
    // browse through all <contains> elements
    for j := 0 to ChildCount - 1 do
    begin
      if (Children[j] is TLineContainsContainsElement) then
      begin
        if Pos((Children[j] as TLineContainsContainsElement).Value, FSL[i]) > 0 then
        begin
          Result := Result + FSL[i] + #13#10;
          break;  // break from inside for loop to next line in SL
        end;
      end;
    end;
  end;
end;

procedure TLineContainsElement.Init;
begin
  inherited;
  if ChildCount = 0 then RequireAttribute('contains');
end;

{ TLineContainsContainsElement }

procedure TLineContainsContainsElement.Init;
begin
  inherited;
  RequireAttribute('value');
end;

class function TLineContainsContainsElement.TagName: string;
begin
  Result := 'contains';
end;

{ TLineContainsRegexpElement }

function TLineContainsRegexpElement.CreateRegexp: TLineContainsRegexpRegexpElement;
begin
  if not Assigned(FRegexpList) then FRegexpList := TList.Create;

  Result := TLineContainsRegexpRegexpElement.Create(self);
  FRegexpList.Add(Result);
end;

destructor TLineContainsRegexpElement.Destroy;
begin
  FRegexpList.Free;
  inherited;
end;

function TLineContainsRegexpElement.ExecuteFilter(AInputString: string): string;
var
  i: integer;
  j: integer;
  bOldMI: boolean;
begin
  Result        := '';
  FSL.Text      := AInputString;
  bOldMI := regex.ModifierI;
  regex.ModifierI := False;
  for i := 0 to FSL.Count - 1 do
  begin
    if GetAttribute('regexp') <> '' then
    begin
      if PerlRE.Match(FRegExp, FSL[i]) then
      begin
        Result := Result + FSL[i] + #13#10;
        continue;
      end;
    end;
    // browse through all <regexp> elements
    for j := 0 to ChildCount - 1 do 
    begin
      if (Children[j] is TLineContainsRegexpRegexpElement) then 
      begin
        if PerlRE.Match((Children[j] as TLineContainsRegexpRegexpElement).pattern, fSL[i]) then
        begin
          Result := Result + FSL[i] + #13#10;
          break;  // break from inside for loop to next line in SL
        end;
      end;
    end;
  end;
  regex.ModifierI := bOldMI;
end;

procedure TLineContainsRegexpElement.Init;
begin
  inherited;
  if ChildCount = 0 then
    RequireAttribute('regexp');
end;

{ TLineContainsRegexpRegexpElement }

procedure TLineContainsRegexpRegexpElement.Init;
begin
  inherited;
  RequireAttribute('pattern');
end;

class function TLineContainsRegexpRegexpElement.TagName: string;
begin
  Result := 'contains';
end;

{ TPrefixLinesElement }

function TPrefixLinesElement.ExecuteFilter(aInputString: string): string;
var
  i: integer;
begin
  FSL.Text := AInputString;
  
  for i := 0 to FSL.Count - 1 do
    FSL[i] := FPrefix + FSL[i];
  Result := FSL.Text; 
end;

procedure TPrefixLinesElement.Init;
begin
  inherited;
  RequireAttribute('prefix');
end;

{ TStripLineBreaksElement }

constructor TStripLineBreaksElement.Create(Owner: TScriptElement);
begin
  FLineBreaks := #13#10;
  inherited;
end;

function TStripLineBreaksElement.ExecuteFilter(aInputString: string): string;
var
  bCharsToRemove :TSysCharSet;
  i              :integer;
begin
  bCharsToRemove := [];
  for i := 1 to Length(FLineBreaks) do
  begin
     bCharsToRemove := bCharsToRemove + [FLineBreaks[i]];
  end;
  Result := StrRemoveChars(aInputString, bCharsToRemove);
end;

{ TStripLineCommentsCommentElement }

procedure TStripLineCommentsCommentElement.Init;
begin
  inherited;
  RequireAttribute('value');
end;

class function TStripLineCommentsCommentElement.TagName: string;
begin
  Result := 'comment';
end;

{ TStripLineCommentsElement }

function TStripLineCommentsElement.CreateComment: TStripLineCommentsCommentElement;
begin
  if not Assigned(FCommentList) then FCommentList := TList.Create;

  Result := TStripLineCommentsCommentElement.Create(self);
  FCommentList.Add(Result);
end;

destructor TStripLineCommentsElement.Destroy;
begin
  fCommentList.Free;
  inherited;
end;

function TStripLineCommentsElement.ExecuteFilter(AInputString: string): string;
var
  i: integer;
  j: integer;
begin
  Result := '';
  FSL.Text := AInputString;
  for i := 0 to FSL.Count - 1 do
  begin
    if GetAttribute('comment') <> '' then 
    begin
      if Pos(FComment, FSL[i]) <> 1 then
      begin
        Result := Result + FSL[i] + #13#10;
        continue;
      end;
    end;
    // browse through all <comment> elements
    for j := 0 to ChildCount - 1 do
    begin
      if (Children[j] is TStripLineCommentsCommentElement) then
      begin
        if Pos((Children[j] as TStripLineCommentsCommentElement).Value, FSL[i]) <> 1 then
        begin
          Result := Result + FSL[i] + #13#10;
          break;  // break from inside for loop to next line in SL
        end;
      end;
    end;
  end;
end;

procedure TStripLineCommentsElement.Init;
begin
  inherited;
  if ChildCount = 0 then
    RequireAttribute('comment');
end;

{ TTabsToSpacesElement }

constructor TTabsToSpacesElement.Create(Owner: TScriptElement);
begin
  FTabLength := 8;
  inherited;
end;

function TTabsToSpacesElement.ExecuteFilter(aInputString: string): string;
var
  bSpaces :string;
//i       :integer;
begin
  bSpaces := DupeString(' ', FTabLength);
  Result := StringReplace(AInputString, #9, bSpaces, [rfReplaceAll]);
end;

{ TReplaceTokensTokenElement }

procedure TReplaceTokensTokenElement.Init;
begin
  inherited;
  RequireAttributes(['name', 'value']);
end;

class function TReplaceTokensTokenElement.TagName: string;
begin
  Result := 'token';
end;

{ TReplaceTokensElement }

constructor TReplaceTokensElement.Create(Owner: TScriptElement);
begin
  fBeginToken := '@';
  fEndToken   := '@';
  inherited;
end;

function TReplaceTokensElement.CreateToken: TReplaceTokensTokenElement;
begin
  if not Assigned(FTokenList) then
    FTokenList := TList.Create;
  Result := TReplaceTokensTokenElement.Create(self);
  FTokenList.Add(Result);
end;

destructor TReplaceTokensElement.Destroy;
begin
  FTokenList.Free;
  inherited;
end;

function TReplaceTokensElement.ExecuteFilter(AInputString: string): string;
var
  i       :integer;
  bSearch :string;
begin
  Result  := AInputString;
  bSearch := FBeginToken + FToken + FEndToken;
  if GetAttribute('token') <> '' then
  begin
    if Pos(bSearch, Result) > 0 then
    begin
      Result := StringReplace(Result, bSearch, Evaluate(FValue), [rfReplaceAll]);
    end;
  end;
  // browse through all <comment> elements
  for i := 0 to ChildCount - 1 do
  begin
    if (Children[i] is TReplaceTokensTokenElement) then
    begin
      if Pos(bSearch, Result) > 0 then
      begin
        Result := StringReplace(Result, bSearch, Evaluate(FValue), [rfReplaceAll]);
      end;
    end;
  end;
end;

procedure TReplaceTokensElement.Init;
begin
  inherited;
  if ChildCount = 0 then 
  begin
    RequireAttributes(['token', 'value']);
  end;
end;

{ TExpandPropertiesElement }

function TExpandPropertiesElement.ExecuteFilter(AInputString: string): string;
begin
  Result := Evaluate(AInputString);
end;

initialization
  RegisterElement(TFilterChainElement);
  RegisterElement(TFilterChainElement,        THeadFilterElement);
  RegisterElement(TFilterChainElement,        TTailFilterElement);
  RegisterElement(TFilterChainElement,        TLineContainsElement);
  RegisterElement(TLineContainsElement,       TLineContainsContainsElement);
  RegisterElement(TFilterChainElement,        TLineContainsRegexpElement);
  RegisterElement(TLineContainsRegExpElement, TLineContainsRegexpRegexpElement);
  RegisterElement(TFilterChainElement,        TPrefixLinesElement);
  RegisterElement(TFilterChainElement,        TStripLineBreaksElement);
  RegisterElement(TFilterChainElement,        TStripLineCommentsElement);
  RegisterElement(TStripLineCommentsElement,  TStripLineCommentsCommentElement);
  RegisterElement(TFilterChainElement,        TTabsToSpacesElement);
  RegisterElement(TFilterChainElement,        TReplaceTokensElement);
  RegisterElement(TReplaceTokensElement,      TReplaceTokensTokenElement);
  RegisterElement(TFilterChainElement,        TExpandPropertiesElement);
end.
