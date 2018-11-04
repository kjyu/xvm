{ ******************************************************* }
{                                                         }
{ XVM                                                     }
{                                                         }
{ 版权所有 (C) 2012 adsj                                  }
{ Mode： 代码生成模块                                     }
{ ******************************************************* }

unit code_emnit;

interface

uses
  System.SysUtils, globals, symbol_table, func_table, i_code, linked_list;

const
  ppstrMnemonics: array [0 .. 32] of AnsiString = ('Mov', 'Add', 'Sub', 'Mul', 'Div', 'Mod', 'Exp',
    'Neg', 'Inc', 'Dec', 'And', 'Or', 'XOr', 'Not', 'ShL', 'ShR', 'Concat', 'GetChar', 'SetChar',
    'Jmp', 'JE', 'JNE', 'JG', 'JL', 'JGE', 'JLE', 'Push', 'Pop', 'Call', 'Ret', 'CallHost',
    'Pause', 'Exit');
  // ----------------------------------------------------------
  (* 生成头文件 *)
procedure EmitHeader();
(* 生成汇编命令 *)
procedure EmitDirectives();
(* 生成符号声明 *)
procedure EmitScopeSymbols(iScope: Integer; iType: Integer);
(* 生成函数 *)
procedure EmitFunc(pFunc: pFuncNode);
(* 生成完整XASM *)
procedure EmitCode();

// ----------------------------------------------------------
var
  sf: TextFile;

  // ----------------------------------------------------------
implementation

uses codesitelogging;

function madespace(icount: Integer): AnsiString;
var
  i: Integer;
begin
  Result := '';
  if icount <= 0 then
  begin
    Exit;
  end;

  for i := 0 to icount - 1 do
    Result := Result + ' ';
end;

procedure EmitCode();
var
  pNode: pLinkedListNode;
  pCurrFunc: pFuncNode;
  pMainFunc: pFuncNode;
