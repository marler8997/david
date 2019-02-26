import core.time : TickDuration;
import core.runtime : Runtime;
import core.stdc.stdlib : exit;

import std.stdio : File;
import std.format : format, formattedWrite;
import std.typecons : Flag, Yes, No;
import std.algorithm : sort;

import mar.sentinel : lit;
import mar.c : tempCString;

import more.time;

static import david;
import david.log;
import david.util : Ticks, TimestampTicks, DurationTicks, LapTimerTicks, StopWatchTicks;
import david.file : exeRelativePath;
import david.platform : platformInit;
import david.windowing : createWindow;
import david.input : InputCodeBaseType;
import graphics = david.graphics;
static import app;
/*
    GameOptions, Logger,
    gameInitSize, gameInit, gameUpdate, gameRender,
    gameImmediateInputTable, gameQueuedInputTable, QueuedControlIndex, gameQueueInput;
    */

__gshared bool updateToRender;

void fatalError(string message) nothrow
{
    try { log(message); } catch(Throwable) { }
    try
    {
        mixin tempCString!("messageCStr", "message");
        version (Windows)
        {
            int result = MessageBox(GetActiveWindow(), messageCStr.str.raw, lit!"Fatal Error".ptr.raw, MB_OK | MB_ICONEXCLAMATION);
        }
    }
    catch (Exception )
    {
        assert(0, "unexpected exception inside fatalError function");
    }
    version (Windows)
        ExitProcess(1);
    else
        exit(1);
}
void fatalErrorf(T...)(string fmt, T args) nothrow
{
    string message;
    try
    {
        message = format(fmt, args);
    }
    catch(Throwable)
    {
        message = "(format error message failed) "~fmt;
    }
    fatalError(message);
}

