{ ******************************************************* }
{                                                         }
{ XVM                                                     }
{                                                         }
{ 版权所有 (C) 2012 adsj                                  }
{ Mode： I-code中间代码(->XASM)模块                       }
{ ******************************************************* }
unit i_code;

interface

uses
  System.SysUtils, linked_list, func_table;

const
{$REGION '静态变量'}
  // I_Code Node Types
  ICODE_NODE_INSTR = 0;
  ICODE_NODE_SOURCE_LINE = 1;
  ICODE_NODE_JUMP_TARGET = 2;
  // 指令
  // -------I_CODE Instruction Opcodes
  INSTR_MOV = 0;

  INSTR_ADD = 1;
  INSTR_SUB = 2;
  INSTR_MUL = 3;
  INSTR_DIV = 4;
  INSTR_MOD = 5;
  INSTR_EXP = 6;
  INSTR_NEG = 7;
  INSTR_INC = 8;
  INSTR_DEC = 9;
  // CALC
  INSTR_AND = 10;
  INSTR_OR = 11;
  INSTR_XOR = 12;
  INSTR_NOT = 13;
  INSTR_SHL = 14;
  INSTR_SHR = 15;
  // STRING
  INSTR_CONCAT = 16;
  INSTR_GETCHAR = 17;
  INSTR_SETCHAR = 18;
  // JUMP INSTR
  INSTR_JMP = 19;
  INSTR_JE = 20;
  INSTR_JNE = 21;
  INSTR_JG = 22;
  INSTR_JL = 23;
  INSTR_JGE = 24;
  INSTR_JLE = 25;
  // STACK
  INSTR_PUSH = 26;
  INSTR_POP = 27;
  // FUNC
  INSTR_CALL = 28;
  INSTR_RET = 29;
  INSTR_CALLHOST = 30;
  // SYSTEM
  INSTR_PAUSE = 31;
  INSTR_EXIT = 32;
  // 中间代码操作数类型表
  OP_TYPE_INT = 0; // 整形字面量
  OP_TYPE_FLOAT = 1; // 浮点型字面量
  OP_TYPE_STRING_INDEX = 2; // 字符串字面量
  OP_TYPE_VAR = 3; // 变量
  OP_TYPE_ARRAY_INDEX_ABS = 4; // 使用绝对索引数组
  OP_TYPE_ARRAY_INDEX_VAR = 5; // 使用相对索引数组
  OP_TYPE_JUMP_TARGET_INDEX = 6; // 跳转目标索引
  OP_TYPE_FUNC_INDEX = 7; // 函数索引
  OP_TYPE_REG = 9; // 寄存器
{$ENDREGION}

type
  // ----------------------------------------------------------
  // 一条中间代码指令
  _ICodeInstr = record
    iOpcode: Integer; // 操作码
    OpList: LinkedList; // 操作数列表
  end;

  ICodeInstr = _ICodeInstr;
  // ----------------------------------------------------------
  pOp = ^Op;

  // 中间代码的操作数
  _Op = record
    iType: Integer; // 类型
    iOffset: Integer; // 偏移量
    iOffsetSymbolIndex: Integer; // 偏移符号索引
    // 值
    case Integer of
      0:
        (iIntLiteral: Integer); // 整数字面值
      1:
        (fFloatLiteral: Real); // 浮点字面值
      2:
        (iStringIndex: Integer); // 字符串表索引
      3:
        (iSymbolIndex: Integer); // 符号表索引
      4:
        (iJumpTargetIndex: Integer); // 跳转目标索引
      5:
        (iFuncIndex: Integer); // 函数索引
      6:
        (iRegCode: Integer); // Register code  寄存器
  end;

  Op = _Op;

  // ----------------------------------------------------------
  // 中间代码节点
  pICodeNode = ^ICodeNode;

  _ICodeNode = record
    iType: Integer; // 节点类型
    case Integer of
      0:
        (Instr: ICodeInstr); // 中间代码指令
      1:
        (pstrSourceLine: PAnsiChar); // 标注这个指令的源代码行
      2:
        (iJumpTargetIndex: Integer); // 跳转目标索引
  end;

  ICodeNode = _ICodeNode;

  // ----------------------------------------------------------
  (* 添加指令 *)
