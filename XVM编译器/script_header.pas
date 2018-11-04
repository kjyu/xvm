unit script_header;

interface

// ----Data Structures
// ----Script
type
  _ScriptHeader = record
    iStackSize: integer; // 要求的堆栈大小
    iIsMainFuncPresent: integer; // _Main是否出现
    iMainFuncIndex: integer; // _Main索引
    iPriorityType: integer; // 线程优先级
    iUserPriority: integer; // 用户定义的优先级
  end;

  ScriptHeader = _ScriptHeader;

implementation

end.
