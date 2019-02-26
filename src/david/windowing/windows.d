module david.windowing.windows;

import mar.passfail;
import mar.c : cstring, tempCString;

import david.types : PixelSize;
import david.log;
import david.platform : winMainInstance;

import core.sys.windows.windows :
    // Defines
    SW_SHOWNORMAL, COLOR_WINDOW, IDC_ARROW, WS_OVERLAPPEDWINDOW, CW_USEDEFAULT,
    // Types
    HWND, ATOM, HINSTANCE, WNDCLASS, WNDPROC, HBRUSH, RECT,
    // Functions
    GetLastError, ShowWindow, LoadCursor, RegisterClass, AdjustWindowRect, CreateWindowEx;

struct Window
{
    private HWND handle;

    static Window nullValue() { return Window(null); }
    bool isNull() const { return handle is null; }

    // TODO: probably remove this at some point
    HWND getWindowsHandle() const { return cast(HWND)handle; }
    passfail tryShow()
    {
        // TODO: what to do about winMainCmdShow?
        ShowWindow(handle, SW_SHOWNORMAL);
        return passfail.pass; // can't fail as far as I know right now
    }
    void show()
    {
        if (tryShow().failed)
            assert(0, "failed to show window"); // todo: throw exception with nice error message
    }
    auto formatError() const
    {
        static struct Formatter
        {
            void toString(scope void delegate(const(char)[]) sink)
            {
                import std.format : formattedWrite;
                // TODO: convert last error to string
                formattedWrite(sink, "(e=%s)", GetLastError());
            }
        }
        return Formatter();
    }
}

ATOM registerWindowClass(cstring windowClassName, WNDPROC windowProc)
{
    WNDCLASS windowClass;
    windowClass.lpfnWndProc   = windowProc;
    windowClass.hInstance     = winMainInstance;
    windowClass.lpszClassName = windowClassName.raw;
    windowClass.hbrBackground = cast(HBRUSH)(COLOR_WINDOW+1);
    windowClass.hCursor       = LoadCursor(null, IDC_ARROW);
    assert(windowClass.hCursor);
    logf("window class is %s", windowClass);
    return RegisterClass(&windowClass);
}

private void toOriginInPlace(RECT* rect)
{
    rect.right -= rect.left;
    rect.left = 0;
    rect.bottom -= rect.top;
    rect.top = 0;
}

Window createWindow(const(char)[] title, PixelSize gamePixelSize, cstring windowClassName)
{
    mixin tempCString!("titleCStr", "title");

    enum WINDOW_STYLE = WS_OVERLAPPEDWINDOW;

    RECT adjustedWindowSize = RECT(0, 0, gamePixelSize.x, gamePixelSize.y);
    assert(AdjustWindowRect(&adjustedWindowSize, WINDOW_STYLE, false));
    toOriginInPlace(&adjustedWindowSize);
    logf("game pixel size %s, adjusted window size is %s",
        gamePixelSize, adjustedWindowSize);
    return Window(CreateWindowEx(
        0, // style
        windowClassName.raw,
        titleCStr.str.raw,
        WINDOW_STYLE,
        // Size and position
        CW_USEDEFAULT, CW_USEDEFAULT,
        adjustedWindowSize.right, adjustedWindowSize.bottom,
        null,            // Parent window
        null,            // Menu
        winMainInstance, // Instance handle
        null             // Additional application data
    ));
}
