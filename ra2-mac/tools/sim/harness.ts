// Virtual-clock harness: drives the engine's real GameAnimationLoop with a
// simulated display (rAF at refreshHz) and simulated CPU cost per tick/render.
// Run via ./run.sh — args: <loop.ts> <refreshHz> <tickCostMs> <renderCostMs> [budgetMs|none]
const file = process.argv[2];
const refreshHz = Number(process.argv[3]);
const tickCostMs = Number(process.argv[4]);
const renderCostMs = Number(process.argv[5]);
const budget = process.argv[6] === 'none' ? undefined : Number(process.argv[6] ?? 8);
const targetTps = 60; // speed 6 ("fastest") = 60 ticks/s in GameSpeed.ts
let now = 0;
(globalThis as any).performance = { now: () => now };
(globalThis as any).document = { hidden: false, addEventListener() {}, removeEventListener() {} };
let pending: ((t: number) => void) | undefined;
(globalThis as any).requestAnimationFrame = (cb: any) => { pending = cb; return 1; };
(globalThis as any).cancelAnimationFrame = () => { pending = undefined; };
const { GameAnimationLoop } = await import(file);
let ticks = 0;
const turnMgr = {
  getTurnMillis: () => 1000 / targetTps,
  doGameTurn: () => { ticks++; now += tickCostMs; return true; },
  setErrorState() {},
};
const renderer = { getStats: () => null, update() {}, render() { now += renderCostMs; }, flush() {} };
const loop = new GameAnimationLoop({ isObserver: false }, renderer, { audioSystem: { setMuted() {} } } as any, turnMgr,
  { skipFrames: true, skipBudgetMillis: budget, frameLimit: { value: 0 } });
loop.start();
const vsync = 1000 / refreshHz, duration = 60_000;
let frames = 0;
while (now < duration && pending) {
  now = Math.ceil((now + 1e-9) / vsync) * vsync; // wait for next vblank
  const cb = pending; pending = undefined; frames++; cb(now);
}
console.log(`${refreshHz}Hz tick=${tickCostMs}ms render=${renderCostMs}ms budget=${budget ?? 'none'} -> ${(ticks / (now / 1000)).toFixed(1)} ticks/s (target ${targetTps}), ${(frames / (now / 1000)).toFixed(1)} fps, speed ${(100 * ticks / (now / 1000) / targetTps).toFixed(0)}%`);
