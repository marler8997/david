module david.images.gdi;

import core.sys.windows.windows;

import std.format : format;

import mar.c : cstring;

import david.types : CString;
import david.windowing : Window;

struct Image
{
    package HANDLE handle;
    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    // TODO: change public to package
    public HDC dc;
    void cleanup()
    {
        assert(0, "not implemented");
    }
}

struct ImageLoader
{
    package Window window;
    package HDC windowDC;
    void prepare(Window window)
    in { assert(!window.isNull); } do
    {
        assert(this.window.isNull);
        assert(this.windowDC is null);
        this.window = window;
        this.windowDC = GetDC(window.getWindowsHandle);
        assert(this.windowDC, format("GetDC failed (e=%s)", GetLastError()));
    }
    void release()
    {
        assert(!this.window.isNull);
        assert(this.windowDC !is null);
        ReleaseDC(this.window.getWindowsHandle, this.windowDC);
        this.windowDC = null;
        this.window = Window.nullValue;
    }
    Image load(cstring filename)
    {
        Image image;
        image.handle = LoadImage(null,
            filename.raw, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE);
        assert(image.handle, format("LoadImage(\"%s\") failed (e=%s)", filename, GetLastError()));

        image.dc = CreateCompatibleDC(windowDC);
        assert(image.dc, format("CreateCompatibleDC failed (e=%s)", GetLastError()));

        SelectObject(image.dc, image.handle);
        return image;
    }
}