begin
  g_pstrOutPutFileName := 'C:\2.txt';
  AssignFile(sf, g_pstrOutPutFileName);
  Rewrite(sf);
  // ----生成文件头
  EmitHeader();
  // ----生成命令
  Writeln(sf, '; ---- Directives---------------------');
  EmitDirectives();
  // ----生成全局变量声明
  Writeln(sf, '; ---- Global Variables --------------');
  EmitScopeSymbols(SCOPE_GLOBAL, 0);
  // ----生成函数
  Writeln(sf, '; ---- Functions ---------------------');
  // 遍历链表局部节点
  pNode := g_FuncTable.pHead;
  // 局部函数节点指针
  pCurrFunc := nil;
  // 如果发现了函数_Main(),就用指针保存
  pMainFunc := nil;
  // 生成每个函数声明和代码
  if g_FuncTable.iNodeCount > 0 then
  begin
    while True do
    begin
      // 获得节点指针
      pCurrFunc := pFuncNode(pNode.pData);
      // 不能生成主应用程序API函数节点
      if pCurrFunc.iIsHostAPI = 0 then
      begin
        // 当前函数_Main()
        if StrIComp(pCurrFunc.pstrName, MAIN_FUNC_NAME) = 0 then
        begin
          // 是，保存以备后用
          pMainFunc := pCurrFunc;
        end
        else
        begin
          // 不是，那么生成
          EmitFunc(pCurrFunc);
          Write(sf, #13#10#13#10); // \n\n
        end;
      end;
      // next node
      pNode := pNode.pNext;
      if pNode = nil then
        Break;
    end;
  end;
  // ----生成_Main()
  Writeln(sf, '; ---- Main -------------------------------');
  // 发现了_Main(),那就生成这个函数
  if pMainFunc <> nil then
  begin
    Write(sf, #13#10#13#10);
    EmitFunc(pMainFunc);
  end;
  // 关闭文件
  Flush(sf);
  Close(sf);
end;

procedure EmitHeader();
begin
  Writeln(sf, Format('; %s', [g_pstrOutPutFileName]));
  Writeln(sf, Format('; Source File: %s', [g_pstrSourceFileName]));
  Writeln(sf, Format('; XSC Version: %d.%d', [VERSION_MAJOR, VERSION_MINOR]));
  Writeln(sf, Format('; Timestamp: %s', [FormatDateTime('yyyy-mm-dd-hh:MM:ss', Now)]));
end;

procedure EmitDirectives();
begin
  if g_ScriptHeader.iStackSize <> 0 then
  begin
    Writeln(sf, Format('        SetStackSize %d', [g_ScriptHeader.iStackSize]));
  end;
  // 如果设定了优先级SetPriority命令
  if g_ScriptHeader.iPriorityType <> PRIORITY_NONE then
  begin
    Write(sf, '        SetPriority ');
    case g_ScriptHeader.iPriorityType of
      PRIORITY_LOW:
        Writeln(sf, PRIORITY_LOW_KEYWORD);
      PRIORITY_MED:
        Writeln(sf, PRIORITY_MED_KEYWORD);
      PRIORITY_HIGH:
        Writeln(sf, PRIORITY_HIGH_KEYWORD);
      PRIORITY_USER:
        Writeln(sf, Format('%d', [g_ScriptHeader.iUserPriority]));
    end;
  end;
end;

procedure EmitScopeSymbols(iScope: Integer; iType: Integer);
var
  pCurrSymbol: PSymbolNode;
  iCurrSymbolIndex: Integer;
  bAddNewLine: Boolean;
begin
  for iCurrSymbolIndex := 0 to g_SymbolTable.iNodeCount - 1 do
  begin
    pCurrSymbol := GetSymbolByIndex(iCurrSymbolIndex);
    if (pCurrSymbol.iScope = iScope) and (pCurrSymbol.iType = iType) then
    begin
      Write(sf, madespace(4));
      if iScope <> SCOPE_GLOBAL then
        Write(sf, madespace(4));
      if pCurrSymbol.iType = SYMBOL_TYPE_PARAM then
        Write(sf, Format('Param  %s', [pCurrSymbol.pstrIdent]));
      if pCurrSymbol.iType = SYMBOL_TYPE_VAR then
      begin
        Write(sf, Format('Var  %s', [pCurrSymbol.pstrIdent]));
        if pCurrSymbol.iSize > 1 then
          Write(sf, Format('[ %d ]', [pCurrSymbol.iSize]));
      end;
      Writeln(sf, '');
      // bAddNewLine := True;
    end;
  end;
  // if bAddNewLine then
  // Writeln(sf, '');
end;

procedure EmitFunc(pFunc: pFuncNode);
var
  iIsFirstSourceLine: Boolean;
  iCurrInstrIndex: Integer;
  pCurrNode: pICodeNode;
  // source tag
  pstrSourceLine: PAnsiChar;
  iLastCharIndex: Integer;
  //
  iOpCount: Integer;
  iCurrOpIndex: Integer;
  apOp: pOp;
  //
  ispace: Integer;
begin
  // 生成函数声明
  Writeln(sf, Format('Func %s', [pFunc.pstrName]));
  Writeln(sf, madespace(4) + '{');
  // 生成函数参数声明
  EmitScopeSymbols(pFunc.iIndex, SYMBOL_TYPE_PARAM);
  // 生成局部变量声明
  EmitScopeSymbols(pFunc.iIndex, SYMBOL_TYPE_VAR);

  if pFunc.ICodeStream.iNodeCount > 0 then
  begin
    iIsFirstSourceLine := True;

    for iCurrInstrIndex := 0 to pFunc.ICodeStream.iNodeCount - 1 do
    begin
      pCurrNode := GetICodeNodeByImpIndex(pFunc.iIndex, iCurrInstrIndex);

      case pCurrNode.iType of
        // 源代码标注
        ICODE_NODE_SOURCE_LINE:
          begin
            //
            pstrSourceLine := pCurrNode.pstrSourceLine;
            iLastCharIndex := StrLen(pstrSourceLine) - 1;
            if pstrSourceLine[iLastCharIndex] = #10 then
              pstrSourceLine[iLastCharIndex] := #0;
            // 生成注释，如果不是第一行的话预先加入一个换行符
            if not iIsFirstSourceLine then
              Writeln(sf, '');

            Writeln(sf, Format(madespace(8) + '; %s', [trim(AnsiString(pstrSourceLine))])); // \n\n
          end;
        // 中间代码指令
        ICODE_NODE_INSTR:
          begin
            // 生成操作码
            Write(sf, Format(madespace(8) + '%s', [ppstrMnemonics[pCurrNode.Instr.iOpcode]]));
            iOpCount := pCurrNode.Instr.OpList.iNodeCount;
            if iOpCount > 0 then
            begin
              // 每个指令至少一个TAB
              // Write(sf, madespace(8));
              // 如果字符太长，再加一个TAB
              if Length(ppstrMnemonics[pCurrNode.Instr.iOpcode]) < TAB_STOP_WIDTH then
                Write(sf, madespace(TAB_STOP_WIDTH -
                  Length(ppstrMnemonics[pCurrNode.Instr.iOpcode])));

              for iCurrOpIndex := 0 to iOpCount - 1 do
              begin
                apOp := GetICodeOpByIndex(pCurrNode, iCurrOpIndex);

                case apOp.iType of
                  OP_TYPE_INT:
                    Write(sf, ' ' + IntToStr(apOp.iIntLiteral));
                  OP_TYPE_FLOAT:
                    Write(sf, ' ' + floattostr(apOp.fFloatLiteral));
                  OP_TYPE_STRING_INDEX:
                    Write(sf, Format(' "%s"', [GetStringByIndex(@g_StringTable,
                      apOp.iStringIndex)]));
                  OP_TYPE_VAR:
                    Write(sf, Format(' %s', [GetSymbolByIndex(apOp.iSymbolIndex).pstrIdent]));
                  OP_TYPE_ARRAY_INDEX_ABS:
                    Write(sf, Format(' %s [ %d ]', [GetSymbolByIndex(apOp.iSymbolIndex).pstrIdent,
                      apOp.iOffset]));
                  OP_TYPE_ARRAY_INDEX_VAR:
                    Write(sf, Format(' %s [ %s ]', [GetSymbolByIndex(apOp.iStringIndex).pstrIdent,
                      GetSymbolByIndex(apOp.iOffsetSymbolIndex).pstrIdent]));
                  OP_TYPE_FUNC_INDEX:
                    Write(sf, Format(' %s', [GetFuncByIndex(apOp.iSymbolIndex).pstrName]));
                  OP_TYPE_REG:
                    Write(sf, '_RetVal');
                  OP_TYPE_JUMP_TARGET_INDEX:
                    Write(sf, Format(' _L%d', [apOp.iJumpTargetIndex]));
                end;
                if iCurrOpIndex <> iOpCount - 1 then
                  Write(sf, ', ');
              end;
            end;
            Write(sf, #13#10);
          end;
        // 跳转目标
        ICODE_NODE_JUMP_TARGET:
          Writeln(sf, Format(madespace(8) + ' _L%d:', [pCurrNode.iJumpTargetIndex]));
      end;
      if iIsFirstSourceLine then
        iIsFirstSourceLine := False;
    end;

  end
  else
    Writeln(sf, madespace(8) + '; (No Code)');
  Writeln(sf, madespace(4) + '}');
end;

end.
