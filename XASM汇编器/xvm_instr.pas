unit xvm_instr;

interface

uses
  xvm_types, System.SysUtils;

const
  MAX_LEXEME_SIZE = 256;

  LEX_STATE_NO_STRING = 0;
  LEX_STATE_IN_STRING = 1;
  LEX_STATE_END_STRING = 2;

  (* TOKEN  属性字类型常量 *)
  TOKEN_TYPE_INT = 0; // 整形字面量
  TOKEN_TYPE_FLOAT = 1; // 浮点字面量
  TOKEN_TYPE_STRING = 2; // 字符串字面常量值,不包括引号,引号认为是分割属性字
  TOKEN_TYPE_QUOTE = 3; // 双引号
  TOKEN_TYPE_IDENT = 4; // 标示符
  TOKEN_TYPE_COLON = 5; // 冒号
  TOKEN_TYPE_OPEN_BRACKET = 6; // 左中括号
  TOKEN_TYPE_CLOSE_BRACKET = 7; // 右中括号
  TOKEN_TYPE_COMMA = 8; // 逗号
  TOKEN_TYPE_OPEN_BRACE = 9; // 左大括号
  TOKEN_TYPE_CLOSE_BRACE = 10; // 右大括号
  TOKEN_TYPE_NEWLINE = 11; // 换行

  TOKEN_TYPE_INSTR = 12; // 指令

  TOKEN_TYPE_SETSTACKSIZE = 13; // SetStackSize指示符
  TOKEN_TYPE_SETPRIORITY = 14; // 线程优先级设置
  TOKEN_TYPE_VAR = 15; // var 指示符
  TOKEN_TYPE_FUNC = 16; // Fun指示符
  TOKEN_TYPE_PARAM = 17; // Param指示符
  TOKEN_TYPE_REG_RETVAL = 18; // _RetVal寄存器

  TOKEN_TYPE_INVALID = 19; // 不符合属性子的错误
  END_OF_TOKEN_STREAM = 20; // 到达属性自流尾部

  MAX_IDENT_SIZE = 256; // 识别码最大长度

  // ---- Instruction Lookup Table 指令表---------------------------------------------------------//

  MAX_INSTR_LOOKUP_COUNT = 256; // 最大指令数
  MAX_INSTR_MNEMONIC_SIZE = 16; // 指令限制长度

  (*指令操作码*)
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

  // ---- Operand Type Bitfield Flags 操作数------------------------------------------------

  OP_FLAG_TYPE_INT = 1; // 整形字面值
  OP_FLAG_TYPE_FLOAT = 2; // 浮点型字面量值
  OP_FLAG_TYPE_STRING = 4; // 字符串型字面量
  OP_FLAG_TYPE_MEM_REF = 8; // 内存引用(变量或者数组索引)

  OP_FLAG_TYPE_LINE_LABEL = 16; // 行标签
  OP_FLAG_TYPE_FUNC_NAME = 32; // 函数名(用于call指令中)
  OP_FLAG_TYPE_HOST_API_CALL = 64; //
  OP_FLAG_TYPE_REG = 128; // 一个寄存器,在这里是_RetValue寄存器

  // Assembled Instruction Stream 汇编指令流
  OP_TYPE_NULL = -1;
  OP_TYPE_INT = 0;
  OP_TYPE_FLOAT = 1;
  OP_TYPE_STRING_INDEX = 2;
  OP_TYPE_ABS_STACK_INDEX = 3;
  OP_TYPE_REL_STACK_INDEX = 4;
  OP_TYPE_INSTR_INDEX = 5;
  OP_TYPE_FUNC_INDEX = 6;
  OP_TYPE_HOST_API_CALL_INDEX = 7;
  OP_TYPE_REG = 8;
  OP_TYPE_STACK_BASE_MARKER = 9;
  // ---- Priority Types 0.8-----------------------------------------------------------------

  PRIORITY_USER = 0; // 用户定义的优先级
  PRIORITY_LOW = 1; // 低优先级
  PRIORITY_MED = 2; // 中优先级
  PRIORITY_HIGH = 3; // 高优先级

  PRIORITY_LOW_KEYWORD = 'Low'; // 低优先级关键字
  PRIORITY_MED_KEYWORD = 'Med'; // 中优先级关键字
  PRIORITY_HIGH_KEYWORD = 'High'; // 高优先级关键字

  // ---- Functions -------------------------------------------------------------------------
  MAIN_FUNC_NAME = '_MAIN';

