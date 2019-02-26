module david.images;

version (Windows)
{
    version(Gdi)
        public import david.images.gdi;
    else version(Direct2D)
        public import david.images.direct2d;
    else version(Direct2DOld)
        public import david.images.direct2d_old;
    else version(Sdl)
        public import david.images.sdl;
    else static assert(0, "Windows requires version Gdi, Direct2D or Sdl");
}
else
{
    version (X11)
        public import david.images.x11;
    else version (Sdl)
        public import david.images.sdl;
    else static assert(0, "Posix requires version X11 or Sdl");
}
