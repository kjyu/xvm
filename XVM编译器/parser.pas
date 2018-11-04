{ ******************************************************* }
{                                                         }
{ XVM                                                     }
{                                                         }
{ 版权所有 (C) 2012 adsj                                  }
{ Mode： 语法分析器模块                                   }
{      注:1.暂不支持 For循环(书上说可以在预处理阶段       }
{          将For转为While)                                }
{         2.暂不支持 ++X等前置单目运算                    }
{ ******************************************************* }
unit parser;

interface

uses
  System.SysUtils, globals, errors, Lexer, stacks, symbol_table, linked_list, func_table, i_code;

const
  MAX_FUNC_DECLARE_PARAM_COUNT = 32;

type
  // ----------------------------------------------------------
  _Expr = record
    iStackOffset: Integer;
  end;

  Expr = _Expr;

  // ----------------------------------------------------------
  Loop = record
    iStartTargetIndex: Integer;
    iEndTargetIndex: Integer;
  end;

  pLoop = ^Loop;
  // ----------------------------------------------------------
  (* 读入特定的属性符 *)
procedure ReadToken(const ReqToken: Token);

// ----------------------------------------------------------
// 文法分析
(* 处理全局范围语句 *)
procedure ParseSourceCode();
(* 语句 *)
procedure ParseStatement();
(* 块 *)
procedure ParseBlock();
(* 变量和数组声明 Var [] *)
procedure ParseVar();
(* 主应用程序 API *)
procedure ParseHost();
(* 函数 Func *)
procedure ParseFuncCall();
procedure ParseFunc();

(* 分析表达式 *)
// 分析子表达式
procedure ParseFactor();
procedure ParseSubExpr();
procedure ParseTerm();
procedure ParseExpr();
// 赋值语句
procedure ParseAssign();
// 分析高级
procedure ParseIf();
procedure ParseWhile();
procedure ParseFor();
procedure ParseBreak();
procedure ParseContinue();
procedure ParseReturn();
// ----------------------------------------------------------
procedure printError(error: PAnsiChar);

var
  // 当前范围
  // 0全局
  // ~0表示当前函数在函数表中的索引
  g_iCurrScope: Integer;
  g_LoopStack: Stack;

implementation

procedure printError(error: PAnsiChar);
begin
//  StrCat(error, '[parser]');
  ExitOnCodeError(GetCurrSourceLineIndex(), GetCurrSourceLine(),
    g_CurrLexerState.iCurrLexemeStart, error);
end;

function IsOpRelational(iOpType: Integer): Boolean;
begin
  Result := (iOpType in [OP_TYPE_EQUAL, OP_TYPE_NOT_EQUAL, OP_TYPE_LESS, OP_TYPE_GREATER,
    OP_TYPE_LESS_EQUAL, OP_TYPE_GREATER_EQUAL]);
end;

function IsOpLogical(iOpType: Integer): Boolean;
begin
  Result := (iOpType in [OP_TYPE_LOGICAL_NOT, OP_TYPE_LOGICAL_AND, OP_TYPE_LOGICAL_OR]);
end;

procedure ReadToken(const ReqToken: Token);
var
  pstrError: PAnsiChar;
