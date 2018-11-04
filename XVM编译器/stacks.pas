{ ******************************************************* }
{                                                         }
{                   XVM                                   }
{                                                         }
{                  版权所有 (C) 2012 adsj                 }
{                  Mode： 堆栈执行模块                    }
{ ******************************************************* }
unit stacks;

interface

uses
  System.SysUtils, linked_list;

type
  // 堆栈
  pStack = ^stack;

  _Stack = record
    ElmnList: LinkedList;
  end;

  stack = _Stack;
  //
  (* 初始化堆栈 *)
procedure InitStack(AStack: pStack);
(* 释放堆栈 *)
procedure FreeStack(AStack: pStack);
(* 确定堆栈是否为空 *)
function IsStackEmpty(AStack: pStack): Boolean;
(* 向堆栈中压入数据 *)
procedure Push(AStack: pStack; pData: Pointer);
(* 从堆栈中弹出数据 *)
procedure PopUp(AStack: pStack);
(* 获得栈顶元素 *)
function Peek(AStack: pStack): Pointer;

implementation

procedure InitStack(AStack: pStack);
begin
  InitLinkedList(@AStack.ElmnList);
end;

procedure FreeStack(AStack: pStack);
begin
  FreeLinkedList(@AStack.ElmnList);
end;

function IsStackEmpty(AStack: pStack): Boolean;
begin
  if AStack.ElmnList.iNodeCount > 0 then
    Result := False
  else
    Result := True;
end;

procedure Push(AStack: pStack; pData: Pointer);
begin
  AddNode(@AStack.ElmnList, pData);
end;

procedure PopUp(AStack: pStack);
begin
  DelNode(@AStack.ElmnList, AStack.ElmnList.pTail);
end;

function Peek(AStack: pStack): Pointer;
begin
  Result := AStack.ElmnList.pTail.pData;
end;

end.
