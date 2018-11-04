unit xvm_errors;

interface

uses System.SysUtils;

const
  // ERROR STRINGS
  ERROR_MSSG_INVALID_INPUT = 'Invalid input';
  ERROR_MSSG_LOCAL_SETSTACKSIZE = 'SetStackSize can only appear in the global scope';
  ERROR_MSSG_INVALID_STACK_SIZE = 'Invalid stack size';
  ERROR_MSSG_MULTIPLE_SETSTACKSIZE = 'Multiple instances of SetStackSize - illegal';
  ERROR_MSSG_LOCAL_SETPRIORITY = 'SetPriority can only appear in the global scope';
  ERROR_MSSG_INVALID_PRIORITY = 'Invalid priority';
  ERROR_MSSG_MULTIPLE_SETPRIORITY = 'Multiple instances of SetPriority - illegal';
  ERROR_MSSG_IDENT_EXPECTED = 'Identifier expected';
  ERROR_MSSG_INVALID_ARRAY_SIZE = 'Invalid array size';
  ERROR_MSSG_IDENT_REDEFINITION = 'Identifier redefinition';
  ERROR_MSSG_UNDEFINED_IDENT = 'Undefined identifier';
  ERROR_MSSG_NESTED_FUNC = 'Nested functions illegal';
  ERROR_MSSG_FUNC_REDEFINITION = 'Function redefinition';
  ERROR_MSSG_UNDEFINED_FUNC = 'Undefined function';
  ERROR_MSSG_GLOBAL_PARAM = 'Parameters can only appear inside functions';
  ERROR_MSSG_MAIN_PARAM = '_Main () function cannot accept parameters';
  ERROR_MSSG_GLOBAL_LINE_LABEL = 'Line labels can only apper inside functions';
  ERROR_MSSG_LINE_LABEL_REDEFINITION = 'Line label redefinition';
  ERROR_MSSG_UNDEFINED_LINE_TABEL = 'Undefined line label';
  ERROR_MSSG_GLOBAL_INSTR = 'Instruction can only apper inside functions';
  ERROR_MSSG_INVALID_INSTR = 'Invalid instruction';
  ERROR_MSSG_INVALID_OP = 'Invalid operand'; // 无效操作数
  ERROR_MSSG_INVALID_STRING = 'Invalid string';
  ERROR_MSSG_INVALID_ARRAY_NOT_INDEXED = 'Arrays must be indexed';
  ERROR_MSSG_INVALID_ARRAY = 'Invalid array';
  ERROR_MSSG_INVALID_ARRAY_INDEX = 'Invalid array index';

procedure ExitOnError(pstrErrorMssg: PAnsiChar);

implementation

procedure ExitOnError(pstrErrorMssg: PAnsiChar);
begin
  Writeln(Format('Fatal Error: %s', [pstrErrorMssg]));
  Abort;
end;

end.
