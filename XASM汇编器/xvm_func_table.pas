unit xvm_func_table;

interface

uses
  System.SysUtils, xvm_types, xvm_globals, xvm_link_list;

function AddFunc(pstrName: PAnsiChar; iEntryPoint: integer): integer;
function GetFuncByName(pstrName: PAnsiChar): pFuncNode;
procedure SetFuncInfo(pstrName: PAnsiChar; iParamCount: integer; iLocalDataSize: integer);

var
  // º¯Êý±í
  g_FuncTable: LinkedList;

implementation

function AddFunc(pstrName: PAnsiChar; iEntryPoint: integer): integer;
var
  iIndex: integer;
  pNewFunc: pFuncNode;
begin
  if GetFuncByName(pstrName) <> nil then
  begin
    Result := -1;
    Exit;
  end;
  GetMem(pNewFunc, sizeof(FuncNode));
  StrCopy(@pNewFunc.pstrName, pstrName);
  pNewFunc.iEntryPoint := iEntryPoint;
  iIndex := AddNode(@g_FuncTable, pNewFunc);
  pNewFunc.iIndex := iIndex;
  Result := iIndex;
end;

function GetFuncByName(pstrName: PAnsiChar): pFuncNode;
var
  iCurrNode: integer;
  pCurrNode: pLinkedListNode;
  pCurrFunc: pFuncNode;
begin
  if (g_FuncTable.iNodeCount = 0) then
  begin
    Result := nil;
    Exit;
  end;
  pCurrNode := g_FuncTable.pHead;
  for iCurrNode := 0 to g_FuncTable.iNodeCount - 1 do
  begin
    pCurrFunc := pFuncNode(pCurrNode.pData);
    if StrIComp(PAnsiChar(@pCurrFunc.pstrName), pstrName) = 0 then
    begin
      Result := pCurrFunc;
      Exit;
    end;;
    pCurrNode := pCurrNode.pNext;
  end;
  Result := nil;
end;

procedure SetFuncInfo(pstrName: PAnsiChar; iParamCount: integer; iLocalDataSize: integer);
var
  pFunc: pFuncNode;
begin
  pFunc := GetFuncByName(pstrName);
  pFunc.iParamCount := iParamCount;
  pFunc.iLocalDataSize := iLocalDataSize;
end;

end.
