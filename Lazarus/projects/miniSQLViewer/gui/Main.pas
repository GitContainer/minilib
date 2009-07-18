unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, Grids,
  dateutils, LCLType,
  contnrs, ExtCtrls, StdCtrls, SynEdit, FileUtil, Buttons, Menus,
  SynHighlighterSqlite, sqlvSessions,
  mnUtils, mncSQLite, mncSchemes, mncSqliteSchemes, sqlvClasses, sqlvStdClasses, LMessages;

type
  TsqlState = (sqlsRoot, sqlsSQL, sqlsResults, sqlsInfo, sqlsMembers);

  TControlObject = class(TObject)
  public
    Control: TControl;
    UseActive: Boolean;
    Reverse: Boolean;
  end;

  { TControlObjects }

  TControlObjects = class(TObjectList)
  private
    function GetItem(Index: Integer): TControlObject;
  public
    function Add(ControlObject: TControlObject): Integer;
    property Items[Index: Integer]: TControlObject read GetItem; default;
  end;

  TPanelObject = class(TObject)
  private
    FList: TControlObjects;
  public
    Control: TControl;
    constructor Create;
    destructor Destroy; override;
    property List: TControlObjects read FList;
    procedure Show(Active: Boolean);
    procedure Hide(Active: Boolean);
  end;

  TPanelsList = class(TObjectList)
  private
    function GetItem(Index: Integer): TPanelObject;
  public
    constructor Create;
    function Find(AControl: TControl): TPanelObject;
    procedure Add(AControl: TControl; ALinkControl: TControl = nil; UseActive: Boolean = False; Reverse: Boolean = False);
    procedure Show(AControl: TControl; Active: Boolean);
    procedure HideAll;
    property Items[Index: Integer]: TPanelObject read GetItem; default;
  end;

  { TMainForm }

  TMainForm = class(TForm)
    FirstBtn: TSpeedButton;
    ResultsBtn: TSpeedButton;
    InfoPanel: TPanel;
    InfoLbl: TLabel;
    FetchCountLbl: TLabel;
    FetchedLbl: TLabel;
    ResultEdit: TMemo;
    InfoBtn: TSpeedButton;
    SQLBackwardBtn: TSpeedButton;
    ConnectBtn: TButton;
    DatabasesCbo: TComboBox;
    DisconnectBtn: TButton;
    AutoCreateChk: TCheckBox;
    SQLForwardBtn: TSpeedButton;
    GroupsList: TComboBox;
    MainMenu: TMainMenu;
    MenuItem1: TMenuItem;
    AboutMnu: TMenuItem;
    OptionsMnu: TMenuItem;
    ForwardBtn: TSpeedButton;
    MembersGrid: TStringGrid;
    ToolsMnu: TMenuItem;
    TitleLbl: TLabel;
    DataPathCbo: TComboBox;
    ObjectsBtn: TSpeedButton;
    Label1: TLabel;
    Label2: TLabel;
    ObjectsPanel: TPanel;
    ClientPanel: TPanel;
    ExecuteBtn: TSpeedButton;
    SQLBtn: TSpeedButton;
    SQLBtn1: TSpeedButton;
    OpenBtn: TSpeedButton;
    SpeedButton5: TSpeedButton;
    TopPanel: TPanel;
    ResultPanel: TPanel;
    RootPanel: TPanel;
    SQLEdit: TSynEdit;
    SQLPanel: TPanel;
    DataGrid: TStringGrid;
    BackwordBtn: TSpeedButton;
    procedure BackwordBtnClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ConnectBtnClick(Sender: TObject);
    procedure DatabasesCboDropDown(Sender: TObject);
    procedure DataPathCboDropDown(Sender: TObject);
    procedure DataPathCboExit(Sender: TObject);
    procedure DisconnectBtnClick(Sender: TObject);
    procedure ExecuteBtnClick(Sender: TObject);
    procedure FirstBtnClick(Sender: TObject);
    procedure FormShortCut(var Msg: TLMKey; var Handled: Boolean);
    procedure GroupsListClick(Sender: TObject);
    procedure GroupsListSelect(Sender: TObject);
    procedure InfoBtnClick(Sender: TObject);
    procedure MembersGridDblClick(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure ObjectsBtnClick(Sender: TObject);
    procedure MembersListDblClick(Sender: TObject);
    procedure MembersListKeyPress(Sender: TObject; var Key: char);
    procedure ResultsBtnClick(Sender: TObject);
    procedure SQLBackwardBtnClick(Sender: TObject);
    procedure SQLBtnClick(Sender: TObject);
    procedure OpenBtnClick(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure ForwardBtnClick(Sender: TObject);
  private
    FLockEnum: Boolean;
    FSqliteSyn: TSynSqliteSyn;
    FDataPath: string;
    procedure FileFoundEvent(FileIterator: TFileIterator);
    procedure DirectoryFoundEvent(FileIterator: TFileIterator);
    procedure EnumDatabases;
    procedure SetDataPath(const AValue: string);
    procedure Connected;
    procedure Disconnected;
    procedure SessionStarted;
    procedure SessionStoped;
  private
    FState: TsqlState;
    PanelsList: TPanelsList;
    FCancel: Boolean;
    procedure AddSql;
    procedure ClearGrid;
    procedure Execute;
    procedure FillGrid(SQLCMD: TmncSQLiteCommand);
    function LogTime(Start: TDateTime): string;
    procedure RefreshSQLHistory;
    procedure RefreshHistory;
    procedure SetState(const AValue: TsqlState);
    procedure StateChanged;
    function GetDatabaseName: string;
    function GetRealDataPath: string;
    procedure SetRealDataPath(FileName: string);
    property DataPath: string read FDataPath write SetDataPath;
  public
    GroupsNames: TStringList;
    SchemeName: string;
    MebmerName: string;
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure OpenMember;
    procedure OpenGroup;
    property State: TsqlState read FState write SetState;
  end;

var
  MainForm: TMainForm;

implementation

{ TMainForm }

procedure TMainForm.ConnectBtnClick(Sender: TObject);
begin
  sqlvEngine.Session.Open(GetDatabaseName, AutoCreateChk.Checked);
  sqlvEngine.Launch('Database', DatabasesCbo.Text);
end;

procedure TMainForm.DatabasesCboDropDown(Sender: TObject);
begin
  DataPath := DataPathCbo.Text;
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
end;

procedure TMainForm.BackwordBtnClick(Sender: TObject);
begin
  sqlvEngine.Backward;
end;

procedure TMainForm.DataPathCboDropDown(Sender: TObject);
begin
  DataPath := DataPathCbo.Text;
end;

procedure TMainForm.DataPathCboExit(Sender: TObject);
begin
  DataPath := DataPathCbo.Text;
end;

procedure TMainForm.DisconnectBtnClick(Sender: TObject);
begin
  sqlvEngine.Session.Close;
  StateChanged;
end;

procedure TMainForm.ExecuteBtnClick(Sender: TObject);
begin
  Execute;
end;

procedure TMainForm.FirstBtnClick(Sender: TObject);
begin
  sqlvEngine.Launch('Database', DatabasesCbo.Text);
end;

procedure TMainForm.FormShortCut(var Msg: TLMKey; var Handled: Boolean);
begin
  if Msg.CharCode = VK_F9 then
  begin
    if (State = sqlsSQL) and sqlvEngine.Session.IsActive then
      Execute;
  end;
end;

procedure TMainForm.GroupsListClick(Sender: TObject);
begin

end;

procedure TMainForm.GroupsListSelect(Sender: TObject);
begin
  OpenGroup;
end;

procedure TMainForm.InfoBtnClick(Sender: TObject);
begin
  State := sqlsInfo;
end;

procedure TMainForm.MembersGridDblClick(Sender: TObject);
begin
  OpenMember;
end;

procedure TMainForm.MenuItem1Click(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.ObjectsBtnClick(Sender: TObject);
begin
  State := sqlsMembers;
end;

procedure TMainForm.MembersListDblClick(Sender: TObject);
begin
  OpenMember;
end;

procedure TMainForm.MembersListKeyPress(Sender: TObject; var Key: char);
begin
  if (Key = #13) then
  begin
    OpenMember;
    Key := #0;
  end;
end;

procedure TMainForm.ResultsBtnClick(Sender: TObject);
begin
  State := sqlsResults;
end;

procedure TMainForm.SQLBackwardBtnClick(Sender: TObject);
begin

end;

procedure TMainForm.OpenBtnClick(Sender: TObject);
begin
  OpenMember;
end;

procedure TMainForm.SQLBtnClick(Sender: TObject);
begin
  State := sqlsSQL;
end;

procedure TMainForm.SpeedButton5Click(Sender: TObject);
begin
  State := sqlsRoot;
end;

procedure TMainForm.ForwardBtnClick(Sender: TObject);
begin
  sqlvEngine.Forward;
end;

procedure TMainForm.FileFoundEvent(FileIterator: TFileIterator);
begin
  DatabasesCbo.Items.Add(FileIterator.FileInfo.Name);
end;

procedure TMainForm.DirectoryFoundEvent(FileIterator: TFileIterator);
begin
  DataPathCbo.Items.Add(FileIterator.FileName);
end;

procedure TMainForm.EnumDatabases;
var
  aFiles: TStringList;
  aFileSearcher: TFileSearcher;
  s: string;
begin
  if not FLockEnum then
  begin
    FLockEnum := True;
    try
      aFileSearcher := TFileSearcher.Create;
      aFiles := TStringList.Create;
      DataPathCbo.Items.BeginUpdate;
      DatabasesCbo.Items.BeginUpdate;
      try
        DataPathCbo.Items.Clear;
        DataPathCbo.Items.Add(FDataPath);
        DatabasesCbo.Clear;
        aFileSearcher.OnDirectoryFound := @DirectoryFoundEvent;
        aFileSearcher.OnFileFound := @FileFoundEvent;
        aFileSearcher.Search(GetRealDataPath, '*.sqlite;*.db', False);
        DataPathCbo.Text := FDataPath;
      finally
        DataPathCbo.Items.EndUpdate;
        DatabasesCbo.Items.EndUpdate;
        aFileSearcher.Free;
        aFiles.Free;
      end;
    finally
      FLockEnum := False;
    end;
  end;
end;

procedure TMainForm.SetDataPath(const AValue: string);
begin
  if FDataPath <> AValue then
  begin
    FDataPath := AValue;
    EnumDatabases;
  end;
end;

procedure TMainForm.Connected;
begin

end;

procedure TMainForm.Disconnected;
begin

end;

procedure TMainForm.SessionStarted;
begin
end;

procedure TMainForm.SessionStoped;
begin

end;

procedure TMainForm.SetState(const AValue: TsqlState);
begin
  if FState <> AValue then
  begin
    FState :=AValue;
    StateChanged;
  end;
end;

procedure TMainForm.StateChanged;
begin
  case FState of
    sqlsRoot: PanelsList.Show(RootPanel, sqlvEngine.Session.IsActive);
    sqlsSQL: PanelsList.Show(SQLPanel, sqlvEngine.Session.IsActive);
    sqlsResults: PanelsList.Show(ResultPanel, sqlvEngine.Session.IsActive);
    sqlsInfo: PanelsList.Show(InfoPanel, sqlvEngine.Session.IsActive);
    sqlsMembers: PanelsList.Show(ObjectsPanel, sqlvEngine.Session.IsActive);
  end;
end;

function TMainForm.GetDatabaseName: string;
begin
  Result := GetRealDataPath + DatabasesCbo.Text;
end;

function TMainForm.GetRealDataPath: string;
begin
  Result := ExpandToPath('', FDataPath, Application.Location);
end;

procedure TMainForm.SetRealDataPath(FileName: string);
var
  aPath: string;
  i: Integer;
begin
  aPath := ExtractFilePath(FileName);
  DataPathCbo.Text := aPath;
  DataPath := aPath;
  FileName := ExtractFileName(FileName);
  i:= DatabasesCbo.Items.IndexOf(FileName);
  if i >= 0 then
    DatabasesCbo.ItemIndex := i;
end;

constructor TMainForm.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  //SQLEdit.CharWidth := 8;
  SQLBackwardBtn.Glyph.Assign(BackwordBtn.Glyph);
  SQLForwardBtn.Glyph.Assign(ForwardBtn.Glyph);
  GroupsNames := TStringList.Create;
  sqlvEngine.WorkPath := Application.Location;
  sqlvEngine.Session.OnConnected := @Connected;
  sqlvEngine.Session.OnDisconnected := @Disconnected;
  sqlvEngine.Session.OnSessionStarted := @SessionStarted;
  sqlvEngine.Session.OnSessionStoped := @SessionStoped;
  FSqliteSyn := TSynSqliteSyn.Create(Self);
  SQLEdit.Highlighter := FSqliteSyn;
  PanelsList := TPanelsList.Create;
  PanelsList.Add(RootPanel);
  PanelsList.Add(RootPanel, DisconnectBtn, True);
  PanelsList.Add(RootPanel, ConnectBtn, True, True);
  PanelsList.Add(RootPanel, SQLBtn, True);
  PanelsList.Add(RootPanel, ObjectsBtn, True);
  PanelsList.Add(SQLPanel);
  PanelsList.Add(SQLPanel, ExecuteBtn, True);
  PanelsList.Add(SQLPanel, ResultsBtn, True);
  PanelsList.Add(SQLPanel, ObjectsBtn, True);
  PanelsList.Add(SQLPanel, InfoBtn, True);
  PanelsList.Add(ResultPanel);
  PanelsList.Add(ResultPanel, SQLBtn, True);
  PanelsList.Add(ResultPanel, InfoBtn, True);
  PanelsList.Add(ObjectsPanel);
  PanelsList.Add(ObjectsPanel, OpenBtn, True);
  PanelsList.Add(ObjectsPanel, SQLBtn, True);
  PanelsList.Add(InfoPanel);
  PanelsList.Add(InfoPanel, ResultsBtn, True);
  PanelsList.Add(InfoPanel, SQLBtn, True);
  if sqlvEngine.Recents.Count > 0 then
    SetRealDataPath(sqlvEngine.Recents[0]);
  sqlvEngine.LoadFile('recent.sql', SQLEdit.Lines);
  StateChanged;
end;

destructor TMainForm.Destroy;
begin
  FreeAndNil(PanelsList);
  FreeAndNil(GroupsNames);
  inherited Destroy;
end;

{ TPanelsList }

constructor TPanelsList.Create;
begin
  inherited Create(True);
end;

function TPanelsList.Find(AControl: TControl): TPanelObject;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count -1 do
  begin
    if (Items[i].Control = AControl) then
    begin
      Result := Items[i];
      break;
    end;
  end;
end;

function TPanelsList.GetItem(Index: Integer): TPanelObject;
begin
  Result := inherited items[Index] as TPanelObject;
end;

procedure TPanelsList.HideAll;
begin
  Show(nil, False);
end;

procedure TPanelsList.Show(AControl: TControl; Active: Boolean);
var
  i: Integer;
  aPanel : TPanelObject;
begin
  aPanel := nil;
  for i := 0 to Count -1 do
  begin
    if (Items[i].Control = AControl) then
      aPanel := Items[i]
    else
    begin
      Items[i].Hide(Active);
    end;
  end;
  if aPanel <> nil then
  begin
    aPanel.Show(Active);
  end;
end;

procedure TPanelsList.Add(AControl: TControl; ALinkControl: TControl; UseActive: Boolean; Reverse: Boolean = False);
var
  aPanel: TPanelObject;
  aLink: TControlObject;
begin
  if ALinkControl <> nil then
  begin
    aPanel := Find(AControl);
    if aPanel = nil then
      raise Exception.Create('Control not found in the list');
    aLink := TControlObject.Create;
    aLink.UseActive := UseActive;
    aLink.Reverse := Reverse;
    aLink.Control := ALinkControl;
    aPanel.List.Add(aLink);
  end
  else
  begin
    aPanel := TPanelObject.Create;
    aPanel.Control := AControl;
    inherited Add(aPanel);
  end;
end;

{ TPanelObject }

constructor TPanelObject.Create;
begin
  FList := TControlObjects.Create(True);
end;

destructor TPanelObject.Destroy;
begin
  FList.Free;
  inherited Destroy;
end;

procedure TPanelObject.Show(Active: Boolean);
var
  i: Integer;
begin
  Control.Visible := True;
  Control.Align := alClient;
  for i := 0 to List.Count -1 do
    List[i].Control.Visible := not List[i].UseActive or ((Active and not List[i].Reverse) or (not Active and List[i].Reverse));
end;

procedure TPanelObject.Hide(Active: Boolean);
var
  i: Integer;
begin
  Control.Visible := False;
  for i := 0 to List.Count -1 do
    List[i].Control.Visible := False;
end;

{ TControlObjects }

function TControlObjects.GetItem(Index: Integer): TControlObject;
begin
  Result := inherited items[Index] as TControlObject;
end;

function TControlObjects.Add(ControlObject: TControlObject): Integer;
begin
  Result := inherited Add(ControlObject);
end;

procedure TMainForm.OpenMember;
begin
  if (MembersGrid.RowCount > 1) and (MembersGrid.Row > 1) then
    sqlvEngine.LaunchGroup(SchemeName, MembersGrid.Cells[0, MembersGrid.Row]);
end;

procedure TMainForm.OpenGroup;
begin
  if (GroupsList.Items.Count > 0) and (GroupsList.ItemIndex >=0) then
    sqlvEngine.Launch(GroupsNames[GroupsList.ItemIndex], MebmerName, True);
end;

procedure TMainForm.RefreshSQLHistory;
begin
  SQLForwardBtn.Enabled := sqlvEngine.SQLHistory.HaveForward;
  SQLBackwardBtn.Enabled := sqlvEngine.SQLHistory.HaveBackward;
end;

procedure TMainForm.RefreshHistory;
begin
  ForwardBtn.Enabled := sqlvEngine.History.HaveForward;
  BackwordBtn.Enabled := sqlvEngine.History.HaveBackward;
end;

procedure TMainForm.AddSql;
begin
  sqlvEngine.SQLHistory.Add(SQLEdit.Text, '');
  RefreshSQLHistory;
end;

procedure TMainForm.Execute;
var
  t: TDateTime;
  SQLSession: TmncSQLiteSession;
  SQLCMD: TmncSQLiteCommand;
begin
  sqlvEngine.SaveFile('recent.sql', SQLEdit.Lines);
  SQLSession := TmncSQLiteSession.Create(sqlvEngine.Session.DBConnection);
  SQLCMD := TmncSQLiteCommand.Create(SQLSession);
  try
    if not SQLCMD.Active then
    begin
      ResultEdit.Clear;
      AddSQL;
      SQLCMD.SQL.Text := SQLEdit.Text;
      SqlBtn.Enabled := False;
      Screen.Cursor := crHourGlass;
      try
        SQLSession.Start;
        try
          ResultEdit.Lines.Add('========= Execute ==========');
          t := NOW;
          SQLCMD.Prepare;
{          if not ShowCMDParams(SQLCMD) then//that todo
          begin
            ResultEdit.Lines.Add('Canceled by user');
            Abort;
          end;}
          try
            ResultEdit.Lines.Add('Prepare time: ' + LogTime(t));
            SQLCMD.NextOnExecute := False;
            t := NOW;
            SQLCMD.Execute;
            ResultEdit.Lines.Add('Execute time: ' + LogTime(t));
            if not SQLCMD.EOF then
            begin
              State := sqlsResults;
              DataGrid.SetFocus;
              t := NOW;
              SQLCMD.Next;
              if SQLCMD.Eof then
                ClearGrid
              else
                FillGrid(SQLCMD);
              ResultEdit.Lines.Add('Fetch time: ' + LogTime(t));
            end
            else
            begin
              ClearGrid;
              State := sqlsInfo;
            end;
            ResultEdit.Lines.Add('Last Row ID: ' + IntToStr(SQLCMD.GetLastInsertID));
            ResultEdit.Lines.Add('Rows affected: ' + IntToStr(SQLCMD.GetRowsChanged));
            SQLSession.Commit;
          except
            ClearGrid;
            raise;
          end;
        except
          on E: Exception do
          begin
            SQLSession.Rollback;
            ResultEdit.Lines.Add(E.Message);
            raise;
          end
        else
          raise;
        end;
      finally
        ResultEdit.Lines.Add('');
        Screen.Cursor := crDefault;
        SqlBtn.Enabled := True;
      end;
    end;
  finally
    SQLCMD.Free;
    SQLSession.Free;
  end;
end;

procedure TMainForm.ClearGrid;
var
  FixedCols: Integer;
begin
  DataGrid.FixedCols := 1;
  DataGrid.FixedRows := 1;
  DataGrid.ColCount := 2;
  DataGrid.RowCount := 2;
  DataGrid.ColWidths[0] := 20;
  DataGrid.Cells[0, 1] := '';
  DataGrid.Cells[1, 0] := '';
  DataGrid.Cells[1, 1] := '';
end;

procedure TMainForm.FillGrid(SQLCMD: TmncSQLiteCommand);

  function GetTextWidth(Text: string): Integer;
  begin
    DataGrid.Canvas.Font := DataGrid.Font;
    Result := DataGrid.Canvas.TextWidth(Text);
  end;

  function GetCharWidth: Integer;
  begin
    Result := (GetTextWidth('Wi') div 2);
  end;
var
  i, z, c, cw, tw, w: Integer;
  s: string;
begin
  FCancel := False;
  DataGrid.ColCount := SQLCMD.Fields.Count + 1;
  DataGrid.FixedCols := 1;
  DataGrid.FixedRows := 1;
  DataGrid.ColWidths[0] := 24;
  DataGrid.Row := 1;
  DataGrid.Col := 1;
  cw := GetCharWidth; //must calc from canvas
  for i := 1 to DataGrid.ColCount - 1 do
  begin
    s := SQLCMD.Fields[i - 1].Name;
    z := 10;//SQLCMD.Fields[i - 1].Size;
    if z < 4 then
      z := 4
    else if z > 20 then
      z := 20;
    w := z * cw;
    tw := GetTextWidth(s) + 12;
    if tw > w then
      w := tw;
    tw := GetTextWidth(SQLCMD.Current.Items[i - 1].AsString) + 12;
    if tw > w then
      w := tw;
    DataGrid.ColWidths[i] := w;
    DataGrid.Cells[i, 0] := s;
  end;

  c := 1;
  while not SQLCMD.EOF do
  begin
    DataGrid.RowCount := c + 1;
    DataGrid.Cells[0, c] := IntToStr(c - 1);
    for i := 1 to DataGrid.ColCount - 1 do
    begin
      DataGrid.Cells[i, c] := SQLCMD.Current.Items[i - 1].AsString;
    end;
    Inc(c);
    if Frac(c / 100) = 0 then
    begin
      FetchCountLbl.Caption := IntToStr(c);
      Application.ProcessMessages;
    end;
    if FCancel then
      break;
    SQLCMD.Next;
  end;
  w := GetTextWidth(IntToStr(c)) + 12;
  if w < 24 then
    w := 24;
  DataGrid.ColWidths[0] := w;
  FetchCountLbl.Caption := IntToStr(c);
end;

function TMainForm.LogTime(Start: TDateTime): string;
var
  ms, m, s: Cardinal;
begin
  ms := MilliSecondsBetween(Now, Start);
  s := (ms div 1000);
  ms := (ms mod 1000);
  m := (s div 60);
  s := (s mod 60);
  Result := Format('%d:%d:%d', [m, s, ms]);
end;

initialization
  {$I Main.lrs}
end.

