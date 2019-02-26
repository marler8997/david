module david.util;

import more.time;

/**
An output range interface.

I created this type because formattedWrite only supports the 'char' type.  Using this
StringSink type allows you to use formattedWrite to write to other char types like
wchar or dchar.

Example:
----
wchar[10] message;
auto sink = StringSink!wchar(message);
formattedWrite(&sink.put, "hello");
----
 */
struct StringSink(Char)
{
    Char[] buffer;
    size_t contentLength;
    this(Char[] buffer)
    {
        this.buffer = buffer;
    }
    auto data()
    {
        return buffer[0..contentLength];
    }
    void put(const(char)[] str)
    {
        if(str.length == 0)
        {
            return;
        }
        static if(Char.sizeof == 1)
        {
            assert(contentLength + str.length <= buffer.length);
            buffer[contentLength .. contentLength + str.length] = str[];
            contentLength += str.length;
        }
        else
        {
            assert(contentLength + str.length <= buffer.length);
            foreach(c; str)
            {
                assert(c <= char.max, "non-ascii not implemented");
                buffer[contentLength++] = cast(char)c;
            }
        }
    }
}
/**
Example:
----
wchar[10] message;
auto sink = stringSink(message);
formattedWrite(&sink.put, "hello");
----
 */
auto stringSink(Char)(Char[] buffer)
{
    return StringSink!Char(buffer);
}

private static struct TimePolicy
{
}
public alias Time = TimeTemplate!TimePolicy;
public alias Ticks = Time.Ticks;
public alias TimestampTicks = Time.TimestampTicks;
public alias DurationTicks = Time.DurationTicks;
public alias LapTimerTicks = Time.LapTimerTicks;
public alias StopWatchTicks = Time.StopWatchTicks;

/+
/**
Use to mixin a default set of log entry points into your `game` module.
These entry points implement a single log file that is created in the
directory where the game is started using the given `filename`.
*/
mixin template SimpleLogFile(string filename)
{
    import std.stdio : File;
    private static __gshared File logFile;
    void initLog()
    {
        logFile = File(filename, "wb");
    }
    void log(string message)
    {
        // TODO: add synchronization code
        logFile.writeln(message);
        logFile.flush();
    }
    void logf(T...)(string fmt, T args)
    {
        // TODO: add synchronization code
        logFile.writefln(fmt, args);
        logFile.flush();
    }
}
+/

struct FpsTracker(size_t msecsPerUpdate = 1000)
{
    private DurationTicks ticksSinceUpdate;
    private uint framesSinceUpdate;
    uint fps;
    void update(DurationTicks frameTicks)
    {
        ticksSinceUpdate = ticksSinceUpdate + frameTicks;
        framesSinceUpdate++;
        const msecsSinceUpdate = ticksSinceUpdate.to!(TimeUnit.milliseconds, uint);
        if (msecsSinceUpdate >= msecsPerUpdate)
        {
            fps = (1000 * framesSinceUpdate) / msecsSinceUpdate;
            ticksSinceUpdate = DurationTicks(0);
            framesSinceUpdate = 0;
        }
    }
}