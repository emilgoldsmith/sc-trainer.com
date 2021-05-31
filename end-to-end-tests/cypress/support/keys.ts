import {
  VALUE_CONTROL,
  VALUE_A,
  VALUE_B,
  VALUE_C,
  VALUE_D,
  CODE_CONTROL_LEFT,
  CODE_A,
  CODE_B,
  CODE_C,
  CODE_D,
  KEY_CONTROL,
  KEY_B,
  KEY_C,
  KEY_A,
  KEY_D,
  VALUE_X,
  VALUE_L,
  VALUE_SPACE,
  VALUE_CAPS_LOCK,
  CODE_X,
  CODE_SPACE,
  CODE_CAPS_LOCK,
  KEY_X,
  KEY_SPACE,
  KEY_CAPS_LOCK,
  VALUE_5,
  CODE_L,
  CODE_5,
  KEY_L,
  KEY_5,
  VALUE_W,
  CODE_W,
  KEY_W,
  VALUE_SHIFT,
  CODE_SHIFT_LEFT,
  KEY_SHIFT,
  KEY_1,
  KEY_2,
  KEY_3,
  VALUE_2,
  VALUE_1,
  VALUE_3,
  CODE_1,
  CODE_2,
  CODE_3,
} from "keycode-js";

export enum Key {
  a,
  b,
  c,
  d,
  l,
  x,
  w,
  W,
  one,
  two,
  three,
  five,
  space,
  leftCtrl,
  capsLock,
  shift,
}

export function getKeyValue(key: Key): string {
  switch (key) {
    case Key.a:
      return VALUE_A;
    case Key.b:
      return VALUE_B;
    case Key.c:
      return VALUE_C;
    case Key.d:
      return VALUE_D;
    case Key.l:
      return VALUE_L;
    case Key.w:
      return VALUE_W;
    case Key.W:
      return VALUE_W.toUpperCase();
    case Key.x:
      return VALUE_X;
    case Key.one:
      return VALUE_1;
    case Key.two:
      return VALUE_2;
    case Key.three:
      return VALUE_3;
    case Key.five:
      return VALUE_5;
    case Key.leftCtrl:
      return VALUE_CONTROL;
    case Key.space:
      return VALUE_SPACE;
    case Key.capsLock:
      return VALUE_CAPS_LOCK;
    case Key.shift:
      return VALUE_SHIFT;
  }
}

export function getCode(key: Key): string {
  switch (key) {
    case Key.a:
      return CODE_A;
    case Key.b:
      return CODE_B;
    case Key.c:
      return CODE_C;
    case Key.d:
      return CODE_D;
    case Key.l:
      return CODE_L;
    case Key.w:
      return CODE_W;
    case Key.W:
      return CODE_W;
    case Key.x:
      return CODE_X;
    case Key.one:
      return CODE_1;
    case Key.two:
      return CODE_2;
    case Key.three:
      return CODE_3;
    case Key.five:
      return CODE_5;
    case Key.leftCtrl:
      return CODE_CONTROL_LEFT;
    case Key.space:
      return CODE_SPACE;
    case Key.capsLock:
      return CODE_CAPS_LOCK;
    case Key.shift:
      return CODE_SHIFT_LEFT;
  }
}

export function getKeyCode(key: Key): number {
  switch (key) {
    case Key.a:
      return KEY_A;
    case Key.b:
      return KEY_B;
    case Key.c:
      return KEY_C;
    case Key.d:
      return KEY_D;
    case Key.l:
      return KEY_L;
    case Key.w:
      return KEY_W;
    case Key.W:
      return KEY_W;
    case Key.x:
      return KEY_X;
    case Key.one:
      return KEY_1;
    case Key.two:
      return KEY_2;
    case Key.three:
      return KEY_3;
    case Key.five:
      return KEY_5;
    case Key.leftCtrl:
      return KEY_CONTROL;
    case Key.space:
      return KEY_SPACE;
    case Key.capsLock:
      return KEY_CAPS_LOCK;
    case Key.shift:
      return KEY_SHIFT;
  }
}