procedure InitInstrTable();
function AddInstrLookup(pstrMnemonic: PAnsiChar; iOpcode: integer; iOpcount: integer): integer;
function GetInstrByMnemonic(pstrMnemonic: PAnsiChar; pInstr: pInstrLookup): Boolean;
procedure SetOpType(iInstrIndex: integer; iOpIndex: integer; iOptype: OpType);

var
  // 指令查找表
  g_InstrTable: array [0 .. MAX_INSTR_LOOKUP_COUNT - 1] of InstrLookup;
  // 当前指令数
  g_iCurrInstrCount: integer;
  // 汇编指令流 pointer to a dynamically allocated instruction stream
  g_pInstrStream: ^InStr;
  // 指令长度
  g_iInstrStreamSize: integer;
  // 当前指令索引
  g_iCurrInstrIndex: integer;

implementation

procedure InitInstrTable();
var
  iInstrIndex: integer;
begin
  iInstrIndex := 0;

  // Mov          Destination, Source

  iInstrIndex := AddInstrLookup('MOV', INSTR_MOV, 2);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);

  // Add         Destination, Source

  iInstrIndex := AddInstrLookup('ADD', INSTR_ADD, 2);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);

  // Sub          Destination, Source

  iInstrIndex := AddInstrLookup('SUB', INSTR_SUB, 2);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);

  // Mul          Destination, Source

  iInstrIndex := AddInstrLookup('MUL', INSTR_MUL, 2);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);

  // Div          Destination, Source

  iInstrIndex := AddInstrLookup('DIV', INSTR_DIV, 2);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);

  // Mod          Destination, Source

  iInstrIndex := AddInstrLookup('MOD', INSTR_MOD, 2);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);

  // Exp          Destination, Source

  iInstrIndex := AddInstrLookup('EXP', INSTR_EXP, 2);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);

  // Neg          Destination

  iInstrIndex := AddInstrLookup('NEG', INSTR_NEG, 1);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);

  // Inc          Destination

  iInstrIndex := AddInstrLookup('INC', INSTR_INC, 1);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);

  // Dec          Destination

  iInstrIndex := AddInstrLookup('DEC', INSTR_DEC, 1);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);

  // ---- Bitwise

  // And          Destination, Source

  iInstrIndex := AddInstrLookup('AND', INSTR_AND, 2);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);

  // Or           Destination, Source

  iInstrIndex := AddInstrLookup('OR', INSTR_OR, 2);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);

  // XOr          Destination, Source

  iInstrIndex := AddInstrLookup('XOR', INSTR_XOR, 2);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);

  // Not          Destination

  iInstrIndex := AddInstrLookup('NOT', INSTR_NOT, 1);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);

  // ShL          Destination, Source

  iInstrIndex := AddInstrLookup('SHL', INSTR_SHL, 2);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);

  // ShR          Destination, Source

  iInstrIndex := AddInstrLookup('SHR', INSTR_SHR, 2);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);

  // ---- String Manipulation

  // Concat       String0, String1

  iInstrIndex := AddInstrLookup('CONCAT', INSTR_CONCAT, 2);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG or OP_FLAG_TYPE_STRING);

  // GetChar      Destination, Source, Index

  iInstrIndex := AddInstrLookup('GETCHAR', INSTR_GETCHAR, 3);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG or OP_FLAG_TYPE_STRING);
  SetOpType(iInstrIndex, 2, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG or OP_FLAG_TYPE_INT);

  // SetChar      Destination, Index, Source

  iInstrIndex := AddInstrLookup('SETCHAR', INSTR_SETCHAR, 3);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG or OP_FLAG_TYPE_INT);
  SetOpType(iInstrIndex, 2, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG or OP_FLAG_TYPE_STRING);

  // ---- Conditional Branching

  // Jmp          Label

  iInstrIndex := AddInstrLookup('JMP', INSTR_JMP, 1);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_LINE_LABEL);

  // JE           Op0, Op1, Label

  iInstrIndex := AddInstrLookup('JE', INSTR_JE, 3);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 2, OP_FLAG_TYPE_LINE_LABEL);

  // JNE          Op0, Op1, Label

  iInstrIndex := AddInstrLookup('JNE', INSTR_JNE, 3);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 2, OP_FLAG_TYPE_LINE_LABEL);

  // JG           Op0, Op1, Label

  iInstrIndex := AddInstrLookup('JG', INSTR_JG, 3);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 2, OP_FLAG_TYPE_LINE_LABEL);

  // JL           Op0, Op1, Label

  iInstrIndex := AddInstrLookup('JL', INSTR_JL, 3);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 2, OP_FLAG_TYPE_LINE_LABEL);

  // JGE          Op0, Op1, Label

  iInstrIndex := AddInstrLookup('JGE', INSTR_JGE, 3);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 2, OP_FLAG_TYPE_LINE_LABEL);

  // JLE           Op0, Op1, Label

  iInstrIndex := AddInstrLookup('JLE', INSTR_JLE, 3);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 1, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);
  SetOpType(iInstrIndex, 2, OP_FLAG_TYPE_LINE_LABEL);

  // ---- The Stack Interface

  // Push          Source

  iInstrIndex := AddInstrLookup('PUSH', INSTR_PUSH, 1);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);

  // Pop           Destination

  iInstrIndex := AddInstrLookup('POP', INSTR_POP, 1);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);

  // ---- The Function Interface

  // Call          FunctionName

  iInstrIndex := AddInstrLookup('CALL', INSTR_CALL, 1);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_FUNC_NAME);

  // Ret

  iInstrIndex := AddInstrLookup('RET', INSTR_RET, 0);

  // CallHost      FunctionName

  iInstrIndex := AddInstrLookup('CALLHOST', INSTR_CALLHOST, 1);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_HOST_API_CALL);

  // ---- Miscellaneous

  // Pause        Duration

  iInstrIndex := AddInstrLookup('PAUSE', INSTR_PAUSE, 1);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);

  // Exit         Code

  iInstrIndex := AddInstrLookup('EXIT', INSTR_EXIT, 1);
  SetOpType(iInstrIndex, 0, OP_FLAG_TYPE_INT or OP_FLAG_TYPE_FLOAT or OP_FLAG_TYPE_STRING or
    OP_FLAG_TYPE_MEM_REF or OP_FLAG_TYPE_REG);

