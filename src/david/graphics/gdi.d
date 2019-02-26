module david.graphics.gdi;

import core.sys.windows.windows;

import std.format : format;

import david.types : PixelSize, Unit, UnitVector, UnitRectangle, GameView;
import david.log;
import david.windowing : Window;
import david.images : Image;
static import david.graphics;
import david.graphics : gameView, getPixelSize, gamePixelWidth, gamePixelHeight;

pragma(lib, "gdi32.lib");

// I don't know which version has better performance so I'm going
// to support both for now
version = StretchAtTheEnd;
//version = StretchEachDraw;

version(StretchAtTheEnd)
{
}
else version(StretchEachDraw)
{
}
else static assert(0);


alias TextChar = char;

void init(Window window)
{
}
// The public common graphics API
private struct GraphicsFrameData
{
    HDC windowDC;
    HDC memoryDC;
    Unit bitmapWidth;
    Unit bitmapHeight;
    HGDIOBJ originalMemoryBitmap;
    HBITMAP memoryBitmap;
}
private __gshared static GraphicsFrameData frameData;
void beginRender(HWND windowHandle)
{
    if(frameData.windowDC is null)
    {
        frameData.windowDC = GetDC(windowHandle);
        assert(frameData.windowDC, format("GetDC failed (e=%s)", GetLastError()));

        frameData.memoryDC = CreateCompatibleDC(frameData.windowDC);
        assert(frameData.memoryDC, format("CreateCompatibleDC failed (e=%s)", GetLastError()));
    }

    if(frameData.bitmapWidth != gameView.width ||
    frameData.bitmapHeight != gameView.height)
    {
        if(frameData.memoryBitmap !is null)
        {
            SelectObject(frameData.memoryDC, frameData.originalMemoryBitmap);
            assert(DeleteObject(frameData.memoryBitmap));
            frameData.memoryBitmap = null;
        }

        version(StretchAtTheEnd)
        {
            frameData.memoryBitmap = CreateCompatibleBitmap(frameData.windowDC,
                gameView.width.value, gameView.height.value);
        }
        else version(StretchEachDraw)
        {
            frameData.memoryBitmap = CreateCompatibleBitmap(frameData.windowDC, gamePixelWidth, gamePixelHeight);
        }
        assert(frameData.memoryBitmap, format("CreateCompatibleBitmap failed (e=%s)", GetLastError()));
        frameData.originalMemoryBitmap = SelectObject(frameData.memoryDC, frameData.memoryBitmap);
        assert(frameData.originalMemoryBitmap);

        frameData.bitmapWidth = gameView.width;
        frameData.bitmapHeight = gameView.height;
    }
}
void endRender(HWND windowHandle)
{
    assert(frameData.originalMemoryBitmap);
    assert(frameData.memoryBitmap);
    assert(frameData.bitmapWidth == gameView.width);
    assert(frameData.bitmapHeight == gameView.height);
    assert(frameData.memoryDC);
    assert(frameData.windowDC);

    version(StretchAtTheEnd)
    {
        auto size = getPixelSize();
        assert(StretchBlt(frameData.windowDC, 0, 0, size.x, size.y,
                        frameData.memoryDC, 0, 0, frameData.bitmapWidth.value,
                                                    frameData.bitmapHeight.value, SRCCOPY));
    }
    else version(StretchEachDraw)
    {
        assert(BitBlt(frameData.windowDC, 0, 0, gamePixelWidth, gamePixelHeight,
                    frameData.memoryDC, 0, 0, SRCCOPY));
    }
}


struct Color
{
    COLORREF colorref;
    HBRUSH brushHandle;
    this(ubyte red, ubyte green, ubyte blue)
    {
        colorref = (red << 0) | (blue << 16) | (green << 8);
    }
    this(uint rgb)
    {
        this(cast(ubyte)(rgb >> 16),
            cast(ubyte)(rgb >>  8),
            cast(ubyte)(rgb >>  0));
    }
}
void initColors(Color[] colors)
{
    foreach(i; 0..colors.length)
    {
        colors[i].brushHandle = CreateSolidBrush(COLORREF(colors[i].colorref));
        assert(colors[i].brushHandle, format("CreateSolidBrush(colorref=0x%x) failed (e=%s)",
            colors[i].colorref, GetLastError()));
    }
}

