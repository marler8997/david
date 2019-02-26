module david.windowing.sdl;

import derelict.sdl2.sdl;

import mar.passfail;
import mar.c : tempCString;

import david.types : PixelSize;

struct Window
{
    private SDL_Window* ptr;
    bool isNull() const
    {
        return ptr is null;
    }
    SDL_Window* getSdlWindow() { return ptr; }
    auto formatError() const
    {
        static struct Formatter
        {
            void toString(scope void delegate(const(char)[]) sink)
            {
                 import core.stdc.string : strlen;
                 auto ptr = SDL_GetError();
                 sink(ptr[0 .. strlen(ptr)]);
            }
        }
        return Formatter();
    }
    passfail tryShow()
    {
        SDL_ShowWindow(ptr);
        return passfail.pass; // can't fail as far as I know right now
    }
    void show()
    {
        if (tryShow().failed)
            assert(0, "failed to show window"); // todo: throw exception with nice error message
    }
}

Window createWindow(const(char)[] title, PixelSize gamePixelSize)
{
    mixin tempCString!("titleCStr", "title");
    return Window(SDL_CreateWindow(
        titleCStr.str.raw,
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        gamePixelSize.x, gamePixelSize.y,
        cast(SDL_WindowFlags)0
    ));
}