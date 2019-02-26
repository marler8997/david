module david.types.core;

import core.stdc.string : strlen;

import std.format : format, formattedWrite;
import std.typecons : Flag, Yes, No;
import std.traits : Unqual, isIntegral, isSigned, isUnsigned;

template cstring(string str)
{
    //static assert(str.ptr[str.length] == '\0');
    enum cstring = immutable CString(str.ptr);
}
struct CString
{
    char* ptr;
    package this(char* ptr)
    {
        this.ptr = ptr;
    }
    package this(immutable char* ptr) immutable
    {
        this.ptr = ptr;
    }
    void toString(scope void delegate(const(char)[]) sink) const
    {
        sink(ptr[0..strlen(ptr)]);
    }
}

pragma(inline) T unconst(T)(const(T) obj)
{
    return cast(T)obj;
}

struct Unit
{
    // I add 1 to the minimum integer value so I can take the absolute value of it, otherwise,
    // you can't represent the minumum value as a positive.
    static @property min() { return int.min + 1; }
    static @property max() { return int.max; }

    int value;
    bool opEquals(Unit rhs) const { return value == rhs.value; }
    @property final bool isZero() const { return value == 0; }
    int opCmp(Unit rhs) const
    {
        return value - rhs.value;
    }
    int opCmp(int rhs) const
    {
        return value - rhs;
    }
    void opOpAssign(string op, T)(inout(T) rhs)
    {
        mixin("value "~op~"= rhs.toValue;");
    }
    inout(Unit) opUnary(string op)() inout
    {
        mixin("return Unit(" ~ op ~ "value);");
    }
    inout(Unit) opBinary(string op, T)(inout(T) rhs) inout if(isUnitOrIntegral!T)
    {
        mixin("return Unit(value " ~ op ~ " rhs.toValue);");
    }
    @property auto normalizeToOne()
    {
        if(value > 0) return Unit(1);
        if(value < 0) return Unit(-1);
        return Unit(0);
    }
    @property auto absoluteValue()
    {
        return (value >= 0) ? this : Unit(-value);
    }
    void contentToString(scope void delegate(const(char)[]) sink) const
    {
        formattedWrite(sink, "%s", value);
    }
    void toString(scope void delegate(const(char)[]) sink) const
    {
        sink("Unit(");
        contentToString(sink);
        sink(")");
    }
}

template isUnitOrIntegral(T)
{
    enum isUnitOrIntegral = is(T : Unit) || isIntegral!T;
}
@property Unit toUnit(T)(T value)
{
    static if( is(T : Unit) )
    {
        return value;
    }
    else static if( isIntegral!T )
    {
        return Unit(value);
    }
    else static assert(0, "toUnit of type " ~ T.stringof ~ " is invalid or not implemented");
}
@property auto toValue(T)(T unitOrIntegral)
{
    static if( is(T : Unit) )
    {
        return unitOrIntegral.value;
    }
    else static if( isIntegral!T )
    {
        return unitOrIntegral;
    }
    else static assert(0, "toValue of type " ~ T.stringof ~ " is invalid or not implemented");
}

struct UnitVector
{
    Unit x;
    Unit y;
    @property bool isZero() const { return x == Unit(0) && y == Unit(0); }
    bool opEquals(UnitVector rhs) const { return x == rhs.x && y == rhs.y; }
    void opOpAssign(string op)(UnitVector other)
    {
        mixin("x "~op~"= other.x;");
        mixin("y "~op~"= other.y;");
    }
    inout(UnitVector) opBinary(string op)(inout(UnitVector) rhs) inout
    {
        mixin("return UnitVector(x "~op~" rhs.x, y "~op~" rhs.y);");
    }
    void contentToString(scope void delegate(const(char)[]) sink) const
    {
        formattedWrite(sink, "%s,%s", x.value, y.value);
    }
    void toString(scope void delegate(const(char)[]) sink) const
    {
        sink("Vector(");
        contentToString(sink);
        sink(")");
    }
}
auto unitVector(T,U)(T x, U y)
{
    return UnitVector(x.toUnit, y.toUnit);
}

struct UnitLine
{
    Unit start;
    Unit end;
    this(Unit start, Unit end) in { assert(start <= end); } body
    {
        this.start = start;
        this.end = end;
    }
    static UnitLine fromUnsorted(Unit a, Unit b)
    {
        return (a <= b) ? UnitLine(a, b) : UnitLine(b, a);
    }

    void opOpAssign(string op)(Unit unit)
    {
        start.opOpAssign!op(unit);
        end.opOpAssign!op(unit);
    }
    inout(UnitLine) opBinary(string op)(inout(UnitLine) rhs) inout
    {
        mixin("return UnitLine(start "~op~" rhs.start, end "~op~" rhs.end);");
    }
    inout(UnitLine) opBinary(string op, T)(inout(T) rhs) inout if(isUnitOrIntegral!T)
    {
        mixin("return UnitLine(start "~op~" rhs.toValue, end "~op~" rhs.toValue);");
    }

