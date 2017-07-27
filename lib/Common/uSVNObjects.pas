unit uSVNObjects;

interface

uses
  SysUtils,
  uAbstractXML;

type
  // "entry" entity
  TCustomSVNEntry = class(TAXAbstract)
  public
    class function doPrefix: string; override;
  end;

  TSVNInfoEntry = class(TCustomSVNEntry)
  private
    FKind: string;
    Frevision: string;
    FPath: string;
    FURL: string;
    function GetIsFile: boolean;
    function GetCommitRevision: string;
  public
    property IsFile: boolean read GetIsFile;
    property CommitRevision: string read GetCommitRevision;
  published
    property Kind: string read FKind write FKind;
    property Path: string read FPath write FPath;
    property revision: string read Frevision write Frevision;
    property URL: string read FURL write FURL;
  end;

  // "entry.repository" entity
  TSVNInfoRepository = class(TCustomSVNEntry)
  private
    Froot: string;
    Fuuid: string;
  published
    property root: string read Froot write Froot;
    property uuid: string read Fuuid write Fuuid;
  end;

  // "entry.wc-info" entity
  TSVNInfoWC_Info = class(TCustomSVNEntry)
  private
    Fdepth: string;
    Fschedule: string;
  published
    property depth: string read Fdepth write Fdepth;
    property schedule: string read Fschedule write Fschedule;
  end;

  // "entry.commit" entity
  TSVNInfoCommit = class(TCustomSVNEntry)
  private
    Fauthor: string;
    Fdate: string;
    Frevision: string;
  published
    property author: string read Fauthor write Fauthor;
    property date: string read Fdate write Fdate;
    property revision: string read Frevision write Frevision;
  end;

  // main. "info" entity
  TSVNInfoInfo = class(TCustomSVNEntry)
  private
    function GetEntries(Index: Integer): TSVNInfoEntry;
    function GetCount: Integer;
  public
    property Count: Integer read GetCount;
    property Entries[Index: Integer]: TSVNInfoEntry read GetEntries;
  end;

  // "entry.wc-status" entity
  TSVNInfoWC_Status = class(TCustomSVNEntry)
  private
    Fitem: string;
    Fprops: string;
    Frevision: string;
    function Getmodified: boolean;
    function Getunversioned: boolean;
  public
    property modified: boolean read Getmodified;
    property unversioned: boolean read Getunversioned;
  published
    property item: string read Fitem write Fitem;
    property props: string read Fprops write Fprops;
    property revision: string read Frevision write Frevision;
  end;

  // "status.target" entity
  TSVNInfoTarget = class(TCustomSVNEntry)
  private
    function GetEntries(Index: Integer): TSVNInfoEntry;
    function GetCount: Integer;
  public
    property Count: Integer read GetCount;
    property Entries[Index: Integer]: TSVNInfoEntry read GetEntries;
  end;

  // main. "status" entity
  TSVNInfoStatus = class(TCustomSVNEntry)
  private
    function GetEntries(Index: Integer): TSVNInfoEntry;
    function GetCount: Integer;
  public
    property Count: Integer read GetCount;
    property Entries[Index: Integer]: TSVNInfoEntry read GetEntries;
  end;

  TSVNInfoPath = class(TCustomSVNEntry)
  private
    Fcopyfrom_rev: string;
    FKind: string;
    Fcopyfrom_path: string;
    Faction: string;
  published
    property action: string read Faction write Faction;
    property copyfrom_path: string read Fcopyfrom_path write Fcopyfrom_path;
    property copyfrom_rev: string read Fcopyfrom_rev write Fcopyfrom_rev;
    property kind: string read FKind write Fkind;
  end;

  TSVNInfoPaths = class(TCustomSVNEntry)
  private
    function GetCount: Integer;
    function GetPath(Index: Integer): TSVNInfoPath;
  public
    property Count: Integer read GetCount;
    property Path[Index: Integer]: TSVNInfoPath read GetPath;
  end;
  
  TSVNInfoLogEntry = class(TCustomSVNEntry)
  private
    Fauthor: string;
    Fdate: string;
    Fmsg: string;
    function GetPaths: TSVNInfoPaths;
  published
    property author: string read Fauthor write Fauthor;
    property date: string read Fdate write Fdate;
    property msg: string read Fmsg write Fmsg;
    property Paths: TSVNInfoPaths read GetPaths;
  end;

  TSVNInfoLog = class(TCustomSVNEntry)
  private
    function GetCount: Integer;
    function GetLog(Index: Integer): TSVNInfoLogEntry;
  public
    property Count: Integer read GetCount;
    property Log[Index: Integer]: TSVNInfoLogEntry read GetLog;
  end;

