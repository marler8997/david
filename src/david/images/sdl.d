module david.images.sdl;

import derelict.sdl2.sdl :
    SDL_Surface,
    SDL_LoadBMP, SDL_FreeSurface;

import mar.c : cstring;

import david.types : CString;
import david.windowing : Window;
import david.sdl : enforceSdlCode, enforceSdlPtr;

struct Image
{
    private SDL_Surface* surface;
    auto getSdlSurface() inout { return surface; }
    void cleanup()
    {
        if (surface)
        {
            SDL_FreeSurface(surface);
            surface = null;
        }
    }
}

struct ImageLoader
{
    void prepare(Window window)
    {
    }
    void release()
    {
    }
    Image load(cstring filename)
    {
        Image image;
        image.surface = SDL_LoadBMP(filename.raw);
        enforceSdlPtr(image.surface, "SDL_LoadBmp(\"%s\")", filename);
        return image;
    }
}
