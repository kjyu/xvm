{ ******************************************************* }
{                                                         }
{ XVM                                                     }
{                                                         }
{ 版权所有 (C) 2012 adsj                                  }
{ Mode： 预处理模块                                       }
{ ******************************************************* }
unit preprocessor;

interface

uses
  System.SysUtils, linked_list, globals;
(* 预处理 状态机模式 *)
procedure PreprocessSourceFile();

implementation

procedure PreprocessSourceFile();
var
  iInBlockComment: Boolean; // is in the /**/
  iInString: Boolean;
  pNode: pLinkedListNode;
  pstrCurrLine: PAnsiChar;
  iCurrCharIndex: Integer;
begin
  iInBlockComment := False;
  iInString := False;
  pNode := g_SourceCode.pHead;
  while True do
  begin
    pstrCurrLine := PAnsiChar(pNode.pData);
    { TODO -oadsj -c预处理 : 没有检查下标，可能会越界 }
    for iCurrCharIndex := 0 to StrLen(pstrCurrLine) - 1 do
    begin
      if pstrCurrLine[iCurrCharIndex] = '"' then
      begin
        iInString := not iInString;
      end;
      if //
        (pstrCurrLine[iCurrCharIndex] = '/') and //
        (pstrCurrLine[iCurrCharIndex + 1] = '/') and //
        (not iInString) and //
        (not iInBlockComment) then
      begin
        pstrCurrLine[iCurrCharIndex] := #10;
        pstrCurrLine[iCurrCharIndex + 1] := #0;
        Break;
      end;
      // 检查块注释
      if //
        (pstrCurrLine[iCurrCharIndex] = '/') and //
        (pstrCurrLine[iCurrCharIndex + 1] = '*') and //
        (not iInString) and //
        (not iInBlockComment) //
      then
      begin
        iInBlockComment := True;
      end;
      // 查找块注释结尾
      if //
        (pstrCurrLine[iCurrCharIndex] = '*') and //
        (pstrCurrLine[iCurrCharIndex + 1] = '/') and //
        (iInBlockComment) //
      then
      begin
        pstrCurrLine[iCurrCharIndex] := ' ';
        pstrCurrLine[iCurrCharIndex + 1] := ' ';
        iInBlockComment := False;
      end;
      if iInBlockComment then
      begin
        if pstrCurrLine[iCurrCharIndex] <> #10 then
          pstrCurrLine[iCurrCharIndex] := ' ';
      end;
    end;

    pNode := pNode.pNext;
    if pNode = nil then
      Break;
  end;
end;

end.
