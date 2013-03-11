unit mncPostgre;
{**
 *  This file is part of the "Mini Connections"
 *
 * @license   modifiedLGPL (modified of http://www.gnu.org/licenses/lgpl.html)
 *            See the file COPYING.MLGPL, included in this distribution,
 * @author    Zaher Dirkey <zaher at parmaja dot com>
 * @author    Belal Hamed <belalhamed at gmail dot com>  
 * @comment   Only for postgre 8.x or later
 *}

{*TODO
  - Retrieving Query Results Row-By-Row
      http://www.postgresql.org/docs/9.2/static/libpq-single-row-mode.html
} 
{$M+}
{$H+}
{$IFDEF FPC}
{$mode delphi}
{$warning Postgre unit not stable yet}
{$ENDIF}

interface

uses
  Classes, SysUtils, Variants, StrUtils,
  {$ifdef FPC}
  //postgres3,
  postgres3dyn,
  {$else}
  mncPGHeader,
  {$endif}
  mnUtils, mnStreams, mncConnections, mncSQL;

type

  TmpgResultFormat = (mrfText, mrfBinary);

  { TmncPGConnection }

  TmncPGConnection = class(TmncSQLConnection)
  private
    FHandle: PPGconn;
  protected
    function CreateConnection: PPGconn; overload;
    function CreateConnection(const vDatabase: string): PPGconn; overload;

    procedure InternalConnect(var vHandle: PPGconn);
    procedure InternalDisconnect(var vHandle: PPGconn);
    procedure DoConnect; override;
    procedure DoDisconnect; override;
    function GetConnected:Boolean; override;

  protected
    procedure RaiseError(Error: Boolean; const ExtraMsg: string = ''); overload;
    procedure RaiseError(PGResult: PPGresult); overload;
    class function GetMode: TmncSessionMode; override;

  public
    constructor Create;
    procedure Interrupt;
    function CreateSession: TmncSQLSession; override;
    //TODO: Reconnect  use PQReset
    property Handle: PPGconn read FHandle;
    procedure CreateDatabase; overload;
    procedure CreateDatabase(const vName: string); overload;
    procedure DropDatabase; overload;
    procedure DropDatabase(const vName: string); overload;
    procedure RenameDatabase(const vName, vToName: string); overload;

    procedure Execute(const vResource: string; const vSQL: string; vArgs: array of const); overload;
    procedure Execute(const vResource: string; const vSQL: string); overload;
    procedure Execute(const vSQL: string); overload;
    procedure Execute(vHandle: PPGconn; const vSQL: string); overload;
  end;

  { TmncPGSession }

  TmncPGSession = class(TmncSQLSession) //note now each session has it's connection 
  private
    FTokenID: Cardinal;
    FDBHandle: PPGconn;
    FExclusive: Boolean;
    FIsolated: Boolean;
    function GetConnection: TmncPGConnection;
    procedure SetConnection(const AValue: TmncPGConnection);
    procedure SetExclusive(const AValue: Boolean);
    function GetDBHandle: PPGconn;
  protected
    function NewToken: string;//used for new command name
    procedure DoStart; override;
    procedure DoStop(How: TmncSessionAction; Retaining: Boolean); override;
    function GetActive: Boolean; override;
  public
    constructor Create(vConnection: TmncConnection); override;
    destructor Destroy; override;
    procedure Execute(vSQL: string);
    function CreateCommand: TmncSQLCommand; override;
    property Exclusive: Boolean read FExclusive write SetExclusive;
    property Connection: TmncPGConnection read GetConnection write SetConnection;
    property DBHandle: PPGconn read GetDBHandle;
    property Isolated: Boolean read FIsolated write FIsolated default True;
  end;

  TArrayOfPChar = array of PChar;

  TmncPostgreParam = class(TmncParam)
  private
    FValue: Variant;
  protected
    function GetValue: Variant; override;
    procedure SetValue(const AValue: Variant); override;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;

  TmncPostgreParams = class(TmncParams)
  protected
    function CreateParam: TmncParam; override;
  end;

  TmncPostgreField = class(TmncField)
  private
    FValue: Variant;
  protected
    function GetValue: Variant; override;
    procedure SetValue(const AValue: Variant); override;
  end;

  TmncPostgreFields = class(TmncFields)
  protected
    function CreateField(vColumn: TmncColumn): TmncField; override;
  end;

  TPGColumn = class(TmncColumn)
  private
    FPGType: Integer;
    FFieldSize: Integer;
  public
    property PGType: Integer read FPGType write FPGType;
    property FieldSize: Integer read FFieldSize write FFieldSize;
  end;

  TPGColumns = class(TmncColumns)
  private
    function GetItem(Index: Integer): TPGColumn;
  protected
  public
    function Add(vName: string; vPGType, vSize: Integer): TmncColumn; overload;
    property Items[Index: Integer]: TPGColumn read GetItem; default;
  end;

  { TmncPGCommand }

  TmncPGCommand = class(TmncSQLCommand)
  private
    FHandle: string;
    FStatment: PPGresult;
    FTuple: Integer;
    FTuples: Integer;
    FBOF: Boolean;
    FEOF: Boolean;
    FFieldsCount: Integer;
    FStatus: TExecStatusType;
    FResultFormat: TmpgResultFormat;
    function GetConnection: TmncPGConnection;
    procedure FetchFields;
    procedure FetchValues;
    function GetSession: TmncPGSession;
    procedure SetSession(const AValue: TmncPGSession);
    function GetColumns: TPGColumns;
    procedure SetColumns(const Value: TPGColumns);
    function GetRecordCount: Integer;
  protected
    procedure InternalClose;
    procedure RaiseError(PGResult: PPGresult);
    procedure CreateParamValues(var Result: TArrayOfPChar);
    procedure FreeParamValues(var Result: TArrayOfPChar);
    procedure DoPrepare; override;
    procedure DoExecute; override;
    procedure DoNext; override;
    function GetEOF: Boolean; override;
    function GetActive: Boolean; override;
    procedure DoClose; override;
    procedure DoCommit; override;
    procedure DoRollback; override;
    function CreateColumns: TmncColumns; override;
    property Connection: TmncPGConnection read GetConnection;
    property Session: TmncPGSession read GetSession write SetSession;
    function CreateParams: TmncParams; override;
    function CreateFields(vColumns: TmncColumns): TmncFields; override;

  public
    constructor CreateBy(vSession:TmncPGSession);
    destructor Destroy; override;
    procedure Clear; override;
    function GetRowsChanged: Integer;
    function GetLastInsertID: Int64;
    property Statment: PPGresult read FStatment;//opened by PQexecPrepared
    property Status: TExecStatusType read FStatus;
    property Handle: string read FHandle;//used for name in PQprepare
    property ResultFormat: TmpgResultFormat read FResultFormat write FResultFormat default mrfText;

    property Columns: TPGColumns read GetColumns write SetColumns;
    property RecordCount: Integer read GetRecordCount;
  end;

  TmncPGDDLCommand = class(TmncPGCommand)
  protected
    procedure DoPrepare; override;
    procedure DoExecute; override;
  end;

implementation

uses
  Math;


procedure TmncPGConnection.RaiseError(Error: Boolean; const ExtraMsg: string);
var
  s : Utf8String;
begin
  if (Error) then
  begin
    s := 'Postgre connection failed' + #13 + PQerrorMessage(FHandle);
    if ExtraMsg <> '' then
      s := s + ' - ' + ExtraMsg;
    raise EmncException.Create(s) {$ifdef fpc} at get_caller_frame(get_frame) {$endif};
  end;
end;

procedure TmncPGConnection.RaiseError(PGResult: PPGresult);
var
  s : Utf8String;
  //ExtraMsg: string;
begin
  case PQresultStatus(PGResult) of
    PGRES_BAD_RESPONSE,PGRES_NONFATAL_ERROR, PGRES_FATAL_ERROR:
    begin
      s := PQresultErrorMessage(PGResult);
      raise EmncException.Create('Postgre command: ' + s) {$ifdef fpc} at get_caller_frame(get_frame) {$endif};
    end;
  end;
end;

procedure TmncPGConnection.RenameDatabase(const vName, vToName: string);
begin
  Execute('postgres', 'alter database %s rename to %s', [vName, vToName]);
end;

{ TmncPGConnection }

constructor TmncPGConnection.Create;
begin
  inherited Create;
end;

procedure TmncPGConnection.Interrupt;
begin
  //PG3_interrupt(DBHandle);
end;

procedure TmncPGConnection.InternalConnect(var vHandle: PPGconn);
begin
  if AutoCreate then
  	CreateDatabase(Resource);
  vHandle := CreateConnection;
  try
    RaiseError(PQstatus(vHandle) = CONNECTION_BAD);
  except
    PQfinish(vHandle);
    vHandle := nil;
    raise;
  end;
end;

procedure TmncPGConnection.InternalDisconnect(var vHandle: PPGconn);
begin
  try
    PQfinish(vHandle);
  finally
    vHandle := nil;
  end;
end;

function TmncPGConnection.CreateConnection: PPGconn;
begin
  Result := CreateConnection(Resource);
end;

function TmncPGConnection.CreateConnection(const vDatabase: string): PPGconn;
var
  PGOptions, PGtty: Pchar;
  aPort: string;
begin
  if not Assigned(PQsetdbLogin) then
  	raise EmncException.Create('PQsetdbLogin not assigned');
  PGOptions := nil;
  PGtty := nil;
  if Port <> '' then
    aPort := Port
  else
    aPort := '5432';
  Result := PQsetdbLogin(PChar(Host), PChar(aPort), PChar(PGOptions), PChar(PGtty), PChar(LowerCase(vDatabase)), PChar(UserName), PChar(Password));
end;

procedure TmncPGConnection.CreateDatabase;
begin
  CreateDatabase(Resource);
end;

procedure TmncPGConnection.CreateDatabase(const vName: string);
begin
  Execute('postgres', 'Create Database %s;', [vName]);
end;

function TmncPGConnection.CreateSession: TmncSQLSession;
begin
  Result := TmncPGSession.Create(Self);
end;

procedure TmncPGConnection.DoConnect;
begin
  InternalConnect(FHandle);
end;

function TmncPGConnection.GetConnected: Boolean;
begin
  Result := FHandle <> nil;
end;

class function TmncPGConnection.GetMode: TmncSessionMode;
begin
  Result := smConnection; //transaction act as connection
end;

procedure TmncPGConnection.DoDisconnect;
begin
  InternalDisconnect(FHandle);
end;

procedure TmncPGConnection.DropDatabase;
begin
  DropDatabase(Resource);
end;

procedure TmncPGConnection.DropDatabase(const vName: string);
begin
  Execute('postgres', 'drop database if exists %s;', [vName]);
end;

procedure TmncPGConnection.Execute(vHandle: PPGconn; const vSQL: string);
var
  res: PGresult;
begin
  try
    res := PQexec(vHandle, PChar(vSQL));
    RaiseError(res);
  except
    raise;
  end;
end;

procedure TmncPGConnection.Execute(const vResource, vSQL: string; vArgs: array of const);
begin
  Execute(vResource, Format(vSQL, vArgs));
end;

procedure TmncPGConnection.Execute(const vResource, vSQL: string);
var
  aHandle: PPGconn;
begin
  aHandle := CreateConnection(vResource);
  try
    if PQstatus(aHandle) = CONNECTION_OK then
    begin
      Execute(aHandle, vSQL);
    end;
  finally
    PQfinish(aHandle);
  end;
end;

procedure TmncPGConnection.Execute(const vSQL: string);
begin
  if PQstatus(FHandle) = CONNECTION_OK then
  begin
    Execute(FHandle, vSQL);
  end;
end;

{ TmncPGSession }

function TmncPGSession.CreateCommand: TmncSQLCommand;
begin
  Result := TmncPGCommand.CreateBy(Self);
end;

destructor TmncPGSession.Destroy;
begin
  inherited;
end;

procedure TmncPGSession.DoStart;
begin
  Execute('BEGIN');
end;

procedure TmncPGSession.DoStop(How: TmncSessionAction; Retaining: Boolean);
begin
  if StartCount>=0 then //dec of FStartCount befor this function
  begin
    case How of
      sdaCommit: Execute('COMMIT');
      sdaRollback: Execute('ROLLBACK');
    end;
    if FDBHandle <> nil then
    begin
      Connection.InternalDisconnect(FDBHandle);
    end;
  end;
end;

function TmncPGSession.NewToken: string;
begin
  ConnectionLock.Enter;
  try
    Inc(FTokenID);
    Result := 'minilib_' + IntToStr(FTokenID);
  finally
    ConnectionLock.Leave;
  end;
end;

procedure TmncPGSession.Execute(vSQL: string);
begin
  Connection.Execute(DBHandle, vSQL)
end;

function TmncPGSession.GetActive: Boolean;
begin
  //Result:= inherited GetActive;
  Result := (FDBHandle <> nil) or Connection.Connected;
end;

constructor TmncPGSession.Create(vConnection: TmncConnection);
begin
  inherited;
  FIsolated := True;
end;

function TmncPGSession.GetConnection: TmncPGConnection;
begin
  Result := inherited Connection as TmncPGConnection;
end;

function TmncPGSession.GetDBHandle: PPGconn;
begin
  {if Connection<>nil then
    Result := Connection.Handle
  else
    Result := nil;}
  if Isolated then
    Result := Connection.FHandle
  else
  begin
    if FDBHandle = nil then
      Connection.InternalConnect(FDBHandle);
    Result := FDBHandle;
  end;
end;

procedure TmncPGSession.SetConnection(const AValue: TmncPGConnection);
begin
  inherited Connection := AValue;
end;

procedure TmncPGSession.SetExclusive(const AValue: Boolean);
begin
  if FExclusive <> AValue then
  begin
    FExclusive := AValue;
    if Active then
      raise EmncException.Create('You can not set Exclusive when session active');
  end;
end;

{ TmncPGCommand }

procedure TmncPGCommand.RaiseError(PGResult: PPGresult);
begin
  Connection.RaiseError(PGResult);
end;

function TmncPGCommand.GetSession: TmncPGSession;
begin
  Result := inherited Session as TmncPGSession;
end;

procedure TmncPGCommand.SetColumns(const Value: TPGColumns);
begin
  inherited Columns := Value;
end;

procedure TmncPGCommand.SetSession(const AValue: TmncPGSession);
begin
  inherited Session := AValue;
end;

procedure TmncPGCommand.InternalClose;
begin
  PQclear(FStatment);
  FStatment := nil;
  FStatus := PGRES_EMPTY_QUERY;
  FTuple := 0;
end;

function TmncPGCommand.CreateParams: TmncParams;
begin
  Result := TmncPostgreParams.Create;
end;

procedure TmncPGCommand.CreateParamValues(var Result: TArrayOfPChar);
var
  i: Integer;
  s: string;
begin
  FreeParamValues(Result);
  SetLength(Result, Params.Count);
  for i := 0 to Params.Count -1 do
  begin
    if Params.Items[i].IsNull then
      FreeMem(Result[i])
    else
    begin
      case VarType(Params.Items[i].Value) of
        VarDate:
          s := FormatDateTime('yyyy-mm-dd hh:nn:ss', Params.Items[i].Value);
        else
          s := Params.Items[i].Value;
      end;
      GetMem(Result[i], Length(s) + 1);
      StrMove(PChar(Result[i]), Pchar(s), Length(s) + 1);
    end;
  end;
end;

procedure TmncPGCommand.FreeParamValues(var Result: TArrayOfPChar);
var
  i: Integer;
begin
  for i := 0 to Length(Result) - 1 do
    FreeMem(Result[i]);
  SetLength(Result, 0);
end;

procedure TmncPGCommand.Clear;
begin
  inherited;
  FBOF := True;
end;

constructor TmncPGCommand.CreateBy(vSession:TmncPGSession);
begin
  inherited CreateBy(vSession);
  //FHandle := Session.NewToken;
  FResultFormat := mrfText;
end;

function TmncPGCommand.CreateColumns: TmncColumns;
begin
  Result := TPGColumns.Create; 
end;

function TmncPGCommand.CreateFields(vColumns: TmncColumns): TmncFields;
begin
  Result := TmncPostgreFields.Create(vColumns);
end;

destructor TmncPGCommand.Destroy;
begin
  inherited;
end;

function TmncPGCommand.GetEOF: Boolean;
begin
  Result := (FStatment = nil) or FEOF;
end;

function TmncPGCommand.GetLastInsertID: Int64;
begin
  Result := 0;
end;

procedure TmncPGCommand.DoExecute;
var
  Values: TArrayOfPChar;
  P: pointer;
  f: Integer;//Result Field format
begin
  if FStatment <> nil then
    PQclear(FStatment);
  try
    if Params.Count > 0 then
    begin
      CreateParamValues(Values);
      P := @Values[0];
    end
    else
      p := nil;
    case ResultFormat of
      mrfBinary: f := 1;
      else
        f := 0;
    end;
    FStatment := PQexecPrepared(Session.DBHandle, PChar(FHandle), Params.Count, P, nil, nil, f);
    //FStatment := PQexec(Session.DBHandle, PChar(SQL.Text));
  finally
    FreeParamValues(Values);
  end;
  FStatus := PQresultStatus(FStatment);
  FTuples := PQntuples(FStatment);
  FFieldsCount := PQnfields(FStatment);
  FBOF := True;
  FTuple := 0;
  FEOF := not (FStatus in [PGRES_TUPLES_OK]);
  try
    RaiseError(FStatment);
  except
    InternalClose;
    raise;
  end;
end;

procedure TmncPGCommand.DoNext;
begin
  if (Status in [PGRES_TUPLES_OK]) then
  begin
    if FBOF then
    begin
      FetchFields;
      FBOF := False;
    end
    else
      inc(FTuple);
    FEOF := FTuple >= FTuples;
    if not FEOF then
      FetchValues;
  end
  else
    FEOF := True;
end;

procedure TmncPGCommand.DoPrepare;
var
  s:string;
  r: PPGresult;
  c: PPGconn;
begin
  FBOF := True;
  FHandle := Session.NewToken;
  s := ParseSQL([psoAddParamsID], '$');
  c := Session.DBHandle;
  r := PQprepare(c, PChar(FHandle), PChar(s), 0 , nil);
  try
    RaiseError(r);
  finally
    PQclear(r);
  end;
end;

procedure TmncPGCommand.DoRollback;
begin
  Session.Rollback;
end;

procedure TmncPGCommand.DoClose;
begin
  InternalClose;
end;

procedure TmncPGCommand.DoCommit;
begin
  Session.Commit;
end;

procedure TmncPGCommand.FetchFields;
var
  i: Integer;
  aName: string;
  //r: PPGresult;
begin
  //Fields.Clear;
  for i := 0 to FFieldsCount - 1 do
  begin
    aName :=  DequoteStr(PQfname(FStatment, i));
    Columns.Add(aName, PQftype(FStatment, i), PQfsize(Statment, i));
  end;
end;

function BEtoN(Val: Integer): Integer;
begin
  Result := Val;
end;

procedure TmncPGCommand.FetchValues;

    function _BRead(vSrc: PChar; vCount: Longint): Integer;
    var
      t: PChar;
      i: Integer;
    begin
      Result := 0;
      t := vSrc;
      Inc(t, vCount-1);
      for I := 0 to vCount - 1 do
      begin
        Result := Result + Ord(t^) * (1 shl (i*8));
        Dec(t);
      end;
    end;

    function _DRead(vSrc: PChar; vCount: Longint): Int64;
    var
      t: PChar;
      c, i: Integer;
    begin
      Result := 0;
      t := vSrc;
      Inc(t, vCount);
      c := vCount div 2;
      for I := 0 to c - 1 do
      begin
        Dec(t, 2);
        Result := Result + _BRead(t, 2) * Trunc(Power(10000, i));
      end;
    end;
var
  t: Int64;
  d: Double;
  //aType: Integer;
  v: Variant;
  aFieldSize: Integer;
  p: PChar;
  i: Integer;
  c: Integer;
  aCurrent: TmncFields;
begin
  c := FFieldsCount;
  if c > 0 then
  begin
    aCurrent := CreateFields(Columns);
    for i := 0 to c - 1 do
    begin
      if PQgetisnull(Statment, FTuple, i) <> 0 then
        aCurrent.Add(i, NULL)
      else
      begin
        p := PQgetvalue(FStatment, FTuple, i);
        if ResultFormat=mrfText then
          v := string(p)
        else
        begin
          aFieldSize :=PQgetlength(Statment, FTuple, i);
          case Columns[i].PGType of
            Oid_Bool: v := (p^ <> #0);
            Oid_varchar, Oid_bpchar, Oid_name: v := string(p);
            Oid_oid, Oid_int2: v := _BRead(p, 2);
            Oid_int4: v := _BRead(p, 4);
            Oid_int8: v := _BRead(p, 8);
            Oid_Money: v := _BRead(p, 8) / 100;
            Oid_Float4, Oid_Float8:
            begin
            end;
            Oid_Date:
            begin
              //d := BEtoN(plongint(p)^) + 36526;
              d := _BRead(p, aFieldSize) + 36526; //36526 = days between 31/12/1899 and 01/01/2000  = delphi, Postgre (0) date
              v := TDateTime(d);
            end;
            Oid_Time,
            Oid_TimeStamp:
            begin
              t := BEtoN(pint64(p)^);
              //v := TDateTime(t);//todo
              v := t;//todo
            end;
            OID_NUMERIC:
            begin
               t := _BRead(p, 2);
               d := Power(10, 2 * t);


              inc(p, 8);
              t := _DRead(p, aFieldSize - 8);
              v := t / d;
            end;
            Oid_Unknown:;
          end;
        end;

        aCurrent.Add(i, v);
      end;
    end;
    Fields := aCurrent;
  end;
end;

function TmncPGCommand.GetActive: Boolean;
begin
  Result := FStatment <> nil; 
end;

function TmncPGCommand.GetColumns: TPGColumns;
begin
  Result := inherited Columns as TPGColumns
end;

function TmncPGCommand.GetConnection: TmncPGConnection;
begin
  Result := Session.Connection as TmncPGConnection;
end;

function TmncPGCommand.GetRecordCount: Integer;
begin
  Result := FTuples;
end;

function TmncPGCommand.GetRowsChanged: Integer;
begin
  CheckActive;
  Result := StrToIntDef(PQcmdTuples(FStatment), 0);
end;

{ TmncPostgreParam }

constructor TmncPostgreParam.Create;
begin
  inherited;
end;

destructor TmncPostgreParam.Destroy;
begin
  inherited;
end;

function TmncPostgreParam.GetValue: Variant;
begin
  Result := FValue;
end;

procedure TmncPostgreParam.SetValue(const AValue: Variant);
begin
  FValue := AValue;
end;

{ TmncPostgreParams }

function TmncPostgreParams.CreateParam: TmncParam;
begin
  Result := TmncPostgreParam.Create;
end;

{ TmncPostgreField }

function TmncPostgreField.GetValue: Variant;
begin
  Result := FValue;
end;

procedure TmncPostgreField.SetValue(const AValue: Variant);
begin
  FValue := AValue;
end;

{ TmncPostgreFields }

function TmncPostgreFields.CreateField(vColumn: TmncColumn): TmncField;
begin
  Result := TmncPostgreField.Create(vColumn);
end;

{ TPGColumns }

function TPGColumns.Add(vName: string; vPGType, vSize: Integer): TmncColumn;
begin
  Result := inherited Add(Count, vName, dtUnknown, TPGColumn);
  TPGColumn(Result).PGType := vPGType;
  TPGColumn(Result).FieldSize := vSize;
end;

function TPGColumns.GetItem(Index: Integer): TPGColumn;
begin
  Result := TPGColumn(inherited GetItem(Index));
end;

{ TmncPGDDLCommand }

procedure TmncPGDDLCommand.DoExecute;
var
  Values: TArrayOfPChar;
begin
  if FStatment <> nil then
    PQclear(FStatment);
  try
    FStatment := PQexec(Session.DBHandle, PChar(SQL.Text));
  finally
    FreeParamValues(Values);
  end;
  FStatus := PQresultStatus(FStatment);
  FTuples := PQntuples(FStatment);
  FFieldsCount := PQnfields(FStatment);
  FBOF := True;
  FEOF := FStatus <> PGRES_TUPLES_OK;
  try
    RaiseError(FStatment);
  except
    InternalClose;
    raise;
  end;
end;

procedure TmncPGDDLCommand.DoPrepare;
begin
  //no need prepare
end;

end.
