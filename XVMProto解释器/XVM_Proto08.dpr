{
 XS_RegisterHostAPIFunc(XS_GLOBAL_FUNC, 'PrintString', HAPI_PrintString);
 XS_StartScript(iThreadIndex);
 writeln('Calling DoStuff () asynchronously:');
 XS_CallScriptFunc(iThreadIndex, '_Main');
 // get the return value and print it
 fPi := XS_GetReturnValueAsFloat(iThreadIndex);
 writeln(Format('Return value received from script: %.2f', [fPi]));
 // invoke a function and run the host alongside it
 writeln('Invoking InvokeLoop () (Press any key to stop):');
 Readln;
 XS_InvokeScriptFunc(iThreadIndex, 'InvokeLoop');
 //
 while not KeyPressed do
 begin
 XS_RunScripts(50);
 end;

 XS_ShutDown();
}
program XVM_Proto08;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  // FastMM4, FastMM4Messages,
  System.SysUtils,
  XVMProtoUnit in 'XVMProtoUnit.pas',
  XVMHead in 'XVMHead.pas',
  CommFunc in 'CommFunc.pas';

var
  iThread: Integer;

procedure HAPI_PrintString(iThreadIndex: Integer);
var
  pstrString: PAnsiChar;
  iCount: Integer;
  iCurrString: Integer;
begin
  pstrString := XS_GetParamAsString(iThreadIndex, 0);
  iCount := XS_GetParamAsInt(iThreadIndex, 1);
  for iCurrString := 0 to iCount - 1 do
    writeln(pstrString);
  XS_ReturnStringFromHost(iThreadIndex, 2, 'This is a return value.');
end;

procedure RunWithParam();
var
  pstrExecFile: AnsiString;
  iThreadIndex: Integer;
  iErrorCode: Integer;
  iThreadTimeslice: Integer;
  fPi: Single;
begin
  PrintLogo;
  // writeln(Format('%15s', ['ParamCount:']), ParamCount);
  // // 参数
  // if ParamCount < 1 then
  // begin
  // writeln('Usage:'#9'XVMPROTO Script.XSE');
  // writeln;
  // writeln(#9'- File extensions are not required.');
  // Exit;
  // end;
  // // 文件
  // pstrExecFile := ParamStr(1);
  // writeln(Format('%15s', ['ExeFile:']), pstrExecFile);
  // if not FileExists(pstrExecFile) then
  // begin
  // writeln('The exec file was not find');
  // Exit;
  // end;
  XS_Init();
  iThreadTimeslice := XS_THREAD_PRIORITY_USER;
  iErrorCode := XS_LoadScript('script.XSE', iThreadIndex, iThreadTimeslice);
  if iErrorCode <> XS_LOAD_OK then
  begin
    write(Format('%15s', ['Error:']));
    case iErrorCode of
      XS_LOAD_ERROR_FILE_IO:
        writeln('File I/O error.');
      XS_LOAD_ERROR_INVALID_XSE:
        writeln('.XSE structure invalid.');
      XS_LOAD_ERROR_UNSUPPORTED_VERS:
        writeln('Unsupported .XSE format version.');
    end;
    Exit;
  end
  else
  begin
    writeln('Script load successfully.' + pstrExecFile);
  end;
  XS_RegisterHostAPIFunc(XS_GLOBAL_FUNC, 'PrintString', HAPI_PrintString);
  XS_StartScript(iThreadIndex);
  writeln('_Main');
  XS_CallScriptFunc(iThreadIndex, '_Main');
end;

begin
  // ReportMemoryLeaksOnShutdown := True;
  RunWithParam();
  Readln;

end.
