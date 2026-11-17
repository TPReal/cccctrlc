help=
;=======================================
(
CCCCtrlC by TPReal

Simple multiple clipboard utility. Creates any number of additional clipboards
(called cccclipboards) and allows accessing them using normal keyboard shortcuts.

To put it simply:
    Hold Ctrl+C to select a cccclipboard, and release to copy to it.
    Hold Ctrl+V to select a cccclipboard, and release paste from it.

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
    Ctrl+Ins+V - show / hide tray icon (right-click the icon for options)

Cccclipboard selection speed can be customised using command line parameter:
    CCCCtrlC.exe interval
where interval is the cccclipboard switch time
(the lower the faster, default value is 10 which is pretty fast).
)
;=======================================

#NoEnv
#UseHook
#SingleInstance, Force
#NoTrayIcon

interval:=10
toolTipOff:=300
toolTipMargin:=30
emptySlots:=5
copyWait:=500
pasteWait:=500

p1=%1%
if(p1)
{
  if(p1<1 or p1>500)
  {
    MsgBox, 0, CCCCtrlC, Bad interval value! (%p1%)`n(the default is %interval%)`n`nProgram will not be started
    ExitApp
  }
  interval:=p1
}
CoordMode, ToolTip, Screen
SysGet, screen, MonitorWorkArea
ttX:=screenRight
ttY:=screenBottom-toolTipMargin
numClips:=0
down:=""
cancel:=false
copyWaitSec:=copyWait/1000
Menu, Tray, Tip, CCCCtrlC
fToolTipTimed("CCCCtrlC started")
return

^x::
^c::
^v::
+Del::
^Ins::
+Ins::
  if(down and !cancel)
  {
    fCancel()
    if(down="^Ins")
    {
      if(A_ThisHotKey="^x")
      {
        while numClips>0
        {
          clip%numClips%:=""
          numClips:=numClips-1
        }
        fToolTip(fDispNum(-1,true))
      }
      else if(A_ThisHotKey="^v")
      {
        if(A_IconHidden)
          Menu, Tray, Icon
        else
          Menu, Tray, NoIcon
        ToolTip,
      }
    }
    else if(down="^c" and A_ThisHotKey="^v")
      fToolTip(help . "`n(current interval value: " . interval . ")")
  }
  else
    down:=A_ThisHotKey
  maxNum:=numClips+(fIsPaste() ? 0 : emptySlots)
  num:=0
  fastNum:=interval
  loop
  {
    Sleep, 1
    if(!down)
      break
    if(!cancel)
    {
      fastNum:=fastNum-1
      if(fastNum<1)
      {
        num:=num+1
        if(num>maxNum)
          fCancel()
        else
        {
          fastNum:=interval
          fToolTip(fDispNum(num,false))
        }
      }
    }
  }
return

~*x Up::
~*c Up::
~*v Up::
~*Del Up::
~*Ins Up::
  anyDown:=GetKeyState("X","P") or GetKeyState("C","P") or GetKeyState("V","P") or GetKeyState("Del","P") or GetKeyState("Ins","P")
  if(!anyDown)
  {
    if(down and !cancel)
      fExecute()
    else
      ToolTip,
    down:=""
    fUnCancel()
  }
return

fExecute()
{
  global
  actn:=SubStr(down,1,1) . "{" . SubStr(down,2) . "}"
  Critical
  if(num=0)
    Send, %actn%
  else
  {
    clip:=ClipBoardAll
    if(fIsPaste())
    {
      ClipBoard:=clip%num%
      Send, %actn%
      Sleep, %pasteWait%
    }else{
      ClipBoard:=""
      Send, %actn%
      ClipWait, %copyWaitSec%, 1
      if(ErrorLevel)
        clip%num%:=""
      else
        clip%num%:=ClipBoardAll
      if(num>numClips)
        numClips:=num
      while !clip%numClips% and numClips>0
        numClips:=numClips-1
    }
    ClipBoard:=clip
    fDispClipActn()
  }
  Critical, Off
}

fIsPaste()
{
  global
  return down="^v" or down="+Ins"
}

fCancel()
{
  global
  cancel:=true
  fToolTip(fDispNum(-1,false))
}

fUnCancel()
{
  SetTimer, UNCANCEL, 2
}

fDispNum(snum,actn)
{
  global
  maxN:=((!fIsPaste() and !cancel and !actn) ? maxNum : numClips)
  if(maxN=0)
    maxN:=1
  str:=""
  n:=1
  while n<maxN+1
  {
    if(str)
      str:=" " . str
    if(n=snum)
      str:=(actn ? "]" : ")") . str
    str:=(clip%n% ? "C" : "_") . str
    if(n=snum)
      str:=(actn ? "[" : "(") . str
    n:=n+1
  }
  return str
}

fDispClipActn()
{
  global
  fToolTipTimed(fDispNum(num,true))
}

fToolTip(text)
{
  global ttX, ttY
  ToolTip, %text%, %ttX%, %ttY%
}

fToolTipTimed(text)
{
  global
  fToolTip(text)
  SetTimer, TOOLTIP_OFF, %toolTipOff%
}

UNCANCEL:
  SetTimer, UNCANCEL, Off
  cancel:=false
return

TOOLTIP_OFF:
  SetTimer, TOOLTIP_OFF, Off
  ToolTip,
return