private enum Scale = false;

version(StretchAtTheEnd)
{
    private auto gameUnitToPixelXMidFrame(Unit unit)
    {
        return (unit - gameView.left).value;
    }
    private auto gameUnitToPixelYMidFrame(Unit unit)
    {
        return (gameView.top - unit).value;
    }
    private static LONG viewUnitToMemoryPixelX(Unit unit)
    {
        return unit.value;
    }
    private static LONG viewUnitToMemoryPixelY(Unit unit)
    {
        return (gameView.height - unit).value;
    }
}
else version(StretchEachDraw)
{
    alias gameUnitToPixelXMidFrame = david.graphics.gameUnitToPixelX;
    alias gameUnitToPixelYMidFrame = david.graphics.gameUnitToPixelY;
    private LONG viewUnitToMemoryPixelX(Unit unit)
    {
        assert(0, "not implemented");
    }
    private LONG viewUnitToMemoryPixelY(Unit unit)
    {
        assert(0, "not implemented");
    }
}

void fillScreen(Color color)
{
    version(StretchAtTheEnd)
    {
        const gdiRect = RECT(0, 0, gameView.width.value, gameView.height.value);
    }
    else
    {
        const gdiRect = RECT(0, 0, gamePixelWidth, gamePixelHeight);
    }
    assert(FillRect(frameData.memoryDC, &gdiRect, color.brushHandle));
}
void gameFillRect(Color color, UnitRectangle rect)
{
    auto gdiRect = RECT(rect.left.gameUnitToPixelXMidFrame, rect.top.gameUnitToPixelYMidFrame,
        rect.right.gameUnitToPixelXMidFrame, rect.bottom.gameUnitToPixelYMidFrame);
    assert(FillRect(frameData.memoryDC, &gdiRect, color.brushHandle));
}
/*
void gameDrawText(const(TextChar)[] text, UnitVector topLeft)
{
    auto gdiRect = RECT(topLeft.x.gameUnitToPixelXMidFrame, topLeft.y.gameUnitToPixelYMidFrame,
        topLeft.x.gameUnitToPixelXMidFrame + 1, topLeft.y.gameUnitToPixelYMidFrame + 1);
    assert(DrawText(frameData.memoryDC, text.ptr, text.length, &gdiRect,
        DT_SINGLELINE | DT_LEFT | DT_NOCLIP));
}
*/
void viewDrawText(const(TextChar)[] text, UnitVector topLeft)
{
    auto x = topLeft.x.viewUnitToMemoryPixelX;
    auto y = topLeft.y.viewUnitToMemoryPixelY;
    auto gdiRect = RECT(x, y, x + 1, y + 1);
    assert(DrawText(frameData.memoryDC, text.ptr, text.length, &gdiRect,
        DT_SINGLELINE | DT_LEFT | DT_NOCLIP));
}

void gameDrawImage(UnitRectangle rect, Image* image, UnitVector imageOffset)
{
    /*
    BITMAP bitmap;
    assert(GetObject(image.handle, bitmap.sizeof, &bitmap),
        format("GetObject failed (e=%s)", GetLastError()));
    */
    version(StretchAtTheEnd)
    {
        assert(BitBlt(frameData.memoryDC,
            rect.left.gameUnitToPixelXMidFrame,
            rect.top.gameUnitToPixelYMidFrame,
            (rect.right - rect.left).value,
            (rect.top - rect.bottom).value,
            image.dc, 0, 0, SRCCOPY));
    }
    else
    {
        log("TODO: implement gameDrawImage");
        //assert(0, "not implemented");
    }
}

void bitBlit(UnitVector dest, UnitVector tileSize, Image* image, UnitVector imageOffset)
{
    assert(BitBlt(frameData.memoryDC, dest.x.gameUnitToPixelXMidFrame, dest.y.gameUnitToPixelYMidFrame,
        tileSize.x.value, tileSize.y.value, image.dc, imageOffset.x.value, imageOffset.y.value, SRCCOPY));
}
