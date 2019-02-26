module david.images.x11;

import david.types : CString;

struct Image
{
    void cleanup()
    {
        assert(0, "not implemented");
    }
}

struct ImageLoader
{
    void prepare(/*HWND windowHandle*/)
    {
    }
    void release()
    {
    }
    Image load(const(CString) filename)
    {
        return Image();
    }
}
