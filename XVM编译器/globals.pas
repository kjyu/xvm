{ ******************************************************* }
{                                                         }
{ XVM                                                     }
{                                                         }
{ 版权所有 (C) 2012 adsj                                  }
{ Mode： 全局变量模块                                     }
{ ******************************************************* }

unit globals;

interface

uses
  System.SysUtils, linked_list, script_header;
const
  // ----Filename
  MAX_FILENAME_SIZE = 2048;
  MAX_IDENT_SIZE = 256;
  MAX_SOURCE_LINE_SIZE = 4096;
  MAX_LEXEME_SIZE = 128;
  SOURCE_FILE_EXT = '.XSS';
  OUTPOT_FILE_EXT = '.XASM';
  // ----Function
  MAIN_FUNC_NAME = '_Main';
  // ----Program
  VERSION_MAJOR = 0;
  VERSION_MINOR = 8;
  // ----tab
  TAB_STOP_WIDTH = 8;
  // ----Priority Types
  PRIORITY_NONE = 0;
  PRIORITY_USER = 1;
  PRIORITY_LOW = 2;
  PRIORITY_MED = 3;
  PRIORITY_HIGH = 4;
  PRIORITY_LOW_KEYWORD = 'Low';
  PRIORITY_MED_KEYWORD = 'Med';
  PRIORITY_HIGH_KEYWORD = 'High';

  // ----Register Codes
  REG_CODE_RETVAL = 0;
  // ----Internal Script Entities
  TEMP_VAR_0 = '_T0';
  TEMP_VAR_1 = '_T1';
  // -------------lex parser------------------------------

  // -----------------------------------------------------
var
  g_iPreserveOutputFile: integer; // xasm 删除
  g_iGenerateXSE: integer; // 生成XSE执行文件
  g_pstrSourceFileName: array [0 .. MAX_FILENAME_SIZE - 1] of AnsiChar;
  g_pstrOutPutFileName: array [0 .. MAX_FILENAME_SIZE - 1] of AnsiChar;
  //
  g_SourceCode: LinkedList;
  g_FuncTable: LinkedList;
  g_SymbolTable: LinkedList;
  g_StringTable: LinkedList;
  g_ScriptHeader: ScriptHeader;
  //全局 临时计算变量
  g_iTempVar0SymbolIndex:integer;
  g_iTempVar1SymbolIndex:integer;
implementation

end.