version (Windows)
{
    import core.sys.windows.windows :
        // Defines
        WM_NCLBUTTONDOWN, WM_QUIT, MB_OK, MB_ICONEXCLAMATION, PM_REMOVE, WAIT_OBJECT_0, WAIT_TIMEOUT,
        WM_KEYDOWN, WM_KEYUP, WM_CLOSE, WM_DESTROY, WM_PAINT, WM_SYSCOMMAND, QS_ALLINPUT,
        // Types
        HINSTANCE, LPSTR, UINT, LRESULT, HWND, LPARAM, WPARAM,MSG,
        // Functions
        MessageBox, ExitProcess, PeekMessage, TranslateMessage, DispatchMessage, GetActiveWindow,
        MsgWaitForMultipleObjects, InvalidateRect, DestroyWindow, PostQuitMessage, ValidateRect, DefWindowProc;
    extern (Windows) int WinMain(HINSTANCE instance, HINSTANCE previousInstance, LPSTR cmdLine, int cmdShow)
    {
        commonMain1();
        platformInit(instance, cmdShow);
        int result = 0; // 0 means fail by default
        try
        {
            Runtime.initialize();
            result = commonMain2();
            Runtime.terminate();
        }
        catch (Throwable e)
        {
            fatalErrorf("Uhandled exception in WinMain: %s", e);
            //MessageBoxA(null, e.toString().toStringz(), null, MB_ICONEXCLAMATION);
            result = 0; // failed
        }
        return result;
    }
}
else
{
    int main(string[] args)
    {
        commonMain1();
        platformInit();
        return commonMain2();
    }
}
__gshared TimestampTicks mainStartTime;
private void commonMain1()
{
    mainStartTime = TimestampTicks.now();
    version (Windows)
    {
        // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        // FOR SOME REASON ON WINDOWS, thisExePath is causing system to hang????
        // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        //string logFilename = exeRelativePath("log.txt");
        string logFilename = "log.txt"; // just go to cwd for now
    }
    else
    {
        string logFilename = exeRelativePath("log");
    }
    setLogFile(logFilename);
}
private int commonMain2()
{
    version (Sdl)
    {
        import derelict.sdl2.sdl;
        import derelict.sdl2.image;
        import derelict.sdl2.mixer;
        import derelict.sdl2.ttf;
        import derelict.sdl2.net;
        import std.file : exists, thisExePath;
        import std.path : buildNormalizedPath, buildPath, dirName;
        auto sdlPath = buildNormalizedPath(dirName(thisExePath), "..", "SDL2-2.0.9");
        if (exists(sdlPath))
        {
            // if we built SDL ourselves
            auto lib = buildPath(sdlPath, "install", "lib", "libSDL2-2.0.so.0");
            logf("using custom sdl library '%s'", lib);
            DerelictSDL2.load(lib);
        }
        else
        {
            fatalErrorf("custom sdl library '%s' not found", sdlPath);
            //DerelictSDL2.load(SharedLibVersion(2, 0, 0));
        }

        //DerelictSDL2Image.load();
        //DerelictSDL2Mixer.load();
        //DerelictSDL2ttf.load();
        //DerelictSDL2Net.load();

        SDL_Init(SDL_INIT_EVERYTHING);
        SDL_LogSetAllPriority(SDL_LOG_PRIORITY_VERBOSE);
        static extern (C) void sdlLog(void* data, int category,
            SDL_LogPriority priority, const char *message) nothrow
        {
            import core.stdc.stdio : printf;
            printf("[SDL:%d:%d] %s\n", category, priority, message);
        }
        SDL_LogSetOutputFunction(&sdlLog, null);
    }

    version (Windows)
    {
        import david.windowing : registerWindowClass;
        const windowClassName = lit!"GamePhysicsWindowClass";
        const windowClass = registerWindowClass(windowClassName.ptr, &WindowProc);
        const windowClassNamePtr = windowClassName.ptr;
    }
    else
    {
        import std.meta : AliasSeq;
        auto windowClassNamePtr = AliasSeq!();
    }

    app.initWindowSize();
    const gamePixelSize = graphics.getPixelSize();
    auto window = createWindow("Game Physics", gamePixelSize, windowClassNamePtr);
    if(window.isNull)
    {
        fatalErrorf("failed to create the windows: %s", window.formatError);
    }

    // Initialize the Game
    graphics.init(window);

    david.Timing timing;
    app.init(&timing, window);

    window.show();
    static if(app.FixedFps != 0)
    {
        const ticksPerSecond = Ticks.per!(TimeUnit.seconds);
        if (LOG_TIMING) logf("ticks per second is %s", ticksPerSecond);
        timing.minTicksPerFrame = ticksPerSecond / app.FixedFps;
    }

    auto now = TimestampTicks.now();
    auto lastUpdateTime = now;
    auto nextUpdateTime = now.offsetWith(timing.minTicksPerFrame);
    GAME_LOOP:
    for(;;)
    {
        //
        // Handle Window Events
        //
    HANDLE_EVENTS_LOOP:
        for (;;)
        {
            final switch(handleEvents())
            {
              case HandleEventsResult.done: break;
              case HandleEventsResult.quit: break GAME_LOOP;
            }
            // The update should have been rendered after handling all the
            // event messages
            if(updateToRender)
            {
                assert(0, "last update was not rendered, this is unexpected");
            }
            final switch(waitForUpdate(&now, &nextUpdateTime, timing))
            {
              case WaitForUpdateResult.readyForUpdate: break HANDLE_EVENTS_LOOP;
              case WaitForUpdateResult.moreEventsToHandle: break;
            }
        }
        //
        // Update Game
        //
        {
            //Sleep(20); // simulate slow computer
            if (LOG_TIMING) log("--------------------------- UPDATE ---------------------------");
            static if (app.FixedFps == 0)
            {
                // NOTE: `now` should always have been updated inside the waitForUpdate function
                const updateDurationTicks = now.diff(lastUpdateTime);
                lastUpdateTime = now;
                if (LOG_TIMING) logf("update time %s", updateDurationTicks);
                if (LOG_TIMING) logf("time till next update %s", nextUpdateTime.diff(now));
                auto updateDuration = Duration!(app.UpdateTimeUnit, app.UpdateTimeInteger)();
                app.update(updateDuration);
                updateDuration.reset();
            }
            else
            {
                app.update();
            }
            updateToRender = true;
        }
        //
        // Render Game
        //
        version (Windows)
        {
            // TODO: should I just paint here instead of invalidating the rect?
            InvalidateRect(window.getWindowsHandle, null, false);
            /*
            {
                graphicsBeginRender(windowHandle);
                scope(exit)
                {
                    graphicsEndRender(windowHandle);
                }
                logf("gameRender");
                gameRender();
            }
            */
        }
        else
        {
            {
                graphics.beginRender(window);
                scope(exit) graphics.endRender(window);
                app.render();
            }
            updateToRender = false;
        }
    }

    version (Windows)
    {
        // Log some performance
        defWndProcTimes.log("DefWndProc");
        dispatchMessageTimes.log("DispatchMessage");
        logf("MsgWaitForMultipleObjects time (%s calls, %s)",
            waitForMessageTimeBin.callCount, waitForMessageTimeBin.total.formatNice);
        logf("TranslateMessage time (%s calls, %s)",
            translateMessageTimeBin.callCount, translateMessageTimeBin.total.formatNice);
        //logf("DispatchMessage time (%s calls, %s)",
        //    dispatchMessageTimeBin.callCount, dispatchMessageTimeBin.total.formatNice);
    }
    auto totalRunTime = TimestampTicks.now().diff(mainStartTime);
    logf("Total Time: %s", totalRunTime.formatNice);
    return 0;
}