end;

function AddInstrLookup(pstrMnemonic: PAnsiChar; iOpcode: integer; iOpcount: integer): integer;
var
  AInstrLookup: InstrLookup;
begin
  // 确保没有超过最大索引
  if g_iCurrInstrCount >= MAX_INSTR_LOOKUP_COUNT then
  begin
    Result := -1;
    Exit;
  end;
  // 设置助记符\操作码\和操作数计数字段
  StrCopy(PAnsiChar(@AInstrLookup.pstrMnemonic), pstrMnemonic);
  AInstrLookup.iOpcode := iOpcode;
  AInstrLookup.iOpcount := iOpcount;
  // 为操作数列表分配空间
  GetMem(AInstrLookup.OpList, sizeof(pOpType) * AInstrLookup.iOpcount);
  // AInstrLookup.OpList := nil;
  g_InstrTable[g_iCurrInstrCount] := AInstrLookup;
  // 返回操作数索引
  Result := g_iCurrInstrCount;
  // 下一个指令索引
  inc(g_iCurrInstrCount);
end;

function GetInstrByMnemonic(pstrMnemonic: PAnsiChar; pInstr: pInstrLookup): Boolean;
var
  iCurrInstrIndex: integer;
begin
  for iCurrInstrIndex := 0 to MAX_INSTR_LOOKUP_COUNT - 1 do
  begin
    if StrIComp(PAnsiChar(@g_InstrTable[iCurrInstrIndex].pstrMnemonic), pstrMnemonic) = 0 then
    begin
      pInstr^ := g_InstrTable[iCurrInstrIndex];
      Result := True;
      Exit;
    end;
    Result := False;
  end;
end;

procedure SetOpType(iInstrIndex: integer; iOpIndex: integer; iOptype: OpType);
begin
  inc(g_InstrTable[iInstrIndex].OpList, iOpIndex);
  g_InstrTable[iInstrIndex].OpList^ := iOptype;
  Dec(g_InstrTable[iInstrIndex].OpList, iOpIndex);
end;

end.
