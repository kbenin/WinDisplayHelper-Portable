#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon
DetectHiddenWindows(true)

; 1. Prompt user to pick target .exe, auto-mute option, and custom Show hotkey
SetupResult := PromptForTargetExe()
if (SetupResult.Exe = "")
    ExitApp()

TargetExe := SetupResult.Exe
AutoMuteEnabled := SetupResult.AutoMute
ShowHotkey := SetupResult.ShowKey
HasBeenFocused := true
IsManuallyMuted := false

; Register the chosen Show/Restore hotkey dynamically (default: Ctrl + Shift + \)
Hotkey(ShowHotkey, BringTargetToFront)

HookProc := CallbackCreate(OnFocusChanged, "F", 7)
hHook := DllCall("SetWinEventHook", "UInt", 0x0003, "UInt", 0x0003, "Ptr", 0, "Ptr", HookProc, "UInt", 0, "UInt", 0, "UInt", 0, "Ptr")

; Watch every 1.5s to auto-exit cleanly if the target game/app is closed
SetTimer(WatchTargetAlive, 1500)

; Guaranteed cleanup on ANY exit (hotkey, target app closing, or Windows shutdown)
OnExit(CleanupOnExit)

; Immediately hide (and mute if enabled) the selected app on launch
CheckWindow()

; Dynamic Show/Restore Hotkey action
BringTargetToFront(*) {
    global IsManuallyMuted := false
    for hwnd in WinGetList("ahk_exe " TargetExe) {
        if IsRealWindow(hwnd) {
            RestoreWindow(hwnd, true)
            WinActivate("ahk_id " hwnd)
        }
    }
    SetAppMute(TargetExe, false)
}

; Ctrl + Shift + M : Toggle background audio mute/unmute without showing the window
^+m:: {
    global IsManuallyMuted
    IsManuallyMuted := !IsManuallyMuted
    SetAppMute(TargetExe, IsManuallyMuted)
    ToolTip((IsManuallyMuted ? "Muted: " : "Unmuted: ") TargetExe)
    SetTimer(() => ToolTip(), -1200)
}

; Ctrl + Shift + Backspace : Restore taskbar icon, unmute audio & exit safely
^+BS:: ExitApp()

WatchTargetAlive() {
    if !ProcessExist(TargetExe)
        ExitApp()
}

CleanupOnExit(ExitReason, ExitCode) {
    global hHook, HookProc, TargetExe
    SetTimer(WatchTargetAlive, 0)
    if IsSet(hHook) && hHook
        DllCall("UnhookWinEvent", "Ptr", hHook)
    if IsSet(HookProc) && HookProc
        CallbackFree(HookProc)

    if IsSet(TargetExe) && (TargetExe != "") {
        for hwnd in WinGetList("ahk_exe " TargetExe) {
            if IsRealWindow(hwnd)
                RestoreWindow(hwnd, false)
        }
        SetAppMute(TargetExe, false)
    }
    DllCall("ClipCursor", "Ptr", 0)
}

GetOpenExeList() {
    exeMap := Map()
    exeList := []

    if ProcessExist("RDR2.exe") {
        exeMap["rdr2.exe"] := true
        exeList.Push("RDR2.exe")
    }

    DetectHiddenWindows(false)
    for hwnd in WinGetList() {
        if IsRealWindow(hwnd) {
            name := ""
            try {
                name := WinGetProcessName("ahk_id " hwnd)
            } catch {
                try {
                    pid := WinGetPID("ahk_id " hwnd)
                    name := ProcessGetName(pid)
                }
            }
            lowerName := StrLower(name)
            if (name != "" && !exeMap.Has(lowerName) && lowerName != "explorer.exe" && lowerName != "autohotkey64.exe") {
                exeMap[lowerName] := true
                exeList.Push(name)
            }
        }
    }
    DetectHiddenWindows(true)

    if (exeList.Length = 0)
        exeList.Push("RDR2.exe")

    return exeList
}

