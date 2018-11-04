{ ******************************************************* }
{                                                         }
{ XVM                                                     }
{                                                         }
{ 版权所有 (C) 2012 adsj                                  }
{ Mode： 链表                                             }
{ ******************************************************* }
unit xvm_link_list;

interface

uses System.SysUtils;

type

  pLinkedListNode = ^_LinkedListNode;

  _LinkedListNode = record
    pData: Pointer;
    pNext: pLinkedListNode;
  end;

  LinkedListNode = _LinkedListNode;

  _LinkedList = record
    pHead: pLinkedListNode;
    pTail: pLinkedListNode;
    iNodeCount: integer;
  end;

  pLinkedList = ^_LinkedList;
  LinkedList = _LinkedList;

procedure InitLinkedList(pList: pLinkedList);
procedure FreeLinkeList(pList: pLinkedList);
function AddNode(pList: pLinkedList; pData: Pointer): integer;
function Addstring(pList: pLinkedList; pstrString: PAnsiChar): integer;

implementation

procedure InitLinkedList(pList: pLinkedList);
begin
  pList.pHead := nil;
  pList.pTail := nil;
  pList.iNodeCount := 0;
end;

procedure FreeLinkeList(pList: pLinkedList);
var
  pCurrNode: pLinkedListNode;
  pNextNode: pLinkedListNode;
begin
  if pList = nil then
    Exit;

  if pList.iNodeCount > 0 then
  begin
    pCurrNode := pList.pHead;
    while True do
    begin
      pNextNode := pCurrNode.pNext;
      if pCurrNode.pData <> nil then
        FreeMem(pCurrNode.pData, sizeof(pCurrNode.pData));
      if pCurrNode <> nil then
        FreeMem(pCurrNode, sizeof(pCurrNode));

      if pNextNode <> nil then
        pCurrNode := pNextNode
      else
        Break;
    end;
  end;
end;

function AddNode(pList: pLinkedList; pData: Pointer): integer;
var
  pNewNode: pLinkedListNode;
begin
  GetMem(pNewNode, sizeof(LinkedListNode));
  pNewNode.pData := pData;
  pNewNode.pNext := nil;
  if (pList.iNodeCount = 0) then
  begin
    pList.pHead := pNewNode;
    pList.pTail := pNewNode;
  end
  else
  begin
    pList.pTail.pNext := pNewNode;
    pList.pTail := pNewNode;
  end;
  pList.iNodeCount := pList.iNodeCount + 1;
  Result := pList.iNodeCount - 1;
end;

function Addstring(pList: pLinkedList; pstrString: PAnsiChar): integer;
var
  iCurrNode: integer;
  pstrStringNode: PAnsiChar;
  pNode: pLinkedListNode;
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

end.