begin
  if GetNextToken() <> ReqToken then
  begin
    GetMem(pstrError, 255);
    FillChar(pstrError^, 255, #0);
    try
      case ReqToken of
        TOKEN_TYPE_INT:
          StrCopy(pstrError, 'Integer');
        TOKEN_TYPE_FLOAT:
          StrCopy(pstrError, 'Float');
        TOKEN_TYPE_IDENT:
          StrCopy(pstrError, 'Identifier');
        TOKEN_TYPE_RSRVD_VAR:
          StrCopy(pstrError, 'var');
        TOKEN_TYPE_RSRVD_TRUE:
          StrCopy(pstrError, 'true');
        TOKEN_TYPE_RSRVD_FALSE:
          StrCopy(pstrError, 'false');
        TOKEN_TYPE_RSRVD_IF:
          StrCopy(pstrError, 'if');
        TOKEN_TYPE_RSRVD_ELSE:
          StrCopy(pstrError, 'else');
        TOKEN_TYPE_RSRVD_BREAK:
          StrCopy(pstrError, 'break');
        TOKEN_TYPE_RSRVD_CONTINUE:
          StrCopy(pstrError, 'continue');
        TOKEN_TYPE_RSRVD_FOR:
          StrCopy(pstrError, 'for');
        TOKEN_TYPE_RSRVD_WHILE:
          StrCopy(pstrError, 'while');
        TOKEN_TYPE_RSRVD_FUNC:
          StrCopy(pstrError, 'func');
        TOKEN_TYPE_RSRVD_RETURN:
          StrCopy(pstrError, 'return');
        TOKEN_TYPE_RSRVD_HOST:
          StrCopy(pstrError, 'host');
        TOKEN_TYPE_OP:
          StrCopy(pstrError, 'Operator');
        TOKEN_TYPE_DELIM_COMMA:
          StrCopy(pstrError, ',');
        TOKEN_TYPE_DELIM_OPEN_PAREN:
          StrCopy(pstrError, '(');
        TOKEN_TYPE_DELIM_CLOSE_PAREN:
          StrCopy(pstrError, ')');
        TOKEN_TYPE_DELIM_OPEN_BRACE:
          StrCopy(pstrError, '[');
        TOKEN_TYPE_DELIM_CLOSE_BRACE:
          StrCopy(pstrError, ']');
        TOKEN_TYPE_DELIM_OPEN_CURLY_BRACE:
          StrCopy(pstrError, '{');
        TOKEN_TYPE_DELIM_CLOSE_CURLY_BRACE:
          StrCopy(pstrError, '}');
        TOKEN_TYPE_DELIM_SEMICOLON:
          StrCopy(pstrError, ';');
        TOKEN_TYPE_STRING:
          StrCopy(pstrError, 'String');
      end;
      StrCat(pstrError, ' expected');
      // 打印错误信息，行数。。。等
      printError(pstrError);
    finally
      // 释放
      FreeMem(pstrError);
    end;
  end;
end;

procedure ParseSourceCode();
begin
  // 重置词法分析器
  ResetLexer();
  InitStack(@g_LoopStack);
  // 将当前的作用域设置为全局
  g_iCurrScope := SCOPE_GLOBAL;
  while True do
  begin
    // 分析下一个语句并忽略文件结束标记
    ParseStatement();
    // 如果已经到了属性流的末尾,就跳出循环
    if (GetNextToken() = TOKEN_TYPE_END_OF_STREAM) then
      Break
    else
      RewindTokenStream();
  end;
  // free the loop stack
  FreeStack(@g_LoopStack);
end;

procedure ParseStatement();
var
  InitToken: Token;
begin
  // 如果下一个属性是分号，那么就是一个空语句
  if GetLookAHeadChar() = ';' then
  begin
    // ';'
    ReadToken(TOKEN_TYPE_DELIM_SEMICOLON);
    Exit;
  end;
  // 确定语句的开始属性
  InitToken := GetNextToken();
  // 根据属性符分直到不同的分析函数
  case InitToken of
    // 文件意外结束
    TOKEN_TYPE_END_OF_STREAM:
      printError('Unexpected end of file');
    // '{'
    TOKEN_TYPE_DELIM_OPEN_CURLY_BRACE:
      ParseBlock();
    // 'var'
    TOKEN_TYPE_RSRVD_VAR:
      ParseVar();
    // host
    TOKEN_TYPE_RSRVD_HOST:
      ParseHost();
    // 'func'
    TOKEN_TYPE_RSRVD_FUNC:
      ParseFunc();
    // if block
    TOKEN_TYPE_RSRVD_IF:
      ParseIf();
    TOKEN_TYPE_RSRVD_WHILE:
      ParseWhile();
    // For 循环暂不支持
    // TOKEN_TYPE_RSRVD_FOR:
    // ParseFor();
    TOKEN_TYPE_RSRVD_BREAK:
      ParseBreak();
    TOKEN_TYPE_RSRVD_CONTINUE:
      ParseContinue();
    TOKEN_TYPE_RSRVD_RETURN:
      ParseReturn();
    // 操作符 ++等暂不支持
    // TOKEN_TYPE_OP
    TOKEN_TYPE_IDENT:
      begin
        if GetSymbolByIdent(GetCurrLexeme(), g_iCurrScope) <> nil then
        begin
          ParseAssign();
        end
        else if GetFuncByName(GetCurrLexeme()) <> nil then
        begin
          AddICodeSourceLine(g_iCurrScope, GetCurrSourceLine());
          ParseFuncCall();
          ReadToken(TOKEN_TYPE_DELIM_SEMICOLON);
        end
        else
        begin
          printError('Invalid identifier');
          ExitOnCodeError(GetCurrSourceLineIndex(), GetCurrSourceLine(),
            g_CurrLexerState.iCurrLexemeStart, 'Invalid identifier');
        end;
      end
  else
    // ExitOnError('Unexpected input');
   printError('Unexpected input');
  end;
end;

procedure ParseBlock();
begin
  // 确保我们没有在全局范围内
  if g_iCurrScope = SCOPE_GLOBAL then
    printError( 'Code blocks illegal in global scope');
  // 读入每个语句直到块结束
  while GetLookAHeadChar() <> '}' do
    ParseStatement();
  // 读入 '}'
  ReadToken(TOKEN_TYPE_DELIM_CLOSE_CURLY_BRACE);
end;

procedure ParseVar();
var
  pstrIdent: PAnsiChar;
  iSize: Integer;
begin
  //
  ReadToken(TOKEN_TYPE_IDENT);
  // 当前单词复制到一个局部字符串缓冲区中以保存变量的标识符
  GetMem(pstrIdent, MAX_LEXEME_SIZE);
  try
    CopyCurrLexeme(pstrIdent);
    iSize := 1;
    // 向前查看是否有左括号
    if GetLookAHeadChar() = '[' then
    begin
      // 验证左括号
      ReadToken(TOKEN_TYPE_DELIM_OPEN_BRACE);
      // 如果是，读入整型属性符
      ReadToken(TOKEN_TYPE_INT);
      // 将当前单词转换为整形以获得大小
      iSize := StrToInt(GetCurrLexeme());
      ReadToken(TOKEN_TYPE_DELIM_CLOSE_BRACE);
    end;
    if AddSymbol(pstrIdent, iSize, g_iCurrScope, SYMBOL_TYPE_VAR) = -1 then
      printError( 'IdentiFier redefinition');

    ReadToken(TOKEN_TYPE_DELIM_SEMICOLON);
  finally
    FreeMem(pstrIdent);
  end;
end;

procedure ParseHost();
begin
  // 读入主应用程序 API 函数名称
  ReadToken(TOKEN_TYPE_IDENT);
  // 将函数添加到函数表中并设置主应用程序API标记
  if AddFunc(GetCurrLexeme(), 1) = -1 then
    printError( 'Function redefinition');
  // 确保函数名字后面跟着()
  ReadToken(TOKEN_TYPE_DELIM_OPEN_PAREN);
  ReadToken(TOKEN_TYPE_DELIM_CLOSE_PAREN);

  // 读入分号
  ReadToken(TOKEN_TYPE_DELIM_SEMICOLON);
end;

procedure ParseFunc();
var
  iFuncIndex: Integer;
  iParamCount: Integer;
  // 数组保存局部参数列表
  ppstrParamList: array [0 .. MAX_FUNC_DECLARE_PARAM_COUNT - 1] of AnsiString;
  clex: PAnsiChar;
begin
  // 函数不允许嵌套,所以这里必须是全局
  if g_iCurrScope <> SCOPE_GLOBAL then
    printError('Nested function illegal');
  // 读入函数名称
  ReadToken(TOKEN_TYPE_IDENT);
  // 将非主应用程序API函数加入到函数表并获得它的索引
  iFuncIndex := AddFunc(GetCurrLexeme(), 0); // 0 not host api
  // 检查函数的重复定义
  if iFuncIndex = -1 then
    printError('Function redefinition');
  // 设定函数的作用域
  g_iCurrScope := iFuncIndex;
  // ----分析参数列表 '('
  ReadToken(TOKEN_TYPE_DELIM_OPEN_PAREN);
  // 使用向前查看字符确定函数是否有参数
  if GetLookAHeadChar() <> ')' then
  begin
    // 如果函数定义的是_Main(),那就给出错误标记,因为_Main()不接受任何参数
    if (g_ScriptHeader.iIsMainFuncPresent <> 0) and (g_ScriptHeader.iMainFuncIndex = iFuncIndex)
    then
    begin
      printError('_Main() cannot accept parameters');
    end;
    // 参数计数从0开始
    iParamCount := 0;
    // 创建一个数组保存局部参数列表
    // 读参数
    while True do
    begin
      ReadToken(TOKEN_TYPE_IDENT);
      // 当前的单词复制到参数表中
      GetMem(clex, 32);
      CopyCurrLexeme(clex);
      ppstrParamList[iParamCount] := AnsiString(clex);
      FreeMem(clex);
      // CopyCurrLexeme(@ppstrParamList[iParamCount]);
      //
      Inc(iParamCount);
      // 检查右括号以确定参数列表是否结束
      if GetLookAHeadChar = ')' then
        Break;
      // 否则读入下一个逗号接着处理下一个参数
      ReadToken(TOKEN_TYPE_DELIM_COMMA);
    end;
    // 设置参数个数
    SetFuncParamCount(g_iCurrScope, iParamCount);
    // 将参数以逆序写入到函数的符号表
    while iParamCount > 0 do
    begin
      Dec(iParamCount);
      AddSymbol(PAnsiChar(ppstrParamList[iParamCount]), 1, g_iCurrScope, SYMBOL_TYPE_PARAM);
    end;
  end;
  // 读入右括号

  ReadToken(TOKEN_TYPE_DELIM_CLOSE_PAREN);
  // ----分析函数体
  // 读入 '{'
  ReadToken(TOKEN_TYPE_DELIM_OPEN_CURLY_BRACE);
  // 分析函数体
  ParseBlock();
  // 返回到全局范围
  g_iCurrScope := SCOPE_GLOBAL;
end;

// <Ident> (<Expr>,<Expr>);
procedure ParseFuncCall();
var
  pFunc: pFuncNode;
  iParamCount: Integer;
  iCallInstr: Integer;
  iInstrIndex: Integer;
begin
  iParamCount := 0;
  // 根据标识符获得函数
  pFunc := GetFuncByName(GetCurrLexeme());
  // 试图读入左括号
  ReadToken(TOKEN_TYPE_DELIM_OPEN_PAREN);
  // 分析每个参数并将参数压入到堆栈
  while True do
  begin
    // 查看是否还有参数
    if GetLookAHeadChar() <> ')' then
    begin
      // 还有参数,所以当做一个表达式来分析
      ParseExpr();
      // 增加参数计数并检查参数个数没有超过函数可以接受的参数个数(除非是主应用程序API函数)
      Inc(iParamCount);
      if (pFunc.iIsHostAPI = 0) and (iParamCount > pFunc.iParamCount) then
      begin
        printError('Too many parametes');
      end;
      // 如果不是最后一个参数,读入逗号
      if GetLookAHeadChar() <> ')' then
        ReadToken(TOKEN_TYPE_DELIM_COMMA);
    end
    else
    begin
      // 没有逗号,退出循环完成分析
      Break;
    end;
  end;
  // 检查右括号
  ReadToken(TOKEN_TYPE_DELIM_CLOSE_PAREN);
  // 检查参数不会太少(除非是主应用程序API函数)
  if (pFunc.iIsHostAPI = 0) and (iParamCount < pFunc.iParamCount) then
  begin
    printError('Too few parameters');
  end;
  // 调用函数,确保使用正确的函数调用指令
  iCallInstr := INSTR_CALL;
  if pFunc.iIsHostAPI = 1 then
  begin
    iCallInstr := INSTR_CALLHOST;
  end;
  iInstrIndex := AddICodeInstr(g_iCurrScope, iCallInstr);
  AddFuncICodeOp(g_iCurrScope, iInstrIndex, pFunc.iIndex);
end;

// <Ident> <Assign-Op> <Expr>
procedure ParseAssign();
var
  iInstrIndex: Integer;
  // 赋值运算符
  iAssignOp: Integer;
  pSymbol: pSymbolNode;
  bIsArray: Boolean;
begin
  if g_iCurrScope = SCOPE_GLOBAL then
  begin
    printError('Assignment illegal in global scope');
  end;
  { TODO :  }
  AddICodeSourceLine(g_iCurrScope, GetCurrSourceLine());
  // 分析变量或者数组
  pSymbol := GetSymbolByIdent(GetCurrLexeme(), g_iCurrScope);
  // 标识符后面是否有数组
  bIsArray := False;
  if GetLookAHeadChar() = '[' then
  begin
    // 确保这个变量是数组
    if pSymbol.iSize = 1 then
      printError('Invalid array');
    // 检查左括号
    ReadToken(TOKEN_TYPE_DELIM_OPEN_BRACE);
    // 确保括号中有表达式
    if GetLookAHeadChar() = ']' then
      printError('Invalid expression');
    // 分析表达式以得到索引
    ParseExpr();
    // 确保表达式后面右括号
    ReadToken(TOKEN_TYPE_DELIM_CLOSE_BRACE);
    // 设置数组标记
    bIsArray := True;
  end
  else
  begin
    // 确保这个变量不是数组
    if pSymbol.iSize > 1 then
      printError('Arrays must be indexed');
  end;

  if (GetNextToken() <> TOKEN_TYPE_OP) and //
    (not(GetCurrOp in [OP_TYPE_ASSIGN, OP_TYPE_ASSIGN_ADD, OP_TYPE_ASSIGN_SUB, OP_TYPE_ASSIGN_MUL,
    OP_TYPE_ASSIGN_DIV, OP_TYPE_ASSIGN_MOD, OP_TYPE_ASSIGN_EXP, OP_TYPE_ASSIGN_CONCAT,
    OP_TYPE_ASSIGN_AND, OP_TYPE_ASSIGN_OR, OP_TYPE_ASSIGN_XOR, OP_TYPE_ASSIGN_SHIFT_LEFT,
    OP_TYPE_ASSIGN_SHIFT_RIGHT])) then
  begin
    printError('Illegal assignment operator');
  end
  else
  begin
    iAssignOp := GetCurrOp();
  end;
  // 分析值表达式
  ParseExpr();
  // 验证分号是否存在
  ReadToken(TOKEN_TYPE_DELIM_SEMICOLON);
  // 将值弹出到_T0
  iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_POP);
  AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
  // 如果这个变量时数组，将堆栈顶部的元素弹出到_T1
  if bIsArray then
  begin
    iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_POP);
    AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar1SymbolIndex);
  end;
  // 为中间代码生成赋值指令
  case iAssignOp of
    // =
    OP_TYPE_ASSIGN:
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_MOV);
    // +=
    OP_TYPE_ASSIGN_ADD:
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_ADD);
    // -=
    OP_TYPE_ASSIGN_SUB:
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_SUB);
    // *=
    OP_TYPE_ASSIGN_MUL:
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_MUL);
    // /=
    OP_TYPE_ASSIGN_DIV:
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_DIV);
    // %=
    OP_TYPE_ASSIGN_MOD:
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_MOD);
    // ^=
    OP_TYPE_ASSIGN_EXP:
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_EXP);
    // $=
    OP_TYPE_ASSIGN_CONCAT:
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_CONCAT);
    // &=
    OP_TYPE_ASSIGN_AND:
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_AND);
    // |=
    OP_TYPE_ASSIGN_OR:
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_OR);
    // #=
    OP_TYPE_ASSIGN_XOR:
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_XOR);
    // <<=
    OP_TYPE_ASSIGN_SHIFT_LEFT:
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_SHL);
    // >>=
    OP_TYPE_ASSIGN_SHIFT_RIGHT:
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_SHR);
  end;
  // 生成目标操作数
  if bIsArray then
  begin
    AddArrayIndexVarICodeOp(g_iCurrScope, iInstrIndex, pSymbol.iIndex, g_iTempVar1SymbolIndex);
  end
  else
  begin
    AddVarICodeOp(g_iCurrScope, iInstrIndex, pSymbol.iIndex);
  end;
  // 生成源操作数
  AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
