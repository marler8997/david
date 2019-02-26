module david.graphics.x11;

import david.types : PixelSize, Unit, UnitVector, UnitRectangle, GameView;
import david.images : Image;
import david.graphics : gameView;

void init(/*HWND windowHandle*/)
{
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

private __gshared ubyte pixelsPerUnit = 1;
void setPixelsPerUnit(ubyte pixelsPerUnit)
{
    .pixelsPerUnit = pixelsPerUnit;
}
PixelSize getPixelSize()
{
    return PixelSize(
        pixelsPerUnit * gameView.width.value,
        pixelsPerUnit * gameView.height.value);
}

struct Color
{
    //COLORREF colorref;
    //HBRUSH brushHandle;
    this(ubyte red, ubyte green, ubyte blue)
    {
        //colorref = (red << 0) | (blue << 16) | (green << 8);
    }
    this(uint rgb)
    {
        this(cast(ubyte)(rgb >> 16),
            cast(ubyte)(rgb >>  8),
            cast(ubyte)(rgb >>  0));
    }
}

alias TextChar = char;
void fillScreen(Color color)
{
    {import std.stdio;writefln("TODO: x11:fillScreen");}
}
void gameFillRect(Color color, UnitRectangle rect)
{
    {import std.stdio;writefln("TODO: x11:gameFillRect");}
}
void gameDrawTiledImage(UnitVector tileSize, UnitRectangle rect, Image* image, UnitVector imageOffset)
{
    {import std.stdio;writefln("TODO: x11:gameDrawTiledImage");}
}
void viewDrawText(const(TextChar)[] text, UnitVector topLeft)
{
    {import std.stdio;writefln("TODO: x11:viewDrawText '%s'", text);}
}
