module david.platform;

version (Windows)
{
    import core.sys.windows.windows : HINSTANCE;
    __gshared HINSTANCE winMainInstance;
    __gshared int winMainCmdShow;
    void platformInit(HINSTANCE instance, int cmdShow)
    {
        import david.log;

        winMainInstance = instance;
        winMainCmdShow = cmdShow;
        logf("cmdShow is %s (%s)", cmdShow, cmdShowName(cmdShow));
    }
    private string cmdShowName(int cmdShow)
    {
        switch(cmdShow)
        {
            case 0: return "SW_HIDE";
            case 1: return "SW_SHOWNORMAL";
            case 2: return "SW_SHOWMINIMIZED";
            case 3: return "SW_SHOWMAXIMIZED";
            case 4: return "SW_SHOWNOACTIVATE";
            case 5: return "SW_SHOW";
            case 6: return "SW_MINIMIZE";
            case 7: return "SW_SHOWMINNOACTIVE";
            case 8: return "SW_SHOWNA";
            case 9: return "SW_RESTORE";
            case 10: return "SW_SHOWDEFAULT";
            case 11: return "SW_FORCEMINIMIZE";
            default: return "SW_UNKNOWN";
        }
    }
}
else
{
    void platformInit()
    {
    }
}