end;

procedure ParseFactor();
var
  iInstrIndex: Integer;
  bUnaryOpPending: Boolean;
  iOpType: Integer;
  itmp: Integer;
  iStringIndex: Integer;
  //
  pSymbol: pSymbolNode;
  //
  iTrueJumpTargetIndex: Integer;
  iExitJumpTargetIndex: Integer;
  //
  iOpIndex: Integer;
begin
  bUnaryOpPending := False;
  // 首先检查单目运算符
  if ((GetNextToken() = TOKEN_TYPE_OP) and //
    (GetCurrOp in [OP_TYPE_ADD, OP_TYPE_SUB, OP_TYPE_BITWISE_NOT, OP_TYPE_LOGICAL_NOT])) then
  begin
    // 如果找到就保存并设置单目运算标记
    bUnaryOpPending := True;
    iOpType := GetCurrOp();
  end
  else
  begin
    // 否则回卷属性符流
    RewindTokenStream();
  end;
  // 根据下一个属性符确定我们正在处理的那种因子
  case GetNextToken() of
    // 是True或False常量，所以把0,1 压入堆栈
    TOKEN_TYPE_RSRVD_TRUE, TOKEN_TYPE_RSRVD_FALSE:
      begin
        iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_PUSH);
        if GetCurrToken() = TOKEN_TYPE_RSRVD_TRUE then
          itmp := 1
        else
          itmp := 0;

        AddIntICodeOp(g_iCurrScope, iInstrIndex, itmp);
      end;
    TOKEN_TYPE_INT:
      begin
        iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_PUSH);
        AddIntICodeOp(g_iCurrScope, iInstrIndex, StrToInt(GetCurrLexeme()));
      end;
    TOKEN_TYPE_FLOAT:
      begin
        iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_PUSH);
        AddFloatICodeOp(g_iCurrScope, iInstrIndex, StrToFloat(GetCurrLexeme()));
      end;
    // 是一个字符串字面量，所以将其加入到字符串表格中并将所有压入堆栈中
    TOKEN_TYPE_STRING:
      begin
        iStringIndex := AddString(@g_stringTable, GetCurrLexeme());
        iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_PUSH);
        AddStringICodeOp(g_iCurrScope, iInstrIndex, iStringIndex);
      end;
    // 标识符的话
    TOKEN_TYPE_IDENT:
      begin
        // 首先检查标识符是变量还是数组
        pSymbol := GetSymbolByIdent(GetCurrLexeme(), g_iCurrScope);
        if pSymbol <> nil then
        begin
          // 标识符后面是否有索引
          if GetLookAHeadChar() = '[' then
          begin
            // 确保这个变量时一个数组
            if pSymbol.iSize = 1 then
            begin
              printError('Invalid array');
            end;
            // 检查左括号
            ReadToken(TOKEN_TYPE_DELIM_OPEN_BRACE);
            // 确保表达式的存在
            if (GetLookAHeadChar() = ']') then
            begin
              printError('Invalid expression');
            end;
            // 递归分析索引表达式
            ParseExpr();
            // 确保括号存在
            ReadToken(TOKEN_TYPE_DELIM_CLOSE_BRACE);
            // 将结果弹出到_T0
            iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_POP);
            AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
            // 将原来的标识符压入堆栈中，并以_T0作为索引
            iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_PUSH);
            AddArrayIndexVarICodeOp(g_iCurrScope, iInstrIndex, pSymbol.iIndex,
              g_iTempVar0SymbolIndex);
          end
          else
          begin
            // 如果不是，确保这个标识符不是一个数组，并将其压入到堆栈中
            if pSymbol.iSize = 1 then
            begin
              iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_PUSH);
              AddVarICodeOp(g_iCurrScope, iInstrIndex, pSymbol.iIndex);
            end
            else
            begin
              printError('Arrays must be indexed');
            end;
          end;
        end
        else
        begin
          if (GetFuncByName(GetCurrLexeme()) <> nil) then
          begin
            // 是函数则分析函数调用
            ParseFuncCall();
            // 压入返回值
            iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_PUSH);
            AddRegICodeOp(g_iCurrScope, iInstrIndex, REG_CODE_RETVAL);
          end;
        end;
      end;
    // 是一个嵌套的表达式，所以递归调用ParseExpr() 并检查右括号
    TOKEN_TYPE_DELIM_OPEN_PAREN:
      begin
        ParseExpr();
        ReadToken(TOKEN_TYPE_DELIM_CLOSE_PAREN);
      end;
  else
    printError('Invalid input');
  end;
  // 是否有没有处理的单目运算符
  if (bUnaryOpPending) then
  begin
    // 有的话从堆栈中弹出因子
    iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_POP);
    AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
    // 执行单目运算符
    if iOpType = OP_TYPE_LOGICAL_NOT then
    begin
      iTrueJumpTargetIndex := GetNextJumpTargetIndex();
      iExitJumpTargetIndex := GetNextJumpTargetIndex();

      // je _T0,0,true
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JE);
      AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
      AddIntICodeOp(g_iCurrScope, iInstrIndex, 0);
      AddJumpTargetICodeOp(g_iCurrScope, iInstrIndex, iTrueJumpTargetIndex);

      // push 0
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_PUSH);
      AddIntICodeOp(g_iCurrScope, iInstrIndex, 0);

      // jmp L1
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JMP);
      AddJumpTargetICodeOp(g_iCurrScope, iInstrIndex, iExitJumpTargetIndex);

      // L0: (True)
      AddICodeInstr(g_iCurrScope, iTrueJumpTargetIndex);

      // push 1
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_PUSH);
      AddIntICodeOp(g_iCurrScope, iInstrIndex, 1);

      // L1: (Exit)
      AddICodeJumpTarget(g_iCurrScope, iExitJumpTargetIndex);
    end
    else
    begin
      case iOpType of
        OP_TYPE_SUB:
          iOpIndex := INSTR_NEG;
        OP_TYPE_BITWISE_NOT:
          iOpIndex := INSTR_NOT;
      end;

      // add the instruction's operand
      iInstrIndex := AddICodeInstr(g_iCurrScope, iOpIndex);
      AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
      // push the result onto the stack
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_PUSH);
      AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
    end;
  end;
