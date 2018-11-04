unit XtremeScript;

interface

{$I xsc.inc}

uses
  System.SysUtils, System.Classes, globals, linked_list, stacks, symbol_table, lexer, i_code,
  script_header, func_table, parser;
// ---- Function Prototypes
procedure PrintLogo();
procedure PrintUsage();

procedure VerifyFilenames();
procedure ReadCmmndLineParams();

procedure Init();
procedure ShutDown();

procedure LoadSourceFile();
(* 编译分析源程序 *)
procedure CompileSourceFile();
(* 打印编译统计数据 *)
procedure PrintCompiletats();
(* 生成最终可执行文件 *)
procedure AssmblOutputFile();

procedure XExit();

implementation

procedure PrintLogo();
begin
  Writeln('XSC');
  Writeln(Format('XtremeScript Compiler Version %d.%d', [VERSION_MAJOR, VERSION_MINOR]));
  Writeln('Written by Alex Varanese [C] andj [P]');
  Writeln;
end;

procedure PrintUsage();
begin
  Writeln('Usage: XSC Source.XSS [Output.XASM] [Options]');
  Writeln;
  Writeln('    - S:Size Sets the stack Size(must be decimal integer value)\ n ');
  Writeln('    - P:Priority Sets the thread Priority: Low, Med, High or timeslice \ n ');
  Writeln('    duration(must be decimal integer value) ');
  Writeln('    - A Preserve assembly output file');
  Writeln('    - n Don ''t generate .XSE (preserves assembly output file)');
  Writeln;
  Writeln(' Notes:');
  Writeln('    - File extensions are not required.');
  Writeln('    - Executable name is optional; source name is used by default');
  Writeln;
end;

procedure VerifyFilenames();
begin

end;

procedure ReadCmmndLineParams();
begin

end;

procedure Init();
begin
  g_ScriptHeader.iIsMainFuncPresent := 0;
  g_ScriptHeader.iStackSize := 0;
  g_ScriptHeader.iPriorityType := PRIORITY_NONE;
  // 初始化主要设置
  // 标记汇编文件删除
  g_iPreserveOutputFile := 0;
  // 生成.XSE
  g_iGenerateXSE := 1;
  // 初始化源代码列表
  InitLinkedList(@g_SourceCode);
  // 初始化表格
  InitLinkedList(@g_FuncTable);
  InitLinkedList(@g_SymbolTable);
  InitLinkedList(@g_StringTable);
end;

procedure ShutDown();
begin
  // 释放源代码
  FreeLinkedList(@g_SourceCode);
  // 释放表格
  FreeLinkedList(@g_FuncTable);
  FreeLinkedList(@g_SymbolTable);
  FreeLinkedList(@g_StringTable);
end;

procedure LoadSourceFile();
var
  sl: TstringList;
  I: Integer;
  pstrCurrLine: PAnsiChar;
begin
  sl := TstringList.Create;
  try
    sl.LoadFromFile(g_pstrSourceFileName);
    for I := 0 to sl.Count - 1 do
    begin
      GetMem(pstrCurrLine, Length(sl[I]) + 1);
      pstrCurrLine[0] := #0;
      StrCopy(pstrCurrLine, PAnsiChar(AnsiString(sl[I])));
      AddNode(@g_SourceCode, pstrCurrLine);
    end;
  finally
    sl.Free;
  end;
end;

procedure CompileSourceFile();
var
  iMainIndex: Integer;
  iXIndex: Integer;
  iYIndex: Integer;
  iMyGlobalIndex: Integer;
  pstrLine0: PAnsiChar;
  pstrLine1: PAnsiChar;
  pstrLine2: PAnsiChar;
  iInstrIndex: Integer;
begin
  // // ---------------
  // iMainIndex := AddFunc('_Main', 0);
  // iMyGlobalIndex := AddSymbol('MyGlobal', 1, SCOPE_GLOBAL, SYMBOL_TYPE_VAR);
  // iXIndex := AddSymbol('x', 1, iMainIndex, SYMBOL_TYPE_VAR);
  // iYIndex := AddSymbol('y', 4, iMainIndex, SYMBOL_TYPE_VAR);
  //
  // GetMem(pstrLine0, max_source_line_size);
  // StrCopy(pstrLine0, 'MyGlobal = 2');
  // GetMem(pstrLine1, max_source_line_size);
  // StrCopy(pstrLine1, 'x = 8');
  // GetMem(pstrLine2, max_source_line_size);
  // StrCopy(pstrLine2, 'Y[1] = MyGlobal ^ x');
  //
  // // MyGlobal = 2
  // AddICodeSourceLine(iMainIndex, pstrLine0);
  // iInstrIndex := AddICodeInstr(iMainIndex, INSTR_MOV);
  // AddVarICodeOp(iMainIndex, iInstrIndex, iMyGlobalIndex);
  // AddIntICodeOp(iMainIndex, iInstrIndex, 2);
  //
  // // x = 8
  // AddICodeSourceLine(iMainIndex, pstrLine1);
  // iInstrIndex := AddICodeInstr(iMainIndex, INSTR_MOV);
  // AddVarICodeOp(iMainIndex, iInstrIndex, iXIndex);
  // AddIntICodeOp(iMainIndex, iInstrIndex, 8);
  // // y[1] = myglobal ^ x
  // AddICodeSourceLine(iMainIndex, pstrLine2);
  // iInstrIndex := AddICodeInstr(iMainIndex, INSTR_EXP);
  // AddVarICodeOp(iMainIndex, iInstrIndex, iMyGlobalIndex);
  // AddVarICodeOp(iMainIndex, iInstrIndex, iXIndex);
  //
  // iInstrIndex := AddICodeInstr(iMainIndex, INSTR_MOV);
  // AddArrayIndexABSICodeOp(iMainIndex, iInstrIndex, iYIndex, 1);
  // AddVarICodeOp(iMainIndex, iInstrIndex, iMyGlobalIndex);
  g_iTempVar0SymbolIndex := AddSymbol(TEMP_VAR_0, 1, SCOPE_GLOBAL, SYMBOL_TYPE_VAR);
  g_iTempVar1SymbolIndex := AddSymbol(TEMP_VAR_1, 1, SCOPE_GLOBAL, SYMBOL_TYPE_VAR);
  // ---------------
  // 分析源文件以创建中间代码表示representation
  ParseSourceCode();
end;

procedure PrintCompiletats();
begin

end;

procedure AssmblOutputFile();
var
  ppstrCmmndLineParams: array [0 .. 2] of PAnsiChar;
begin
  // 传递给XASM的命令行参数
  // 将第一个参数设置为'XASM'
  GetMem(ppstrCmmndLineParams[0], Length('XASM') + 1);
  StrCopy(ppstrCmmndLineParams[0], 'XASM');
  // 将.XASM文件名称复制到第二个参数
  GetMem(ppstrCmmndLineParams[1], StrLen(g_pstrOutPutFileName));
  // 将第三个参数设置为nil
  ppstrCmmndLineParams[2] := nil;
  // 调用汇编器
  // spawnv(P_WAIT,'XASM.exe',ppstrCmmndLineParams);
  // 释放命令行参数
  FreeMem(ppstrCmmndLineParams[0]);
  FreeMem(ppstrCmmndLineParams[1]);
end;

procedure XExit();
begin
  ShutDown();
  Halt(0);
end;

end.
