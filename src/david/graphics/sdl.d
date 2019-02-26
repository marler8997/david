module david.graphics.sdl;

import david.types : PixelSize, Unit, UnitVector, UnitRectangle, GameView;
import david.log;
import david.windowing : Window;
import david.images : Image;
import david.graphics : gameView, gameUnitToPixelX, gameUnitToPixelY, gameUnitScalePixelX, gameUnitScalePixelY;
import david.sdl : enforceSdlCode, enforceSdlPtr;

import derelict.sdl2.sdl :
    SDL_Surface, SDL_Rect,
    SDL_MapRGB, SDL_GetError, SDL_FillRect, SDL_GetWindowSurface,
    SDL_LockSurface, SDL_UnlockSurface, SDL_UpdateWindowSurface, SDL_BlitSurface;

void init(Window window)
{
    // TODO: should we get the surface in beginrender/endrender instead?
    frameData.surface = SDL_GetWindowSurface(window.getSdlWindow);
    enforceSdlPtr(frameData.surface, "SDL_GetWindowSurface");
}
void initColors(Color[] colors)
{
/*
    foreach(i; 0..colors.length)
    {
        colors[i].brushHandle = CreateSolidBrush(COLORREF(colors[i].colorref));
        assert(colors[i].brushHandle, format("CreateSolidBrush(colorref=0x%x) failed (e=%s)",
            colors[i].colorref, GetLastError()));
    }
    */
}


private struct GraphicsFrameData
{
    SDL_Surface* surface;
}
private __gshared static GraphicsFrameData frameData;
void beginRender(Window window)
{
    // TODO: check return for errors
    //SDL_LockSurface(frameData.surface);
}
void endRender(Window window)
{
    // TODO: check return for errors
    //SDL_UnlockSurface(frameData.surface);
    // TODO: check return for errors
    SDL_UpdateWindowSurface(window.getSdlWindow);
}

struct Color
{
    ubyte red;
    ubyte green;
    ubyte blue;
    this(ubyte red, ubyte green, ubyte blue)
    {
        this.red = red;
        this.green = green;
        this.blue = blue;
    }
    this(uint rgb)
    {
        this.red   = cast(ubyte)(rgb >> 16);
        this.green = cast(ubyte)(rgb >>  8);
        this.blue  = cast(ubyte)(rgb >>  0);
    }
}

alias TextChar = char;
void fillScreen(Color color)
{
    // TODO: check if there is a more efficient way to do this
    gameFillRect(color, gameView.getRect);
}

void gameFillRect(Color color, UnitRectangle rect)
{
    auto sdlRect = SDL_Rect(
        rect.left.gameUnitToPixelX,
        rect.top.gameUnitToPixelY,
        rect.calculateWidth.gameUnitScalePixelX,
        rect.calculateHeight.gameUnitScalePixelY);
    const errorCode = SDL_FillRect(frameData.surface, &sdlRect,
        SDL_MapRGB(frameData.surface.format, color.red, color.green, color.blue));
    enforceSdlCode(errorCode, "SDL_FillRect");
}

void bitBlit(UnitVector dest, UnitVector tileSize, Image* image, UnitVector imageOffset)
{
    const srcRect = SDL_Rect(
        imageOffset.x.value, imageOffset.y.value,
        tileSize.x.value, tileSize.y.value);
    auto dstRect = SDL_Rect(
        dest.x.gameUnitToPixelX,
        dest.y.gameUnitToPixelY, 0, 0);
    const errorCode = SDL_BlitSurface(
        image.getSdlSurface, &srcRect,
        frameData.surface, &dstRect);
    enforceSdlCode(errorCode, "SDL_BlitSurface");
}

void viewDrawText(const(TextChar)[] text, UnitVector topLeft)
{
    //{import std.stdio;writefln("TODO: sdl:viewDrawText '%s'", text);}
    logf("TODO: sdl:viewDrawText '%s'", text);
}
