module david.input.posix;

import std.bitmanip : bitfields;

enum InputCode //: WPARAM
{
    a = 'A',
    b = 'B',
    c = 'C',
    d = 'D',
    e = 'E',
    f = 'F',
    g = 'G',
    h = 'H',
    i = 'I',
    j = 'J',
    k = 'K',
    l = 'L',
    m = 'M',
    n = 'N',
    o = 'O',
    p = 'P',
    q = 'Q',
    r = 'R',
    s = 'S',
    t = 'T',
    u = 'U',
    v = 'V',
    w = 'W',
    x = 'X',
    y = 'Y',
    z = 'Z',
    left = 0,//KEY_LEFT,
    right = 0,//KEY_RIGHT,
    escape = 0,//KEY_ESCAPE,
}

// Immediate input is input that is keeps track of whether or not it
// is pressed
struct ImmediateInputTableEntry
{
    InputCode code;
    mixin(bitfields!(
        bool, "pressed", 1,
        ubyte, "", 7));
        
}

// Queued input is input keys that are queued up and processed by the
// game when they are pressed
struct QueuedInputTableEntry
{
    InputCode code;
}
