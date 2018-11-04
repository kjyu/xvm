{ ******************************************************* }
{                                                         }
{ XVM                                                     }
{                                                         }
{ 版权所有 (C) 2012 adsj                                  }
{ Mode： 链接列表执行模块                                 }
{ ******************************************************* }
unit linked_list;

interface

uses System.SysUtils;

type
  // 数据链表
  pLinkedListNode = ^LinkedListNode;

  _LinkedListNode = record
    pData: Pointer; // 指向节点的数据
    pNext: pLinkedListNode; // 指向链表下一个节点
  end;

  LinkedListNode = _LinkedListNode;

  // 维护链表
  pLinkedList = ^LinkedList;

  _LinkedList = record
    pHead: pLinkedListNode; // 指向首节点
    pTail: pLinkedListNode; // 指向尾节点
    iNodeCount: Integer; // 链表中的节点个数
  end;

  LinkedList = _LinkedList;
  // 接口
  (* 初始化链表 *)
procedure InitLinkedList(pList: pLinkedList);
(* 释放链表 *)
procedure FreeLinkedList(pList: pLinkedList);
(* 插入节点 *)
function AddNode(pList: pLinkedList; pData: Pointer): Integer;
(* 删除节点 *)
procedure DelNode(pList: pLinkedList; pNode: pLinkedListNode);
(* 插入字符串节点 *)
function AddString(pList: pLinkedList; pstrString: PAnsiChar): Integer;
(* 查找字符串节点 *)
function GetStringByIndex(pList: pLinkedList; iIndex: Integer): PAnsiChar;

implementation

procedure InitLinkedList(pList: pLinkedList);
begin
  pList.pHead := nil;
  pList.pTail := nil;
  pList.iNodeCount := 0;
end;

procedure FreeLinkedList(pList: pLinkedList);
var
  pCurrNode: pLinkedListNode;
  pNextNode: pLinkedListNode;
begin
  if not Assigned(pList) then
    Exit;
  if pList.iNodeCount > 0 then
  begin
    pCurrNode := pList.pHead;
    while True do
    begin
      pNextNode := pCurrNode.pNext;
      // free data
      if pCurrNode.pData <> nil then
        FreeMem(pCurrNode.pData);
      // free itself
      if pCurrNode <> nil then
        FreeMem(pCurrNode);
      if pNextNode <> nil then
        pCurrNode := pNextNode
      else
        Break;
    end;
  end;
end;

function AddNode(pList: pLinkedList; pData: Pointer): Integer;
var
  pNewNode: pLinkedListNode;
begin
  GetMem(pNewNode, SizeOf(LinkedListNode));
  pNewNode.pData := pData;
  pNewNode.pNext := nil;
  if pList.iNodeCount = 0 then
  begin
    pList.pHead := pNewNode;
    pList.pTail := pNewNode;
  end
  else
  begin
    pList.pTail.pNext := pNewNode;
    pList.pTail := pNewNode;
  end;
  Result := pList.iNodeCount;
  Inc(pList.iNodeCount);
end;

procedure DelNode(pList: pLinkedList; pNode: pLinkedListNode);

var
  pTravNode: pLinkedListNode;
  iCurrNode: Integer;
begin
  if pList.iNodeCount = 0 then
    Exit;
  if pNode = pList.pHead then
  begin
    pList.pHead := pNode.pNext;
  end
  else
  begin
    pTravNode := pList.pHead;
    for iCurrNode := 0 to pList.iNodeCount - 1 do
    begin
      if pTravNode.pNext = pNode then
      begin
        if pList.pTail = pNode then
        begin
          pTravNode.pNext := nil;
          pList.pTail := pTravNode;
        end
        else
        begin
          pTravNode.pNext := pNode.pNext;
        end;
        Break;
      end;
      pTravNode := pTravNode.pNext;
    end;
  end;
  Dec(pList.iNodeCount);
  if pNode.pData <> nil then
    FreeMem(pNode.pData);
  FreeMem(pNode);
end;

function AddString(pList: pLinkedList; pstrString: PAnsiChar): Integer;
var
  pNode: pLinkedListNode;
  iCurrNode: Integer;
  pstrStringNode: PAnsiChar;
begin
  pNode := pList.pHead;
  for iCurrNode := 0 to pList.iNodeCount - 1 do
  begin
    if StrComp(PAnsiChar(pNode.pData), pstrString) = 0 then
    begin
      Result := iCurrNode;
      Exit;
    end;
    pNode := pNode.pNext;
  end;
  GetMem(pstrStringNode, StrLen(pstrString) + 1);
  StrCopy(pstrStringNode, pstrString);
  Result := AddNode(pList, pstrStringNode);
end;

function GetStringByIndex(pList: pLinkedList; iIndex: Integer): PAnsiChar;
var
  pNode: pLinkedListNode;
  iCurrNode: Integer;
begin
  pNode := pList.pHead;
  for iCurrNode := 0 to pList.iNodeCount - 1 do
  begin
    if iIndex = iCurrNode then
    begin
      Result := PAnsiChar(pNode.pData);
      Exit;
    end;
    pNode := pNode.pNext;
  end;
  Result := nil;
end;

end.
