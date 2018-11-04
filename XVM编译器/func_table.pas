{ ******************************************************* }
{                                                         }
{ XVM                                                     }
{                                                         }
{ 版权所有 (C) 2012 adsj                                  }
{ Mode： 函数列表模块                                     }
{ ******************************************************* }
unit func_table;

interface

uses
  System.SysUtils, globals, linked_list;

type
  pFuncNode = ^FuncNode;

  _FuncNode = record
    iIndex: integer; // 函数名字
    pstrName: array [0 .. MAX_IDENT_SIZE - 1] of AnsiChar;
    iIsHostAPI: integer; // 是否是主应用程序API
    //
    iParamCount: integer; // 接受参数个数
    ICodeStream: LinkedList; // 局部中间代码流
  end;

  FuncNode = _FuncNode;
  // 接口
function GetFuncByIndex(iIndex: integer): pFuncNode;
function GetFuncByName(pstrName: PAnsiChar): pFuncNode;
function AddFunc(pstrName: PAnsiChar; iIsHostAPI: integer): integer;
procedure SetFuncParamCount(iIndex: integer; iParamCount: integer);

implementation

function GetFuncByIndex(iIndex: integer): pFuncNode;
var
  pCurrNode: pLinkedListNode;
  pCurrFunc: pFuncNode;
  iCurrNode: integer;
begin
  if g_FuncTable.iNodeCount = 0 then
  begin
    Result := nil;
    Exit;
  end;
  pCurrNode := g_FuncTable.pHead;
  for iCurrNode := 0 to g_FuncTable.iNodeCount - 1 do
  begin
    pCurrFunc := pFuncNode(pCurrNode.pData);
    if iIndex = pCurrFunc.iIndex then
    begin
      Result := pCurrFunc;
      Exit;
    end;
    pCurrNode := pCurrNode.pNext;
  end;
  Result := nil;
end;

function GetFuncByName(pstrName: PAnsiChar): pFuncNode;
var
  pCurrFunc: pFuncNode;
  iCurrFuncIndex: integer;
begin
  for iCurrFuncIndex := 0 to g_FuncTable.iNodeCount - 1 do
  begin
    pCurrFunc := GetFuncByIndex(iCurrFuncIndex);
    if (pCurrFunc <> nil) and (StrIComp(@pCurrFunc.pstrName, pstrName) = 0) then
    begin
      Result := pCurrFunc;
      Exit;
    end;
  end;
  Result := nil;
end;

function AddFunc(pstrName: PAnsiChar; iIsHostAPI: integer): integer;
var
  pNewFunc: pFuncNode;
  iIndex: integer;
begin
  if GetFuncByName(pstrName) <> nil then
  begin
    Result := -1;
    Exit;
  end;
  GetMem(pNewFunc, SizeOf(FuncNode));
  StrCopy(@pNewFunc.pstrName, pstrName);
  // 将函数加入到链表中并获它的索引，但是这个索引要+1之后才能返回，因为全局范围使用0
  iIndex := AddNode(@g_FuncTable, pNewFunc) + 1;
  pNewFunc.iIndex := iIndex;
  pNewFunc.iIsHostAPI := iIsHostAPI;
  pNewFunc.iParamCount := 0;
  pNewFunc.ICodeStream.iNodeCount := 0;
  if StrIComp(pstrName, MAIN_FUNC_NAME) = 0 then
  begin
    g_ScriptHeader.iIsMainFuncPresent := 1;
    g_ScriptHeader.IMainFuncIndex := iIndex;
  end;
  Result := iIndex;
end;

procedure SetFuncParamCount(iIndex: integer; iParamCount: integer);
var
  pFunc: pFuncNode;
begin
  pFunc := GetFuncByIndex(iIndex);
  pFunc.iParamCount := iParamCount;
end;

end.
