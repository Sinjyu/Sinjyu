// Virtual-clock replica of OpenRA.Game/Game.cs Loop() (release-20231010, unchanged up to bleed 2026-10).
// Only the timing skeleton is kept; LogicTick/RenderTick are replaced by fixed CPU costs, and
// RenderTick with VSync blocks until the next vblank like SwapBuffers does.
using System;

static class Sim
{
	static double now;
	static long RunTime => (long)now;

	static void Main(string[] a)
	{
		bool patched = a[0] == "patched";
		int timestep = int.Parse(a[1]);      // game speed: fastest=20ms
		double tickMs = double.Parse(a[2]);  // cost of one LogicTick
		double renderMs = double.Parse(a[3]);// cost of one RenderTick (CPU+GPU)
		double hz = double.Parse(a[4]);      // display refresh, 0 = VSync off
		var (ticks, frames) = Run(patched, timestep, tickMs, renderMs, hz, 60_000);
		var tps = ticks / 60.0; var target = 1000.0 / timestep;
		Console.WriteLine($"{(patched ? "patched " : "original")} step={timestep}ms tick={tickMs}ms render={renderMs}ms vsync={(hz > 0 ? hz + "Hz" : "off")} -> {tps:F1} ticks/s of {target:F0} ({100 * tps / target:F0}%), {frames / 60.0:F1} fps");
	}

	static (int, int) Run(bool patched, int logicInterval, double tickMs, double renderMs, double hz, double duration)
	{
		const int MaxLogicTicksBehind = 250, MinReplayFps = 10;
		const int MinGameplayFps = 30; // patch: only force a render if none happened for 1000/30 ms
		int ticks = 0, frames = 0;
		var nextLogic = RunTime; var nextRender = RunTime; var forcedNextRender = RunTime;
		var renderBeforeNextTick = false; long lastRender = long.MinValue / 2;
		var renderInterval = 1000 / 1000; // CapFramerate=false (default)
		while (now < duration)
		{
			var t = RunTime;
			if (t - nextLogic > MaxLogicTicksBehind) nextLogic = t;
			var nextUpdate = Math.Min(nextLogic, nextRender);
			if (t >= nextUpdate)
			{
				var forceRender = renderBeforeNextTick || t >= forcedNextRender;
				if (t >= nextLogic && !renderBeforeNextTick)
				{
					nextLogic += logicInterval;
					now += tickMs; ticks++;                                   // LogicTick()
					if (!patched || RunTime - lastRender >= 1000 / MinGameplayFps)
						renderBeforeNextTick = true;                          // "Force at least one render per tick"
				}
				var haveSomeTimeUntilNextLogic = t < nextLogic;
				var isTimeToRender = t >= nextRender;
				if ((isTimeToRender && haveSomeTimeUntilNextLogic) || forceRender)
				{
					nextRender = t + renderInterval;
					forcedNextRender = t + Math.Max(1000 / MinReplayFps, renderInterval);
					now += renderMs;                                          // RenderTick()
					if (hz > 0) { var v = 1000 / hz; now = Math.Ceiling(now / v - 1e-9) * v; } // SwapBuffers waits for vblank
					frames++; lastRender = RunTime;
					renderBeforeNextTick = false;
				}
			}
			else now = nextUpdate;                                            // Thread.Sleep
		}
		return (ticks, frames);
	}
}
