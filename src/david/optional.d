module david.optional;

// TODO: check if mar already has equivalent or move it to mar
template Optional(T)
{
    static if ( is(T == enum) )
    {
        alias Optional = OptionalEnum!T;
    }
    else static assert("Optional not implemented for " ~ T.stringof);
}
private struct OptionalEnum(T)
{
    import std.traits : OriginalType;

    static if (OriginalType!T.min < T.min)
    {
        private enum hasNullValue = true;
        private enum nullValue = cast(T)OriginalType!T.min;
    }
    else static if (OriginalType!T.max < T.max)
    {
        private enum hasNullValue = true;
        private enum nullValue = cast(T)OriginalType!T.max;
    }
    else
    {
        private enum hasNullValue = false;
    }
    

    static if (!hasNullValue)
    {
        private bool _hasValue;
        private T _value = void;
    }
    else
    {
        private T _value;
    }

    static OptionalEnum!T opDispatch(string name)()
    {
        return OptionalEnum!T(mixin("T." ~ name));
    }
    static if (hasNullValue)
    {
        static OptionalEnum!T noValue() { return OptionalEnum!T(nullValue); }
        bool hasValue() const { return _value != nullValue; }
    }
    else
    {
        static OptionalEnum!T noValue() { return OptionalEnum!T(false); }
        bool hasValue() const { return _hasValue; }
    }
    auto value() inout in { assert(hasValue); } do { return _value; }
}
