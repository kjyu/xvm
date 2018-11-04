unit xvm_label_table;

interface

uses xvm_types, xvm_link_list, System.SysUtils;

var
  // 标签表 跳转标签
  g_LabelTable: LinkedList;

function GetLabelByIdent(pstrIdent: PAnsiChar; iFuncIndex: integer): pLabelNode;
function AddLabel(pstrIdent: PAnsiChar; iTargetIndex: integer; iFuncIndex: integer): integer;

implementation

function GetLabelByIdent(pstrIdent: PAnsiChar; iFuncIndex: integer): pLabelNode;
var
  iCurrNode: integer;
  pCurrLabel: pLabelNode;
  pCurrNode: pLinkedListNode;
begin
  // 如果表示空的返回Nil
  if g_LabelTable.iNodeCount = 0 then
  begin
    Result := nil;
    Exit;
  end;
  // 标签指针用于表的便利
  pCurrNode := g_LabelTable.pHead;
  // 遍历直至找到匹配结构
  for iCurrNode := 0 to g_LabelTable.iNodeCount - 1 do
  begin
    pCurrLabel := pLabelNode(pCurrNode.pData);
    // 如果名称和范围匹配,则返回当前指针
    if (StrIComp(PAnsiChar(@pCurrLabel.pstrIdent), pstrIdent) = 0) and
      (pCurrLabel.iFuncIndex = iFuncIndex) then
    begin
      Result := pCurrLabel;
      Exit;
    end;
    // 否则一道下一个节点
    pCurrNode := pCurrNode.pNext;
  end;
  // 没有找到返回nil
  Result := nil;
end;

function AddLabel(pstrIdent: PAnsiChar; iTargetIndex: integer; iFuncIndex: integer): integer;
var
  iIndex: integer;
  pNewLabel: pLabelNode;
begin
  // 如果标签已经存在,则返回-1
  if GetLabelByIdent(pstrIdent, iFuncIndex) <> nil then
  begin
    Result := -1;
    Exit;
  end;
  // 建立新的标签节点
  GetMem(pNewLabel, sizeof(LabelNode));
  // 初始化新标签
  StrCopy(PAnsiChar(@pNewLabel.pstrIdent), pstrIdent);
  pNewLabel.iTargetIndex := iTargetIndex;
  pNewLabel.iFuncIndex := iFuncIndex;
  // 往表中添加新标签，并获取索引
  iIndex := AddNode(@g_LabelTable, pNewLabel);
  // 设置标签节点索引
  pNewLabel.iIndex := iIndex;
  // 返回新标签索引
  Result := iIndex;
end;

end.
