#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook

; Shortcuts are not intercepted in elevated windows unless the script is elevated too.
; The /restart switch marks a relaunch, so a failed elevation does not loop.
if not (A_IsAdmin or InStr(DllCall("GetCommandLine", "Str"), " /restart")) {
    relaunch := A_IsCompiled ? '"' A_ScriptFullPath '" /restart' : '"' A_AhkPath '" /restart "' A_ScriptFullPath '"'
    try
        Run("*RunAs " relaunch)
    ExitApp()
}

help := "
(
CCCCtrlC by TPReal

Simple multiple clipboard utility. Creates any number of additional clipboards
(called cccclipboards) and allows accessing them using normal keyboard shortcuts.

To put it simply:
    Hold Ctrl+C to select a cccclipboard, and release to copy to it.
    Hold Ctrl+V to select a cccclipboard, and release to paste from it.

Some more description:
If you press Ctrl+C or any other clipboard shortcut (see below) and release it
normally (without delay), then the regular clipboard is used for the operation.
But if you hold the shortcut for a moment, in the bottom right corner of the screen
you will see a clipboard selection indicator scrolling over cccclipboards. Release the keys
and the action will be executed on the currently selected cccclipboard.

Supported clipboard manipulation shortcuts:
    Ctrl+X, Ctrl+C, Ctrl+V
    Shift+Del, Ctrl+Ins, Shift+Ins

Special functions:
    Ctrl+C+V - display this help
    Ctrl+X+C - display cccclipboards list; symbols on the list:
        C - data in cccclipboard
        _ - cccclipboard empty
    Ctrl+Ins+X - erase all cccclipboards (does not erase the primary clipboard)

CCCCtrlC runs as administrator, so that it also works in elevated windows.

Right-click the tray icon for options: running at Windows startup
and the cccclipboard selection interval, i.e. the cccclipboard switch time
(the lower the faster, default value is 10 which is pretty fast).
)"

configFile := A_ScriptDir "\CCCCtrlC.ini"
defaultInterval := 10
; Counted in iterations of the selection loop, not in milliseconds.
interval := defaultInterval
; Read and written as a plain file: IniRead and IniWrite fail on some network file systems.
try {
    if RegExMatch(FileRead(configFile), "m)^Interval=(\d+)\s*$", &match) and IsValidInterval(match[1])
        interval := Integer(match[1])
}
toolTipOff := 500
toolTipMargin := 30
emptySlots := 5
copyWait := 500
pasteWait := 500

CoordMode("ToolTip", "Screen")
MonitorGetWorkArea(, , , &ttX, &screenBottom)
ttY := screenBottom - toolTipMargin

; "" marks an empty cccclipboard; the last element is never empty.
clips := []
; The shortcut that started the gesture in progress, "" when there is none.
down := ""
cancelled := false
; The selected cccclipboard, 0 being the regular clipboard.
num := 0
maxNum := 0

A_IconTip := "CCCCtrlC"
;@Ahk2Exe-SetMainIcon CCCCtrlC.ico
if not A_IsCompiled {
    try
        TraySetIcon(A_ScriptDir "\CCCCtrlC.ico")
}
taskName := "CCCCtrlC"
taskService := ComObject("Schedule.Service")
taskService.Connect()
runAtStartupItem := "Run at startup"
A_TrayMenu.Insert("1&", runAtStartupItem, ToggleRunAtStartup)
A_TrayMenu.Insert("2&")
if IsRunAtStartup()
    A_TrayMenu.Check(runAtStartupItem)

intervalPresets := [3, 5, 10, 15, 20, 30, 50]
intervalMenu := Menu()
for preset in intervalPresets
    intervalMenu.Add(preset, (itemName, *) => SetInterval(itemName), "Radio")
intervalMenu.Add()
intervalMenu.Add("Custom...", AskForInterval, "Radio")
A_TrayMenu.Insert("2&", "Selection interval", intervalMenu)
UpdateIntervalMenu()
ShowToolTipTimed("CCCCtrlC started")

^x::
^c::
^v::
+Del::
^Ins::
+Ins:: {
    global down, num, maxNum
    if down and not cancelled {
        Cancel()
        if down = "^Ins" {
            if ThisHotkey = "^x" {
                clips.Length := 0
                ShowToolTip(SlotsText(-1, true))
            }
        } else if down = "^c" and ThisHotkey = "^v"
            ShowToolTip(help "`n(current interval value: " interval ")")
    } else
        down := ThisHotkey
    maxNum := clips.Length + (IsPaste() ? 0 : emptySlots)
    num := 0
    ticks := interval
    loop {
        Sleep(1)
        if not down
            break
        if not cancelled and --ticks < 1 {
            num += 1
            if num > maxNum
                Cancel()
            else {
                ticks := interval
                ShowToolTip(SlotsText(num, false))
            }
        }
    }
}

