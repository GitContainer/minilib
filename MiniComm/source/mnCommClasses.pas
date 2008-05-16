unit mnCommClasses;
{**
 *  This file is part of the "Mini Comm"
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
  Classes, SysUtils,
  mnStreams;

const
  cTimeout = 30000;

type
  EComPort = class(Exception)
  end;

  TDataBits = (dbFive, dbSix, dbSeven, dbEight);
  TParityBits = (prNone, prOdd, prEven, prMark, prSpace);
  TStopBits = (sbOneStopBit, sbOneAndHalfStopBits, sbTwoStopBits);
  TFlowControl = (fcHardware, fcSoftware, fcNone, fcCustom);

  TDTRFlowControl = (dtrDisable, dtrEnable, dtrHandshake);
  TRTSFlowControl = (rtsDisable, rtsEnable, rtsHandshake, rtsToggle);

  TFlowControlFlags = record
    OutCTSFlow: Boolean;
    OutDSRFlow: Boolean;
    ControlDTR: TDTRFlowControl;
    ControlRTS: TRTSFlowControl;
    XonXoffOut: Boolean;
    XonXoffIn: Boolean;
    DSRSensitivity: Boolean;
    TxContinueOnXoff: Boolean;
    XonChar: Char;
    XoffChar: Char;
  end;

  TParityFlags = record
    Check: Boolean;
    Replace: Boolean;
    ReplaceChar: Char;
  end;

  TComEvent = (evRxChar, evTxEmpty, evRxFlag, evRing, evBreak, evCTS, evDSR,
    evError, evRLSD, evRx80Full);
  TComEvents = set of TComEvent;

  TmnCommConnectMode = (ccmReadWrite, ccmRead, ccmWrite);

  { TmnCustomCommStream }

  TmnCustomCommStream = class(TmnCustomStream)
  private
    FBaudRate: Int64;
    FConnectMode: TmnCommConnectMode;
    FParity: TParityBits;
    FStopBits: TStopBits;
    FPort: string;
    FFlowControl: TFlowControl;
    FDataBits: TDataBits;
    FEventChar: Char;
    FDiscardNull: Boolean;
    FBufferSize: Integer;
    FUseOverlapped: Boolean;
    FTimeout: Cardinal;
    FReadTimeout: Cardinal;
    FWriteTimeout: Cardinal;
    FFailTimeout: Boolean;
    FReadTimeoutConst: Cardinal;
    FWriteTimeoutConst: Cardinal;
    FWaitMode: Boolean;
    FQueMode: Boolean;
    procedure SetEventChar(const Value: Char);
    procedure SetDiscardNull(const Value: Boolean);
    procedure SetBufferSize(const Value: Integer);
    procedure SetTimeout(const Value: Cardinal);
    procedure SetUseOverlapped(const Value: Boolean);
    procedure SetReadTimeout(const Value: Cardinal);
    procedure SetWriteTimeout(const Value: Cardinal);
  protected
    procedure DoConnect; virtual; abstract;
    procedure DoDisconnect; virtual; abstract;
    function GetConnected: Boolean; virtual; abstract;
    function GetFlowControlFlags: TFlowControlFlags; virtual;
    function GetParityFlags: TParityFlags; virtual;
    function DoRead(var Buffer; Count: Integer): Integer; virtual; abstract;
    function DoWrite(const Buffer; Count: Integer): Integer; virtual; abstract;
  public
    constructor Create(Suspend: Boolean; Port: string; BaudRate: Int64; DataBits: TDataBits = dbEight; Parity: TParityBits = prNone; StopBits: TStopBits = sbOneStopBit; FlowControl: TFlowControl = fcHardware; UseOverlapped: Boolean = True); overload;
    constructor Create(Params: string); overload;
    destructor Destroy; override;
    procedure Connect;
    procedure Disconnect;
    procedure Open; //Alias for Connect
    procedure Close; //Alias for Disconnect
    procedure Flush; virtual;
    procedure Purge; virtual;
    procedure Reset; virtual;
    procedure Cancel; virtual;
    function GetInQue: Integer; virtual;
    function ReadString: string;
    function WaitEvent(const Events: TComEvents): TComEvents; virtual;
    function Read(var Buffer; Count: Integer): Integer; override;
    function Write(const Buffer; Count: Integer): Integer; override;
    property Connected: Boolean read GetConnected;
    property Port: string read FPort;
    property BaudRate: Int64 read FBaudRate;
    property DataBits: TDataBits read FDataBits;
    property Parity: TParityBits read FParity;
    property StopBits: TStopBits read FStopBits;
    property FlowControl: TFlowControl read FFlowControl write FFlowControl;
    property EventChar: Char read FEventChar write SetEventChar default #0;
    property DiscardNull: Boolean read FDiscardNull write SetDiscardNull default False;
    property BufferSize: Integer read FBufferSize write SetBufferSize;

    property UseOverlapped: Boolean read FUseOverlapped write SetUseOverlapped;
    property ConnectMode: TmnCommConnectMode read FConnectMode write FConnectMode;
    //WaitMode: Make WaitEvent before read buffer
    property WaitMode: Boolean read FWaitMode write FWaitMode;
    property QueMode: Boolean read FQueMode write FQueMode;
    property Timeout: Cardinal read FTimeout write SetTimeout default cTimeout;
    //FailTimeout: raise an exception when timeout accord
    property FailTimeout: Boolean read FFailTimeout write FFailTimeout default True;
    //ReadTimeout: for internal timeout while reading COM will return in this with buffered chars
    //When ReadTimeout = 0 it not return until the whale buffer requested read
    property ReadTimeout: Cardinal read FReadTimeout write SetReadTimeout default 0;
    property ReadTimeoutConst: Cardinal read FReadTimeoutConst write FReadTimeoutConst default 10;
    //When WriteTimeout = 0 it not return until the whale buffer requested writen
    property WriteTimeout: Cardinal read FWriteTimeout write SetWriteTimeout default 1000;
    property WriteTimeoutConst: Cardinal read FWriteTimeoutConst write FWriteTimeoutConst default 10;
  end;

const
  AllComEvents: TComEvents = [Low(TComEvent)..High(TComEvent)];

implementation

{ TmnCustomCommStream }

procedure TmnCustomCommStream.Cancel;
begin
end;

procedure TmnCustomCommStream.Close;
begin
  Disconnect;
end;

constructor TmnCustomCommStream.Create(Suspend: Boolean; Port: string; BaudRate: Int64;
  DataBits: TDataBits; Parity: TParityBits; StopBits: TStopBits;
  FlowControl: TFlowControl; UseOverlapped: Boolean);
begin
  inherited Create;
  FReadTimeout := 0;
  FReadTimeoutConst := 10;
  FWriteTimeout := 100;
  FWriteTimeoutConst := 10;
  FTimeout := cTimeout;
  FFailTimeout := True;
  FPort := Port;
  FBaudRate := BaudRate;
  FDataBits := DataBits;
  FParity := Parity;
  FStopBits := StopBits;
  FFlowControl := FlowControl;
  FUseOverlapped := UseOverlapped;
  if not Suspend then
    Open;
end;

procedure TmnCustomCommStream.Connect;
begin
  DoConnect;
end;

constructor TmnCustomCommStream.Create(Params: string);
begin

end;

destructor TmnCustomCommStream.Destroy;
begin
  if Connected then
    Disconnect;
  inherited;
end;

procedure TmnCustomCommStream.Disconnect;
begin
  DoDisconnect;
end;

procedure TmnCustomCommStream.Flush;
begin
end;

function TmnCustomCommStream.GetFlowControlFlags: TFlowControlFlags;
begin
  Result.XonChar := #17;
  Result.XoffChar := #19;
  Result.DSRSensitivity := False;
  Result.ControlRTS := rtsDisable;
  Result.ControlDTR := dtrDisable;
  Result.TxContinueOnXoff := False;
  Result.OutCTSFlow := False;
  Result.OutDSRFlow := False;
  Result.XonXoffIn := False;
  Result.XonXoffOut := False;
  case FlowControl of
    fcHardware:
      begin
        Result.ControlRTS := rtsHandshake;
        Result.OutCTSFlow := True;
      end;
    fcSoftware:
      begin
        Result.XonXoffIn := True;
        Result.XonXoffOut := True;
      end;
  end;
end;

function TmnCustomCommStream.GetInQue: Integer;
begin
  Result := 0;
end;

function TmnCustomCommStream.GetParityFlags: TParityFlags;
begin
  Result.Check := False;
  Result.Replace := False;
  Result.ReplaceChar := #0;
end;

procedure TmnCustomCommStream.Open;
begin
  if Connected then
    raise EComPort.Create('Already connected');
  Connect;
end;

procedure TmnCustomCommStream.Purge;
begin
end;

function TmnCustomCommStream.Read(var Buffer; Count: Integer): Integer;
begin
  if WaitMode then
  begin
    if WaitEvent([evRxChar, evRxFlag]) <> [] then
    begin
      if QueMode then
        Count := GetInQue;
      Result := DoRead(Buffer, Count)
    end
    else
      Result := 0;
  end
  else
  begin
    if QueMode then
      Count := GetInQue;
    Result := DoRead(Buffer, Count);
  end;
end;

function TmnCustomCommStream.ReadString: string;
var
  c: Integer;
begin
  c := 255;
  SetLength(Result, c);
  c := Read(Result[1], c);
  SetLength(Result, c);
end;

procedure TmnCustomCommStream.Reset;
begin
end;

procedure TmnCustomCommStream.SetBufferSize(const Value: Integer);
begin
  FBufferSize := Value;
end;

procedure TmnCustomCommStream.SetReadTimeout(const Value: Cardinal);
begin
  FReadTimeout := Value;
end;

procedure TmnCustomCommStream.SetDiscardNull(const Value: Boolean);
begin
  FDiscardNull := Value;
end;

procedure TmnCustomCommStream.SetEventChar(const Value: Char);
begin
  FEventChar := Value;
end;

procedure TmnCustomCommStream.SetTimeout(const Value: Cardinal);
begin
  FTimeout := Value;
end;

procedure TmnCustomCommStream.SetUseOverlapped(const Value: Boolean);
begin
  if FUseOverlapped <> Value then
  begin
    if Connected then
      raise EComPort.Create('Already connected');
    FUseOverlapped := Value;
  end;
end;

procedure TmnCustomCommStream.SetWriteTimeout(const Value: Cardinal);
begin
  FWriteTimeout := Value;
end;

function TmnCustomCommStream.WaitEvent(const Events: TComEvents): TComEvents;
begin
end;

function TmnCustomCommStream.Write(const Buffer; Count: Integer): Integer;
begin
  Result := DoWrite(Buffer, Count);
end;

end.