enum WaitForUpdateResult
{
    readyForUpdate,
    moreEventsToHandle,
}
WaitForUpdateResult waitForUpdate(TimestampTicks* now, TimestampTicks* nextUpdateTime, const ref david.Timing timing)
{
    for (bool forbidAnotherWait = false;; forbidAnotherWait = true)
    {
        *now = TimestampTicks.now();
        const ticksTillUpdate = nextUpdateTime.diff(*now);
        if (LOG_TIMING) logf("ticksTillUpdate = %s (%s ms)", ticksTillUpdate, ticksTillUpdate.to!(TimeUnit.milliseconds));

        if (ticksTillUpdate <= 0) // If we are LATE!!!
        {
            static if(app.FixedFps == 0)
            {
                // TODO: don't have to wait the minimum because we are late
                *nextUpdateTime = now.offsetWith(timing.minTicksPerFrame + ticksTillUpdate);
            }
            else
            {
                // If we are late, we can take a little less time on the next frame, but we shouldn't
                // make it too long if we are VERY VERY late
                if (-ticksTillUpdate < timing.minTicksPerFrame)
                {
                    if (LOG_TIMING) logf("only a little late: %s", -ticksTillUpdate);
                    *nextUpdateTime = now.offsetWith(timing.minTicksPerFrame + ticksTillUpdate);
                }
                else
                {
                    if (LOG_TIMING) logf("VERY LATE: %s", -ticksTillUpdate);
                    *nextUpdateTime = now.offsetWith(timing.minTicksPerFrame);
                }
            }
            return WaitForUpdateResult.readyForUpdate;
        }

        const millisecondsToWait = forbidAnotherWait ? 0 : ticksTillUpdate.to!(TimeUnit.milliseconds, uint);
        if (millisecondsToWait == 0)
        {
            // This means that we are early but less than a millisecond early. The problem is
            // we can't really wait longer since we can only wait in millisecond units.
            // So we'll just add the extra ticks we need to wait to the next time slot.
            *nextUpdateTime = now.offsetWith(timing.minTicksPerFrame + ticksTillUpdate);
            return WaitForUpdateResult.readyForUpdate;
        }

        version (Windows)
        {
            waitForMessageTimeBin.enter();
            const result = MsgWaitForMultipleObjects(0, null, 0, millisecondsToWait, QS_ALLINPUT);
            waitForMessageTimeBin.exit();
            if (result == WAIT_OBJECT_0)
            {
                if (LOG_TIMING) logf("WaitForWindowsMessages(%s ms) popped", millisecondsToWait);
                return WaitForUpdateResult.moreEventsToHandle;
            }
            assert(result == WAIT_TIMEOUT);
            if (LOG_TIMING) logf("WaitForWindowsMessages(%s ms) timeout", millisecondsToWait);
        }
        else version (Sdl)
        {
            import derelict.sdl2.sdl : SDL_Delay;
            // for now just delay
            SDL_Delay(millisecondsToWait);
        }
        else
        {
            assert(0, "not implemented");
        }
    }
}


