unit mnClients;
{**
 *  This file is part of the "Mini Library"
 *
 * @license   modifiedLGPL (modified of http://www.gnu.org/licenses/lgpl.html)
 *            See the file COPYING.MLGPL, included in this distribution,
 * @author    Zaher Dirkey <zaher at parmaja dot com>
 *}

{$M+}{$H+}
{$IFDEF FPC}
{$mode delphi}
{$ENDIF}

interface

uses
  Classes, {$ifndef FPC} Types, {$endif} SysUtils,
  mnSockets, mnStreams, mnConnections;

type

{ TmnClient }

  TmnClients = class;

  { TmnClientSocketStream }

  TmnClientSocket = class(TmnSocketStream)
  private
    FAddress: string;
    FPort: string;
    procedure SetAddress(const Value: string);
    procedure SetPort(const Value: string);
  protected
    function CreateSocket: TmnCustomSocket; override;
  public
    constructor Create(const vAddress, vPort: string; vOptions: TmnsoOptions = [soNoDelay]);
    property Port: string read FPort write SetPort;
    property Address: string read FAddress write SetAddress;
  end;

  TmnClientSocketStream = TmnClientSocket;

  { TmnClientConnection }

  TmnClientConnection = class(TmnConnection) //this child object in Clients
  private
    function GetOwner: TmnClients;
  protected
  public
    constructor Create(vOwner: TmnConnections; vSocket: TmnConnectionStream = nil); override;
    destructor Destroy; override;
    property Owner: TmnClients read GetOwner;
  end;

  TmnClientConnectionClass = class of TmnClientConnection;

  TmnOnLog = procedure(Connection: TmnConnection; const S: string) of object;
  TmnOnCallerNotify = procedure(Caller: TmnClients) of object;

  { TmnClients }

  TmnClients = class(TmnConnections) // thread pooling to collect outgoing clients threads
  private
    FOnLog: TmnOnLog;
    FOnChanged: TmnOnCallerNotify;
    procedure Connect;
    procedure Disconnect;
    function GetConnected: Boolean;
  protected
    function DoCreateConnection(vStream: TmnConnectionStream): TmnConnection; override;
  protected
    FOptions: TmnsoOptions;
    procedure Shutdown;
    procedure Execute; override;
    procedure Changed;
    procedure Remove(Connection: TmnClientConnection);
    procedure Add(Connection: TmnClientConnection);
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Stop; override;
    procedure Log(Connection: TmnConnection; S: string);
    function AddConnection(vPort: string; vAddress: string): TmnClientConnection;
    property Connected: Boolean read GetConnected;

    property OnLog: TmnOnLog read FOnLog write FOnLog;
    property OnChanged: TmnOnCallerNotify read FOnChanged write FOnChanged;
  end;

implementation

{ TmnClientConnection }

constructor TmnClientConnection.Create(vOwner: TmnConnections; vSocket: TmnConnectionStream);
begin
  inherited;
  FreeOnTerminate := True;
  if Owner <> nil then
    Owner.Add(Self);
end;

destructor TmnClientConnection.Destroy;
begin
  if Owner <> nil then
    Owner.Remove(Self);
  inherited;
end;

function TmnClientConnection.GetOwner: TmnClients;
begin
  Result := (inherited Owner) as TmnClients;
end;

{ TmnClients }

procedure TmnClients.Add(Connection: TmnClientConnection);
begin
  Enter;
  try
    List.Add(Connection);
    Changed;
  finally
    Leave;
  end;
end;

procedure TmnClients.Changed;
begin
  if Assigned(FOnChanged) then
  begin
    FOnChanged(Self);
  end;
end;

procedure TmnClients.Connect;
begin
end;

constructor TmnClients.Create;
begin
  inherited;
  FOptions := [soNoDelay]; //you can use soKeepAlive
end;

destructor TmnClients.Destroy;
begin
  inherited;
end;

procedure TmnClients.Disconnect;
begin
  if Connected then
  begin
  end;
end;

procedure TmnClients.Execute;
begin
  Connect;
  Shutdown;
  Disconnect;
end;

function TmnClients.GetConnected: Boolean;
begin
  Result := Terminated;
end;

function TmnClients.DoCreateConnection(vStream: TmnConnectionStream): TmnConnection;
begin
  Result := TmnClientConnection.Create(Self, vStream);
end;

procedure TmnClients.Log(Connection: TmnConnection; S: string);
begin
  if Assigned(FOnLog) then
  begin
    Enter;
    try
      FOnLog(Connection, S);
    finally
      Leave;
    end;
  end;
end;

procedure TmnClients.Remove(Connection: TmnClientConnection);
begin
  Enter;
  try
    if Connection.FreeOnTerminate then
      List.Remove(Connection);
    Changed;
  finally
    Leave;
  end;
end;

procedure TmnClients.Stop;
begin
  Terminate;
end;

procedure TmnClients.Shutdown;
var
  i: Integer;
begin
  Enter;
  try
    for i := 0 to List.Count - 1 do
    begin
      List[i].FreeOnTerminate := False;
      List[i].Terminate;
    end;
  finally
    Leave;
  end;
  try
    while List.Count > 0 do
    begin
//      WaitForSingleObject(List[0].Handle, INFINITE);
      List[0].WaitFor;
      List[0].Free;
      List.Delete(0);
    end;
    Changed;
  finally
  end;
end;

function TmnClients.AddConnection(vPort: string; vAddress: string): TmnClientConnection;
begin
  if vPort = '' then
    vPort := FPort;
  if vAddress = '' then
    vAddress := FAddress;
  Result := CreateConnection(nil) as TmnClientConnection;
  Result.Start;
end;

{ TmnClientSocket }

function TmnClientSocket.CreateSocket: TmnCustomSocket;
begin
  Result := WallSocket.Connect(Options, Timeout, Port, Address)
end;

constructor TmnClientSocket.Create(const vAddress, vPort: string; vOptions: TmnsoOptions);
begin
  inherited Create;
  FAddress := vAddress;
  FPort := vPort;
  Options := vOptions;
end;

procedure TmnClientSocket.SetAddress(const Value: string);
begin
  if FAddress = Value then Exit;
  if Connected then
    raise EmnException.Create('Can not change Port value when active');
  FAddress := Value;
end;

procedure TmnClientSocket.SetPort(const Value: string);
begin
  if FPort =Value then Exit;
  if Connected then
    raise EmnException.Create('Can not change Port value when active');
  FPort := Value;
end;

end.
