// 诊断：心灵控制器（Psychic Dominator）放了没反应。
// 读你自己的 ra2md.mix 里的 rulesmd.ini，打印移植版 PsychicDominatorEffect.ts 用到的设置。
//
//   bun ~/Sinjyu/ra2-mac/tools/diag-dominator.ts ~/Games/RA2 [~/ra2-mac-port]
//
// 只读，不改任何文件。用的是移植工程自己的 MIX/INI 解析代码。
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";

const retail = process.argv[2];
const port = process.argv[3] ?? join(process.env.HOME ?? "", "ra2-mac-port");
if (!retail) {
    console.error("用法: bun diag-dominator.ts <游戏文件夹> [移植工程目录]");
    process.exit(1);
}
const src = join(port, "redalert2", "src");
const { MixFile } = await import(join(src, "data", "MixFile"));
const { IniFile } = await import(join(src, "data", "IniFile"));
const { VirtualFile } = await import(join(src, "data", "vfs", "VirtualFile"));

function findCaseInsensitive(dir: string, name: string): string | undefined {
    const hit = readdirSync(dir).find((f) => f.toLowerCase() === name.toLowerCase());
    return hit ? join(dir, hit) : undefined;
}
// 工程的 MIX 解析会打印大量 [Our] Entry 调试行，解析期间先静音
function quiet<T>(fn: () => T): T {
    const log = console.log;
    console.log = () => {};
    try { return fn(); } finally { console.log = log; }
}
function openMixBytes(bytes: Uint8Array, label: string) {
    return quiet(() => new MixFile(VirtualFile.fromBytes(bytes, label).stream as any));
}
function entryBytes(mix: any, name: string): Uint8Array | undefined {
    if (!mix.containsFile(name)) return undefined;
    const s = mix.openFile(name).stream as any;
    return new Uint8Array(s.buffer, s.byteOffset, s.byteLength);
}

const ra2md = findCaseInsensitive(retail, "ra2md.mix");
if (!ra2md) {
    console.error(`在 ${retail} 里没找到 ra2md.mix`);
    process.exit(1);
}
const outer = openMixBytes(new Uint8Array(readFileSync(ra2md)), "ra2md.mix");
let rulesBytes = entryBytes(outer, "rulesmd.ini");
let where = "ra2md.mix";
if (!rulesBytes) {
    const local = entryBytes(outer, "localmd.mix");
    if (local) {
        rulesBytes = entryBytes(openMixBytes(local, "localmd.mix"), "rulesmd.ini");
        where = "ra2md.mix → localmd.mix";
    }
}
const override = existsSync(join(retail, "rulesmd.ini")) ? join(retail, "rulesmd.ini") : undefined;
if (override) console.log(`注意：游戏文件夹里另有一个 rulesmd.ini（${override}），这里只检查 MIX 里的那份`);
if (!rulesBytes) {
    console.error("在 ra2md.mix 里没找到 rulesmd.ini（也没找到 localmd.mix）");
    process.exit(1);
}
console.log(`rulesmd.ini 来自 ${where}，${rulesBytes.byteLength} 字节\n`);

const ini = quiet(() => new IniFile(VirtualFile.fromBytes(rulesBytes!, "rulesmd.ini")));
const general = ini.getSection("General");

console.log("[General] 里所有含 Dominator 的键（移植版只读 DominatorWarhead / DominatorDamage / DominatorCaptureRange）：");
let any = false;
for (const [k, v] of general?.entries ?? []) {
    if (/dominator/i.test(k)) { console.log(`  ${k}=${v}`); any = true; }
}
if (!any) console.log("  （一个都没有）→ 移植版会用默认值：范围 1 格、伤害 1000、弹头 DominatorWH");

const wh = general?.getString("DominatorWarhead") || "DominatorWH";
console.log(`\n爆炸弹头 "${wh}" 在规则里${ini.getSection(wh) ? "存在" : "【不存在】→ 爆炸会被跳过"}`);
console.log(`实际夺取范围：${general?.has("DominatorCaptureRange") ? general.getNumber("DominatorCaptureRange") : "1（默认值）"} 格`);

console.log("\n超级武器里 Type=PsychicDominator 的那一段：");
for (const name of ini.getSection("SuperWeaponTypes")?.entries.values() ?? []) {
    const sec = ini.getSection(String(name));
    if (sec && /psychicdominator/i.test(sec.getString("Type") ?? "")) {
        console.log(`  [${name}]`);
        for (const [k, v] of sec.entries) console.log(`    ${k}=${v}`);
    }
}
