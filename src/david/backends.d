module david.backends;

import david.optional;

enum DavidBackend
{
    gdi,
    direct2dAurora,
    direct2dEvilrat,
    sdl,
}

Optional!DavidBackend tryParseBackend(const(char)[] name)
{
    if (name == "gdi")
        return Optional!DavidBackend.gdi;
    if (name == "direct2d")
        return Optional!DavidBackend.direct2dEvilrat;
    if (name == "sdl")
        return Optional!DavidBackend.sdl;
    return Optional!DavidBackend.noValue;
}
DavidBackend parseBackend(const(char)[] name)
{
    auto result = tryParseBackend(name);
    if (!result.hasValue)
    {
        assert(0, "throw proper error for invalid backend");
    }
    return result.value;
}

auto formatBackends()
{
    static struct Formatter
    {
        void toString(scope void delegate(const(char)[]) sink) const
        {
            sink("TODO: write enum members");
        }
    }
    return Formatter();
}