end;

procedure ParseTerm();
var
  iInstrIndex: Integer;
  iOpType: Integer;
  iOpInstr: Integer;
begin
  // 分析第一个因子
  ParseFactor();
  // 分析 后续的* , /,%,^,&,|,#,>> and >> 运算符
  while True do
  begin
    // 获得下一个属性符
    if ( //
      (GetNextToken() <> TOKEN_TYPE_OP) or //
      (not(GetCurrOp in [OP_TYPE_MUL, OP_TYPE_DIV, OP_TYPE_MOD, OP_TYPE_EXP, OP_TYPE_BITWISE_AND,
      OP_TYPE_BITWISE_OR, OP_TYPE_BITWISE_XOR, OP_TYPE_BITWISE_SHIFT_LEFT,
      OP_TYPE_BITWISE_SHIFT_RIGHT]))) then
    begin
      RewindTokenStream();
      Break;
    end;
    // 保存运算符
    iOpType := GetCurrOp();
    // 分析第二个因子
    ParseFactor();
    // 将第一个操作数弹出到_T1
    iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_POP);
    AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar1SymbolIndex);
    // 将第二个操作数弹出到_T0
    iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_POP);
    AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
    // 根据运算符类型完成相应的操作
    case iOpType of
      OP_TYPE_MUL:
        iOpInstr := INSTR_MUL;
      OP_TYPE_DIV:
        iOpInstr := INSTR_DIV;
      OP_TYPE_MOD:
        iOpInstr := INSTR_MOD;
      OP_TYPE_EXP:
        iOpInstr := INSTR_EXP;
      OP_TYPE_BITWISE_AND:
        iOpInstr := INSTR_AND;
      OP_TYPE_BITWISE_OR:
        iOpInstr := INSTR_OR;
      OP_TYPE_BITWISE_XOR:
        iOpInstr := INSTR_XOR;
      OP_TYPE_BITWISE_SHIFT_LEFT:
        iOpInstr := INSTR_SHL;
      OP_TYPE_BITWISE_SHIFT_RIGHT:
        iOpInstr := INSTR_SHR;
    end;

    iInstrIndex := AddICodeInstr(g_iCurrScope, iOpInstr);
    AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
    AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar1SymbolIndex);
    // 结果入栈(保存到_T0)
    iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_PUSH);
    AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
  end;
