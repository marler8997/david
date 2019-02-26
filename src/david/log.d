module david.log;

static import std.stdio;
import std.stdio : File;

enum LOG_TIMING = false;

__gshared File logFile;

/*
void setLogFile(File logFile)
{
    .logFile = logFile;
}
*/
void setLogFile(string filename)
{
    logFile = File(filename, "w");
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
