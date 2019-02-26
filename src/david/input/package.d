module david.input;

import std.bitmanip : bitfields;

version (Sdl)
{
    public import david.input.sdl;
}
else version (Windows)
{
    public import david.input.windows;
}
else
{
    public import david.input.posix;
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
