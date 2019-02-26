module david.types.graphics;

import std.format : formattedWrite;

import david.types.core : Unit, toUnit, UnitVector, UnitRectangle;

struct PixelSize
{
    uint x;
    uint y;
    void toString(scope void delegate(const(char)[]) sink) const
    {
        formattedWrite(sink, "%s x %s", x, y);
    }
}
struct PixelVector
{
    uint x;
    uint y;
    void toString(scope void delegate(const(char)[]) sink) const
    {
        formattedWrite(sink, "%s, %s", x, y);
    }
}

struct GameView
{
    /*
    we store the size in 2 forms, left/right/top/bottom and width/height.
    the reason is that the game view values will be read VERY often but
    changed rarely, so it makes sense to store the size in all possible values
    even though they are redundant.
    */
    private UnitRectangle rect;
    private UnitVector size;

    pragma(inline) @property Unit width()  const { return size.x; }
    pragma(inline) @property Unit height() const { return size.y; }

    auto getRect() inout { return rect; }

    void setSize(T,U)(T width, U height)
    {
        size.x = width.toUnit;
        size.y = height.toUnit;
        rect.right = rect.left   + size.x;
        rect.top   = rect.bottom + size.y;
    }
    void moveBottomLeftTo(const(UnitVector) bottomLeft)
    {
        rect.left    = bottomLeft.x;
        rect.right   = bottomLeft.x + size.x;
        rect.bottom  = bottomLeft.y;
        rect.top     = bottomLeft.y + size.y;
    }

    pragma(inline) @property Unit left()   { return rect.left; }
    pragma(inline) @property Unit right()  { return rect.right; }
    pragma(inline) @property Unit bottom() { return rect.bottom; }
    pragma(inline) @property Unit top()    { return rect.top; }

    Unit xMiddle() { return rect.left   + size.x / 2; }
    Unit yMiddle() { return rect.bottom + size.y / 2; }

    pragma(inline)
    bool overlap(UnitRectangle other) const { return rect.overlap(other); }
    pragma(inline)
    bool overlap(UnitRectangle other, UnitRectangle* overlappedRect) const { return rect.overlap(other, overlappedRect); }
}