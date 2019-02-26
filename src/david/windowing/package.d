module david.windowing;

version (Windows)
{
    version(Gdi)
        public import david.windowing.gdi;
    else version(Direct2D)
        public import david.windowing.direct2d;
    else version(Direct2DOld)
        public import david.windowing.direct2d_old;
    else version (Sdl)
        public import david.windowing.sdl;
    else static assert(0, "Windows requires version Gdi, Direct2D or Sdl");
}
else
{
    version (X11)
        public import david.windowing.x11;
    else version (Sdl)
        public import david.windowing.sdl;
    else static assert(0, "Posix requires version X11 or Sdl");
}
