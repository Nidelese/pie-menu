; PieMenu.ahk — pink princess pie launcher, Windows edition
;
; Hold Win, tap Tab → pie appears at the cursor. Move onto a slice,
; release Win (or left-click) to launch. Esc cancels.
; Needs AutoHotkey v2 (https://www.autohotkey.com). While this script is
; running, Win+Tab no longer opens Task View.

#Requires AutoHotkey v2.0
#SingleInstance Force
CoordMode "Mouse", "Screen"

; ══ Apps (clockwise from North) — edit run paths to match this machine ══════
Apps := [
    {name: "Firefox",  run: "firefox.exe"},
    {name: "Obsidian", run: EnvGet("LOCALAPPDATA") "\Obsidian\Obsidian.exe"},
    {name: "Krita",    run: "C:\Program Files\Krita (x64)\bin\krita.exe"},
    {name: "Audacity", run: "C:\Program Files\Audacity\Audacity.exe"},
    {name: "Steam",    run: "steam://open/main"},
    {name: "OBS",      run: "C:\Program Files\obs-studio\bin\64bit\obs64.exe", dir: "C:\Program Files\obs-studio\bin\64bit"},
    {name: "Kdenlive", run: "C:\Program Files\kdenlive\bin\kdenlive.exe"},
    {name: "LMMS",     run: "C:\Program Files\LMMS\lmms.exe"},
]

; ══ Geometry ════════════════════════════════════════════════════════════════
R_INNER := 55
R_OUTER := 190
R_TEXT  := 132
GAP_DEG := 1.43              ; gap between slice edges (≈0.025 rad)

; ══ Palette (pink princess), 0xAARRGGBB ═════════════════════════════════════
COL_OVERLAY    := 0x281E1020   ; whole-monitor dim (also makes the window clickable everywhere)
COL_VIGNETTE   := 0x4A1E1020   ; darker halo behind the pie
COL_SLICE      := 0xE02E1830
COL_SLICE_HOV  := 0xF2F4A7C3
COL_BORDER     := 0x73F4A7C3
COL_BORDER_HOV := 0xE6F4A7C3
COL_INNER      := 0xF21E1020
COL_TEXT       := 0xFFFDE8F0
COL_TEXT_HOV   := 0xFF1E1020
FONT_CANDIDATES := ["JetBrainsMono Nerd Font", "JetBrains Mono", "Segoe UI"]

; ══ Optional config: pie-menu.ini next to this script ═══════════════════════
; [apps] name = command (clockwise from North, any count) · [colors] #RRGGBB
; or #RRGGBBAA · [menu] radii/gap/font. Missing file/keys keep the defaults.
IniPath := A_ScriptDir "\pie-menu.ini"
if FileExist(IniPath) {
    appSection := IniRead(IniPath, "apps", , "")
    if (appSection != "") {
        parsed := []
        for line in StrSplit(appSection, "`n", "`r") {
            eq := InStr(line, "=")
            if !eq
                continue
            nm := Trim(SubStr(line, 1, eq - 1))
            cmd := ExpandEnv(Trim(SubStr(line, eq + 1)))
            if (nm = "" || cmd = "")
                continue
            entry := {name: nm, run: cmd}
            ; full path to a real file → launch from its own folder
            ; (OBS and friends refuse to start from elsewhere)
            if (SubStr(cmd, 2, 1) = ":" && FileExist(cmd)) {
                SplitPath cmd, , &cmdDir
                entry.dir := cmdDir
            }
            parsed.Push(entry)
        }
        if parsed.Length
            Apps := parsed
    }
    COL_OVERLAY    := IniColor(IniPath, "overlay", COL_OVERLAY)
    COL_VIGNETTE   := IniColor(IniPath, "vignette", COL_VIGNETTE)
    COL_SLICE      := IniColor(IniPath, "slice", COL_SLICE)
    COL_SLICE_HOV  := IniColor(IniPath, "slice_hover", COL_SLICE_HOV)
    COL_BORDER     := IniColor(IniPath, "border", COL_BORDER)
    COL_BORDER_HOV := IniColor(IniPath, "border_hover", COL_BORDER_HOV)
    COL_INNER      := IniColor(IniPath, "center", COL_INNER)
    COL_TEXT       := IniColor(IniPath, "text", COL_TEXT)
    COL_TEXT_HOV   := IniColor(IniPath, "text_hover", COL_TEXT_HOV)
    R_INNER := Integer(IniRead(IniPath, "menu", "inner_radius", R_INNER))
    R_OUTER := Integer(IniRead(IniPath, "menu", "outer_radius", R_OUTER))
    R_TEXT  := Integer(IniRead(IniPath, "menu", "text_radius", R_TEXT))
    GAP_DEG := Number(IniRead(IniPath, "menu", "gap_degrees", GAP_DEG))
    fontPref := Trim(IniRead(IniPath, "menu", "font", ""))
    if (fontPref != "")
        FONT_CANDIDATES.InsertAt(1, fontPref)
}
SLICE_DEG := 360 / Apps.Length

; ══ GDI+ startup ════════════════════════════════════════════════════════════
GdipToken := 0
_si := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
NumPut("UInt", 1, _si)
DllCall("gdiplus\GdiplusStartup", "Ptr*", &GdipToken, "Ptr", _si, "Ptr", 0)
OnExit (*) => DllCall("gdiplus\GdiplusShutdown", "Ptr", GdipToken)

FontFam := 0
for _f in FONT_CANDIDATES {
    _ff := 0
    if !DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", _f, "Ptr", 0, "Ptr*", &_ff) && _ff {
        FontFam := _ff
        break
    }
}

