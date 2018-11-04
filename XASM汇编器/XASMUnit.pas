unit XASMUnit;

interface

uses
  System.SysUtils, System.Classes,
  xvm_lexer, xvm_types, xvm_link_list, xvm_func_table,
  xvm_instr, xvm_label_table, xvm_symbol_table, xvm_errors;

const
  // -------------------------------------文件名--------------------------------------------------//
  MAX_FILENAME_SIZE = 2048;

  SOURCE_FILE_EXT = '.XASM';
  EXEC_FILE_EXT = '.XSE';

  // -------------------------------------源代码--------------------------------------------------//
  MAX_SOURCE_CODE_SIZE = 65536;

  MAX_SOURCE_LINE_SIZE = 4096;

  // -------------------------------------.XSE文件头----------------------------------------------//

  XSE_ID_STRING = 'XSE0';

  VERSION_MAJOR = 0;
  VERSION_MINOR = 8;

  // -----Global Variables------
var
  g_pSourceFile: file;
  // 源文件名
  g_pstrSourceFilename: AnsiString;
  // 目标文件名
  g_pstrExecFilename: AnsiString;
  // 脚本头
  g_ScriptHeader: ScriptHeader;
  // 是否已经设置堆栈大小
  g_bIsSetStackSizeFound: Boolean;
  // 是否已经设置优先级
  g_bIsSetPriorityFound: Boolean;
  // 字符串表
  g_StringTable: LinkedList;
  // HostAPI 表
  g_HostAPICallTable: LinkedList;
  // ---Misc
procedure PrintLogo();
procedure PrintUsage();

procedure Init();
procedure ShutDown();

procedure LoadSourceFile();
procedure AssmblSourceFile();
procedure PrintAssmblStats();
procedure BuildXSE();

procedure MyExit();
procedure ExitOnCodeError(pstrErrorMssg: PAnsiChar);
procedure ExitOnCharExpectedError(cChar: AnsiChar);

implementation

{$REGION '字符处理函数'}

// 去除注释等无用信息
procedure StripStrComments(var strSourceLine: AnsiString);
var
  i: integer;
  bInStr: Boolean;
begin
  bInStr := False;
  if Trim(strSourceLine) = '' then
  begin
    strSourceLine := '';
    Exit;
  end;

  for i := 1 to Length(strSourceLine) do
  begin
    if strSourceLine[i] = '"' then
    begin
      bInStr := not bInStr;
    end;

    if strSourceLine[i] = ';' then
    begin
      if not bInStr then
      begin
        strSourceLine := Trim(Copy(strSourceLine, 1, i - 1));
        Exit;
      end;
    end;
  end;
end;

{$ENDREGION}
{$REGION '杂项'}

// ---------------------MISC
procedure PrintLogo();
begin
  Writeln('XASM');
  Writeln(Format('StremeScript Assembler Version %d.%d', [VERSION_MAJOR, VERSION_MINOR]));
  Writeln('Written by Alex Varanese [C] .adsj [P]');
  Writeln;
end;

procedure PrintUsage();
begin
  Write('Usage:');
  Writeln('XASM Source.XASM [Executable.XSE]');
  Writeln;
  Writeln('      -File extensions are not required.');
  Writeln('      -Executable name is optional; source name is used by default.');
end;
{$ENDREGION}

procedure Init();
begin
  InitInstrTable();
  InitLinkedList(@g_SymbolTable);
  InitLinkedList(@g_LabelTable);
  InitLinkedList(@g_FuncTable);
  InitLinkedList(@g_StringTable);
  InitLinkedList(@g_HostAPICallTable);
end;

procedure ShutDown();
var
  iCurrLineIndex: integer;
  iCurrInstrIndex: integer;
begin
  // free each source line individually
  for iCurrLineIndex := 0 to g_iSourceCodeSize - 1 do
  begin
    inc(g_ppstrSourceCode, iCurrLineIndex);
    FreeMem(g_ppstrSourceCode^);
    Dec(g_ppstrSourceCode, iCurrLineIndex);
  end;

  FreeMem(g_ppstrSourceCode);
  //
  // free the assembled instruction stream
  if g_pInstrStream <> nil then
  begin
    for iCurrInstrIndex := 0 to g_iInstrStreamSize - 1 do
    begin
      inc(g_pInstrStream, iCurrInstrIndex);
      if (g_pInstrStream^.pOpList <> nil) then
        FreeMem(g_pInstrStream^.pOpList);
      Dec(g_pInstrStream, iCurrInstrIndex);
    end;
    FreeMem(g_pInstrStream);
  end;
  // ----Free the tables
  FreeLinkeList(@g_SymbolTable);
  FreeLinkeList(@g_LabelTable);
  FreeLinkeList(@g_FuncTable);
  FreeLinkeList(@g_StringTable);
  FreeLinkeList(@g_HostAPICallTable);
  // free instrTable
  for iCurrInstrIndex := 0 to Length(g_InstrTable) - 1 do
  begin
    if g_InstrTable[iCurrInstrIndex].OpList <> nil then
      FreeMem(g_InstrTable[iCurrInstrIndex].OpList);
  end;
end;

procedure LoadSourceFile();
var
  iIndex: integer;
  g_SourceCode: TStringList;
  tmpstr: AnsiString;
