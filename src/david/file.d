module david.file;

auto exeRelativePath(T)(T path)
{
    import std.path : isAbsolute, buildPath, dirName;
    import std.file : thisExePath;
    if (isAbsolute(path))
        return path;
    return buildPath(dirName(thisExePath), path);
}