; ══ State ═══════════════════════════════════════════════════════════════════
MenuOn := false
Hovered := -1
WinX := 0, WinY := 0, WinW := 0, WinH := 0
Cx := 0, Cy := 0
PieGui := 0
hdcMem := 0, hBmp := 0, oldBmp := 0, pG := 0

; ══ Hotkeys ═════════════════════════════════════════════════════════════════
#Tab:: ShowMenu()

#HotIf MenuOn
*Esc:: CloseMenu()
*LButton:: {
    ; swallow the press so it never reaches whatever is under the overlay
}
*LButton up:: Launch()
#HotIf

; ══ Menu lifecycle ══════════════════════════════════════════════════════════
ShowMenu() {
    global MenuOn, Hovered, WinX, WinY, WinW, WinH, Cx, Cy
    global PieGui, hdcMem, hBmp, oldBmp, pG
    if MenuOn
        return

    MouseGetPos &sx, &sy
    ; monitor under the cursor
    WinX := 0, WinY := 0, WinW := A_ScreenWidth, WinH := A_ScreenHeight
    loop MonitorGetCount() {
        MonitorGet A_Index, &ml, &mt, &mr, &mb
        if (sx >= ml && sx < mr && sy >= mt && sy < mb) {
            WinX := ml, WinY := mt, WinW := mr - ml, WinH := mb - mt
            break
        }
    }
    Cx := sx - WinX, Cy := sy - WinY

    ; borderless, layered, always-on-top, never activated
    PieGui := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale +E0x80000 +E0x08000000")
    PieGui.Show("NA x" WinX " y" WinY " w" WinW " h" WinH)

    ; 32-bit back buffer for UpdateLayeredWindow
    hdcScreen := DllCall("GetDC", "Ptr", 0, "Ptr")
    hdcMem := DllCall("CreateCompatibleDC", "Ptr", hdcScreen, "Ptr")
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcScreen)
    bi := Buffer(40, 0)
    NumPut("UInt", 40, bi, 0), NumPut("Int", WinW, bi, 4), NumPut("Int", -WinH, bi, 8)
    NumPut("UShort", 1, bi, 12), NumPut("UShort", 32, bi, 14)
    bits := 0
    hBmp := DllCall("CreateDIBSection", "Ptr", hdcMem, "Ptr", bi, "UInt", 0, "Ptr*", &bits, "Ptr", 0, "UInt", 0, "Ptr")
    oldBmp := DllCall("SelectObject", "Ptr", hdcMem, "Ptr", hBmp, "Ptr")
    pG := 0
    DllCall("gdiplus\GdipCreateFromHDC", "Ptr", hdcMem, "Ptr*", &pG)
    DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pG, "Int", 4)      ; AntiAlias
    DllCall("gdiplus\GdipSetTextRenderingHint", "Ptr", pG, "Int", 4)  ; AntiAlias

    MenuOn := true
    Hovered := -1
    Redraw()
    SetTimer Poll, 15
}

