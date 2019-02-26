#!/usr/bin/env rund
//!debug
//!debugSymbols
module __none;

version (HaveLibraries) {} else
{
    //
    // This code bootstraps the build by making sure we have all the build libraries
    //
    import core.stdc.errno;
    import std.string, std.range, std.algorithm, std.path, std.file, std.stdio, std.process;
    auto relpath(string path) { return buildNormalizedPath(__FILE_FULL_PATH__.dirName, path); }
    int main(string[] args)
    {
        auto buildlib = relpath("../buildlib");
        if (!exists(buildlib))
        {
            writefln("Error: missing repo, clone it with: git clone https://github.com/dragon-lang/buildlib %s", buildlib);
            return 1;
        }
        auto newArgs = ["rund", "-version=HaveLibraries", "-I=" ~ buildlib, "-I=" ~ relpath("src"), relpath("build.d")]
            ~ args[1 .. $];
        writefln("%s", escapeShellCommand(newArgs));
        stdout.flush();
        version (Windows)
        {
            // Windows doesn't have exec, fall back to spawnProcess then wait
            // NOTE: I think windows may have a way to do exec, look into this more
            auto pid = spawnProcess(newArgs);
            return pid.wait();
        }
        else
        {
            auto newArgv = newArgs.map!toStringz.chain(null.only).array;
            execvp(newArgv[0], newArgv.ptr);
            // should never return
            writefln("Error: execv of '%s' failed (e=%s)", newArgs[0], errno);
            return 1;
        }
    }
}

version (HaveLibraries):

import std.typecons;
import std.array;
import std.string;
import std.path;
import std.stdio;

import build.path : shortRelpath;
import build.proc : which, run;
import build.git : setDefaultGitRepoDir;
import build.depends : Depends;

import david.build;
import david.backends;

void usage()
{
    writeln("Usage: build.d test");
    writeln("Usage: build.d editorSdl");
    writeln("Usage: build.d editorDavid <backend>");
    writefln("  backend    %s", formatBackends);
}

int main(string[] args)
{
    setDefaultGitRepoDir(shortRelpath(".."));
    davidLibrary.repo.overrideLocalPath(shortRelpath("."));

    args = args[1 .. $];
    {
        size_t newArgsLength = 0;
        scope(exit) args = args[0 .. newArgsLength];
        for (size_t i = 0; i < args.length; i++)
        {
            const arg = args[i];
            if (!arg.startsWith("-"))
            {
                args[newArgsLength++] = arg;
            }
            else
            {
                writefln("Error: unknown option '%s'", arg);
                return 1;
            }
        }
    }
    if (args.length == 0)
    {
        usage();
        return 1;
    }
    const command = args[0];
    args = args[1 .. $];

    if (command == "editorSdl")
        return editorSdl(args);
    if (command == "editorDavid")
        return editorDavid(args);
    if (command == "test")
        return test(args);

    writefln("Error: unknown command '%s'", command);
    return 1;
}



int buildEditor(string dir, DavidBackend backend)
{
    Depends depends;
    addDepends(&depends, backend);
    if (false)//updateRepos)
    {
        depends.updateRepos();
        return 0;
    }

    auto compile = appender!(string[])();
    compile.put(which("dmd"));
    compile.put("-od=" ~ shortRelpath(dir));
    compile.put("-of=" ~ shortRelpath(dir, dir));
    compile.put("-g");
    compile.put("-debug");
    depends.enforceExistsAddCompilerArgs(compile);
    addCompilerArgs(compile, backend);
    compile.put(shortRelpath(buildPath(dir, "app.d")));
    run(compile.data);
    return 0;
}


int editorSdl(string[] args)
{
   return buildEditor("editorSdl", DavidBackend.sdl);
}
int editorDavid(string[] args)
{
    if (args.length != 1)
    {
        writefln("Error: the editorDavid command requires 1 argument");
        return 1;
    }
    return buildEditor("editorDavid", parseBackend(args[0]));
}

int test(string[] args)
{
    if (args.length > 0)
    {
        writefln("Error: the 'test' command does not support any arguments");
        return 1;
    }

    writefln("Error: test not impl");
    return 1;
}