begin
  if not FileExists(g_pstrSourceFilename) then
  begin
    ExitOnError('Could not open source file');
    Exit;
  end;

  g_SourceCode := TStringList.Create;
  try
    g_SourceCode.LoadFromFile(g_pstrSourceFilename);
    g_iSourceLines := g_SourceCode.Count;
    // 处理字符串,取出注释及空白字符
    for iIndex := g_SourceCode.Count - 1 downto 0 do
    begin
      tmpstr := Trim(g_SourceCode[iIndex]);
      StripStrComments(tmpstr);
      if tmpstr = '' then
        g_SourceCode.Delete(iIndex)
      else
        g_SourceCode[iIndex] := tmpstr;
    end;

    g_iSourceCodeSize := g_SourceCode.Count;
    GetMem(g_ppstrSourceCode, sizeof(PAnsiChar) * g_iSourceCodeSize);
    for iIndex := 0 to g_iSourceCodeSize - 1 do
    begin
      inc(g_ppstrSourceCode, iIndex);
      GetMem(g_ppstrSourceCode^, Length(g_SourceCode[iIndex] + #10 + #0));
      StrCopy(g_ppstrSourceCode^, PAnsiChar(AnsiString(g_SourceCode[iIndex] + #10 + #0)));
      Dec(g_ppstrSourceCode, iIndex);
    end;
  finally
    g_SourceCode.Free;
  end;
end;

{$REGION '汇编源代码'}

procedure AssmblSourceFile();
var
  iIsFuncActive: Boolean;
  pCurrFunc: pFuncNode;
  iCurrFuncIndex: integer;
  pstrCurrFuncName: array [0 .. MAX_IDENT_SIZE - 1] of AnsiChar; //
  iCurrFuncParamCount: integer;
  iCurrFuncLocalDataSize: integer;
  CurrInstr: InstrLookup;
  //
  pstrIdent: array [0 .. MAX_IDENT_SIZE - 1] of AnsiChar; //
  iSize: integer;
  iStackIndex: integer;
  //
  pstrFuncName: PAnsiChar;
  iEntryPoint: integer;
  iFuncIndex: integer;
  //
  iTargetIndex: integer;
  //
  iCurrInstrIndex: integer;

  //
  iCurrOpIndex: integer;
  CurrOpTypes: OpType;
  pOpList: pOP;
  InitOpToken: Token;
  //
  pstrString: PAnsiChar;
  iStringIndex: integer;
  //
  iBaseIndex: integer;
  IndexToken: Token;
  iOffsetIndex: integer;
  pstrIndexIdent: PAnsiChar;
  //
  pstrLabelIdent: PAnsiChar;
  pLabel: pLabelNode;
  //
  pFunc: pFuncNode;
  //
  pstrHostAPICall: PAnsiChar;
  iIndex: integer;
  //
  AToken: Token;
begin
  // initlize the script header
  g_ScriptHeader.iStackSize := 0;
  g_ScriptHeader.iIsMainFuncPresent := 0; // false
  // set some initial variables
  g_iInstrStreamSize := 0;
  g_bIsSetStackSizeFound := False;
  g_bIsSetPriorityFound := False;
  g_ScriptHeader.iGlobalDataSize := 0;
  // set the current function's flags and variables
  iCurrFuncParamCount := 0;
  iCurrFuncLocalDataSize := 0;
  iIsFuncActive := False;
  // create an instruction definition structure to hold instruction infomation when deling with instructions/
  // ---perform first pass over the source
  // rest the lexer
  ResetLexer();

  while True do
  begin
    // get the next token and make sure we aren't at the  end of the stream
    if (GetNextToken = END_OF_TOKEN_STREAM) then
      Break;
    case g_Lexer.CurrToken of
      // setstacksize
      TOKEN_TYPE_SETSTACKSIZE:
        begin
          // 堆栈大小只允许在全局中设置一次
          if iIsFuncActive then
            ExitOnCodeError(ERROR_MSSG_LOCAL_SETSTACKSIZE);
          if (g_bIsSetStackSizeFound) then
            ExitOnCodeError(ERROR_MSSG_INVALID_STACK_SIZE);
          if (GetNextToken <> TOKEN_TYPE_INT) then
            ExitOnCodeError(ERROR_MSSG_INVALID_STACK_SIZE);

          g_ScriptHeader.iStackSize := StrToInt(GetCurrLexeme);

          g_bIsSetStackSizeFound := True;
        end;
      TOKEN_TYPE_SETPRIORITY:
        begin
          // 只能在全局中设置优先级
          if (iIsFuncActive) then
            ExitOnCodeError(ERROR_MSSG_LOCAL_SETPRIORITY);
          // 只能设置一次优先级
          if g_bIsSetPriorityFound then
            ExitOnCodeError(ERROR_MSSG_MULTIPLE_SETPRIORITY);
          // 判断参数类型
          GetNextToken();
          case (g_Lexer.CurrToken) of
            TOKEN_TYPE_INT:
              begin
                g_ScriptHeader.iUserPriorty := StrToInt(GetCurrLexeme);
                g_ScriptHeader.iPriorityType := PRIORITY_USER;
              end;
            TOKEN_TYPE_IDENT:
              begin
                if StrIComp(PAnsiChar(@g_Lexer.pstrCurrLexeme[0]), PRIORITY_LOW_KEYWORD) = 0 then
                begin
                  g_ScriptHeader.iPriorityType := PRIORITY_LOW;
                end
                else if StrIComp(PAnsiChar(@g_Lexer.pstrCurrLexeme[0]), PRIORITY_MED_KEYWORD) = 0
                then
                begin
                  g_ScriptHeader.iPriorityType := PRIORITY_MED;
                end
                else if StrIComp(PAnsiChar(@g_Lexer.pstrCurrLexeme[0]), PRIORITY_HIGH_KEYWORD) = 0
                then
                begin
                  g_ScriptHeader.iPriorityType := PRIORITY_HIGH;
                end
                else
                begin
                  ExitOnCodeError(ERROR_MSSG_INVALID_PRIORITY);
                end;
              end;
          else
            ExitOnCodeError(ERROR_MSSG_INVALID_PRIORITY);
          end;
          g_bIsSetPriorityFound := True;
        end;
      // VAR VAR[]
      TOKEN_TYPE_VAR:
        begin
          // 获取变量标识符
          if (GetNextToken <> TOKEN_TYPE_IDENT) then
            ExitOnCodeError(ERROR_MSSG_IDENT_EXPECTED);

          StrCopy(PAnsiChar(@pstrIdent), GetCurrLexeme);
          // 现在通过检查它是否是数组从而判定它的大小，否则默认为1
          iSize := 1;
          // 检查前面是否有左中括号
          if (GetLookAheadChar = '[') then
          begin
            // 确认左中括号
            if (GetNextToken <> TOKEN_TYPE_OPEN_BRACKET) then
              ExitOnCharExpectedError('[');
            // 因为我们在分析数组，故下一个单词描述数组大小的整数
            if (GetNextToken <> TOKEN_TYPE_INT) then
              ExitOnCodeError(ERROR_MSSG_INVALID_ARRAY_SIZE);
            // 转换为整数值
            iSize := StrToInt(GetCurrLexeme);
            // 确保大小合法,大于0
            if iSize <= 0 then
              ExitOnCodeError(ERROR_MSSG_INVALID_ARRAY_SIZE);
            // 确保右中括号的合法
            if (GetNextToken <> TOKEN_TYPE_CLOSE_BRACKET) then
              ExitOnCharExpectedError(']');
          end;
          // 决定变量在堆栈中的索引
          // 如果是局部变量，那么它的堆栈索引通常是
          // 用0减去局部变量数据大小+2
          if iIsFuncActive then
          begin
            iStackIndex := -(iCurrFuncLocalDataSize + 2);
          end
          // 如果是全局变量，所以它相当于目前全局数据的个数
          else
          begin
            iStackIndex := g_ScriptHeader.iGlobalDataSize;
          end;
          // 尝试把它加入符号表
          if (AddSymbol(PAnsiChar(@pstrIdent), iSize, iStackIndex, iCurrFuncIndex) = -1) then
          begin
            ExitOnCodeError(ERROR_MSSG_IDENT_REDEFINITION);
          end;
          // 根据作用域，通过变量大小增大全局变量或局部变量的大小
          if iIsFuncActive then
            inc(iCurrFuncLocalDataSize, iSize)
          else
            inc(g_ScriptHeader.iGlobalDataSize, iSize);
        end;
      // func
      TOKEN_TYPE_FUNC:
        begin
          // 首先确认不在函数内部，因为嵌套的函数函数不合法
          if iIsFuncActive then
          begin
            ExitOnCodeError(ERROR_MSSG_NESTED_FUNC);
          end;
          // 读取下一个单词，即函数名称
          if (GetNextToken <> TOKEN_TYPE_IDENT) then
            ExitOnCodeError(ERROR_MSSG_IDENT_EXPECTED);

          pstrFuncName := GetCurrLexeme();
          // 计算函数入口点，即直接跟在当前指令后面的指令
          // 也就相当于指令流大小
          iEntryPoint := g_iInstrStreamSize;
          // 试着把它添加到函数表中，如果已经被声明则打印错误
          iFuncIndex := AddFunc(pstrFuncName, iEntryPoint);
          if (iFuncIndex = -1) then
            ExitOnCodeError(ERROR_MSSG_FUNC_REDEFINITION);
          // 是不是主函数_Main
          if StrIComp(pstrFuncName, MAIN_FUNC_NAME) = 0 then
          begin
            g_ScriptHeader.iIsMainFuncPresent := 1;
            g_ScriptHeader.iMainFuncIndex := iFuncIndex;
          end;
          // 把函数标记为True，并重置函数跟踪变量
          iIsFuncActive := True;
          StrCopy(PAnsiChar(@pstrCurrFuncName), pstrFuncName);
          iCurrFuncIndex := iFuncIndex;
          iCurrFuncParamCount := 0;
          // 读取大量换行符直到遇到左大括号
          while (GetNextToken = TOKEN_TYPE_NEWLINE) do;
          // 确认单词是左大括号
          if (g_Lexer.CurrToken <> TOKEN_TYPE_OPEN_BRACE) then
            ExitOnCharExpectedError('{');
          // 所有函数都自动追加Ret寄存器，所以增大指令流所需大小
          inc(g_iInstrStreamSize);
        end;
      // close bracket
      TOKEN_TYPE_CLOSE_BRACE:
        begin
          // 这里应该是函数的结尾，所以保证它在函数内部
          if not iIsFuncActive then
            ExitOnCharExpectedError('}');
          // 设置我们收集到的信息
          SetFuncInfo(@pstrCurrFuncName, iCurrFuncParamCount, iCurrFuncLocalDataSize);
          // 关闭函数
          iIsFuncActive := False;
        end;
      // param
      TOKEN_TYPE_PARAM:
        begin
          // if we aren't currently in a function , print an error
          if not iIsFuncActive then
            ExitOnCodeError(ERROR_MSSG_GLOBAL_PARAM);
          // _Main() can't accept parameters,so make sure we aren't in it
          if StrIComp(PAnsiChar(@pstrCurrFuncName), MAIN_FUNC_NAME) = 0 then
            ExitOnCodeError(ERROR_MSSG_MAIN_PARAM);

          // the parameter's identifier should follow
          if (GetNextToken <> TOKEN_TYPE_IDENT) then
            ExitOnCodeError(ERROR_MSSG_IDENT_EXPECTED);
          // increment the current function's local data size
          inc(iCurrFuncParamCount);
        end;
      // ---instruction
      TOKEN_TYPE_INSTR:
        begin
          // make sure we aren't in the global scope,since instructions
          // can onlu appear in functions
          if not iIsFuncActive then
            ExitOnCodeError(ERROR_MSSG_GLOBAL_INSTR);
          // increment the instruction stream size
          inc(g_iInstrStreamSize);
        end;
      TOKEN_TYPE_IDENT:
        begin
          // make sure it's a line label
          if GetLookAheadChar <> ':' then
            ExitOnCodeError(ERROR_MSSG_INVALID_INSTR);
          // make sure we're in a fucntion,since labels can only appear there
          if not iIsFuncActive then
            ExitOnCodeError(ERROR_MSSG_GLOBAL_LINE_LABEL);
          // the current lexeme is the labek's identifier
          StrCopy(PAnsiChar(@pstrIdent), GetCurrLexeme);
          // the target instruction is always the value of the current
          // instruction count,which is the current size -1
          iTargetIndex := g_iInstrStreamSize - 1;
          // save the label's function index as well
          iFuncIndex := iCurrFuncIndex;
          // try adding the label to the label table,and print an error if it already exists
          if (AddLabel(@pstrIdent, iTargetIndex, iFuncIndex) = -1) then
            ExitOnCodeError(ERROR_MSSG_LINE_LABEL_REDEFINITION);
        end;
    else
      // anything else should cause an error, minus line breaks
      if g_Lexer.CurrToken <> TOKEN_TYPE_NEWLINE then
        ExitOnCodeError(ERROR_MSSG_INVALID_INPUT);
    end;
    // skip to the next line,since the initial tokens are all we're really worrid
    // about in this phase
    if (not SkipToNextLine()) then
      Break;
  end;
  // the second loop

  // we counted the instructions,so allocate the assembled instruction stream array
  // so the next phase can begin
  GetMem(g_pInstrStream, g_iInstrStreamSize * sizeof(InStr));
  // initialize every operand list pointer to null
  for iCurrInstrIndex := 0 to g_iInstrStreamSize - 1 do
  begin
    inc(g_pInstrStream, iCurrInstrIndex);
    g_pInstrStream^.pOpList := nil;
    Dec(g_pInstrStream, iCurrInstrIndex);
  end;
  // set current instruction index to zero
  g_iCurrInstrCount := 0;
  // perform the second pass over the source
  // reset the lexer so we begin at the top of the source again
  ResetLexer();
  // loop through each line of code
  while True do
  begin
    if (GetNextToken = END_OF_TOKEN_STREAM) then
      Break;

    case g_Lexer.CurrToken of
      // func
      TOKEN_TYPE_FUNC:
        begin
          GetNextToken();
          pCurrFunc := GetFuncByName(GetCurrLexeme);
          iIsFuncActive := True;
          iCurrFuncParamCount := 0;
          iCurrFuncIndex := pCurrFunc.iIndex;
          // read any number of line breaks until the opening is found
          while (GetNextToken = TOKEN_TYPE_NEWLINE) do;
        end;
      TOKEN_TYPE_CLOSE_BRACE:
        begin
          iIsFuncActive := False;
          if (StrIComp(PAnsiChar(@pCurrFunc.pstrName), MAIN_FUNC_NAME) = 0) then
          begin
            inc(g_pInstrStream, g_iCurrInstrIndex);
            g_pInstrStream.iOpcode := INSTR_EXIT;
            g_pInstrStream.iOpcount := 1;
            GetMem(g_pInstrStream.pOpList, sizeof(OP));
            g_pInstrStream.pOpList.iType := OP_TYPE_INT;
            g_pInstrStream.pOpList.iIntLiteral := 0;
            Dec(g_pInstrStream, g_iCurrInstrIndex);
          end
          else
          begin
            inc(g_pInstrStream, g_iCurrInstrIndex);
            g_pInstrStream.iOpcode := INSTR_RET;
            g_pInstrStream.iOpcount := 0;
            g_pInstrStream.pOpList := nil;
            Dec(g_pInstrStream, g_iCurrInstrIndex);
          end;
          inc(g_iCurrInstrIndex);
        end;
      // param
      TOKEN_TYPE_PARAM:
        begin
          if (GetNextToken <> TOKEN_TYPE_IDENT) then
            ExitOnCodeError(ERROR_MSSG_IDENT_EXPECTED);
          StrCopy(PAnsiChar(@pstrIdent), GetCurrLexeme);

          iStackIndex := -(pCurrFunc.iLocalDataSize + 2 + (iCurrFuncParamCount + 1));
          // add the parameter to the symbol table
          if AddSymbol(@pstrIdent, 1, iStackIndex, iCurrFuncIndex) = -1 then
          begin
            ExitOnCodeError(ERROR_MSSG_IDENT_REDEFINITION);
          end;
          inc(iCurrFuncParamCount);
        end;
      TOKEN_TYPE_INSTR:
        begin
          GetInstrByMnemonic(GetCurrLexeme, @CurrInstr);
          inc(g_pInstrStream, g_iCurrInstrIndex);
          g_pInstrStream.iOpcode := CurrInstr.iOpcode;
          g_pInstrStream.iOpcount := CurrInstr.iOpcount;
          Dec(g_pInstrStream, g_iCurrInstrIndex);
          // allocate space to hold the oprand list
          GetMem(pOpList, CurrInstr.iOpcount * sizeof(OP));
          for iCurrOpIndex := 0 to CurrInstr.iOpcount - 1 do
          begin
            // point to the des data
            inc(pOpList, iCurrOpIndex);
            CurrOpTypes := GetCurrOpType(CurrInstr.OpList, iCurrOpIndex);
            InitOpToken := GetNextToken;
            case InitOpToken of
              TOKEN_TYPE_INT:
                begin
                  if (CurrOpTypes and OP_FLAG_TYPE_INT) <> 0 then
                  begin
                    pOpList.iType := OP_TYPE_INT;
                    pOpList.iInstrIndex := StrToInt(GetCurrLexeme);
                  end
                  else
                  begin
                    ExitOnCodeError(ERROR_MSSG_INVALID_OP);
                  end;
                end;
              TOKEN_TYPE_FLOAT:
                begin
                  if (CurrOpTypes and OP_FLAG_TYPE_FLOAT) <> 0 then
                  begin
                    pOpList.iType := OP_TYPE_FLOAT;
                    pOpList.fFloatLiteral := StrToFloat(GetCurrLexeme);
                  end
                  else
                  begin
                    ExitOnCodeError(ERROR_MSSG_INVALID_OP);
                  end;
                end;
              TOKEN_TYPE_QUOTE:
                begin
                  if (CurrOpTypes and OP_FLAG_TYPE_STRING) <> 0 then
                  begin
                    GetNextToken;
                    case g_Lexer.CurrToken of
                      TOKEN_TYPE_QUOTE:
                        begin
                          pOpList.iType := OP_TYPE_INT;
                          pOpList.iIntLiteral := 0;
                        end;
                      TOKEN_TYPE_STRING:
                        begin
                          pstrString := GetCurrLexeme;
                          iStringIndex := Addstring(@g_StringTable, pstrString);
                          if (GetNextToken <> TOKEN_TYPE_QUOTE) then
                            ExitOnCharExpectedError('\');

                          pOpList.iType := OP_TYPE_STRING_INDEX;
                          pOpList.iStringTableIndex := iStringIndex;
                        end;
                    else
                      ExitOnCodeError(ERROR_MSSG_INVALID_OP);
                    end;
                  end
                  else
                    ExitOnCodeError(ERROR_MSSG_INVALID_OP);
                end;
              TOKEN_TYPE_REG_RETVAL:
                begin
                  if (CurrOpTypes and OP_FLAG_TYPE_REG) <> 0 then
                  begin
                    pOpList.iType := OP_TYPE_REG;
                    pOpList.iReg := 0;
                  end
                  else
                  begin
                    ExitOnCodeError(ERROR_MSSG_INVALID_OP);
                  end;
                end;
              TOKEN_TYPE_IDENT:
                begin
                  if (CurrOpTypes and OP_FLAG_TYPE_MEM_REF) <> 0 then
                  begin
                    StrCopy(PAnsiChar(@pstrIdent), GetCurrLexeme);
                    if (GetSymbolByIdent(@pstrIdent, iCurrFuncIndex) = nil) then
                    begin
                      ExitOnCodeError(ERROR_MSSG_UNDEFINED_IDENT);
                    end;
                    //
                    iBaseIndex := GetStackIndexByIdent(@pstrIdent, iCurrFuncIndex);
                    if GetLookAheadChar() <> '[' then
                    begin
                      if (GetSizeByIdent(@pstrIdent, iCurrFuncIndex) > 1) then
                      begin
                        ExitOnCodeError(ERROR_MSSG_INVALID_ARRAY_NOT_INDEXED);
                      end;
                      pOpList.iType := OP_TYPE_ABS_STACK_INDEX;
                      pOpList.iIntLiteral := iBaseIndex;
                    end
                    else
                    begin
                      if (GetSizeByIdent(@pstrIdent, iCurrFuncIndex) = 1) then
                      begin
                        ExitOnCodeError(ERROR_MSSG_INVALID_ARRAY);
                      end;
                      if (GetNextToken <> TOKEN_TYPE_OPEN_BRACKET) then
                      begin
                        ExitOnCharExpectedError('[');
                      end;
                      IndexToken := GetNextToken;
                      if IndexToken = TOKEN_TYPE_INT then
                      begin
                        iOffsetIndex := StrToInt(GetCurrLexeme);
                        pOpList.iType := OP_TYPE_ABS_STACK_INDEX;
                        pOpList.iStackIndex := iBaseIndex + iOffsetIndex;
                      end
                      else if IndexToken = TOKEN_TYPE_IDENT then
                      begin
                        pstrIndexIdent := GetCurrLexeme;
                        if GetSymbolByIdent(pstrIndexIdent, iCurrFuncIndex) = nil then
                        begin
                          ExitOnCodeError(ERROR_MSSG_UNDEFINED_IDENT);
                        end;
                        if (GetSizeByIdent(pstrIndexIdent, iCurrFuncIndex) > 1) then
                        begin
                          ExitOnCodeError(ERROR_MSSG_INVALID_ARRAY_INDEX);
                        end;
                        iOffsetIndex := GetStackIndexByIdent(pstrIndexIdent, iCurrFuncIndex);
                        pOpList.iType := OP_TYPE_REL_STACK_INDEX;
                        pOpList.iStackIndex := iBaseIndex;
                        pOpList.iOffserIndex := iOffsetIndex;
                      end
                      else
                      begin
                        ExitOnCodeError(ERROR_MSSG_INVALID_ARRAY_INDEX);
                      end;
                      if (GetNextToken <> TOKEN_TYPE_CLOSE_BRACKET) then
                      begin
                        ExitOnCharExpectedError('[');
                      end;
                    end;
                  end;
                  // label
                  if (CurrOpTypes and OP_FLAG_TYPE_LINE_LABEL) <> 0 then
                  begin
                    pstrLabelIdent := GetCurrLexeme;
                    pLabel := GetLabelByIdent(pstrLabelIdent, iCurrFuncIndex);
                    if pLabel = nil then
                    begin
                      ExitOnCodeError(ERROR_MSSG_UNDEFINED_LINE_TABEL);
                    end;
                    pOpList.iType := OP_TYPE_INSTR_INDEX;
                    pOpList.iInstrIndex := pLabel.iTargetIndex;
                  end;
                  // function name
                  if (CurrOpTypes and OP_FLAG_TYPE_FUNC_NAME) <> 0 then
                  begin
                    pstrFuncName := GetCurrLexeme;
                    pFunc := GetFuncByName(pstrFuncName);
                    if (pFunc = nil) then
                    begin
                      ExitOnCodeError(ERROR_MSSG_UNDEFINED_FUNC);
                    end;
                    pOpList.iType := OP_TYPE_FUNC_INDEX;
                    pOpList.iFuncIndex := pFunc.iIndex;
                  end;
                  // host api
                  if (CurrOpTypes and OP_FLAG_TYPE_HOST_API_CALL) <> 0 then
                  begin
                    pstrHostAPICall := GetCurrLexeme;
                    iIndex := Addstring(@g_HostAPICallTable, pstrHostAPICall);

                    pOpList.iType := OP_TYPE_HOST_API_CALL_INDEX;
                    pOpList.iHostAPICallIndex := iIndex;
                  end;
                end;
            else
              ExitOnCodeError(ERROR_MSSG_INVALID_OP);
            end;

            if (iCurrOpIndex < CurrInstr.iOpcount - 1) then
              if (GetNextToken <> TOKEN_TYPE_COMMA) then
                ExitOnCharExpectedError(',');
            // reser the point
            Dec(pOpList, iCurrOpIndex);
          end;
          // make sure there's no extranous stuff ahead
          if (GetNextToken <> TOKEN_TYPE_NEWLINE) then
            ExitOnCodeError(ERROR_MSSG_INVALID_INPUT);
          inc(g_pInstrStream, g_iCurrInstrIndex);
          g_pInstrStream.pOpList := pOpList;
          Dec(g_pInstrStream, g_iCurrInstrIndex);
          inc(g_iCurrInstrIndex);
        end;
    end;
    // skip to the next line
    if (not SkipToNextLine) then
      Break;
  end;
end;
{$ENDREGION}

procedure PrintAssmblStats();
var
  iVarCount: integer;
  iArrayCount: integer;
  iGlobalCount: integer;
  pCurrNode: pLinkedListNode;
  iCurrNode: integer;
  pCurrSymbol: pSymbolNode;
begin
  iVarCount := 0;
  iArrayCount := 0;
  iGlobalCount := 0;
  //
  pCurrNode := g_SymbolTable.pHead;
  for iCurrNode := 0 to g_SymbolTable.iNodeCount - 1 do
  begin
    pCurrSymbol := pSymbolNode(pCurrNode.pData);
    if (pCurrSymbol.iSize > 1) then
      inc(iArrayCount)
    else
      inc(iVarCount);

    if (pCurrSymbol.iStackIndex >= 0) then
      inc(iGlobalCount);
    //
    pCurrNode := pCurrNode.pNext;
  end;

  Writeln(Format('%s created successfully!' + #13#10, [g_pstrExecFilename]));
  Writeln(Format('Source Lines Processed: %d/%d', [g_iSourceCodeSize, g_iSourceLines]));
  Write('            Stack Size: ');
  if (g_ScriptHeader.iStackSize <> 0) then
    Writeln(Format('%d', [g_ScriptHeader.iStackSize]))
  else
    Writeln('Default');

  Write('              Priority: ');
  case g_ScriptHeader.iPriorityType of
    PRIORITY_USER:
      Writeln(Format('%d ms', [g_ScriptHeader.iUserPriorty]));
    PRIORITY_LOW:
      Writeln(PRIORITY_LOW_KEYWORD);
    PRIORITY_MED:
      Writeln(PRIORITY_MED_KEYWORD);
    PRIORITY_HIGH:
      Writeln(PRIORITY_HIGH_KEYWORD);
  else
    Writeln('Invalid Priority');
  end;

  Writeln(Format('Instructions Assembled: %d', [g_iInstrStreamSize]));
  Writeln(Format('             Varisbles: %d', [iVarCount]));
  Writeln(Format('                Arrays: %d', [iArrayCount]));
  Writeln(Format('               Globals: %d', [iGlobalCount]));
  Writeln(Format('       String Literals: %d', [g_StringTable.iNodeCount]));
  Writeln(Format('                Labels: %d', [g_LabelTable.iNodeCount]));
  Writeln(Format('        Host API Calls: %d', [g_HostAPICallTable.iNodeCount]));
  Writeln(Format('             Functions: %d', [g_FuncTable.iNodeCount]));

  Write('      _Main () Present:');
  if (g_ScriptHeader.iIsMainFuncPresent <> 0) then
    Writeln(Format(' Yes [index %d]', [g_ScriptHeader.iMainFuncIndex]))
  else
    Writeln('No');
end;

procedure BuildXSE();
var
  pExecFile: THandle;
  cVersionMajor: AnsiChar;
  cVersionMinor: AnsiChar;
  XSE: array [0 .. 3] of AnsiChar;
  iCurrInstrIndex: integer;
  sOpcode: SmallInt;
  iOpcount: integer;
  iCurrOpIndex: integer;
  CurrOP: pOP;
  // string
  iCurrNode: integer;
  pNode: pLinkedListNode;
  pstrCurrString: PAnsiChar;
  iCurrStringLength: integer;
  // func
  pFunc: pFuncNode;
  cFuncNameLength: integer;
  // host api
  pstrCurrHostAPICall: PAnsiChar;
  iCurrHostLength: integer;
begin
  if FileExists(g_pstrExecFilename) then
  begin
    DeleteFile(g_pstrExecFilename);
  end;
  pExecFile := FileCreate(g_pstrExecFilename);

  // 写ID字符串（4字节）
  StrCopy(PAnsiChar(@XSE), PAnsiChar(AnsiString(XSE_ID_STRING)));
  FileWrite(pExecFile, XSE, 4);
  // 写版本      1/1  2
  cVersionMajor := AnsiChar(VERSION_MAJOR);
  cVersionMinor := AnsiChar(VERSION_MINOR);
  FileWrite(pExecFile, cVersionMajor, 1);
  FileWrite(pExecFile, cVersionMinor, 1);
  // 写堆栈大小   4
  FileWrite(pExecFile, g_ScriptHeader.iStackSize, 4);
  // 全局数据大小  4
  FileWrite(pExecFile, g_ScriptHeader.iGlobalDataSize, 4);
  // 写_Main 标记  1
  FileWrite(pExecFile, AnsiChar(g_ScriptHeader.iIsMainFuncPresent), 1);
  // 写_Main函数索引
  FileWrite(pExecFile, g_ScriptHeader.iMainFuncIndex, 4);
  // 写优先级
  FileWrite(pExecFile, g_ScriptHeader.iPriorityType, 1);
  // 写用户定义的时间片
  FileWrite(pExecFile, g_ScriptHeader.iUserPriorty, 4);
  // 输出指令条数 4
  FileWrite(pExecFile, g_iInstrStreamSize, 4);
  // ↑23
  // 对每条指令做循环
  for iCurrInstrIndex := 0 to g_iInstrStreamSize - 1 do
  begin
    inc(g_pInstrStream, iCurrInstrIndex);
    // 写操作码 2
    sOpcode := g_pInstrStream.iOpcode;
    FileWrite(pExecFile, sOpcode, 2);
    // 写出操作数计数 1
    iOpcount := g_pInstrStream.iOpcount;
    FileWrite(pExecFile, AnsiChar(iOpcount), 1);
    // 对操作数列表循环，把每个操作数写入
    for iCurrOpIndex := 0 to iOpcount - 1 do
    begin
      CurrOP := g_pInstrStream.pOpList;
      inc(CurrOP, iCurrOpIndex);
      FileWrite(pExecFile, CurrOP.iType, 1);
      // 根据操作数类型写操作数
      case CurrOP.iType of
        // 整形字面量
        OP_TYPE_INT:
          FileWrite(pExecFile, CurrOP.iIntLiteral, sizeof(integer));
        // 浮点字面量
        OP_TYPE_FLOAT:
          FileWrite(pExecFile, CurrOP.fFloatLiteral, sizeof(Single));
        // 字符串索引
        OP_TYPE_STRING_INDEX:
          FileWrite(pExecFile, CurrOP.iStringTableIndex, sizeof(integer));
        // 指令索引
        OP_TYPE_INSTR_INDEX:
          FileWrite(pExecFile, CurrOP.iInstrIndex, sizeof(integer));
        // 绝对堆栈索引
        OP_TYPE_ABS_STACK_INDEX:
          FileWrite(pExecFile, CurrOP.iStackIndex, sizeof(integer));
        // 相对堆栈索引
        OP_TYPE_REL_STACK_INDEX:
          begin
            FileWrite(pExecFile, CurrOP.iStackIndex, sizeof(integer));
            FileWrite(pExecFile, CurrOP.iOffserIndex, sizeof(integer));
          end;
        // 函数索引
        OP_TYPE_FUNC_INDEX:
          FileWrite(pExecFile, CurrOP.iFuncIndex, sizeof(integer));
        // 主应用程序API调用
        OP_TYPE_HOST_API_CALL_INDEX:
          FileWrite(pExecFile, CurrOP.iHostAPICallIndex, sizeof(integer));
        // 寄存器
        OP_TYPE_REG:
          FileWrite(pExecFile, CurrOP.iReg, sizeof(integer));
      end;
      Dec(CurrOP, iCurrOpIndex);
    end;
    Dec(g_pInstrStream, iCurrInstrIndex);
  end;
  // 字符串
  // 写字符串个数
  FileWrite(pExecFile, g_StringTable.iNodeCount, 4);
  // 把指针设置到链表头
  pNode := g_StringTable.pHead;
  //
  for iCurrNode := 0 to g_StringTable.iNodeCount - 1 do
  begin
    // 复制字符串并计算长度
    pstrCurrString := PAnsiChar(pNode.pData);
    iCurrStringLength := StrLen(pstrCurrString);
    // 写字符串长度
    FileWrite(pExecFile, AnsiChar(iCurrStringLength), 4);
    FileWrite(pExecFile, pstrCurrString^, StrLen(pstrCurrString));
    pNode := pNode.pNext;
  end;
  // 函数表
  FileWrite(pExecFile, g_FuncTable.iNodeCount, 4);
  // 把指针设置到链表头
  pNode := g_FuncTable.pHead;
  // 对链表中每个节点循环，写它们的字符串信息
  for iCurrNode := 0 to g_FuncTable.iNodeCount - 1 do
  begin
    // 函数
    pFunc := pFuncNode(pNode.pData);
    // 写出入口点 4
    FileWrite(pExecFile, pFunc.iEntryPoint, sizeof(integer));
    // 写出参数个数 1
    FileWrite(pExecFile, AnsiChar(pFunc.iParamCount), 1);
    // 写出局部数据大小4
    FileWrite(pExecFile, pFunc.iLocalDataSize, sizeof(integer));
    // 写函数名长度 1字节
    cFuncNameLength := StrLen(pFunc.pstrName);
    FileWrite(pExecFile, cFuncNameLength, 1);
    // 写函数名 N
    FileWrite(pExecFile, pFunc.pstrName, cFuncNameLength);
    // 移到下一点
    pNode := pNode.pNext;
  end;
  // 主应用程序API
  FileWrite(pExecFile, g_HostAPICallTable.iNodeCount, 4);
  // 把指针设置到链表头
  pNode := g_HostAPICallTable.pHead;
  // 对链表中每个节点循环，写它们的字符串
  for iCurrNode := 0 to g_HostAPICallTable.iNodeCount - 1 do
  begin
    // 复制字符串指针并计算长度
    pstrCurrHostAPICall := PAnsiChar(pNode.pData);
    iCurrHostLength := StrLen(pstrCurrHostAPICall);
    // 写长度1
    FileWrite(pExecFile, AnsiChar(iCurrHostLength), 1);
    // 写字符串数据N
    FileWrite(pExecFile, pstrCurrHostAPICall^, StrLen(pstrCurrHostAPICall));
    // 移动到下一节点
    pNode := pNode.pNext;
  end;
  FileClose(pExecFile);
end;

procedure MyExit();
begin
  ShutDown;
  Exit;
end;

{$REGION '错误处理'}

procedure ExitOnCodeError(pstrErrorMssg: PAnsiChar);
var
  pstrSourceLine: AnsiString;
  iCurrCharIndex: integer;
begin
  Writeln(Format('Error:%s', [pstrErrorMssg]));
  Writeln(Format('Line %d', [g_Lexer.iCurrSourceLine]));

  pstrSourceLine := GetCurrSourceStr(g_Lexer.iCurrSourceLine);
  for iCurrCharIndex := 0 to Length(pstrSourceLine) - 1 do
    if pstrSourceLine[iCurrCharIndex] = '\t' then
      pstrSourceLine[iCurrCharIndex] := ' ';

  Writeln(Format('%s', [pstrSourceLine]));

  for iCurrCharIndex := 0 to g_Lexer.iIndex0 - 1 do
    Writeln(' ');

  Writeln(Format('Could not assemble %s', [g_pstrExecFilename]));
  Exit;
end;

procedure ExitOnCharExpectedError(cChar: AnsiChar);
var
  pstrErrorMssg: AnsiString;
begin
  pstrErrorMssg := Format('%s expected ', [cChar]);
  ExitOnCodeError(PAnsiChar(pstrErrorMssg));
end;
{$ENDREGION}

end.
