program XASM08;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Winapi.Windows,
  XASMUnit in 'XASMUnit.pas',
  xvm_link_list in 'xvm_link_list.pas',
  xvm_errors in 'xvm_errors.pas',
  xvm_globals in 'xvm_globals.pas',
  xvm_types in 'xvm_types.pas',
  xvm_lexer in 'xvm_lexer.pas',
  xvm_func_table in 'xvm_func_table.pas',
  xvm_symbol_table in 'xvm_symbol_table.pas',
  xvm_label_table in 'xvm_label_table.pas',
  xvm_instr in 'xvm_instr.pas';

var
  btime: Cardinal;
  etime: Cardinal;

begin
  ReportMemoryLeaksOnShutdown := True;
  try
    PrintLogo;
    Writeln(Format('%15s', ['ParamCount:']), ParamCount);
    // 参数
    if ParamCount < 1 then
    begin
      PrintUsage;
      Exit;
    end;
    // 文件
    g_pstrSourceFilename :=AnsiString( ParamStr(1) );
    g_pstrExecFilename := ParamStr(2);
    Writeln(Format('%15s', ['SourceFile:']), g_pstrSourceFilename);
    Writeln(Format('%15s', ['ExeFile:']), g_pstrExecFilename);
    if not FileExists(g_pstrSourceFilename) then
    begin
      Writeln('The SourceFile file was not find');
      Exit;
    end;
    //
    btime := GetTickCount;
    Init();
    LoadSourceFile();
    Writeln(Format('Assembling %s...', [g_pstrSourceFilename]));
    Writeln;
    AssmblSourceFile();
    Writeln(Format('Building %s...', [g_pstrExecFilename]));
    Writeln;
    BuildXSE();
    PrintAssmblStats();
    ShutDown();
    etime := GetTickCount;
    Writeln(Format('use time %d ms', [etime - btime]));
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Readln;

end.