end;

procedure ParseExpr();
var
  iInstrIndex: Integer;
  iOpType: Integer;
  //
  iTrueJumpTargetIndex: Integer;
  iFalseJumpTargetIndex: Integer;
  iExitJumpTargetIndex: Integer;
begin
  ParseSubExpr();

  while True do
  begin
    if ((GetNextToken() <> TOKEN_TYPE_OP) or ((not IsOpRelational(GetCurrOp())) and
      (not IsOpLogical(GetCurrOp())))) then
    begin
      RewindTokenStream();
      Break;
    end;
    // save the operator
    iOpType := GetCurrOp();
    // parse the second term
    ParseSubExpr();
    // pop the first operand into _T1
    iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_POP);
    AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar1SymbolIndex);
    // pop the second operand into _T0
    iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_POP);
    AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
    // perform the binary operation associated with the specified operator
    // determine the operator type
    if IsOpRelational(iOpType) then
    begin
      // get a pair of free jump target indices
      iTrueJumpTargetIndex := GetNextJumpTargetIndex();
      iExitJumpTargetIndex := GetNextJumpTargetIndex();
      // it's a relational operator
      case iOpType of
        // equal
        OP_TYPE_EQUAL:
          iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JE);
        // not equal
        OP_TYPE_NOT_EQUAL:
          iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JNE);
        // greater
        OP_TYPE_GREATER:
          iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JG);
        // less
        OP_TYPE_LESS:
          iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JL);
        // Greater or equal
        OP_TYPE_GREATER_EQUAL:
          // generate a JGE instruction
          iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JGE);
        // ;less then or equal
        OP_TYPE_LESS_EQUAL:
          iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JLE);
      end;
      // add the jump instruction's operands (_T0 and _T1)
      AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
      AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar1SymbolIndex);
      AddJumpTargetICodeOp(g_iCurrScope, iInstrIndex, iTrueJumpTargetIndex);
      // generate the outcome for falsehood
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_PUSH);
      AddIntICodeOp(g_iCurrScope, iInstrIndex, 0);
      // generate a jump past the true outcome
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JMP);
      AddJumpTargetICodeOp(g_iCurrScope, iInstrIndex, iExitJumpTargetIndex);
      // set the jump target for the true outcome
      AddICodeJumpTarget(g_iCurrScope, iTrueJumpTargetIndex);
      // generate the outcome for truth
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_PUSH);
      AddIntICodeOp(g_iCurrScope, iInstrIndex, 1);
      // set the jump target for exiting the operand evaluation
      AddICodeJumpTarget(g_iCurrScope, iExitJumpTargetIndex);
    end
    else
    begin
      // it must be a logical operator
      case iOpType of
        // and
        OP_TYPE_LOGICAL_AND:
          begin
            iFalseJumpTargetIndex := GetNextJumpTargetIndex();
            iExitJumpTargetIndex := GetNextJumpTargetIndex();

            // JE _T0,0,True
            iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JE);
            AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
            AddIntICodeOp(g_iCurrScope, iInstrIndex, 0);
            AddJumpTargetICodeOp(g_iCurrScope, iInstrIndex, iFalseJumpTargetIndex);
            // JE _T1,0,True
            iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JE);
            AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar1SymbolIndex);
            AddIntICodeOp(g_iCurrScope, iInstrIndex, iFalseJumpTargetIndex);
            // Push 1
            iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_PUSH);
            AddIntICodeOp(g_iCurrScope, iInstrIndex, 1);
            // Jmp Exit
            iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JMP);
            AddJumpTargetICodeOp(g_iCurrScope, iInstrIndex, iExitJumpTargetIndex);
            // L0:(False)
            AddICodeInstr(g_iCurrScope, iFalseJumpTargetIndex);
            // Push 0
            iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_PUSH);
            AddIntICodeOp(g_iCurrScope, iInstrIndex, 0);
            // L1:(Exit)
            AddICodeJumpTarget(g_iCurrScope, iExitJumpTargetIndex);
          end;
        // or
        OP_TYPE_LOGICAL_OR:
          begin
            // get a pair of free jump target indices
            iTrueJumpTargetIndex := GetNextJumpTargetIndex();
            iExitJumpTargetIndex := GetNextJumpTargetIndex();
            // JNE _T0,0,True
            iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JNE);
            AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
            AddIntICodeOp(g_iCurrScope, iInstrIndex, 0);
            AddJumpTargetICodeOp(g_iCurrScope, iInstrIndex, iTrueJumpTargetIndex);
            // JNE _T1,0,True
            iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JNE);
            AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar1SymbolIndex);
            AddIntICodeOp(g_iCurrScope, iInstrIndex, 0);
            AddJumpTargetICodeOp(g_iCurrScope, iInstrIndex, iTrueJumpTargetIndex);
            // Push 0
            iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_PUSH);
            AddIntICodeOp(g_iCurrScope, iInstrIndex, 0);
            // Jmp Exit
            iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JMP);
            AddJumpTargetICodeOp(g_iCurrScope, iInstrIndex, iExitJumpTargetIndex);
            // L0:(True)
            AddICodeJumpTarget(g_iCurrScope, iTrueJumpTargetIndex);
            // Push 1
            iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_PUSH);
            AddIntICodeOp(g_iCurrScope, iInstrIndex, 1);
            // L1:(Exit)
            AddICodeJumpTarget(g_iCurrScope, iExitJumpTargetIndex);
          end;
      end;
    end
  end;