PromptForTargetExe() {
    result := {Exe: "", AutoMute: true, ShowKey: "^+vkDC"}

    picker := Gui("+AlwaysOnTop -MinimizeBox", "Display Helper Setup")
    picker.SetFont("s10", "Segoe UI")
    picker.AddText("w340", "Select or type the target .exe:")
    
    cb := picker.AddComboBox("w255 Choose1", GetOpenExeList())
    btnRefresh := picker.AddButton("x+8 yp-1 w77", "Refresh")
    
    chkMute := picker.AddCheckbox("xm y+10 Checked", "Auto-mute app audio while hidden")

    ; Optional custom Show/Restore Hotkey selector
    picker.AddText("xm y+10", "Show/Restore Hotkey:")
    hkBox := picker.AddHotkey("x+10 yp-3 w185", "^+\")

    picker.SetFont("s8 c555555", "Segoe UI")
    guideText := (
        "INSTRUCTIONS:`n"
        "1. Run your target app first, or click Refresh to update the dropdown.`n"
        "2. Click Start — the app hides immediately & auto-exits when closed.`n`n"
        "SHORTCUT KEYS:`n"
        "• Show/Restore Hotkey (Default: Ctrl+Shift+\) : Bring app back`n"
        "• Ctrl + Shift + M : Toggle background audio mute/unmute`n"
        "• Ctrl + Shift + Backspace : Restore taskbar icon, unmute & exit"
    )
    picker.AddText("xm w340 y+10", guideText)
    
    picker.SetFont("s10 cDefault", "Segoe UI")
    btnStart := picker.AddButton("xm w165 y+14 Default", "Start")
    btnCancel := picker.AddButton("x+10 w165", "Cancel")

    btnRefresh.OnEvent("Click", (*) => RefreshDropdown(cb))
    btnStart.OnEvent("Click", (*) => ValidateAndStart(cb, chkMute, hkBox, picker, result))
    btnCancel.OnEvent("Click", (*) => (result.Exe := "", picker.Destroy()))
    picker.OnEvent("Close", (*) => (result.Exe := "", picker.Destroy()))

    picker.Show()
    WinWaitClose(picker)
    return result
}

ValidateAndStart(cb, chkMute, hkBox, picker, result) {
    input := Trim(cb.Text)
    if (input = "") {
        MsgBox("Please select or enter a target .exe name.", "Display Helper", "Icon!")
        return
    }
    if !RegExMatch(input, "i)\.exe$")
        input .= ".exe"

    if !ProcessExist(input) {
        MsgBox("'" input "' is not currently running.`n`nPlease launch the app first and click Refresh.", "Process Not Found", "Icon!")
        return
    }

    chosenKey := Trim(hkBox.Value)
    if (chosenKey = "" || chosenKey = "^+\") {
        chosenKey := "^+vkDC"
    }

    result.Exe := input
    result.AutoMute := (chkMute.Value = 1)
    result.ShowKey := chosenKey
    picker.Destroy()
}

RefreshDropdown(cb) {
    currentText := Trim(cb.Text)
    newList := GetOpenExeList()
    cb.Delete()
    cb.Add(newList)
    if (newList.Length > 0) {
        cb.Choose(1)
    } else if (currentText != "") {
        cb.Text := currentText
    }
}

OnFocusChanged(hWinEventHook, event, hwnd, idObject, idChild, idEventThread, dwmsEventTime) {
    CheckWindow()
}

CheckWindow() {
    global HasBeenFocused, AutoMuteEnabled, IsManuallyMuted
    if WinActive("ahk_exe " TargetExe) {
        HasBeenFocused := true
        IsManuallyMuted := false
        for hwnd in WinGetList("ahk_exe " TargetExe) {
            if IsRealWindow(hwnd)
                RestoreWindow(hwnd, true)
        }
        if AutoMuteEnabled
            SetAppMute(TargetExe, false)
    } else if HasBeenFocused {
        for hwnd in WinGetList("ahk_exe " TargetExe) {
            if IsRealWindow(hwnd)
                HideWindowInstantly(hwnd)
        }
        if AutoMuteEnabled || IsManuallyMuted
            SetAppMute(TargetExe, true)
    }
}

HideWindowInstantly(hwnd) {
    exStyle := WinGetExStyle("ahk_id " hwnd)
    if !(exStyle & 0x80) || (WinGetStyle("ahk_id " hwnd) & 0x10000000) {
        DllCall("ShowWindow", "Ptr", hwnd, "Int", 11)
        newStyle := (exStyle & ~0x40000) | 0x80
        DllCall("SetWindowLongPtr", "Ptr", hwnd, "Int", -20, "Ptr", newStyle)
        DllCall("ShowWindow", "Ptr", hwnd, "Int", 0)
    }
}

RestoreWindow(hwnd, activate := true) {
    exStyle := WinGetExStyle("ahk_id " hwnd)
    style := WinGetStyle("ahk_id " hwnd)
    if (exStyle & 0x80) || !(style & 0x10000000) {
        newStyle := (exStyle & ~0x80) | 0x40000
        DllCall("SetWindowLongPtr", "Ptr", hwnd, "Int", -20, "Ptr", newStyle)
        DllCall("ShowWindow", "Ptr", hwnd, "Int", activate ? 9 : 7)
    }
}

IsRealWindow(hwnd) {
    title := WinGetTitle("ahk_id " hwnd)
    class := WinGetClass("ahk_id " hwnd)
    if (title = "" || InStr(title, "IME") || InStr(class, "IME") || InStr(class, "MSCTFIME"))
        return false
    return true
}

; ==============================================================================
; Windows Core Audio Per-Process Mute Engine
; ==============================================================================
SetAppMute(exeName, muteState) {
    targetLower := StrLower(exeName)
    try {
        IMMDeviceEnumerator := ComObject("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
        ComCall(4, IMMDeviceEnumerator, "Int", 0, "Int", 1, "Ptr*", &pDevice := 0)
        if !pDevice
            return

        IID_IASM2 := Buffer(16)
        DllCall("ole32\CLSIDFromString", "WStr", "{77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F}", "Ptr", IID_IASM2)
        ComCall(3, pDevice, "Ptr", IID_IASM2, "UInt", 23, "Ptr", 0, "Ptr*", &pSessionMgr := 0)
        ObjRelease(pDevice)
        if !pSessionMgr
            return

        ComCall(5, pSessionMgr, "Ptr*", &pSessionEnum := 0)
        ObjRelease(pSessionMgr)
        if !pSessionEnum
            return

        ComCall(3, pSessionEnum, "Int*", &sessionCount := 0)

        Loop sessionCount {
            ComCall(4, pSessionEnum, "Int", A_Index - 1, "Ptr*", &pSessionCtrl := 0)
            if !pSessionCtrl
                continue

            try {
                pSessionCtrl2 := ComObjQuery(pSessionCtrl, "{BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D}")
                ComCall(14, pSessionCtrl2, "UInt*", &pid := 0)

                if (pid > 0) {
                    procName := ""
                    try procName := ProcessGetName(pid)
                    if (StrLower(procName) = targetLower) {
                        pSimpleVol := ComObjQuery(pSessionCtrl, "{87CE5498-68D6-44E5-9215-6DA47EF883D8}")
                        ComCall(5, pSimpleVol, "Int", muteState ? 1 : 0, "Ptr", 0)
                    }
                }
            }
            ObjRelease(pSessionCtrl)
        }
        ObjRelease(pSessionEnum)
    }
}
