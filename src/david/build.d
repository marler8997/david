/**
Contains helper methods to build david programs.
*/
module david.build;

import std.typecons : Flag, Yes, No;
import std.path : dirName;

import build.path : shortRelpath;
import build.git : GitRepo;
import build.depends : Depends;
import build.depends.dlibs : DLibrary;
import david.backends;

__gshared auto marRepo            = GitRepo("github.com/dragon-lang/mar", "master");
__gshared auto moreRepo           = GitRepo("github.com/marler8997/mored", "master");
__gshared auto davidRepo          = GitRepo("github.com/marler8997/david", "master");
__gshared auto directxlibsRepo    = GitRepo("github.com/marler8997/directxlibs", "master");
__gshared auto directxAuroraRepo  = GitRepo("github.com/auroragraphics/directx", "master");
__gshared auto directxEvilratRepo = GitRepo("github.com/evilrat666/directx-d", "master");
__gshared auto derelictUtilRepo   = GitRepo("github.com/DerelictOrg/DerelictUtil", "master");
__gshared auto derelictSdlRepo    = GitRepo("github.com/DerelictOrg/DerelictSDL2", "master");

__gshared auto marLibrary            = DLibrary(&marRepo, "src", null);
__gshared auto moreLibrary           = DLibrary(&moreRepo, "", null);
__gshared auto davidLibrary          = DLibrary(&davidRepo, "src", [&marLibrary, &moreLibrary]);
__gshared auto directxAuroraLibrary  = DLibrary(&directxAuroraRepo, "source", null);
__gshared auto directxEvilratLibrary = DLibrary(&directxEvilratRepo, "src", null);
__gshared auto derelictUtilLibrary   = DLibrary(&derelictUtilRepo, "source", null);
__gshared auto derelictSdlLibrary    = DLibrary(&derelictSdlRepo, "source", [&derelictUtilLibrary]);

//__gshared auto directxlibsLibrary = BinaryRepo(&directxlibsRepo);

void addDepends(Depends* depends, const DavidBackend backend)
{
    depends.add(&davidLibrary);

    final switch(backend)
    {
    case DavidBackend.gdi:
        break;
    case DavidBackend.direct2dAurora:
        depends.add(&directxAuroraLibrary);
        depends.add(&directxlibsRepo);
        break;
    case DavidBackend.direct2dEvilrat:
        depends.add(&directxEvilratLibrary);
        depends.add(&directxlibsRepo);
        break;
    case DavidBackend.sdl:
        depends.add(&derelictSdlLibrary);
        break;
    }
}

private void addDirect2dArgs(Sink)(Sink sink, Flag!"coff" coff)
{
    sink.put("-version=Direct2D");
    directxlibsRepo.enforceExists();
    sink.put(shortRelpath(directxlibsRepo.localPath, coff ? "d2d1.coff.lib" : "d2d1.omf.lib"));
}

void addCompilerArgs(Sink)(Sink sink, const DavidBackend backend, Flag!"coff" coff = No.coff)
{
    import std.path : buildPath;

    sink.put("-i");
    sink.put(buildPath(davidLibrary.repo.localPath, "src", "david", "main.d"));
    version (Windows)
    {
        if (coff)
        {
             sink.put("-m32mscoff");
             // TODO: there is also -m64
        }
        sink.put(
            buildPath(davidLibrary.repo.localPath, "src", "windowsapp.def"),
        );
        sink.put("-version=ANSI");
    }
    final switch(backend)
    {
    case DavidBackend.gdi:
        sink.put("-version=Gdi");
        break;
    case DavidBackend.direct2dAurora:
        sink.put("-version=Direct2DAurora");
        addDirect2dArgs(sink, coff);
        break;
    case DavidBackend.direct2dEvilrat:
        sink.put("-version=Direct2DEvilrat");
        addDirect2dArgs(sink, coff);
        break;
    case DavidBackend.sdl:
        sink.put("-version=Sdl");
        break;
    }
}