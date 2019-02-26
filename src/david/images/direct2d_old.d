module david.images.direct2d_old;

import core.sys.windows.windows;

import mar.c : cstring;

import david.types : CString;
import david.windowing : Window;

struct Image
{
    void cleanup()
    {
        assert(0, "not implemented");
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
        return Image();
    }
}