enum KeyState { up, down }
void handleKeyEvent(KeyState state, InputCodeBaseType code)
{
    import std.conv : asOriginalType;

    // TODO: may also want to support lookup tables for inputs
    //       could have one big input table for all inputs, or possibly
    //       multiple input tables that span accross multiple ranges.

    // TODO: would be nice if I could disable auto-repeat keydown
    //       windows messages.
    foreach(i; 0..app.immediateInputTable.length)
    {
        if(app.immediateInputTable[i].code.asOriginalType == code)
        {
            app.immediateInputTable[i].pressed = (state == KeyState.down) ? true : false;
            return;
        }
    }
    if (state == KeyState.down)
    {
        foreach(i; 0..app.queuedInputTable.length)
        {
            if(app.queuedInputTable[i].code.asOriginalType == code)
            {
                app.queueInput(cast(app.QueuedControlIndex)i);
                return;
            }
        }
    }
}


enum HandleEventsResult { done, quit }
version (Sdl)
{
    HandleEventsResult handleEvents()
    {
        import derelict.sdl2.sdl :
           SDL_QUIT, SDL_KEYDOWN, SDL_KEYUP,
           SDL_Event,
           SDL_PollEvent;

        for (uint eventsHandled = 0; ;eventsHandled++)
        {
            SDL_Event event;
            if (!SDL_PollEvent(&event))
            {
                if (LOG_TIMING) logf("handled %s window event(s)", eventsHandled);
                break;
            }
            if (event.type == SDL_KEYDOWN)
            {
                handleKeyEvent(KeyState.down, event.key.keysym.scancode);
            }
            else if (event.type == SDL_KEYUP)
            {
                handleKeyEvent(KeyState.up, event.key.keysym.scancode);
            }
            else if (event.type == SDL_QUIT)
            {
                log("SDL_QUIT");
                return HandleEventsResult.quit;
            }
            else
            {
               logf("TODO: event with unknown type '%s'", event.type);
            }
        }
        return HandleEventsResult.done;
    }
}
else version (Windows)
{
    HandleEventsResult handleEvents()
    {
        for(uint messagesHandled = 0; ; messagesHandled++)
        {
            MSG msg;
            if(!PeekMessage(&msg, null, 0, 0, PM_REMOVE))
            {
                if (LOG_TIMING) logf("handled %s windows message(s)", messagesHandled);
                break;
            }

            //log("got message %s", result);

            translateMessageTimeBin.enter();
            TranslateMessage(&msg);
            translateMessageTimeBin.exit();

            auto messageTimeBin = dispatchMessageTimes.getTimeBin(msg.message);
            messageTimeBin.enter();
            DispatchMessage(&msg);
            messageTimeBin.exit();

            if(msg.message == WM_QUIT)
            {
                log("WM_QUIT");
                return HandleEventsResult.quit;
            }
        }
        return HandleEventsResult.done;
    }

    struct MessagePerformance
    {
        uint msg;
        TimeBin timeBin;
        alias timeBin this;
    }

    auto messageTimeBins(Flag!"dynamic" dynamic = No.dynamic)(MessagePerformance[] messageTable)
    {
        return MessageTimeBins!dynamic(messageTable);
    }
    struct MessageTimeBins(Flag!"dynamic" dynamic)
    {
        MessagePerformance[] messageTable;
        static if(!dynamic)
        {
            TimeBin unknownTimeBin;
        }
        this(MessagePerformance[] messageTable)
        {
            this.messageTable = messageTable;
        }
        TimeBin* getTimeBin(UINT msg)
        {
            foreach(i; 0..messageTable.length)
            {
                if(messageTable[i].msg == msg)
                {
                    return &messageTable[i].timeBin;
                }
            }
            static if(dynamic)
            {
                messageTable ~= MessagePerformance(msg);
                assert(messageTable[$-1].msg == msg);
                return &messageTable[$-1].timeBin;
            }
            else
            {
                return &unknownTimeBin;
            }
        }
        void log(string name)
        {
            sort!q{a.timeBin.total < b.timeBin.total}(messageTable);
            foreach(i; 0..messageTable.length)
            {
                auto messageTime = &messageTable[i];
                logf("%s(msg=%s) (%s calls, %s)",
                    name, messageTime.msg, messageTime.callCount, messageTime.total.formatNice);
            }
            static if(!dynamic)
            {
                logf("%s(msg=unknown) (%s calls, %s)", name,
                    unknownTimeBin.callCount, unknownTimeBin.total.formatNice);
            }
        }
    }
    __gshared auto defWndProcTimes = messageTimeBins!(Yes.dynamic)([
        MessagePerformance(WM_NCLBUTTONDOWN),
    ]);
    __gshared auto dispatchMessageTimes = messageTimeBins!(Yes.dynamic)([
        MessagePerformance(WM_NCLBUTTONDOWN),
    ]);
}

