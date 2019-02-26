module david.graphics.direct2daurora;

import core.sys.windows.windows;

import std.format : format;

//import directx.com;
//import directx.win32;
//import directx.d2d1;
//import directx.d2d1helper;
//import directx.dwrite;

import aurora.directx.d2d1;

import david.types : PixelSize, Unit, UnitVector, UnitRectangle, GameView;
import david.windowing : Window;
import david.images : Image;
import david.graphics : gameView;

alias TextChar = wchar;

private __gshared ID2D1Factory direct2dFactory;
private __gshared ID2D1HwndRenderTarget renderTarget;

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

void init(Window window)
{
    {
        auto options = D2D1_FACTORY_OPTIONS(D2D1_DEBUG_LEVEL_WARNING);
        auto result = D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED,
            &IID_ID2D1Factory, &options, cast(void**)&direct2dFactory);
        assert(S_OK == result, format("D2D1CreateFactory returned 0x%x", result));
    }
    {
        auto gamePixelSize = getPixelSize();
        auto result = direct2dFactory.CreateHwndRenderTarget(
            D2D1.RenderTargetPropertiesPtr(),
            D2D1.HwndRenderTargetPropertiesPtr(window.getWindowsHandle,
                D2D1_SIZE_U(gamePixelSize.x, gamePixelSize.y)), &renderTarget);
        assert(S_OK == result, format("CreateHwndRenderTarget returned 0x%x", result));
    }
}

void beginRender(HWND windowHandle)
{
    renderTarget.BeginDraw();
    /*
    auto identity = D2D1.Matrix3x2F.Identity;
    renderTarget.SetTransform(&identity.matrix);
    */
}
void endRender(HWND windowHandle)
{
/*
    {
        ID2D1SolidColorBrush brush;
        assert(S_OK == CreateSolidColorBrush(renderTarget, D2D1.ColorF(1, 0, 0), &brush));

        // Draw a grid background.
        for (int x = 0; x < windowContentWidth; x += 10)
        {
            renderTarget.DrawLine(
                D2D1.Point2F(x, 0.0f),
                D2D1.Point2F(x, windowContentHeight),
                brush,
                0.5f
                );
        }

        brush.Release();
    }
    */
    renderTarget.EndDraw();
}

struct Color
{
    ubyte red;
    ubyte green;
    ubyte blue;
    private ID2D1SolidColorBrush brush;
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
    private auto colorF()
    {
        return D2D1.ColorF(((cast(uint)red  ) << 16) |
                      ((cast(uint)green) <<  8) |
                      ((cast(uint)blue ) <<  0) );
    }
}
void initColors(Color[] colors)
{
    foreach(i; 0..colors.length)
    {
        assert(S_OK == CreateSolidColorBrush(renderTarget, colors[i].colorF, &colors[i].brush));
        assert(colors[i].brush, format("D2D1.CreateSolidColorBrush failed (e=%d)", GetLastError()));
    }
}

private LONG toPixelX(Unit unit)
{
    return pixelsPerUnit * (unit - gameView.left).value;
}
private LONG toPixelY(Unit unit)
{
    return pixelsPerUnit * (gameView.top - unit).value;
}

void fillScreen(Color color)
{
    auto d2dColor = color.colorF;
    renderTarget.Clear(&d2dColor.color);
}
void gameFillRect(Color color, UnitRectangle rect)
{
    auto d2dRect = D2D1.RectF(rect.left.toPixelX, rect.top.toPixelY,
        rect.right.toPixelX, rect.bottom.toPixelY);
    renderTarget.FillRectangle(&d2dRect, color.brush);
}
/+
void gameDrawText(const(TextChar)[] text, UnitVector topLeft)
{
    /*
    auto gdiRect = RECT(topLeft.x.toPixelX, topLeft.y.toPixelY,
        topLeft.x.toPixelX + 1, topLeft.y.toPixelY + 1);
    assert(DrawText(frameData.memoryDC, text.ptr, text.length, &gdiRect,
        DT_SINGLELINE | DT_LEFT | DT_NOCLIP));
        */
}
+/
void screenDrawText(const(TextChar)[] text, UnitVector topLeft/*, Color color*/)
{
/*
    auto color = Color(0xFF, 0xFF, 0xFF);
    assert(S_OK == CreateSolidColorBrush(renderTarget, color.colorF, &color.brush));
    assert(color.brush, format("D2D1.CreateSolidColorBrush failed (e=%d)", GetLastError()));
    scope(exit)
    {
        color.brush.Release();
    }

    //auto d2dRect = D2D1.RectF(rect.left.toPixelX, rect.top.toPixelY,
    //    rect.right.toPixelX, rect.bottom.toPixelY);
    auto d2dRect = D2D1.RectF(0, 0, 100, 100);
    renderTarget.DrawText(text.ptr, text.length, null, &d2dRect, color.brush);
    */
}
void viewDrawText(const(TextChar)[] text, UnitVector topLeft)
{
    // not implemented
}

void bitBlit(UnitVector dest, UnitVector tileSize, Image* image, UnitVector imageOffset)
{
    {import std.stdio;writefln("graphics/direct2d.d: TODO: implement bitBlit");}
    /*
    assert(BitBlt(frameData.memoryDC, dest.x.gameUnitToPixelXMidFrame, dest.y.gameUnitToPixelYMidFrame,
        tileSize.x.value, tileSize.y.value, image.dc, imageOffset.x.value, imageOffset.y.value, SRCCOPY));
        */
}