implementation

uses
  Windows;

{ TSVNInfoInfo }

function TSVNInfoInfo.GetCount: Integer;
begin
  Result := CountByClass[TSVNInfoEntry];
end;

function TSVNInfoInfo.GetEntries(Index: Integer): TSVNInfoEntry;
begin
  Result := TSVNInfoEntry(ChildAXByClass[Index, TSVNInfoEntry]);
end;

{ TSVNInfoEntry }

function TSVNInfoEntry.GetCommitRevision: string;
begin
  Result := '';
  if Assigned(ChildAXByClass[0, TSVNInfoCommit]) then
    Result := TSVNInfoCommit(ChildAXByClass[0, TSVNInfoCommit]).revision;
end;

function TSVNInfoEntry.GetIsFile: boolean;
begin
  Result := AnsiSameText(Kind, 'file');
end;

{ TSVNStatusTarget }

function TSVNInfoTarget.GetCount: Integer;
begin
  Result := CountByClass[TSVNInfoEntry];
end;

function TSVNInfoTarget.GetEntries(Index: Integer): TSVNInfoEntry;
begin
  Result := TSVNInfoEntry(ChildAXByClass[Index, TSVNInfoEntry]);
end;

{ TSVNInfoWC_Status }

function TSVNInfoWC_Status.Getmodified: boolean;
begin
  Result := AnsiSameText(Fitem, 'modified');
end;

function TSVNInfoWC_Status.Getunversioned: boolean;
begin
  Result := AnsiSameText(Fitem, 'unversioned');
end;

{ TSVNInfoStatus }

function TSVNInfoStatus.GetCount: Integer;
begin
  Result := TSVNInfoTarget(GetFirstByClass(TSVNInfoTarget)).Count;
end;

function TSVNInfoStatus.GetEntries(Index: Integer): TSVNInfoEntry;
begin
  Result := TSVNInfoTarget(GetFirstByClass(TSVNInfoTarget)).Entries[Index];
end;

{ TSVNinfoPaths }

function TSVNInfoPaths.GetCount: Integer;
begin
  Result := CountByClass[TSVNInfoPath];
end;

function TSVNInfoPaths.GetPath(Index: Integer): TSVNInfoPath;
begin
  Result := TSVNInfoPath(ChildAXByClass[Index, TSVNInfoPath]);
end;

{ TSVNInfoLog }

function TSVNInfoLog.GetCount: Integer;
begin
  Result := CountByClass[TSVNInfoLogEntry];
end;

function TSVNInfoLog.GetLog(Index: Integer): TSVNInfoLogEntry;
begin
  Result := TSVNInfoLogEntry(ChildAXByClass[Index, TSVNInfoLogEntry]);
end;

{ TSVNInfoLogEntry }

function TSVNInfoLogEntry.GetPaths: TSVNInfoPaths;
begin
  Result := TSVNInfoPaths(CheckAddClassInstance(TSVNInfoPaths));
end;

{ TCustomSVNEntry }

class function TCustomSVNEntry.doPrefix: string;
begin
  Result := 'TSVNInfo';
end;

initialization
  RegisterAXClasses([TSVNInfoEntry, TSVNInfoInfo, TSVNInfoCommit,
    TSVNInfoWC_Info,
    TSVNInfoTarget, TSVNInfoWC_Status,
    TSVNInfoPath, TSVNInfoPaths,
    TSVNInfoLogEntry, TSVNInfoLog]);
end.