struct TimeBin
{
    uint callCount;
    uint depth;
    StopWatchTicks stopwatch;
    auto total() const { return stopwatch.totalDuration; }

    void enter()
    {
        callCount++;
        if (depth == 0)
        {
            stopwatch.start();
        }
        depth++;
    }
    void exit()
    {
        depth--;
        if (depth == 0)
        {
            stopwatch.stop();
        }
    }
}
__gshared TimeBin waitForMessageTimeBin;
__gshared TimeBin translateMessageTimeBin;

version (Windows)
{
    extern(Windows) LRESULT WindowProc(HWND windowHandle, UINT msg, WPARAM param1, LPARAM param2) nothrow
    {
        try
        {
            TimeBin* messageTimeBin = defWndProcTimes.getTimeBin(msg);
            messageTimeBin.enter();
            scope(exit) messageTimeBin.exit();

            switch (msg)
            {
            case WM_KEYDOWN:
                handleKeyEvent(KeyState.down, param1);
                return 0;
            case WM_KEYUP:
                handleKeyEvent(KeyState.up, param1);
                return 0;
            case WM_CLOSE:
                DestroyWindow(windowHandle);
                return 0;
            case WM_DESTROY:
                PostQuitMessage(0);
                return 0;
            case WM_PAINT:
                {
                    {
                        graphics.beginRender(windowHandle);
                        scope(exit) graphics.endRender(windowHandle);
                        app.render();
                    }
                    ValidateRect(windowHandle, null);
                    updateToRender = false;
                }
                return 0;
            case WM_SYSCOMMAND:
                logf("SYSCOMMAND %s %s", param1, param2);
                break;
            default:
                break;
            }

            return DefWindowProc(windowHandle, msg, param1, param2);
        }
        catch(Throwable e)
        {
            try {fatalErrorf("Unhandled Exception in WindowProc: %s", e); } catch(Throwable) { }
            ExitProcess(1);
            return 1; // fail
        }
    }
}
/*
auto fmtNice(TickDuration duration)
{
    struct Formatter
    {
        TickDuration duration;
        void toString(scope void delegate(const(char)[]) sink) const
        {
            if(duration.msecs == 0)
            {
                formattedWrite(sink, "%s us", duration.usecs);
            }
            else if(duration.seconds == 0)
            {
                formattedWrite(sink, "%s.%03d ms", duration.msecs, duration.usecs % 1000);
            }
            else
            {
                formattedWrite(sink, "%s.%03d s", duration.seconds, duration.msecs % 1000);
            }
        }
    }
    return Formatter(duration);
}
*/
auto formatNice(DurationTicks ticks)
{
    struct Formatter
    {
        DurationTicks ticks;
        void toString(scope void delegate(const(char)[]) sink) const
        {
            // TODO: add more granularity
            formattedWrite(sink, "%s ms", ticks.to!(TimeUnit.milliseconds));
        }
    }
    return Formatter(ticks);
}