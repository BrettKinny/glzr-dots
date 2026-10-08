/// <reference path="../types/fresh.d.ts" />
/// <reference path="../types/plugins.d.ts" />

// Was %APPDATA%\fresh\init.ts. Lives in glzr-dots as a user plugin because init.ts is a
// single file at a fixed path (no junction possible); %APPDATA%\fresh\plugins is a junction here.

// ─────────────────────────────────────────────────────────────────────
//  Windows disk section for the Fresh dashboard.
//
//  The bundled dashboard's built-in "disk" section shells out to the
//  Unix `df` binary. On Windows `df` isn't on the PATH Fresh inherits
//  (Git for Windows ships it in ...\Git\usr\bin, which isn't on PATH),
//  so the section renders "df failed". We drop that section and re-add
//  one backed by `Get-CimInstance Win32_LogicalDisk`, which is always
//  present on Windows.
//
//  Uses only the public, documented extension API — no editing of
//  bundled plugin files:
//    editor.on("plugins_loaded", ...)   -> run after plugins export
//    editor.getPluginApi("dashboard")   -> DashboardApi
//    dash.removeSection / registerSection
// ─────────────────────────────────────────────────────────────────────

const editor = getEditor();

// Left-pad a label to a fixed width (drive letters are ASCII, so a
// simple length check is enough — no wide-char handling needed).
function pad(s: string, width: number): string {
    return s.length >= width ? s : s + " ".repeat(width - s.length);
}

// Match the built-in disk bar: `width` cells, ━ filled / ╌ empty.
function bar(pct: number, width: number): string {
    const filled = Math.max(0, Math.min(width, Math.round((pct / 100) * width)));
    return "━".repeat(filled) + "╌".repeat(width - filled);
}

// 1024-based human size, mirroring `df -h` suffixes (G / T).
function human(bytes: number): string {
    const gib = bytes / 1024 ** 3;
    if (gib >= 1024) return (gib / 1024).toFixed(1) + "T";
    if (gib >= 100) return String(Math.round(gib)) + "G";
    if (gib >= 10) return gib.toFixed(0) + "G";
    return gib.toFixed(1) + "G";
}

// Run a process with a timeout, mirroring the dashboard's own `run`
// helper. Returns trimmed stdout/stderr plus an ok flag.
async function run(cmd: string, args: string[], timeoutMs: number) {
    const handle = editor.spawnProcess(cmd, args, "");
    const timedOut = await Promise.race([
        handle.result.then(() => false),
        editor.delay(timeoutMs).then(() => true),
    ]);
    if (timedOut) {
        await handle.kill();
        return { stdout: "", stderr: "timed out", ok: false };
    }
    const r = await handle.result;
    return { stdout: r.stdout ?? "", stderr: r.stderr ?? "", ok: r.exit_code === 0 };
}

// One line per fixed drive (DriveType=3): "C:|<sizeBytes>|<freeBytes>".
const PS_DISK =
    "Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | " +
    "ForEach-Object { '{0}|{1}|{2}' -f $_.DeviceID,$_.Size,$_.FreeSpace }";

// Swap the df-backed "disk" section for a Windows-native one once the
// bundled dashboard plugin has exported its API.
editor.on("plugins_loaded", () => {
    const dash = editor.getPluginApi("dashboard");
    if (!dash) return; // dashboard plugin disabled — nothing to patch

    dash.removeSection("disk"); // drop the df-backed built-in

    dash.registerSection("disk", async (ctx) => {
        const { stdout, ok, stderr } = await run(
            "powershell",
            ["-NoProfile", "-NonInteractive", "-Command", PS_DISK],
            3000,
        );
        if (!ok) {
            ctx.error(`disk query failed${stderr ? " — " + stderr.slice(0, 40) : ""}`);
            return;
        }
        let drawn = 0;
        for (const line of stdout.split(/\r?\n/)) {
            const [dev, sizeStr, freeStr] = line.split("|");
            const size = Number(sizeStr);
            const free = Number(freeStr);
            if (!dev || !size || isNaN(size) || isNaN(free)) continue;
            const used = size - free;
            const pct = Math.round((used / size) * 100);
            const color = pct >= 90 ? "err" : pct >= 75 ? "warn" : "ok";
            ctx.text("    " + pad(dev, 10), { color: "muted" });
            ctx.text(bar(pct, 18), { color, bold: true });
            ctx.text("  " + String(pct).padStart(3) + "%", { color });
            ctx.text(`   ${human(used)} / ${human(size)}`, { color: "muted" });
            ctx.newline();
            drawn++;
        }
        if (drawn === 0) ctx.error("no fixed drives found");
    });
});

// freshpr (~/.glzr/powershell/freshpr.ps1) sets FRESHPR_RANGE → open the PR diff straight away.
// "review-range" is audit_mode's prompt type, so confirming it runs Review Diff: Range.
// Delay lets the dashboard open and fill its sections (git, disk) before the review takes over;
// dashboard has no "loaded" signal to wait on.
const freshprRange = editor.getEnv("FRESHPR_RANGE");
if (freshprRange) {
    registerHandler("freshprStartReview", async () => {
        try {
            await editor.delay(1500);
            editor.startPromptWithInitial("Review range (A..B or commit):", "review-range", freshprRange);
            editor.executeAction("prompt_confirm");
        } catch (e) {
            editor.setStatus(`freshpr: ${e}`);
        }
    });
    editor.on("ready", "freshprStartReview");
}
