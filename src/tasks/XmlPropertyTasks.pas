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
    @author Radim Novotny <radimnov@seznam.cz>
}

{
  Notes:
     Property "Validate" is not implemented yet
}

unit XmlPropertyTasks;

interface

uses
    WantClasses,
    JalMiniDOM;

type
  TXmlPropertyTask = class(TTask)
    private
      FProcessingRoot      :boolean;
      FFile                :string;
      FCollapseAttributes  :boolean;
      FPrefix              :string;
      FKeepRoot            :boolean;
      FValidate            :boolean;

      procedure ParseError(AMsg: string; ALine: integer=0; ACol: Integer=0);
      function  GeneratePropertyName(AParentTagPath: string;
                                     AName: string;
                                     AIsAttribute : boolean) : string;
    public
      constructor Create(Owner : TScriptElement); override;

      procedure Init;    override;
      procedure Execute; override;
      procedure ParseXML(ATagPath: string; ANode: IElement);
    published
      property _file              :string  read FFile               write FFile;
      property collapseattributes :boolean read FCollapseAttributes write FCollapseAttributes;
      property prefix             :string  read FPrefix             write FPrefix;
      property keeproot           :boolean read FKeepRoot           write FKeepRoot;
      property validate           :boolean read FValidate           write FValidate;
  end;

implementation

uses
  SysUtils,
  JalSAX,
  JalCollections,
  WantResources,
  WildPaths;

type
  EWantParseException = class(EWantException)
  public
    constructor Create(Msg :string; Line, Col :Integer);
  end;

{ TXmlPropertyTask }

constructor TXmlPropertyTask.Create(Owner: TScriptElement);
begin
  inherited;
  FKeepRoot           := True;
  FValidate           := False;
  FCollapseAttributes := False;
end;

procedure TXmlPropertyTask.Execute;
var
  Dom       :IDocument;
begin
  if not PathIsFile(FFile) then
    ParseError(Format('Cannot find file "%s"',[FFile]));

  FFile := ToAbsolutePath(FFile);
  try
    Dom := JALMiniDOM.ParseToDom(ToSystemPath(FFile), True);
    FProcessingRoot := true;
    ParseXML('', Dom.Root);
  except
    on e :SAXParseException do
      ParseError(ToRelativePath(FFile, CurrentDir) + ' ' +  e.Message);
    on e :Exception do
    begin
      e.Message := ToRelativePath(FFile, CurrentDir) + ' ' +  e.Message;
      raise;
    end;
  end;
end;

function TXmlPropertyTask.GeneratePropertyName(AParentTagPath: string;
  AName: string; AIsAttribute: boolean): string;
begin
  if AParentTagPath <> '' then
    Result := AParentTagPath
  else
    Result := '';
  if AIsAttribute and (not FCollapseAttributes) then
    Result := Result + '('
  else if AParentTagPath <> '' then
    Result := Result + '.';
  Result := Result + AName;
  if AIsAttribute and (not FCollapseAttributes) then
    Result := Result + ')';
end;

procedure TXmlPropertyTask.Init;
begin
  inherited;
  RequireAttribute('file');
end;

procedure TXmlPropertyTask.ParseError(AMsg :string; ALine, ACol :Integer);
begin
  raise EWantParseException.Create(AMsg, ALine, ACol) at CallerAddr;
end;

procedure TXmlPropertyTask.ParseXML(ATagPath: string; ANode: IElement);
var
   bAttrName    :string;
   FTagPath     :string;
   bIter        :IIterator;
   bAtrIter     :IIterator;
   bAttr        :IAttribute;
   bText        :JALMiniDOM.ITextNode;
   bChild       :JALMiniDOM.IElement;
begin
  inherited;
  if not (FProcessingRoot and (not FKeepRoot)) then
  begin
    FTagPath := GeneratePropertyName(ATagPath, ANode.name, False);
    if not FProcessingRoot then
    begin
      bIter := ANode.children.Iterator;
      while bIter.HasNext do
      begin
        if 0 = (bIter.Next as INode).QueryInterface(ITextNode, bText)  then
          Project.SetProperty(FPrefix+FTagPath, TrimRight(bText.text));
      end;
    end;

    bAtrIter := ANode.attributes.Iterator;
    while bAtrIter.hasNext do
    begin
      if 0 = (bAtrIter.Next as IAttribute).QueryInterface(IAttribute, bAttr)  then
      begin
        bAttrName := GeneratePropertyName(FTagPath, bAttr.name, true);
        Project.SetProperty(FPrefix+bAttrName, bAttr.value);
      end;
    end;
  end;
  FProcessingRoot := False; // set only in first iteration

  bIter := ANode.children.Iterator;
  while bIter.HasNext do
  begin
    if 0 = (bIter.Next as INode).QueryInterface(IElement, bChild)  then
      ParseXML(FTagPath, bChild)
  end;
end;

{ EWantParseException }

constructor EWantParseException.Create(Msg: string; Line, Col: Integer);
begin
  inherited Create(Format('(%d:%d): %s',[Line, Col, Msg]));
end;

initialization
  RegisterTask(TXmlPropertyTask);
end.
