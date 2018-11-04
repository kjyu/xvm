{ ******************************************************* }
{                                                         }
{ XVM                                                     }
{                                                         }
{ 版权所有 (C) 2012 adsj                                  }
{ Mode： 符号列表模块                                     }
{ ******************************************************* }
unit xvm_symbol_table;

interface

uses
  System.SysUtils, xvm_types, xvm_link_list;

var
  // 符号表
  g_SymbolTable: LinkedList;

function GetSymbolByIdent(pstrIdent: PAnsiChar; iFuncIndex: integer): pSymbolNode;
function AddSymbol(pstrIdent: PAnsiChar; iSize: integer; iStackIndex: integer;
  iFuncIndex: integer): integer;
function GetStackIndexByIdent(pstrIdent: PAnsiChar; iFuncIndex: integer): integer;
function GetSizeByIdent(pstrIdent: PAnsiChar; iFuncIndex: integer): integer;

implementation

function GetSymbolByIdent(pstrIdent: PAnsiChar; iFuncIndex: integer): pSymbolNode;
var
  iCurrNode: integer;
  pCurrNode: pLinkedListNode;
  pCurrSymbol: pSymbolNode;
begin
  if (g_SymbolTable.iNodeCount = 0) then
  begin
    Result := nil;
    Exit;
  end;
  pCurrNode := g_SymbolTable.pHead;
  for iCurrNode := 0 to g_SymbolTable.iNodeCount - 1 do
  begin
    pCurrSymbol := pSymbolNode(pCurrNode.pData);
    if StrIComp(PAnsiChar(@pCurrSymbol.pstrIdent), pstrIdent) = 0 then
      if (pCurrSymbol.iFuncIndex = iFuncIndex) or (pCurrSymbol.iStackIndex >= 0) then
      begin
        Result := pCurrSymbol;
        Exit;
      end;
    pCurrNode := pCurrNode.pNext;

  end;
  Result := nil;
end;

function AddSymbol(pstrIdent: PAnsiChar; iSize: integer; iStackIndex: integer;
  iFuncIndex: integer): integer;
var
  iIndex: integer;
  pNewSymbol: pSymbolNode;
begin
  // 如果标签已经存在
  if GetSymbolByIdent(pstrIdent, iFuncIndex) <> nil then
  begin
    Result := -1;
    Exit;
  end;
  // 创建新的符号节点
  GetMem(pNewSymbol, sizeof(SymbolNode));
  // 初始化新标签
  StrCopy(@pNewSymbol.pstrIdent, pstrIdent);
  pNewSymbol.iSize := iSize;
  pNewSymbol.iStackIndex := iStackIndex;
  pNewSymbol.iFuncIndex := iFuncIndex;
  // 往表中添加符号,并取得其索引
  iIndex := AddNode(@g_SymbolTable, pNewSymbol);
  // 设置符号节点索引
  pNewSymbol.iIndex := iIndex;
  // 返回新符号的索引
  Result := iIndex;
end;

function GetStackIndexByIdent(pstrIdent: PAnsiChar; iFuncIndex: integer): integer;
var
  pSymbol: pSymbolNode;
begin
  pSymbol := GetSymbolByIdent(pstrIdent, iFuncIndex);
  Result := pSymbol.iStackIndex;
end;

function GetSizeByIdent(pstrIdent: PAnsiChar; iFuncIndex: integer): integer;
var
  pSymbol: pSymbolNode;
begin
  pSymbol := GetSymbolByIdent(pstrIdent, iFuncIndex);
  Result := pSymbol.iSize;
end;

end.