    bool overlap(UnitLine other) const
    {
        enum ReturnLine = false;
        mixin(overlapCode);
    }
    bool overlap(UnitLine other, UnitLine* overlappedLine) const
    {
        enum ReturnLine = true;
        mixin(overlapCode);
    }
    private enum overlapCode =
    q{
        if(start <= other.start)
        {
            if(end > other.start)
            {
                static if(ReturnLine)
                {
                    if(end <= other.end)
                    {
                        *overlappedLine = UnitLine(other.start, end);
                    }
                    else
                    {
                        *overlappedLine = UnitLine(other.start, other.end);
                    }
                }
                return true;
            }
        }
        else if(start < other.end)
        {
            static if(ReturnLine)
            {
                *overlappedLine = UnitLine(start, other.end);
            }
            return true;
        }
        return false;
    };
    void toString(scope void delegate(const(char)[]) sink) const
    {
        formattedWrite(sink, "Line[%s,%s]", start.value, end.value);
    }
}
auto unitLine(T,U)(T start, U end)
{
    return UnitLine(start.toUnit, end.toUnit);
}
// Returns the smallest continuous line that contains both the given lines
auto containingLine(UnitLine a, UnitLine b)
{
    UnitLine container;
    if(a.start <= b.start)
    {
        container.start = a.start;
    }
    else
    {
        container.start = b.start;
    }

    if(a.end >= b.end)
    {
        container.end = a.end;
    }
    else
    {
        container.end = b.end;
    }
    return container;
}
unittest
{
    assert(unitLine(0, 0) == containingLine(unitLine(0, 0), unitLine(0, 0)));
    assert(unitLine(-1, 0) == containingLine(unitLine(-1, 0), unitLine(0, 0)));
    assert(unitLine(-1, 1) == containingLine(unitLine(-1, 0), unitLine(0, 1)));
    assert(unitLine(-1, 2) == containingLine(unitLine(-1, 2), unitLine(0, 1)));
    assert(unitLine(-2, 3) == containingLine(unitLine(-1, 2), unitLine(-2, 3)));
    assert(unitLine(-2, 3) == containingLine(unitLine(-2, -1), unitLine(2, 3)));
}

unittest
{
    assert( unitLine(0, 1).overlap(unitLine(0 , 1)));
    assert( unitLine(0, 1).overlap(unitLine(-1, 1)));
    assert( unitLine(0, 1).overlap(unitLine(0 , 2)));

    assert(!unitLine(0, 0).overlap(unitLine(0 , 1)));
    assert( unitLine(0, 0).overlap(unitLine(-1, 1)));
    assert(!unitLine(0, 0).overlap(unitLine(0 , 2)));

    assert(!unitLine(1, 1).overlap(unitLine(0 , 1)));
    assert(!unitLine(1, 1).overlap(unitLine(-1, 1)));
    assert( unitLine(1, 1).overlap(unitLine(0 , 2)));
}

struct UnitRectangle
{
    union
    {
        UnitLine xLine;
        struct
        {
            Unit left;
            Unit right;
        }
    }
    union
    {
        UnitLine yLine;
        struct
        {
            Unit bottom;
            Unit top;
        }
    }
    this(Unit left, Unit right, Unit bottom, Unit top)
        in { assert(right >= left && top >= bottom); } body
    {
        this.left = left;
        this.right = right;
        this.bottom = bottom;
        this.top = top;
    }
    this(UnitLine xLine, UnitLine yLine)
    {
        this.xLine = xLine;
        this.yLine = yLine;
    }

    void move(const(UnitVector) moveDistance)
    {
        xLine += moveDistance.x;
        yLine += moveDistance.y;
    }
    void moveBottomLeftTo(const(UnitVector) bottomLeft)
    {
        {
            auto saveWidth = right - left;
            left  = bottomLeft.x;
            right = bottomLeft.x + saveWidth;
        }
        {
            auto saveHeight = top - bottom;
            bottom = bottomLeft.y;
            top    = bottomLeft.y + saveHeight;
        }
    }

    auto calculateWidth() { return right - left; }
    auto calculateHeight() { return top - bottom; }
    auto xMiddle()
    {
        return left + (right - left) / 2;
    }
    auto yMiddle()
    {
        return bottom + (top - bottom) / 2;
    }

    auto xShifted(T)(T shiftValue)
    {
        return UnitRectangle(xLine + shiftValue, yLine);
    }
    auto yShifted(T)(T shiftValue)
    {
        return UnitRectangle(xLine, yLine + shiftValue);
    }

    bool overlap(UnitRectangle other) const
    {
        return xLine.overlap(other.xLine) && yLine.overlap(other.yLine);
    }
    bool overlap(UnitRectangle other, UnitRectangle* overlappedRect) const
    {
        UnitLine xOverlapLine;
        if(xLine.overlap(other.xLine, &xOverlapLine))
        {
            UnitLine yOverlapLine;
            if(yLine.overlap(other.yLine, &yOverlapLine))
            {
                *overlappedRect = UnitRectangle(xOverlapLine, yOverlapLine);
                return true;
            }
        }
        return false;
    }

    void toString(scope void delegate(const(char)[]) sink) const
    {
        formattedWrite(sink, "Rectangle{x[%s,%s], y[%s,%s]}",
            left.value, right.value, bottom.value, top.value);
    }
}
auto unitRectangle(T,U,V,W)(T left, U right, V bottom, W top)
{
    return UnitRectangle(left.toUnit, right.toUnit, bottom.toUnit, top.toUnit);
}
auto pointSize(T,U,V,W)(T x, U y, V width, W height)
{
    return UnitRectangle(x.toUnit, (x+width).toUnit, y.toUnit, (y+height).toUnit);
}