end;

procedure ParseSubExpr();
var
  iInstrIndex: Integer;
  iOpType: Integer;
  iOpInstr: Integer;
begin
  // 分析第一项
  ParseTerm();
  // 分析后续的 + 或者 - 运算符
  while True do
  begin
    // 获得下一个属性符
    if ((GetNextToken() <> TOKEN_TYPE_OP) or //
      (not(GetCurrOp() in [OP_TYPE_ADD, OP_TYPE_SUB, OP_TYPE_CONCAT]))) then
    begin
      RewindTokenStream();
      Break;
    end;
    iOpType := GetCurrOp();
    // 分析第二项
    ParseTerm();
    // 将第一个操作数弹出到_T1
    iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_POP);
    AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar1SymbolIndex);
    // 将第二个操作数弹出到_T0
    iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_POP);
    AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
    // 根据特定的运算符进行相应的操作  + - $
    case iOpType of
      // add
      OP_TYPE_ADD:
        iOpInstr := INSTR_ADD;
      OP_TYPE_SUB:
        iOpInstr := INSTR_SUB;
      OP_TYPE_CONCAT:
        iOpInstr := INSTR_CONCAT;
    end;
    iInstrIndex := AddICodeInstr(g_iCurrScope, iOpInstr);
    AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
    AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar1SymbolIndex);
    // 结果入栈(保存在_T0中)
    iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_PUSH);
    AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
  end;