~*x Up::
~*c Up::
~*v Up::
~*Del Up::
~*Ins Up:: {
    global down
    for key in ["x", "c", "v", "Del", "Ins"]
        if GetKeyState(key, "P")
            return
    if down and not cancelled
        Execute()
    else
        ToolTip()
    down := ""
    SetTimer(UnCancel, -2)
}

Execute() {
    action := SubStr(down, 1, 1) "{" SubStr(down, 2) "}"
    Critical()
    if num = 0
        Send(action)
    else {
        saved := ClipboardAll()
        if IsPaste() {
            A_Clipboard := clips[num]
            Send(action)
            Sleep(pasteWait)
        } else {
            A_Clipboard := ""
            Send(action)
            copied := ClipWait(copyWait / 1000, true)
            while clips.Length < num
                clips.Push("")
            clips[num] := copied ? ClipboardAll() : ""
            while clips.Length and not clips[clips.Length]
                clips.Pop()
        }
        A_Clipboard := saved
        ShowToolTipTimed(SlotsText(num, true))
    }
    Critical("Off")
}

IsPaste() {
    return down = "^v" or down = "+Ins"
}

Cancel() {
    global cancelled := true
    ShowToolTip(SlotsText(-1, false))
}

UnCancel() {
    global cancelled := false
}

; Slots are listed right to left; `executed` tells a finished action from a selection in progress.
SlotsText(selected, executed) {
    count := Max((IsPaste() or cancelled or executed) ? clips.Length : maxNum, 1)
    text := ""
    loop count {
        slot := (A_Index <= clips.Length and clips[A_Index]) ? "C" : "_"
        if A_Index = selected
            slot := executed ? "[" slot "]" : "(" slot ")"
        text := slot (text ? " " text : "")
    }
    return text
}

ShowToolTip(text) {
    ToolTip(text, ttX, ttY)
}

ShowToolTipTimed(text) {
    ShowToolTip(text)
    SetTimer(ToolTip, -toolTipOff)
}

IsRunAtStartup() {
    try
        taskService.GetFolder("\").GetTask(taskName)
    catch
        return false
    return true
}

; A scheduled task rather than a Startup folder shortcut, as only a task can start elevated
; without a UAC prompt.
ToggleRunAtStartup(*) {
    folder := taskService.GetFolder("\")
    if IsRunAtStartup()
        folder.DeleteTask(taskName, 0)
    else {
        user := EnvGet("USERDOMAIN") "\" A_UserName
        interactiveToken := 3
        task := taskService.NewTask(0)
        task.Principal.UserId := user
        task.Principal.LogonType := interactiveToken
        task.Principal.RunLevel := 1 ; highest
        ; The defaults would skip the start on battery power and kill the task after 3 days.
        task.Settings.DisallowStartIfOnBatteries := false
        task.Settings.StopIfGoingOnBatteries := false
        task.Settings.ExecutionTimeLimit := "PT0S"
        ; Tasks default to below-normal priority, which would make the keyboard hook sluggish.
        task.Settings.Priority := 4
        task.Triggers.Create(9).UserId := user ; at logon
        action := task.Actions.Create(0) ; run a program
        action.Path := A_IsCompiled ? A_ScriptFullPath : A_AhkPath
        if not A_IsCompiled
            action.Arguments := '"' A_ScriptFullPath '"'
        folder.RegisterTaskDefinition(taskName, task, 6, , , interactiveToken) ; 6: create or update
    }
    A_TrayMenu.ToggleCheck(runAtStartupItem)
}

IsValidInterval(value) {
    return IsInteger(value) and value >= 1 and value <= 500
}

SetInterval(value) {
    global interval := Integer(value)
    FileOpen(configFile, "w").Write("[Settings]`nInterval=" interval "`n")
    UpdateIntervalMenu()
}

UpdateIntervalMenu() {
    isPreset := false
    for preset in intervalPresets {
        if preset = interval {
            intervalMenu.Check(String(preset))
            isPreset := true
        } else
            intervalMenu.Uncheck(String(preset))
    }
    customItem := intervalPresets.Length + 2 "&"
    intervalMenu.Rename(customItem, isPreset ? "Custom..." : "Custom (" interval ")...")
    if isPreset
        intervalMenu.Uncheck(customItem)
    else
        intervalMenu.Check(customItem)
}

AskForInterval(*) {
    answer := InputBox("Cccclipboard switch time, 1 to 500 (the lower the faster):", "CCCCtrlC", "w320 h110", interval)
    if answer.Result != "OK"
        return
    if IsValidInterval(answer.Value)
        SetInterval(answer.Value)
    else
        MsgBox("Bad interval value! (" answer.Value ")", "CCCCtrlC")
}
