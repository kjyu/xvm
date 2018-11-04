unit xvm_types;

interface

uses xvm_globals;

type
  _ScriptHeader = record
    iStackSize: integer; // 请求的堆栈大小
    iGlobalDataSize: integer; // 脚本大小
    // 全局数据
    iIsMainFuncPresent: integer; // _Main是否存在
    iMainFuncIndex: integer; // _Main索引
    iPriorityType: integer; // 线程优先级类型  0.8
    iUserPriorty: integer; // 用户定义的优先级(如果有的话) 0.8
  end;

  ScriptHeader = _ScriptHeader;

  // --------Instruction Lookup Table 指令查找表----------------
type
  OpType = integer;
  pOpType = ^OpType;

  _InstrLookup = record
    // 助记字符串
    pstrMnemonic: array [0 .. MAX_INSTR_MNEMONIC_SIZE - 1] of AnsiChar;
    // 操作码
    iOpcode: integer;
    // 操作数个数
    iOpcount: integer;
    // 操作数列表指针
    OpList: pOpType;
  end;

  InstrLookup = _InstrLookup;
  pInstrLookup = ^InstrLookup;

  // --------Assembled Instruction Stream  汇编指令流
type
  _Op = record // 汇编操作数
    iType: integer; // 类型
    iOffserIndex: integer; // 索引偏移
    case integer of
      0:
        (iIntLiteral: integer); // 整数字面值
      1:
        (fFloatLiteral: Single); // 浮点字面值
      2:
        (iStringTableIndex: integer); // 字符串表索引
      3:
        (iStackIndex: integer); // 栈索引
      4:
        (iInstrIndex: integer); // 指令索引
      5:
        (iFuncIndex: integer); // 函数索引
      6:
        (iHostAPICallIndex: integer); // 主API函数索引
      7:
        (iReg: integer); // Register code  寄存器
  end;

  OP = _Op;
  pOP = ^OP;

type
  _Instr = record // An instruction
    iOpcode: integer; // 操作码
    iOpcount: integer; // Number of operands
    pOpList: pOP; // Point to operand list
  end;

  InStr = _Instr;

type
  _FuncNode = record // 一个函数节点
    iIndex: integer; // 索引
    pstrName: array [0 .. MAX_IDENT_SIZE - 1] of AnsiChar;
    iEntryPoint: integer; // 入口
    iParamCount: integer; // 参数个数
    iLocalDataSize: integer; // 局部堆栈大小
  end;

  FuncNode = _FuncNode;
  pFuncNode = ^FuncNode;

  // ----------Label Table-------------
type

  _LabelNode = record // a node
    iIndex: integer; // 索引
    pstrIdent: array [0 .. MAX_IDENT_SIZE - 1] of AnsiChar; // identifier
    iTargetIndex: integer; // 目标指令索引
    iFuncIndex: integer; // function in which then label resides
  end;

  LabelNode = _LabelNode;
  pLabelNode = ^LabelNode;

  // ----------Symbol Table------------
type
  _SymbolNode = record
    iIndex: integer; // 索引
    pstrIdent: array [0 .. MAX_IDENT_SIZE - 1] of AnsiChar; // 识别码
    iSize: integer; // Size (1 for variables, N for arrays)
    iStackIndex: integer; // 栈索引
    iFuncIndex: integer; // Function in which the symbol resides
  end;

  SymbolNode = _SymbolNode;
  pSymbolNode = ^SymbolNode;

implementation

end.
