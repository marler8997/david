module david.timing;

import more.time : TimeUnit;

import david.log;
import david.util : Ticks, DurationTicks;

static import app;

struct Timing
{
    /*package*/ DurationTicks minTicksPerFrame;
    static if(app.FixedFps == 0)
    {
        void setMinMillisPerFrame(uint minMillisPerFrame)
        {
            assert(0, "not implemented");
        }
        void setMaxFps(uint maxFps)
        {
            const ticksPerSecond = Ticks.per!(TimeUnit.seconds);
            if (LOG_TIMING) logf("ticks per second %s", ticksPerSecond);
            this.minTicksPerFrame = ticksPerSecond / maxFps;
            if (LOG_TIMING) logf("minTicksPerFrame = %s (about %s ms)", minTicksPerFrame, minTicksPerFrame.to!(TimeUnit.milliseconds));
        }
    }
}
