unit mncMySQLORM;
{**
 *  This file is part of the "Mini Connections"
 *
 * @license   modifiedLGPL modified of http://www.gnu.org/licenses/lgpl.html
 *            See the file COPYING.MLGPL, included in this distribution,
 * @author    Zaher Dirkey <zaher at parmaja dot com>
 *}
{
  TODO:
    use foUnique
}
{$IFDEF FPC}
{$mode delphi}
{$ENDIF}
{$H+}{$M+}

interface

uses
  SysUtils, Classes, Variants,
  mncORM, mncConnections, mncMySQL;

type

  { TmncMySQLORM }

  TmncMySQLORM = class(TmncStdORM)
  protected
    type

      { TDatabaseMySQL }

      TDatabaseMySQL = class(TormGenerator)
      public
      end;

      { TSchemaMySQL }

      TSchemaMySQL = class(TormGenerator)
      public
      end;

      { TTableMySQL }

      TTableMySQL = class(TTableStd)
      public
        constructor Create; override;
        function GenForignKey(Table: TTable; Field: TField; AExternal: Boolean): string; override;
      end;

      { TFieldsMySQL }

      TFieldsMySQL = class(TFieldsStd)
      public
      end;

      { TFieldMySQL }

      TFieldMySQL = class(TormGenerator)
      public
        function DoGenerateSQL(AObject: TormSQLObject; SQL: TCallbackObject; vLevel: Integer): Boolean; override;
      end;

      { TInsertDataMySQL }

      TInsertDataMySQL = class(TormGenerator)
      public
        function DoGenerateSQL(AObject: TormSQLObject; SQL: TCallbackObject; vLevel: Integer): Boolean; override;
      end;

  protected
    class function FieldTypeToString(FieldType: TmncORM.TormFieldType; FieldSize: Integer): String;
    procedure Created; override;
  public
    class function GetConnectionClass: TmncConnectionClass; override;
  end;

implementation

{ TmncMySQLORM.TInsertDataMySQL }

function TmncMySQLORM.TInsertDataMySQL.DoGenerateSQL(AObject: TormSQLObject; SQL: TCallbackObject; vLevel: Integer): Boolean;
var
  o: TormObject;
  i: Integer;
begin
  i := 0;
  with AObject as TInsertData do
  begin
    SQL.Add('insert into ' + Table.QuotedSQLName + '(' );
    for o in this do
    begin
      if i > 0 then
        SQL.Add(',', []);
      SQL.Add(Table.Prefix + (o as TFieldValue).Name); //todo need to use SQLName
      Inc(i);
    end;
    SQL.Add(') values (');

    i := 0;
    for o in this do
    begin
      if i > 0 then
        SQL.Add(',', []);
      SQL.Add(ValueToStr((o as TFieldValue).Value));
      Inc(i);
    end;
    SQL.Add(')', [cboEndChunk, cboEndLine]);
  end;
  Result := True;
end;

{ TmncMySQLORM.TFieldMySQL }

function TmncMySQLORM.TFieldMySQL.DoGenerateSQL(AObject: TormSQLObject; SQL: TCallbackObject; vLevel: Integer): Boolean;
var
  fs: Integer;
begin
//  vSQL.Add(LevelStr(vLevel) + Name + ' as Integer'); bug in fpc needs to reproduce but i can
  with AObject as TField do
  begin
    fs := FieldSize;
    if fs = 0 then
      fs := 60;
    SQL.Add(LevelStr(vLevel) + QuotedSQLName + ' '+ FieldTypeToString(FieldType, fs));
    if (foNotNull in Options) or (foPrimary in Options) then
      SQL.Add(' not null');
    if foSequenced in Options then
      SQL.Add(' auto_increment');
    if not VarIsEmpty(DefaultValue) then
    begin
      if VarType(DefaultValue) = varString then
        SQL.Add(' default ''' + DefaultValue + '''')
      else
        SQL.Add(' default ' + VarToStr(DefaultValue));
    end;
  end;
  Result := True;
end;

{ TmncMySQLORM.TTableMySQL }

constructor TmncMySQLORM.TTableMySQL.Create;
begin
  inherited Create;
  InternalIndexes := True;
end;

function TmncMySQLORM.TTableMySQL.GenForignKey(Table: TTable; Field: TField; AExternal: Boolean): string;
begin
  //Result := 'foreign key (' + Field.QuotedSQLName + ')' //there is no name for forign key in sqlite
  Result := 'foreign key Ref_' + Table.SQLName + Field.ReferenceInfo.Table.Name + Field.ReferenceInfo.Field.Name + '(' + Field.QuotedSQLName + ')'
          +' references ' + Field.ReferenceInfo.Table.QuotedSQLName + '(' + Field.ReferenceInfo.Field.QuotedSQLName + ')';
end;

{ TmncMySQLORM }

class function TmncMySQLORM.FieldTypeToString(FieldType: TmncORM.TormFieldType; FieldSize: Integer): String;
begin
  case FieldType of
    ftString: Result := 'varchar('+IntToStr(FieldSize)+')';
    ftBoolean: Result := 'boolean';
    ftSmallInteger: Result := 'smllint';
    ftInteger: Result := 'integer';
    ftBigInteger: Result := 'bigint';
    ftCurrency: Result := 'decimal(12, 4)';
    ftFloat: Result := 'float';
    ftDate: Result := 'date';
    ftTime: Result := 'time';
    ftDateTime: Result := 'datetime';
    ftText: Result := 'text';
    ftBlob: Result := 'text';
  end;
end;

procedure TmncMySQLORM.Created;
begin
  inherited Created;
  RegisterGenerator(TDatabase, TDatabaseMySQL);
  RegisterGenerator(TSchema, TSchemaMySQL);
  RegisterGenerator(TTable, TTableMySQL);
  RegisterGenerator(TFields, TFieldsMySQL);
  RegisterGenerator(TField, TFieldMySQL);
  RegisterGenerator(TInsertData, TInsertDataMySQL);
end;

class function TmncMySQLORM.GetConnectionClass: TmncConnectionClass;
begin
  Result := TmncMySQLConnection;
end;

end.
