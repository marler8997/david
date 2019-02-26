module david.sdl;

import david.log;

void enforceSdlCode(T...)(int result, string fmt, T args)
{
    import core.stdc.string : strlen;
    import std.format : format;
    import derelict.sdl2.sdl : SDL_GetError;
    if (result != 0)
    {
        const error = SDL_GetError();
        logf("SdlError: %s failed: %s (result=%s)", format(fmt, args), error[0 .. strlen(error)], result);
        assert(0, "SDL Error");
    }
}
void enforceSdlPtr(T...)(void *ptr, lazy string fmt, T args)
{
    import core.stdc.string : strlen;
    import std.format : format;
    import derelict.sdl2.sdl : SDL_GetError;
    if (ptr is null)
    {
        const error = SDL_GetError();
        logf("SdlError: %s failed: %s", format(fmt, args), error[0 .. strlen(error)]);
        assert(0, "SDL Error");
    }
}