end;

// 分析高级语法
procedure ParseIf();
var
  iInstrIndex: Integer;
  iFalseJumpTargetIndex: Integer;
  iSkipFalseJumpTargetIndex: Integer;
begin
  if g_iCurrScope = SCOPE_GLOBAL then
    ExitOnError('if illegal in global scope');

  // 标注代码行
  AddICodeSourceLine(g_iCurrScope, GetCurrSourceLine());

  // 创建一个跳转目标
  iFalseJumpTargetIndex := GetNextJumpTargetIndex();

  // 读入左括号
  ReadToken(TOKEN_TYPE_DELIM_OPEN_PAREN);

  // 分析表达式并将值放到堆栈中
  ParseExpr();

  // 读入右括号
  ReadToken(TOKEN_TYPE_DELIM_CLOSE_PAREN);

  // 将结果弹出到_T0,并与 0 进行比较
  iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_POP);
  AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);

  // 如果结果是 0，跳转到false目标
  iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JE);
  AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
  AddIntICodeOp(g_iCurrScope, iInstrIndex, 0);
  AddJumpTargetICodeOp(g_iCurrScope, iInstrIndex, iFalseJumpTargetIndex);

  // 分析true语句块
  ParseStatement();

  // 查找else语句
  if GetNextToken() = TOKEN_TYPE_RSRVD_ELSE then
  begin
    // 如果找到就在true语句后面加上无条件跳转以跳过false语句块
    iSkipFalseJumpTargetIndex := GetNextJumpTargetIndex();
    iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JMP);
    AddJumpTargetICodeOp(g_iCurrScope, iInstrIndex, iSkipFalseJumpTargetIndex);

    // 将false目标放在false语句块的前面
    AddICodeJumpTarget(g_iCurrScope, iFalseJumpTargetIndex);

    // 分析false语句块
    ParseStatement();

    // 设置false语句块后面的跳转目标
    AddICodeJumpTarget(g_iCurrScope, iSkipFalseJumpTargetIndex);
  end
  else
  begin
    // 否则回卷属性流
    RewindTokenStream();

    // 将false目标放在true代码块的后面
    AddICodeJumpTarget(g_iCurrScope, iFalseJumpTargetIndex);
  end;
end;

// while ( <Expression> ) <Statement>
procedure ParseWhile();
var
  iInstrIndex: Integer;
  iStartTargetIndex: Integer;
  iEndTargetIndex: Integer;
  apLoop: pLoop;
begin
  // 确保我们在一个函数中
  if g_iCurrScope = SCOPE_GLOBAL then
    printError('statement illegal in global scope');

  // 标注代码行
  AddICodeSourceLine(g_iCurrScope, GetCurrSourceLine());

  // 获得两个跳转目标。分别对应于循环顶部和底部操作
  iStartTargetIndex := GetNextJumpTargetIndex();
  iEndTargetIndex := GetNextJumpTargetIndex();

  // 在循环的最后设置一个跳转目标
  AddICodeJumpTarget(g_iCurrScope, iStartTargetIndex);

  // 读入左括号 '('
  ReadToken(TOKEN_TYPE_DELIM_OPEN_PAREN);

  // 分析表达式并将结果压入到堆栈
  ParseExpr();

  // 读入右括号 ')'
  ReadToken(TOKEN_TYPE_DELIM_CLOSE_PAREN);

  // 将结果弹出到_T0,如果非 0 的话就跳出循循环
  iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_POP);
  AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);

  iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JE);
  AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
  AddIntICodeOp(g_iCurrScope, iInstrIndex, 0);
  AddJumpTargetICodeOp(g_iCurrScope, iInstrIndex, iEndTargetIndex);

  // 创建一个新的循环实例结构
  GetMem(apLoop, SizeOf(Loop));

  // 设置开始和结束跳转的目标索引
  apLoop.iStartTargetIndex := iStartTargetIndex;
  apLoop.iEndTargetIndex := iEndTargetIndex;

  // 将循环结构压入到堆栈中
  Push(@g_LoopStack, apLoop);

  // 分析循环体
  ParseStatement();

  // 弹出循环体
  PopUp(@g_LoopStack);

  // 无条件跳转回到循环开始的地方
  iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JMP);
  AddJumpTargetICodeOp(g_iCurrScope, iInstrIndex, iStartTargetIndex);

  // 设置循环最后的跳转目标
  AddICodeJumpTarget(g_iCurrScope, iEndTargetIndex);
end;

// for ( <Initializer>; <Condition>; <Perpetuator> )
// <Statement>
procedure ParseFor();
var
  iInstrIndex: Integer;
  iStartTargetIndex: Integer;
  iEndTargetIndex: Integer;
  apLoop: pLoop;
  InitToken: Token;
