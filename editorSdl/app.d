module app;

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// TODO: Change FixedFps to 0
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
enum FixedFps = 60;
enum FixedPixelsPerUnit = 1;

import david.timing : Timing;
import david.input : ImmediateInputTableEntry, QueuedInputTableEntry, InputCode;
import graphics = david.graphics;

void initWindowSize()
{
    graphics.gameView.setSize(1280, 720);
}
void init(T...)(Timing* timing, T platformArguments)
{
}

enum ImmediateControlIndex
{
    left,
    right,
}
__gshared ImmediateInputTableEntry[] immediateInputTable =  [
    ImmediateControlIndex.left  : ImmediateInputTableEntry(InputCode.a),
    ImmediateControlIndex.right : ImmediateInputTableEntry(InputCode.d),
];
enum QueuedControlIndex {
    escape
};
__gshared QueuedInputTableEntry[] queuedInputTable = [
    QueuedControlIndex.escape : QueuedInputTableEntry(InputCode.escape),
];
void queueInput(QueuedControlIndex index)
{
    //queuedInputs.append(index);
}

void update()
{
}

void render()
{
}