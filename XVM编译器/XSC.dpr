program XSC;

{$APPTYPE CONSOLE}
{$R *.res}

uses
 // FastMM4,FastMM4Messages,
  System.SysUtils,
  XtremeScript in 'XtremeScript.pas',
  linked_list in 'linked_list.pas',
  stacks in 'stacks.pas',
  globals in 'globals.pas',
  errors in 'errors.pas',
  code_emnit in 'code_emnit.pas',
  func_table in 'func_table.pas',
  i_code in 'i_code.pas',
  lexer in 'lexer.pas',
  preprocessor in 'preprocessor.pas',
  symbol_table in 'symbol_table.pas',
  parser in 'parser.pas',
  script_header in 'script_header.pas',
  string_table in 'string_table.pas';

begin
  try
    PrintLogo();
    //
    StrCopy(@g_pstrSourceFileName,AnsiString( 'C:\1.txt' ));
    Writeln(Format('Comliling %s...', [g_pstrSourceFileName]));
    //载入源文件
    LoadSourceFile();
    //预处理源文件
    PreprocessSourceFile();
    //编译源文件
    CompileSourceFile();
    //生成中间代码
    EmitCode();
    //打印编译期信息
    PrintCompiletats();

    ShutDown();

//    if g_iGenerateXSE <> 0 then
//      AssmblOutputFile();
//
//    if g_iPreserveOutputFile = 0 then
//      RemoveDir(g_pstrOutPutFileName);
    { TODO -oUser -cConsole Main : Insert code here }
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