Poll() {
    global Hovered
    if !MenuOn
        return
    MouseGetPos &sx, &sy
    dx := sx - (WinX + Cx), dy := sy - (WinY + Cy)
    h := -1
    if (Sqrt(dx * dx + dy * dy) >= R_INNER) {
        ; angle with North = 0, clockwise; shift by half a slice so
        ; hit boundaries fall on slice edges, not centers
        a := Mod(Atan2Deg(dy, dx) + 90 + SLICE_DEG / 2 + 360, 360)
        h := Mod(Floor(a / SLICE_DEG), Apps.Length)
    }
    if (h != Hovered) {
        Hovered := h
        Redraw()
    }
    if (!GetKeyState("LWin", "P") && !GetKeyState("RWin", "P"))
        Launch()
}

Launch() {
    global
    if !MenuOn
        return
    idx := Hovered
    CloseMenu()
    if (idx >= 0) {
        app := Apps[idx + 1]
        try Run(app.run, app.HasProp("dir") ? app.dir : "")
        catch
            TrayTip("Couldn't launch " app.name " — edit its path at the top of PieMenu.ahk", "Pie Menu")
    }
}

CloseMenu() {
    global MenuOn, PieGui, hdcMem, hBmp, oldBmp, pG
    if !MenuOn
        return
    MenuOn := false
    SetTimer Poll, 0
    DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pG)
    DllCall("SelectObject", "Ptr", hdcMem, "Ptr", oldBmp)
    DllCall("DeleteObject", "Ptr", hBmp)
    DllCall("DeleteDC", "Ptr", hdcMem)
    PieGui.Destroy()
    PieGui := 0
}

; ══ Drawing ═════════════════════════════════════════════════════════════════
Redraw() {
    DllCall("gdiplus\GdipGraphicsClear", "Ptr", pG, "UInt", COL_OVERLAY)

    ; vignette behind the pie
    b := NewBrush(COL_VIGNETTE)
    rv := R_OUTER + 30
    DllCall("gdiplus\GdipFillEllipse", "Ptr", pG, "Ptr", b, "Float", Cx - rv, "Float", Cy - rv, "Float", rv * 2, "Float", rv * 2)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", b)

    loop Apps.Length {
        i := A_Index - 1
        hov := (i = Hovered)
        centerDeg := -90 + i * SLICE_DEG
        startDeg := centerDeg - SLICE_DEG / 2 + GAP_DEG
        sweepDeg := SLICE_DEG - 2 * GAP_DEG

        b := NewBrush(hov ? COL_SLICE_HOV : COL_SLICE)
        DllCall("gdiplus\GdipFillPie", "Ptr", pG, "Ptr", b, "Float", Cx - R_OUTER, "Float", Cy - R_OUTER
            , "Float", R_OUTER * 2, "Float", R_OUTER * 2, "Float", startDeg, "Float", sweepDeg)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", b)

        p := NewPen(hov ? COL_BORDER_HOV : COL_BORDER, 1.5)
        DllCall("gdiplus\GdipDrawPie", "Ptr", pG, "Ptr", p, "Float", Cx - R_OUTER, "Float", Cy - R_OUTER
            , "Float", R_OUTER * 2, "Float", R_OUTER * 2, "Float", startDeg, "Float", sweepDeg)
        DllCall("gdiplus\GdipDeletePen", "Ptr", p)

        rad := centerDeg * 0.017453292519943295
        DrawLabel(Apps[i + 1].name, Cx + R_TEXT * Cos(rad), Cy + R_TEXT * Sin(rad)
            , hov ? 14 : 12, hov, hov ? COL_TEXT_HOV : COL_TEXT)
    }

    ; inner circle
    b := NewBrush(COL_INNER)
    DllCall("gdiplus\GdipFillEllipse", "Ptr", pG, "Ptr", b, "Float", Cx - R_INNER, "Float", Cy - R_INNER, "Float", R_INNER * 2, "Float", R_INNER * 2)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", b)
    p := NewPen(COL_BORDER_HOV, 2)
    DllCall("gdiplus\GdipDrawEllipse", "Ptr", pG, "Ptr", p, "Float", Cx - R_INNER, "Float", Cy - R_INNER, "Float", R_INNER * 2, "Float", R_INNER * 2)
    DllCall("gdiplus\GdipDeletePen", "Ptr", p)

    DrawLabel(Hovered >= 0 ? Apps[Hovered + 1].name : "✦", Cx, Cy, 11, false, COL_TEXT)

    ; push the frame to screen
    pt := Buffer(8), sz := Buffer(8), src := Buffer(8, 0), bf := Buffer(4, 0)
    NumPut("Int", WinX, pt, 0), NumPut("Int", WinY, pt, 4)
    NumPut("Int", WinW, sz, 0), NumPut("Int", WinH, sz, 4)
    NumPut("UChar", 255, bf, 2), NumPut("UChar", 1, bf, 3)  ; alpha 255, AC_SRC_ALPHA
    DllCall("UpdateLayeredWindow", "Ptr", PieGui.Hwnd, "Ptr", 0, "Ptr", pt, "Ptr", sz
        , "Ptr", hdcMem, "Ptr", src, "UInt", 0, "Ptr", bf, "UInt", 2)
}

