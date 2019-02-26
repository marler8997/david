module david.graphics;

import david.types : Unit, UnitVector, UnitRectangle, PixelSize, GameView;
import david.images : Image;

static import app;

version (Windows)
{
    version(Gdi)
        public import david.graphics.gdi;
    else version(Direct2DAurora)
        public import david.graphics.direct2daurora;
    else version(Direct2DEvilrat)
        public import david.graphics.direct2devilrat;
    else version(Sdl)
        public import david.graphics.sdl;
    else static assert(0, "Windows requires version Gdi, Direct2D or Sdl");
}
else version (Posix)
{
    version(X11)
        public import david.graphics.x11;
    else version(Sdl)
        public import david.graphics.sdl;
    else static assert(0, "Posix requires version X11 or Sdl");
}

__gshared GameView gameView;

/// NOTE: pixels per unit is always >= 1
static if (app.FixedPixelsPerUnit == 0)
{
    private __gshared ubyte pixelsPerUnit = 1;
    void setPixelsPerUnit(ubyte pixelsPerUnit) { .pixelsPerUnit = pixelsPerUnit; }

}
else
{
    private enum ubyte pixelsPerUnit = 1;
}
PixelSize getPixelSize()
{
    return PixelSize(
        pixelsPerUnit * gameView.width.value,
        pixelsPerUnit * gameView.height.value);
}
auto gamePixelWidth() { return pixelsPerUnit * gameView.width.value; }
auto gamePixelHeight() { return pixelsPerUnit * gameView.height.value; }
auto gameUnitToPixelX(Unit unit)
{
    return pixelsPerUnit * (unit - gameView.left).value;
}

// Different than gameUnitToPixelX.  It just scales the value, does not
// reverse the value if coordinates go right to left.
// Typically used for pixel sizes rather than pixel coordinates.
auto gameUnitScalePixelX(Unit unit) { return pixelsPerUnit * unit.value; }
// Different than gameUnitToPixelY.  It just scales the value, does not
// reverse the value if coordinates go top to bottom.
// Typically used for pixel sizes rather than pixel coordinates.
auto gameUnitScalePixelY(Unit unit) { return pixelsPerUnit * unit.value; }


auto topToBottomGameUnitToPixelY(Unit unit)
{
    return pixelsPerUnit * (gameView.top - unit).value;
}
auto bottomToTopGameUnitToPixelY(Unit unit)
{
    return pixelsPerUnit * (unit - gameView.top).value;
}

// TODO: this should probably be moved into the "backend-specific" module.
version (Gdi)
    alias gameUnitToPixelY = topToBottomGameUnitToPixelY;
else version (Sdl)
    alias gameUnitToPixelY = topToBottomGameUnitToPixelY;
else static assert("not sure what how this graphics backend treats Y coordinates");

/*
auto gameUnitVectorToPixelVector(UnitVector unitVector)
{
    return PixelVector(unitVector.x.gameUnitToPixelX, unitVector.y.gameUnitToPixelY);
}
*/

// TODO: add transparency support!!!
void gameDrawTiledImage(UnitVector tileSize, UnitRectangle rect, Image* image, UnitVector imageOffset)
{
    import std.format : format;

    //version(StretchAtTheEnd)
    //{
        Unit currentY = rect.bottom + tileSize.y;
        Unit nextY;
        for(;;)
        {
            nextY = currentY + tileSize.y;
            if(currentY > rect.top )
                break;

            Unit currentX = rect.left;
            Unit nextX;
            for(;;)
            {
                nextX = currentX + tileSize.x;
                if(nextX > rect.right)
                    break;

                // TODO: use TransparentBlt instead!
                bitBlit(UnitVector(currentX, currentY), tileSize,
                    image, imageOffset);
                currentX = nextX;
            }

            assert(currentX == rect.right, format("currentX %s, rect.right %s, not implemented", currentX, rect.right));
            /*
            bitBlit(UnitVector(rect.left, rect.top),
                UnitVector((rect.right - rect.left).value,
                           (rect.top - rect.bottom).value),
                image, UnitVector(0, 0), SRCCOPY);
                */

            currentY = nextY;
        }
        assert(currentY == rect.top + tileSize.y, "not implemented");
        /*
        bitBlit(UnitVector(rect.left, rect.top),
            UnitVector((rect.right - rect.left).value,
                       (rect.top - rect.bottom).value),
            image, UnitVector(0, 0), SRCCOPY);
            */
    //}
    //else static assert(0, "not implemented");
}
