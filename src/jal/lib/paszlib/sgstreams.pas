unit sgstreams;

interface

uses SysUtils, Classes, Math; {, QDialogs;}

const sbhSignature='SsB';

type
  TStreamBlockHeader=packed record
    Signature: packed array[0..3] of char;
    Size: Cardinal;
  end;

  TStreamBlock=class(TMemoryStream)
    public
      procedure LoadFromStream(s: TStream);
      procedure SaveToStream(s: TStream);
  end;

implementation

procedure TStreamBlock.LoadFromStream(s: TStream);
var si: TStreamBlockHeader;
begin
  Clear;
  s.Read(si, sizeof(TStreamBlockHeader));
  if si.Signature<>sbhSignature then
    raise Exception.Create('Bad StreamBlock signature.')
  else begin
    if CopyFrom(s, si.Size)<>si.Size then
      raise Exception.Create('Stream write error when loading Stream Block.');
    Seek(0,0);
  end;  
end;

procedure TStreamBlock.SaveToStream(s: TStream);
var si: TStreamBlockHeader; 
begin
  si.Signature:=sbhSignature;
  si.Size:=Size;
  s.Write(si, sizeof(TStreamBlockHeader));
  Seek(0,0);
  if s.CopyFrom(Self, si.Size)<>si.Size then
    raise Exception.Create('Stream write error when saving Stream Block.');
end;


end.