begin
  // like the loop of while
  if g_iCurrScope = SCOPE_GLOBAL then
    ExitOnError('for illegal in global scope');

  // annotate the line
  AddICodeSourceLine(g_iCurrScope, GetCurrSourceLine());

  // A for loop parser implementation could go here
  // 获得两个跳转目标，分别对应于循环顶部和底部
  iStartTargetIndex := GetNextJumpTargetIndex();
  iEndTargetIndex := GetNextJumpTargetIndex();
  // 在循环的最后设置一个跳转目标
  AddICodeJumpTarget(g_iCurrScope, iStartTargetIndex);
  // 读入左括号 '('
  ReadToken(TOKEN_TYPE_DELIM_OPEN_PAREN);
  // 分析第一个赋值语句
  if GetLookAHeadChar() = ';' then
  begin
    // ';'
    ReadToken(TOKEN_TYPE_DELIM_SEMICOLON);
  end
  else
  begin
    InitToken := GetNextToken();
    case InitToken of
      TOKEN_TYPE_END_OF_STREAM:
        printError('Unexpected end of file');
      TOKEN_TYPE_IDENT:
        begin
          ParseAssign();
        end;
    else
      printError('L_Value is Error in the first parame of for');
    end;
  end;
  // 分析条件表达式
  if GetLookAHeadChar() = ';' then
  begin
    // ';'
    ReadToken(TOKEN_TYPE_DELIM_SEMICOLON);
  end
  else
  begin
    ParseExpr();
  end;

  // // 分析自增项
  // if GetLookAHeadChar() = ';' then
  // begin
  // // ';'
  // ReadToken(TOKEN_TYPE_DELIM_SEMICOLON);
  // end
  // else
  // begin
  // ParseExpr();
  // end;
  // // 读入右括号 ')'
  // ReadToken(TOKEN_TYPE_DELIM_CLOSE_PAREN);

  // 将结果弹出到_T0,如果非 0 的话就跳出循循环
  iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_POP);
  AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);

  iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JE);
  AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
  AddIntICodeOp(g_iCurrScope, iInstrIndex, 0);
  AddJumpTargetICodeOp(g_iCurrScope, iInstrIndex, iEndTargetIndex);

  // 创建一个新的循环实例结构
  GetMem(apLoop, SizeOf(Loop));

  // 设置开始和结束跳转的目标索引
  apLoop.iStartTargetIndex := iStartTargetIndex;
  apLoop.iEndTargetIndex := iEndTargetIndex;

  // 将循环结构压入到堆栈中
  Push(@g_LoopStack, apLoop);

  // 分析循环体
  ParseStatement();

  // 弹出循环体
  PopUp(@g_LoopStack);

  // 无条件跳转回到循环开始的地方
  iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JMP);
  AddJumpTargetICodeOp(g_iCurrScope, iInstrIndex, iStartTargetIndex);

  // 设置循环最后的跳转目标
  AddICodeJumpTarget(g_iCurrScope, iEndTargetIndex);
end;

procedure ParseBreak();
var
  iTargetIndex: Integer;
  iInstrIndex: Integer;
begin
  // 确保在一个循环中
  if IsStackEmpty(@g_LoopStack) then
    printError('break illegal outside loops');

  // 标注代码行
  AddICodeSourceLine(g_iCurrScope, GetCurrSourceLine());

  // 试图读入一个分号
  ReadToken(TOKEN_TYPE_DELIM_SEMICOLON);

  // 获得循环结束的跳转目标索引
  iTargetIndex := pLoop(peek(@g_LoopStack)).iEndTargetIndex;

  // 无条件跳转到循环的结束位置
  iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JMP);
  AddJumpTargetICodeOp(g_iCurrScope, iInstrIndex, iTargetIndex);
end;

procedure ParseContinue();
var
  iTargetIndex: Integer;
  iInstrIndex: Integer;
begin
  if IsStackEmpty(@g_LoopStack) then
    printError('continue illegal outside loops');

  // 标准代码行
  AddICodeSourceLine(g_iCurrScope, GetCurrSourceLine());

  // 试图读入分号
  ReadToken(TOKEN_TYPE_DELIM_SEMICOLON);

  // 获得循环开始位置的跳转目标索引
  iTargetIndex := pLoop(peek(@g_LoopStack)).iStartTargetIndex;

  // 无条件跳转
  iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_JMP);
  AddJumpTargetICodeOp(g_iCurrScope, iInstrIndex, iTargetIndex);
end;

procedure ParseReturn();
var
  iInstrIndex: Integer;
begin
  // 确保我们在一个函数里
  if g_iCurrScope = SCOPE_GLOBAL then
    printError('return illegal in global scope');
  // 标注代码行
  AddICodeSourceLine(g_iCurrScope, GetCurrSourceLine());
  // 如果后面没有分号，分析表达式并将结果放到_RetVal中
  if GetLookAHeadChar() <> ';' then
  begin
    // 分析表达式并计算返回值，将返回值放到堆栈中
    ParseExpr();
    // 确定我们从哪个函数返回
    if (g_ScriptHeader.iIsMainFuncPresent = 1) and (g_ScriptHeader.iMainFuncIndex = g_iCurrScope)
    then
    begin
      // 如果是 _Main(), 将结果弹出到_T0
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_POP);
      AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
    end
    else
    begin
      // 如果不是_Main,将结果弹出到_RetVal寄存器
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_POP);
      AddRegICodeOp(g_iCurrScope, iInstrIndex, REG_CODE_RETVAL);
    end;

  end
  else
  begin
    // 退出_Main()的时候清理 _T0
    if (g_ScriptHeader.iIsMainFuncPresent = 1) and (g_ScriptHeader.iMainFuncIndex = g_iCurrScope)
    then
    begin
      iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_MOV);
      AddVarICodeOp(g_iCurrScope, iInstrIndex, 0);
    end;
  end;

  if (g_ScriptHeader.iIsMainFuncPresent = 1) and (g_ScriptHeader.iMainFuncIndex = g_iCurrScope) then
  begin
    // 是_Main,所以退出并以_T0作为退出代码
    iInstrIndex := AddICodeInstr(g_iCurrScope, INSTR_EXIT);
    AddVarICodeOp(g_iCurrScope, iInstrIndex, g_iTempVar0SymbolIndex);
  end
  else
  begin
    // 不是_Main,所以从函数返回
    AddICodeInstr(g_iCurrScope, INSTR_RET);
  end;
end;

end.
