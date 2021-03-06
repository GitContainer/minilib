unit mnConnections;
{**
 *  This file is part of the "Mini Library"
 *
 * @license   modifiedLGPL (modified of http://www.gnu.org/licenses/lgpl.html)
 *            See the file COPYING.MLGPL, included in this distribution,
 * @author    Zaher Dirkey <zaher at parmaja dot com>
 *}

{$M+}
{$H+}
{$IFDEF FPC}
{$MODE delphi}
{$ENDIF}

interface

uses
  Classes,
  SysUtils,
  SyncObjs,
  mnStreams,
  mnSockets;

type

  { TmnThread }

  TmnThread = class(TThread)
  public
    constructor Create;
  end;

  { TmnLockThread }

  TmnLockThread = class(TmnThread)
  private
    FLock: TCriticalSection;
  protected
  public
    constructor Create;
    destructor Destroy; override;
    procedure Enter;
    procedure Leave;
  end;

  TmnConnection = class;


  { TmnConnectionList }

  TmnConnectionList = class(TList)
  private
    function GetItems(Index: Integer): TmnConnection;
    procedure SetItems(Index: Integer; const Value: TmnConnection);
  protected
  public
    property Items[Index: Integer]: TmnConnection read GetItems write SetItems; default;
  end;

  { TmnConnections }

  TmnConnections = class(TmnLockThread)  //TmnListener and TmnCaller using it
  private
    FLastID: Int64;
    FList: TmnConnectionList;
  protected
    FPort: string;
    FAddress: string;
    function DoCreateConnection(vStream: TmnConnectionStream): TmnConnection; virtual;
    function CreateConnection(vSocket: TmnCustomSocket): TmnConnection;
    procedure DoCreateStream(var Result: TmnConnectionStream; vSocket: TmnCustomSocket); virtual; //todo move it to another unit
    function CreateStream(vSocket: TmnCustomSocket): TmnConnectionStream;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Stop; virtual;
    property Count: Integer read GetCount;
    property LastID: Int64 read FLastID;
    property List: TmnConnectionList read FList;
  end;

  { TmnConnection }

  TmnConnection = class(TmnThread)
  private
    FID: Integer;
    FOwner: TmnConnections;
    FStream: TmnConnectionStream;
    function GetActive: Boolean;
    function GetConnected: Boolean;
    procedure SetConnected(const Value: Boolean);
  protected
    property Owner: TmnConnections read FOwner;
    procedure Created; virtual;
    procedure Prepare; virtual;
    procedure Process; virtual;
    procedure Execute; override;
    procedure Unprepare; virtual;
    procedure SetStream(AValue: TmnConnectionStream);
    procedure HandleException(E: Exception); virtual;
  public
    constructor Create(vOwner: TmnConnections; vStream: TmnConnectionStream); virtual; //TODO use TmnBufferStream
    destructor Destroy; override;
    procedure Connect; virtual;
    procedure Disconnect(Safe: Boolean = true); virtual; // don't raise exception, now by default true
    procedure Open; //Alias for Connect
    procedure Close; //Alias for Disconnect
    procedure Stop; virtual;
    procedure Release;
    property Connected: Boolean read GetConnected write SetConnected;
    property Active: Boolean read GetActive;
    property Stream: TmnConnectionStream read FStream; //write SetStream; //not now
    property ID: Integer read FID;
  end;

procedure mnCheckError(Value: Integer);

implementation

procedure mnCheckError(Value: Integer);
begin
  if Value > 0 then
    raise EmnException.Create('WinSocket, error #' + IntToStr(Value));
end;

{ TmnConnections }

function TmnConnections.CreateStream(vSocket: TmnCustomSocket): TmnConnectionStream;
begin
  Result := nil;
  DoCreateStream(Result, vSocket);
end;

function TmnConnections.DoCreateConnection(vStream: TmnConnectionStream): TmnConnection;
begin
  Result := TmnConnection.Create(Self, vStream);
end;

function TmnConnections.CreateConnection(vSocket: TmnCustomSocket): TmnConnection;
begin
  Inc(FLastID);
  Result := DoCreateConnection(CreateStream(vSocket));
  Result.FID := FLastID;
end;

procedure TmnConnections.DoCreateStream(var Result: TmnConnectionStream; vSocket: TmnCustomSocket);
begin
  Result := TmnSocketStream.Create(vSocket);
end;

constructor TmnConnections.Create;
begin
  inherited;
  FList := TmnConnectionList.Create;
end;

destructor TmnConnections.Destroy;
begin
  FList.Free;
  inherited;
end;

procedure TmnConnections.Stop;
begin
end;

function TmnConnections.GetCount: Integer;
begin
  Result := FList.Count;
end;

procedure TmnConnection.Execute;
begin
  try
    Prepare;
    while not Terminated and Connected do
    begin
      try
        Process;
      except
        on E: Exception do
        begin
          HandleException(E);
          //Disconnect; //TODO: Do we need to disconnect when we have exception? maybe we need to add option for it
        end;
      end;
    end;
  finally
    Unprepare;
  end;
end;

constructor TmnLockThread.Create;
begin
  inherited;
  FLock := TCriticalSection.Create;
end;

destructor TmnLockThread.Destroy;
begin
  FLock.Free;
  inherited;
end;

procedure TmnLockThread.Enter;
begin
  FLock.Enter;
end;

procedure TmnLockThread.Leave;
begin
  FLock.Leave;
end;

procedure TmnConnection.Process;
begin
end;

function TmnConnectionList.GetItems(Index: Integer): TmnConnection;
begin
  Result := inherited Items[Index];
end;

procedure TmnConnectionList.SetItems(Index: Integer; const Value: TmnConnection);
begin
  inherited Items[Index] := Value;
end;

{ TmnConnection }

procedure TmnConnection.Close;
begin
  Disconnect;
end;

constructor TmnConnection.Create(vOwner: TmnConnections; vStream: TmnConnectionStream);
begin
  inherited Create;
  FOwner := vOwner;
  FStream := vStream;
  Created;
end;

destructor TmnConnection.Destroy;
begin
  if Connected then
    Close;
  FreeAndNil(FStream);
  inherited;
end;

procedure TmnConnection.Open;
begin
  Connect;
end;

procedure TmnConnection.Stop;
begin
  Terminate;
  Disconnect;
end;

procedure TmnConnection.Release;
begin
  if FOwner <> nil then
  begin
    FOwner.List.Extract(Self);
    FOwner := nil;
  end;
end;

function TmnConnection.GetConnected: Boolean;
begin
  Result := (FStream <> nil) and FStream.Connected;
end;

function TmnConnection.GetActive: Boolean;
begin
  Result := Connected and not Terminated;
end;

procedure TmnConnection.HandleException(E: Exception);
begin
end;

procedure TmnConnection.SetConnected(const Value: Boolean);
begin
  if Value then
    Open
  else
    Close;
end;

procedure TmnConnection.Created;
begin
end;

procedure TmnConnection.SetStream(AValue: TmnConnectionStream);
begin
  if FStream <> nil then
    raise exception.Create('We already have a stream');
  FStream := AValue;
end;

procedure TmnConnection.Disconnect(Safe: Boolean);
begin
  if not Safe and (FStream = nil) then
    raise Exception.Create('No stream to disconnect');
  if (FStream <> nil) and FStream.Connected then
    FStream.Disconnect;
end;

procedure TmnConnection.Connect;
begin
  if FStream <> nil then
    FStream.Connect;
end;

procedure TmnConnection.Prepare;
begin
end;

procedure TmnConnection.Unprepare;
begin
end;

{ TmnThread }

constructor TmnThread.Create;
begin
  inherited Create(True);
  FreeOnTerminate := False;
end;

end.

