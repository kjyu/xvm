{ ******************************************************* }
{                                                         }
{ XVM                                                     }
{                                                         }
{ 版权所有 (C) 2012 adsj                                  }
{ Mode： 错误处理模块                                     }
{ ******************************************************* }
unit errors;

interface

uses
  System.SysUtils, globals;
(* 打印普通错误 *)
procedure ExitOnError(pstrErrorMssg: PAnsiChar);
(* 打印代码错误 *)
// procedure ExitOnCodeError(pstrErrorMssg: PAnsiChar);
procedure ExitOnCodeError(iSourceLine: Integer; pstrCurrSourceLine: PAnsiChar;
  iLexemeStartIndex: Integer; pstrErrorMssg: PAnsiChar);

implementation

procedure ExitOnError(pstrErrorMssg: PAnsiChar);
begin
  Writeln(Format('Fatal Error: %s.', [pstrErrorMssg]));
  Readln;
  Halt(0);
end;

procedure ExitOnCodeError(iSourceLine: Integer; pstrCurrSourceLine: PAnsiChar;
  iLexemeStartIndex: Integer; pstrErrorMssg: PAnsiChar);
var
  pstrSourceLine: PAnsiChar;
  iLastCharIndex: Integer;
  iCurrCharIndex: Integer;
  iCurrSpace: Integer;
begin
  { TODO -oadsj -c打印错误 : 暂时传递全部错误参数， }
  // 打印信息
  Writeln(Format('Error: %s.', [pstrErrorMssg]));
  Writeln(Format('Line %d', [iSourceLine])); // GetCurrSourceLineIndex()
  // 将源代码中的所有空白换为tab
  // 错误位置
  if pstrCurrSourceLine <> nil then
  begin
    GetMem(pstrSourceLine, StrLen(pstrCurrSourceLine) + 1);
    StrCopy(pstrSourceLine, pstrCurrSourceLine);
  end
  else
  begin
    GetMem(pstrSourceLine, 1);
    pstrSourceLine[0] := #0;
  end;
  // 如果该行的最后一个字符是断行标记，就把这个标记去掉
  iLastCharIndex := StrLen(pstrSourceLine) - 1;
  if pstrSourceLine[iLastCharIndex] = #10 then
    pstrSourceLine[iLastCharIndex] := #0;
  // 检查每个字符并用空格替换TAB
  for iCurrCharIndex := 0 to StrLen(pstrSourceLine) - 1 do
  begin
    if pstrSourceLine[iCurrCharIndex] = #9 then
      pstrSourceLine[iCurrCharIndex] := ' ';
  end;
  // 打印出错的源代码行
  Writeln(pstrSourceLine);
  // 在出错的但此前面打印一个^
  for iCurrSpace := 0 to iLexemeStartIndex - 1 do
    Write(' ');
  Writeln('^');
  // 打印信息表明源代码不能被转换为汇编
  Writeln(Format('Could not compile %s.', [g_pstrSourceFileName]));
  Readln;
  Halt(0);
end;

end.