function AddICodeInstr(iFuncIndex: Integer; iOpcode: Integer): Integer;
(* 添加操作数 *)
procedure AddICodeOp(iFuncIndex: Integer; iInstrIndex: Integer; Value: Op);
// ----------------------------------------------------------
{$REGION '添加各种操作数'}
(* 添加整形字面量操作数 *)
procedure AddIntICodeOp(iFuncIndex: Integer; iInstrIndex: Integer; iValue: Integer);
(* 添加浮点字面值操作数 *)
procedure AddFloatICodeOp(iFuncIndex: Integer; iInstrIndex: Integer; fValue: Real);
(* 添加字符串操作数 *)
procedure AddStringICodeOp(iFuncIndex: Integer; iInstrIndex: Integer; iStringIndex: Integer);
(* 添加变量操作数 *)
procedure AddVarICodeOp(iFuncIndex: Integer; iInstrIndex: Integer; iSymbolIndex: Integer);
(* 添加绝对索引数组操作数 *)
procedure AddArrayIndexABSICodeOp(iFuncIndex: Integer; iInstrIndex: Integer;
  iArraySymbolIndex: Integer; iOffset: Integer);
(* 添加相对索引数组操作数 *)
procedure AddArrayIndexVarICodeOp(iFuncIndex: Integer; iInstrIndex: Integer;
  iArraySymbolIndex: Integer; iOffsetSymbolIndex: Integer);
(* 添加函数操作数 *)
procedure AddFuncICodeOp(iFuncIndex: Integer; iInstrIndex: Integer; iOpFuncIndex: Integer);
(* 添加寄存器操作数 *)
procedure AddRegICodeOp(iFuncIndex: Integer; iInstrIndex: Integer; iRegCode: Integer);
(* 添加跳转目标索引操作数 *)
procedure AddJumpTargetICodeOp(iFuncIndex: Integer; iInstrIndex: Integer; iTargetIndex: Integer);
{$ENDREGION}
// ----------------------------------------------------------
(* 获取中间代码节点 *)
function GetICodeNodeByImpIndex(iFuncIndex: Integer; iInstrIndex: Integer): pICodeNode;
(* 获取节点 *)
function GetICodeOpByIndex(pInstr: pICodeNode; iOpIndex: Integer): pOp;
(* 添加跳转目标 *)
procedure AddICodeJumpTarget(iFuncIndex: Integer; iTargetIndex: Integer);
(* 返回当前目标索引 *)
function GetNextJumpTargetIndex(): Integer;
(* 添加源代码标注 *)
procedure AddICodeSourceLine(iFuncIndex: Integer; pstrSourceLine: PAnsiChar);

// ----------------------------------------------------------
var
  g_iCurrJumpTargetIndex: Integer;

implementation

function AddICodeInstr(iFuncIndex: Integer; iOpcode: Integer): Integer;
var
  pFunc: pFuncNode;
  pInstrNode: pICodeNode;
  iIndex: Integer;
begin
  pFunc := GetFuncByIndex(iFuncIndex);

  GetMem(pInstrNode, SizeOf(ICodeNode));

  pInstrNode.iType := ICODE_NODE_INSTR;
  pInstrNode.Instr.iOpcode := iOpcode;

  pInstrNode.Instr.OpList.iNodeCount := 0;

  iIndex := AddNode(@pFunc.ICodeStream, pInstrNode);

  Result := iIndex;
end;

// ----------------------------------------------------------
function GetICodeNodeByImpIndex(iFuncIndex: Integer; iInstrIndex: Integer): pICodeNode;
var
  pFunc: pFuncNode;
  pCurrNode: pLinkedListNode;
  iCurrNode: Integer;
begin
  pFunc := GetFuncByIndex(iFuncIndex);

  if pFunc.ICodeStream.iNodeCount = 0 then
  begin
    Result := nil;
    Exit;
  end;
  pCurrNode := pFunc.ICodeStream.pHead;

  for iCurrNode := 0 to pFunc.ICodeStream.iNodeCount - 1 do
  begin
    if iInstrIndex = iCurrNode then
    begin
      Result := pICodeNode(pCurrNode.pData);
      Exit;
    end;
    pCurrNode := pCurrNode.pNext;
  end;

  Result := nil;
end;

function GetICodeOpByIndex(pInstr: pICodeNode; iOpIndex: Integer): pOp;
var
  pCurrNode: pLinkedListNode;
  iCurrNode: Integer;
begin
  if pInstr.Instr.OpList.iNodeCount = 0 then
  begin
    Result := nil;
    Exit;
  end;

  pCurrNode := pInstr.Instr.OpList.pHead;

  for iCurrNode := 0 to pInstr.Instr.OpList.iNodeCount - 1 do
  begin
    if iOpIndex = iCurrNode then
    begin
      Result := pOp(pCurrNode.pData);
      Exit;
    end;
    pCurrNode := pCurrNode.pNext;
  end;
  Result := nil;
end;

procedure AddICodeOp(iFuncIndex: Integer; iInstrIndex: Integer; Value: Op);
var
  pInstr: pICodeNode;
  pValue: pOp;
begin
  pInstr := GetICodeNodeByImpIndex(iFuncIndex, iInstrIndex);
  GetMem(pValue, SizeOf(Op));
  Move(Value, pValue^, SizeOf(Op));

  AddNode(@pInstr.Instr.OpList, pValue);
