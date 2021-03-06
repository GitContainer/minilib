unit mnClasses;
{**
 *  This file is part of the "Mini Library"
 *
 * @license   modifiedLGPL (modified of http://www.gnu.org/licenses/lgpl.html)
 *            See the file COPYING.MLGPL, included in this distribution,
 * @author    Zaher Dirkey <zaher at parmaja dot com>
 *}

{$IFDEF FPC}
{$MODE delphi}
{$ENDIF}
{$M+}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, DateUtils, Types,
  {$ifdef FPC}
  Contnrs;
  {$else}
  System.Generics.Collections;
  {$endif}

type

  { TmnObject }

  TmnObject = class(TObject)
  protected
    procedure Created; virtual;
  public
    procedure AfterConstruction; override;
  end;

  { TmnObjectList }

  //USAGE: TMyObjectList = class(TmnObjectList<TMyObject>)

  {$ifdef FPC}
  TmnObjectList<_Object_> = class(TObjectList)
  {$else}
  TmnObjectList<_Object_: class> = class(TObjectList<_Object_>)
  {$endif}
  private
    function GetItem(Index: Integer): _Object_;
    procedure SetItem(Index: Integer; AObject: _Object_);
  protected

    function _AddRef: Integer; {$ifdef WINDOWS}stdcall{$else}cdecl{$endif};
    function _Release: Integer; {$ifdef WINDOWS}stdcall{$else}cdecl{$endif};

    {$ifdef FPC}
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
    {$else}
    procedure Notify(const Value: _Object_; Action: TCollectionNotification); override;
    {$endif}
    //override this function of u want to check the item or create it before returning it
    function Require(Index: Integer): _Object_; virtual;

    {$H-}procedure Removing(Item: _Object_); virtual;{$H+}
    {$H-}procedure Added(Item: _Object_); virtual;{$H+}

    procedure Created; virtual;
  public
    function QueryInterface({$ifdef FPC}constref{$else}const{$endif} iid : TGuid; out Obj):HResult; {$ifdef WINDOWS}stdcall{$else}cdecl{$endif};
    procedure AfterConstruction; override;
    function Add(Item: _Object_): Integer;
    procedure Insert(Index: Integer; Item: _Object_);
    function Extract(Item: _Object_): _Object_;

    property Items[Index: Integer]: _Object_ read GetItem write SetItem; default;
    function Last: _Object_;
    function First: _Object_;
  end;

  { TmnNamedObjectList }

  TmnNamedObject = class(TmnObject)
  private
    FName: string;
  public
    property Name: string read FName write FName;
  end;

  //USAGE: TMyNamedObjectList = class(TmnNamedObjectList<TMyNamedObject>)

  {$ifdef FPC}
  TmnNamedObjectList<_Object_> = class(TmnObjectList<_Object_>)
  {$else}
  TmnNamedObjectList<_Object_: TmnNamedObject> = class(TmnObjectList<_Object_>)
  {$endif}
  private
  public
    function Find(const Name: string): _Object_;
    function IndexOfName(vName: string): Integer;
  end;

implementation

function TmnObjectList<_Object_>.GetItem(Index: Integer): _Object_;
begin
  Result := Require(Index);
end;

procedure TmnObjectList<_Object_>.SetItem(Index: Integer; AObject: _Object_);
begin
  inherited Items[Index] := AObject;
end;

function TmnObjectList<_Object_>.Last: _Object_;
begin
  if Count<>0 then
    Result := _Object_(inherited Last)
  else
    Result := nil;
end;

{$ifdef FPC}
procedure TmnObjectList<_Object_>.Notify(Ptr: Pointer; Action: TListNotification);
begin
  if (Action in [lnExtracted, lnDeleted]) then
    Removing(_Object_(Ptr));
  inherited;
  if (Action = lnAdded) then
    Added(_Object_(Ptr));
end;
{$else}
procedure TmnObjectList<_Object_>.Notify(const Value: _Object_; Action: TCollectionNotification);
begin
  if (Action in [cnExtracted, cnRemoved]) then
    Removing(Value);
  inherited;
  if (Action = cnAdded) then
    Added(Value);
end;
{$endif}

function TmnObjectList<_Object_>.Require(Index: Integer): _Object_;
begin
  Result := _Object_(inherited Items[Index]);
end;

function TmnObjectList<_Object_>._AddRef: Integer; {$ifdef WINDOWS}stdcall{$else}cdecl{$endif};
begin
  Result := 0;
end;

function TmnObjectList<_Object_>._Release: Integer; {$ifdef WINDOWS}stdcall{$else}cdecl{$endif};
begin
  Result := 0;
end;

procedure TmnObjectList<_Object_>.Removing(Item: _Object_);
begin

end;

function TmnObjectList<_Object_>.QueryInterface({$ifdef FPC}constref{$else}const{$endif} iid : TGuid; out Obj): HResult; {$ifdef WINDOWS}stdcall{$else}cdecl{$endif};
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

procedure TmnObjectList<_Object_>.Added(Item: _Object_);
begin
end;

function TmnObjectList<_Object_>.Add(Item: _Object_): Integer;
begin
  Result := inherited Add(Item);
end;

procedure TmnObjectList<_Object_>.Insert(Index: Integer; Item: _Object_);
begin
  inherited Insert(Index, Item);
end;

function TmnObjectList<_Object_>.Extract(Item: _Object_): _Object_;
begin
  Result := _Object_(inherited Extract(Item));
end;

function TmnObjectList<_Object_>.First: _Object_;
begin
  if Count<>0 then
    Result := _Object_(inherited First)
  else
    Result := nil;
end;

procedure TmnObjectList<_Object_>.Created;
begin
end;

procedure TmnObjectList<_Object_>.AfterConstruction;
begin
  inherited;
  Created;
end;

{ TmnNamedObjectList }

function  TmnNamedObjectList<_Object_>.Find(const Name: string): _Object_;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    if SameText(Items[i].Name, Name) then
    begin
      Result := Items[i];
      break;
    end;
  end;
end;

function TmnNamedObjectList<_Object_>.IndexOfName(vName: string): Integer;
var
  i: integer;
begin
  Result := -1;
  if vName <> '' then
    for i := 0 to Count - 1 do
    begin
      if SameText(Items[i].Name, vName) then
      begin
        Result := i;
        break;
      end;
    end;
end;

{ TmnObject }

procedure TmnObject.Created;
begin

end;

procedure TmnObject.AfterConstruction;
begin
  inherited AfterConstruction;
  Created;
end;

end.
