unit CommFunc;

interface

uses
  System.SysUtils, Winapi.Windows;

type
  PKBDCode = ^TKBDCode;

  TKBDCode = record
    Code, Normal, Shift, Ctrl, Alt: word;
  end;

const
  { Key translation table }
  KDBCodeTable: array [0 .. 91] of TKBDCode = ((Code: VK_BACK; Normal: $08;
    Shift: $08; Ctrl: $7F; Alt: $100 + 14), (Code: VK_TAB; Normal: $09;
    Shift: $10F; Ctrl: $194; Alt: $100 + 165), (Code: VK_RETURN; Normal: $0D;
    Shift: $0D; Ctrl: $0A; Alt: $100 + 166), (Code: VK_ESCAPE; Normal: $1B;
    Shift: $1B; Ctrl: $1B; Alt: $100 + 1), (Code: VK_SPACE; Normal: $20;
    Shift: $20; Ctrl: $103; Alt: $20), (Code: Ord('0'); Normal: Ord('0');
    Shift: Ord(')'); Ctrl: $FFFF; Alt: $100 + 129), (Code: Ord('1');
    Normal: Ord('1'); Shift: Ord('!'); Ctrl: $FFFF; Alt: $100 + 120),
    (Code: Ord('2'); Normal: Ord('2'); Shift: Ord('@'); Ctrl: $103;
    Alt: $100 + 121), (Code: Ord('3'); Normal: Ord('3'); Shift: Ord('#');
    Ctrl: $FFFF; Alt: $100 + 122), (Code: Ord('4'); Normal: Ord('4');
    Shift: Ord('$'); Ctrl: $FFFF; Alt: $100 + 123), (Code: Ord('5');
    Normal: Ord('5'); Shift: Ord('%'); Ctrl: $FFFF; Alt: $100 + 124),
    (Code: Ord('6'); Normal: Ord('6'); Shift: Ord('^'); Ctrl: $1E;
    Alt: $100 + 125), (Code: Ord('7'); Normal: Ord('7'); Shift: Ord('&');
    Ctrl: $FFFF; Alt: $100 + 126), (Code: Ord('8'); Normal: Ord('8');
    Shift: Ord('*'); Ctrl: $FFFF; Alt: $100 + 127), (Code: Ord('9');
    Normal: Ord('9'); Shift: Ord('('); Ctrl: $FFFF; Alt: $100 + 128),
    (Code: Ord('A'); Normal: Ord('a'); Shift: Ord('A'); Ctrl: $01;
    Alt: $100 + 30), (Code: Ord('B'); Normal: Ord('b'); Shift: Ord('B');
    Ctrl: $02; Alt: $100 + 48), (Code: Ord('C'); Normal: Ord('c');
    Shift: Ord('C'); Ctrl: $03; Alt: $100 + 46), (Code: Ord('D');
    Normal: Ord('d'); Shift: Ord('D'); Ctrl: $04; Alt: $100 + 32),
    (Code: Ord('E'); Normal: Ord('e'); Shift: Ord('E'); Ctrl: $05;
    Alt: $100 + 18), (Code: Ord('F'); Normal: Ord('f'); Shift: Ord('F');
    Ctrl: $06; Alt: $100 + 33), (Code: Ord('G'); Normal: Ord('g');
    Shift: Ord('G'); Ctrl: $07; Alt: $100 + 34), (Code: Ord('H');
    Normal: Ord('h'); Shift: Ord('H'); Ctrl: $08; Alt: $100 + 35),
    (Code: Ord('I'); Normal: Ord('i'); Shift: Ord('I'); Ctrl: $09;
    Alt: $100 + 23), (Code: Ord('J'); Normal: Ord('j'); Shift: Ord('J');
    Ctrl: $0A; Alt: $100 + 36), (Code: Ord('K'); Normal: Ord('k');
    Shift: Ord('K'); Ctrl: $0B; Alt: $100 + 37), (Code: Ord('L');
    Normal: Ord('l'); Shift: Ord('L'); Ctrl: $0C; Alt: $100 + 38),
    (Code: Ord('M'); Normal: Ord('m'); Shift: Ord('M'); Ctrl: $0D;
    Alt: $100 + 50), (Code: Ord('N'); Normal: Ord('n'); Shift: Ord('N');
    Ctrl: $0E; Alt: $100 + 49), (Code: Ord('O'); Normal: Ord('o');
    Shift: Ord('O'); Ctrl: $0F; Alt: $100 + 24), (Code: Ord('P');
    Normal: Ord('p'); Shift: Ord('P'); Ctrl: $10; Alt: $100 + 25),
    (Code: Ord('Q'); Normal: Ord('q'); Shift: Ord('Q'); Ctrl: $11;
    Alt: $100 + 16), (Code: Ord('R'); Normal: Ord('r'); Shift: Ord('R');
    Ctrl: $12; Alt: $100 + 19), (Code: Ord('S'); Normal: Ord('s');
    Shift: Ord('S'); Ctrl: $13; Alt: $100 + 31), (Code: Ord('T');
    Normal: Ord('t'); Shift: Ord('T'); Ctrl: $14; Alt: $100 + 20),
    (Code: Ord('U'); Normal: Ord('u'); Shift: Ord('U'); Ctrl: $15;
    Alt: $100 + 22), (Code: Ord('V'); Normal: Ord('v'); Shift: Ord('V');
    Ctrl: $16; Alt: $100 + 47), (Code: Ord('W'); Normal: Ord('w');
    Shift: Ord('W'); Ctrl: $17; Alt: $100 + 17), (Code: Ord('X');
    Normal: Ord('x'); Shift: Ord('X'); Ctrl: $18; Alt: $100 + 45),
    (Code: Ord('Y'); Normal: Ord('y'); Shift: Ord('Y'); Ctrl: $19;
    Alt: $100 + 21), (Code: Ord('Z'); Normal: Ord('z'); Shift: Ord('Z');
    Ctrl: $1A; Alt: $100 + 44), (Code: VK_PRIOR; Normal: $149; Shift: $149;
    Ctrl: $18F; Alt: $100 + 153), (Code: VK_NEXT; Normal: $151; Shift: $151;
    Ctrl: $176; Alt: $100 + 161), (Code: VK_END; Normal: $14F; Shift: $14F;
    Ctrl: $175; Alt: $100 + 159), (Code: VK_HOME; Normal: $147; Shift: $147;
    Ctrl: $177; Alt: $100 + 151), (Code: VK_LEFT; Normal: $14B; Shift: $14B;
    Ctrl: $173; Alt: $100 + 155), (Code: VK_UP; Normal: $148; Shift: $148;
    Ctrl: $18D; Alt: $100 + 152), (Code: VK_RIGHT; Normal: $14D; Shift: $14D;
    Ctrl: $174; Alt: $100 + 157), (Code: VK_DOWN; Normal: $150; Shift: $150;
    Ctrl: $191; Alt: $100 + 160), (Code: VK_INSERT; Normal: $152; Shift: $152;
    Ctrl: $192; Alt: $100 + 162), (Code: VK_DELETE; Normal: $153; Shift: $153;
    Ctrl: $193; Alt: $100 + 163), (Code: VK_NUMPAD0; Normal: Ord('0');
    Shift: $152; Ctrl: $100 + 146; Alt: $FFFF), (Code: VK_NUMPAD1;
    Normal: Ord('1'); Shift: $14F; Ctrl: $100 + 117; Alt: $FFFF),
    (Code: VK_NUMPAD2; Normal: Ord('2'); Shift: $150; Ctrl: $100 + 145;
    Alt: $FFFF), (Code: VK_NUMPAD3; Normal: Ord('3'); Shift: $151;
    Ctrl: $100 + 118; Alt: $FFFF), (Code: VK_NUMPAD4; Normal: Ord('4');
    Shift: $14B; Ctrl: $100 + 115; Alt: $FFFF), (Code: VK_NUMPAD5;
    Normal: Ord('5'); Shift: $14C; Ctrl: $100 + 143; Alt: $FFFF),
    (Code: VK_NUMPAD6; Normal: Ord('6'); Shift: $14D; Ctrl: $100 + 116;
    Alt: $FFFF), (Code: VK_NUMPAD7; Normal: Ord('7'); Shift: $147;
    Ctrl: $100 + 119; Alt: $FFFF), (Code: VK_NUMPAD8; Normal: Ord('8');
    Shift: $148; Ctrl: $100 + 141; Alt: $FFFF), (Code: VK_NUMPAD9;
    Normal: Ord('9'); Shift: $149; Ctrl: $100 + 132; Alt: $FFFF),
    (Code: VK_MULTIPLY; Normal: Ord('*'); Shift: Ord('*'); Ctrl: $100 + 150;
    Alt: $100 + 55), (Code: VK_ADD; Normal: Ord('+'); Shift: Ord('+');
    Ctrl: $100 + 144; Alt: $100 + 78), (Code: VK_SUBTRACT; Normal: Ord('-');
    Shift: Ord('-'); Ctrl: $100 + 142; Alt: $100 + 74), (Code: VK_DECIMAL;
    Normal: Ord('.'); Shift: Ord('.'); Ctrl: $100 + 83; Alt: $100 + 147),
    (Code: VK_DIVIDE; Normal: Ord('/'); Shift: Ord('/'); Ctrl: $100 + 149;
    Alt: $100 + 164), (Code: VK_F1; Normal: $100 + 59; Shift: $100 + 84;
    Ctrl: $100 + 94; Alt: $100 + 104), (Code: VK_F2; Normal: $100 + 60;
    Shift: $100 + 85; Ctrl: $100 + 95; Alt: $100 + 105), (Code: VK_F3;
    Normal: $100 + 61; Shift: $100 + 86; Ctrl: $100 + 96; Alt: $100 + 106),
    (Code: VK_F4; Normal: $100 + 62; Shift: $100 + 87; Ctrl: $100 + 97;
    Alt: $100 + 107), (Code: VK_F5; Normal: $100 + 63; Shift: $100 + 88;
    Ctrl: $100 + 98; Alt: $100 + 108), (Code: VK_F6; Normal: $100 + 64;
    Shift: $100 + 89; Ctrl: $100 + 99; Alt: $100 + 109), (Code: VK_F7;
    Normal: $100 + 65; Shift: $100 + 90; Ctrl: $100 + 100; Alt: $100 + 110),
    (Code: VK_F8; Normal: $100 + 66; Shift: $100 + 91; Ctrl: $100 + 101;
    Alt: $100 + 111), (Code: VK_F9; Normal: $100 + 67; Shift: $100 + 92;
    Ctrl: $100 + 102; Alt: $100 + 112), (Code: VK_F10; Normal: $100 + 68;
    Shift: $100 + 93; Ctrl: $100 + 103; Alt: $100 + 113), (Code: VK_F11;
    Normal: $100 + 133; Shift: $100 + 135; Ctrl: $100 + 137; Alt: $100 + 139),
    (Code: VK_F12; Normal: $100 + 134; Shift: $100 + 136; Ctrl: $100 + 138;
    Alt: $100 + 140), (Code: $DC; Normal: Ord('\'); Shift: Ord('|'); Ctrl: $1C;
    Alt: $100 + 43), (Code: $BF; Normal: Ord('/'); Shift: Ord('?'); Ctrl: $FFFF;
    Alt: $100 + 53), (Code: $BD; Normal: Ord('-'); Shift: Ord('_'); Ctrl: $1F;
    Alt: $100 + 130), (Code: $BB; Normal: Ord('='); Shift: Ord('+');
    Ctrl: $FFFF; Alt: $100 + 131), (Code: $DB; Normal: Ord('[');
    Shift: Ord('{'); Ctrl: $1B; Alt: $100 + 26), (Code: $DD; Normal: Ord(']');
    Shift: Ord('}'); Ctrl: $1D; Alt: $100 + 27), (Code: $BA; Normal: Ord(';');
    Shift: Ord(':'); Ctrl: $FFFF; Alt: $100 + 39), (Code: $DE;
    Normal: Ord(''''); Shift: Ord('"'); Ctrl: $FFFF; Alt: $100 + 40),
    (Code: $BC; Normal: Ord(','); Shift: Ord('<'); Ctrl: $FFFF; Alt: $100 + 51),
    (Code: $BE; Normal: Ord('.'); Shift: Ord('>'); Ctrl: $FFFF; Alt: $100 + 52),
    (Code: $C0; Normal: Ord('`'); Shift: Ord('~'); Ctrl: $FFFF; Alt: $100 + 41),
    // TODO 4 -c Crt: Determine what the Win9x keys return
    (Code: VK_LWIN; Normal: $FFFF; Shift: $FFFF; Ctrl: $FFFF; Alt: $FFFF),
    (Code: VK_RWIN; Normal: $FFFF; Shift: $FFFF; Ctrl: $FFFF; Alt: $FFFF),
    (Code: VK_APPS; Normal: $FFFF; Shift: $FFFF; Ctrl: $FFFF; Alt: $FFFF));

var
  _InputHandle: THandle = INVALID_HANDLE_VALUE;
  _ExtendedChar: smallint = -1;
function KeyPressed: boolean;

implementation

function __TranslateKey(Input: INPUT_RECORD; K: PKBDCode): word; register;
begin
  if ((Input.Event.KeyEvent.dwControlKeyState and (RIGHT_ALT_PRESSED or
    LEFT_ALT_PRESSED)) <> 0) then
    Result := K.Alt
  else if ((Input.Event.KeyEvent.dwControlKeyState and (RIGHT_CTRL_PRESSED or
    LEFT_CTRL_PRESSED)) <> 0) then
    Result := K.Ctrl
  else if ((Input.Event.KeyEvent.dwControlKeyState and SHIFT_PRESSED) <> 0) then
    Result := K.Shift
  else
  begin
    if (AnsiChar(Chr(Input.Event.KeyEvent.wVirtualKeyCode)) >= 'A') and
      (AnsiChar(Chr(Input.Event.KeyEvent.wVirtualKeyCode)) <= 'Z') then
      Result := Ord(Input.Event.KeyEvent.AsciiChar)
    else
      Result := K.Normal;
  end;
end;

function __LookupKey(Code: word): PKBDCode; register;

var
  I: integer;
begin
  Result := nil;
  for I := Low(KDBCodeTable) to High(KDBCodeTable) do
  begin
    if (KDBCodeTable[I].Code = Code) then
    begin
      Result := @KDBCodeTable[I];
      Exit;
    end;
  end;
end;

function KeyPressed: boolean;
var
  Input: array of INPUT_RECORD;
  NumRead, NumEvents, J: DWORD;
  K: PKBDCode;
begin
  Result := False;
  if (_ExtendedChar <> -1) then
  begin
    Result := True;
    Exit;
  end;
  _InputHandle := GetStdHandle(STD_INPUT_HANDLE);
  GetNumberOfConsoleInputEvents(_InputHandle, NumEvents);

  if (NumEvents = 0) then
    Exit;

  SetLength(Input, NumEvents);
  try
    PeekConsoleInput(_InputHandle, Input[0], NumEvents, NumRead);
    for J := 0 to NumRead - 1 do
    begin
      if ((Input[J].EventType and KEY_EVENT) <> 0) and
        (Input[J].Event.KeyEvent.bKeyDown) then
      begin
        if ((Input[J].Event.KeyEvent.wVirtualKeyCode <> VK_SHIFT) and
          (Input[J].Event.KeyEvent.wVirtualKeyCode <> VK_CONTROL) and
          (Input[J].Event.KeyEvent.wVirtualKeyCode <> VK_MENU)) then
        begin
          K := __LookupKey(Input[J].Event.KeyEvent.wVirtualKeyCode);
          if (K <> nil) then
          begin
            if (smallint(__TranslateKey(Input[J], K)) <> -1) then
            begin
              Result := True;
              Exit;
            end;
          end;
        end;
      end;
    end;
    { Flush the events so WaitForSingleObject(_InputHandle, INFINITE) won't
      keep firing if the only events in the keyboard input queue are non-
      keyboard events.  (In other words, flush the buffer of the exact number
      of events we read and checked for keyboard activity from.) }
    ReadConsoleInput(_InputHandle, Input[0], NumRead, NumRead);
  finally
    SetLength(Input, 0);
  end;
end;

end.