end;

// ----------------------------------------------------------
procedure AddIntICodeOp(iFuncIndex: Integer; iInstrIndex: Integer; iValue: Integer);
var
  Value: Op;
begin
  Value.iType := OP_TYPE_INT;
  Value.iIntLiteral := iValue;

  AddICodeOp(iFuncIndex, iInstrIndex, Value);
end;

procedure AddFloatICodeOp(iFuncIndex: Integer; iInstrIndex: Integer; fValue: Real);
var
  Value: Op;
begin
  Value.iType := OP_TYPE_FLOAT;
  Value.fFloatLiteral := fValue;

  AddICodeOp(iFuncIndex, iInstrIndex, Value);
end;

procedure AddStringICodeOp(iFuncIndex: Integer; iInstrIndex: Integer; iStringIndex: Integer);
var
  Value: Op;
begin
  Value.iType := OP_TYPE_STRING_INDEX;
  Value.iStringIndex := iStringIndex;

  AddICodeOp(iFuncIndex, iInstrIndex, Value);
end;

procedure AddVarICodeOp(iFuncIndex: Integer; iInstrIndex: Integer; iSymbolIndex: Integer);
var
  Value: Op;
begin
  Value.iType := OP_TYPE_VAR;
  Value.iSymbolIndex := iSymbolIndex;

  AddICodeOp(iFuncIndex, iInstrIndex, Value);
end;

procedure AddArrayIndexABSICodeOp(iFuncIndex: Integer; iInstrIndex: Integer;
  iArraySymbolIndex: Integer; iOffset: Integer);
var
  Value: Op;
begin
  Value.iType := OP_TYPE_ARRAY_INDEX_ABS;
  Value.iSymbolIndex := iArraySymbolIndex;
  Value.iOffset := iOffset;
  AddICodeOp(iFuncIndex, iInstrIndex, Value);
end;

procedure AddArrayIndexVarICodeOp(iFuncIndex: Integer; iInstrIndex: Integer;
  iArraySymbolIndex: Integer; iOffsetSymbolIndex: Integer);
var
  Value: Op;
begin
  Value.iType := OP_TYPE_ARRAY_INDEX_VAR;
  Value.iSymbolIndex := iArraySymbolIndex;

  AddICodeOp(iFuncIndex, iInstrIndex, Value);
end;

procedure AddFuncICodeOp(iFuncIndex: Integer; iInstrIndex: Integer; iOpFuncIndex: Integer);
var
  Value: Op;
begin
  Value.iType := OP_TYPE_FUNC_INDEX;
  Value.iFuncIndex := iOpFuncIndex;

  AddICodeOp(iFuncIndex, iInstrIndex, Value);
end;

procedure AddRegICodeOp(iFuncIndex: Integer; iInstrIndex: Integer; iRegCode: Integer);
var
  Value: Op;
begin
  Value.iType := OP_TYPE_REG;
  Value.iRegCode := iRegCode;

  AddICodeOp(iFuncIndex, iInstrIndex, Value);
end;

procedure AddJumpTargetICodeOp(iFuncIndex: Integer; iInstrIndex: Integer; iTargetIndex: Integer);
var
  Value: Op;
begin
  Value.iType := OP_TYPE_JUMP_TARGET_INDEX;
  Value.iJumpTargetIndex := iTargetIndex;

  AddICodeOp(iFuncIndex, iInstrIndex, Value);
end;

// ----------------------------------------------------------
procedure AddICodeJumpTarget(iFuncIndex: Integer; iTargetIndex: Integer);
var
  pFunc: pFuncNode;
  pSourceLineNode: pICodeNode;
begin
  pFunc := GetFuncByIndex(iFuncIndex);
  GetMem(pSourceLineNode, SizeOf(ICodeNode));

  pSourceLineNode.iType := ICODE_NODE_JUMP_TARGET;
  pSourceLineNode.iJumpTargetIndex := iTargetIndex;

  AddNode(@pFunc.ICodeStream, pSourceLineNode);
end;

function GetNextJumpTargetIndex(): Integer;
begin
  Result := g_iCurrJumpTargetIndex;
  Inc(g_iCurrJumpTargetIndex);
end;

procedure AddICodeSourceLine(iFuncIndex: Integer; pstrSourceLine: PAnsiChar);
var
  pFunc: pFuncNode;
  pSourceLineNode: pICodeNode;
begin
  pFunc := GetFuncByIndex(iFuncIndex);

  GetMem(pSourceLineNode, SizeOf(ICodeNode));

  pSourceLineNode.iType := ICODE_NODE_SOURCE_LINE;
  pSourceLineNode.pstrSourceLine := pstrSourceLine;

  AddNode(@pFunc.ICodeStream, pSourceLineNode);
end;

// ----------------------------------------------------------
end.