DrawLabel(text, x, y, size, bold, argb) {
    font := 0, fmt := 0
    DllCall("gdiplus\GdipCreateFont", "Ptr", FontFam, "Float", size, "Int", bold ? 1 : 0, "Int", 2, "Ptr*", &font)
    DllCall("gdiplus\GdipCreateStringFormat", "Int", 0, "Int", 0, "Ptr*", &fmt)
    DllCall("gdiplus\GdipSetStringFormatAlign", "Ptr", fmt, "Int", 1)      ; center
    DllCall("gdiplus\GdipSetStringFormatLineAlign", "Ptr", fmt, "Int", 1)  ; middle
    br := NewBrush(argb)
    rect := Buffer(16)
    NumPut("Float", x - 90, rect, 0), NumPut("Float", y - 20, rect, 4)
    NumPut("Float", 180, rect, 8), NumPut("Float", 40, rect, 12)
    DllCall("gdiplus\GdipDrawString", "Ptr", pG, "WStr", text, "Int", -1, "Ptr", font, "Ptr", rect, "Ptr", fmt, "Ptr", br)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", br)
    DllCall("gdiplus\GdipDeleteStringFormat", "Ptr", fmt)
    DllCall("gdiplus\GdipDeleteFont", "Ptr", font)
}

; ══ Small helpers ═══════════════════════════════════════════════════════════
NewBrush(argb) {
    b := 0
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", argb, "Ptr*", &b)
    return b
}

NewPen(argb, width) {
    p := 0
    DllCall("gdiplus\GdipCreatePen1", "UInt", argb, "Float", width, "Int", 2, "Ptr*", &p)
    return p
}

Atan2Deg(y, x) {
    if (x = 0 && y = 0)
        return 0
    return DllCall("msvcrt\atan2", "Double", y, "Double", x, "Cdecl Double") * 57.29577951308232
}

IniColor(path, key, fallback) {
    v := StrReplace(Trim(IniRead(path, "colors", key, "")), "#")
    if !RegExMatch(v, "i)^[0-9a-f]{6}([0-9a-f]{2})?$")
        return fallback
    rgb := Integer("0x" SubStr(v, 1, 6))
    a := StrLen(v) = 8 ? Integer("0x" SubStr(v, 7, 2)) : (fallback >> 24) & 0xFF
    return (a << 24) | rgb
}

ExpandEnv(s) {
    if !InStr(s, "%")
        return s
    buf := Buffer(4096)
    DllCall("ExpandEnvironmentStringsW", "WStr", s, "Ptr", buf, "UInt", 2048)
    return StrGet(buf)
}
