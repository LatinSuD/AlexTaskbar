#NoEnv
#SingleInstance force
#Persistent

; AlexTaskbar v1.0
;   https://github.com/LatinSuD/AlexTaskbar/

; Set the width of the taskbar
TaskbarWidth := 200

; Whether to use clock
useClock=1

; calendar application (when double click on clock)
calendarApp = outlookcal:




; TODO: Prevent listing of hidden apps like "program manager"
; TODO: Delay when opening
; TODO: right click: open real menu (shift modifies?), close, max/minimize, insert separator, delete separator, change title, change icon
; TODO: function to search open apps using keyboard
; TODO: click active window to minimize
; TODO: settings (right click en una zona vacia?)
; TODO: store preferences in file or reg
; TODO: save window order by id or title accross relaunch/reboot!
; TODO: Hint/tooltip. When mouse over slot show full title


DictImg := []       ; icons of windows
DictTitles := []    ; titles of windows
DictLastSeen := []  ; to keep track of terminated windows


if ( useClock )
	clockPosition := A_ScreenHeight - 20
else
	clockPosition := A_ScreenHeight 


; Create the GUI for the taskbar
Gui +LastFound +OwnDialogs -Border +AlwaysOnTop +ToolWindow

; handle to our own window
myHWND := WinExist()
; remove ourselves from task list
WinSet, ExStyle, +0x80 

Gui Color, 000000
Gui Font, s14 cWhite

; create Listview
Gui Add, ListView, x-5 y-5 h%clockPosition% vMyListView gMyClick -Hdr AltSubmit, Icon|Window Title|ImageIndex|windowId
LV_ModifyCol(1,20)
LV_ModifyCol(2,TaskbarWidth)
LV_ModifyCol(3,0)
LV_ModifyCol(4,0)

Gui +LastFound
;WinSet, TransColor, FFFFFF
GuiControl, +Backgroundblack, MyListView

; where we are shown or hidden
showState=0

; Set the size and position of the taskbar
;WinSet, Region, 0-0 %TaskbarWidth%-%TaskbarHeight%, A
;WinMove, A, , 0, %A_ScreenHeight% - %TaskbarHeight%, %TaskbarWidth%, %TaskbarHeight%

; Timer to control mouse, auto-hide, clock
SetTimer, PeriodicTimer, 100


; Create an ImageList to hold 10 small icons initially
ImageListID := IL_Create(10)  
LV_SetImageList(ImageListID)


; Hide the original taskbar (not recommended)
;WinHide, ahk_class Shell_TrayWnd


CoordMode,Mouse,Screen


;; CLOCK
if ( useClock ) {
	; Size 9, no antialising
	Gui, Font, cFFffff s9 q3, Arial
	; 
	Gui, Add, Text, vclockTime x1 y%clockPosition% BackgroundTrans gClockClick, %A_YYYY%-%A_MM%-%A_DD%  %a_hour%:%a_min%:%a_sec%.
	
	; Size 9, no antialising, bold
	Gui, Font, cFFffff s9 q3 w800, Arial
	Gui, Add, Text, vclockMinutes x68 y%clockPosition% BackgroundTrans gClockClick,%a_hour%:%a_min%
}


return


;;;;;; END OF MAIN
;;;;;;;;;;;;;;;;;;;;;;;


; Function to update the taskbar list
UpdateTaskbar:
{
	stamp := A_TickCount
    WinGet, idList, List
	
    Loop % idList
    {
        id := idList%A_Index%
		;OutputDebug, id %id%

		; No listarnos a nosotros mismos
		if ( id == myHWND ) {
			Continue
		}

		if (ObjRawGet(DictLastSeen, id) == "")
			isNewWindow=1
		else
			isNewWindow=0
		
        WinGetTitle, title, ahk_id %id%
        ;WinGet, processName, ProcessName, ahk_id %id%

		
		if ( title == "" ) {
			Continue
		} else {
			oldTitle := ObjRawGet(DictTitles, id)
			if (oldTitle != ""  &&  oldTitle != title) {
				; Update window title if changed
				Loop % LV_GetCount() {
					LV_GetText(aId, A_Index, 4)
					;OutputDebug, %id% %aId%
					if (id == aId) {
						;OutputDebug, AJA
						LV_Modify(A_Index, "Col2", title)
					}
				}		
			}
			
			ObjRawSet(DictTitles, id, title)
			ObjRawSet(DictLastSeen, id, stamp)
		}
		
		
		;LV_Modify(0, "-Select")
		if ( id == activa ) {
			Loop % LV_GetCount() {
				LV_GetText(aId, A_Index, 4)
				if ( id == aId ) { 
					;OutputDebug, Seleccionando %id%
					LV_Modify(A_Index, "Select")
				} else {
					LV_Modify(A_Index, "-Select")
				}
			}
		}


		
		; process icon
		IconHwnd := getIconFromWindow(id)
		;OutputDebug, %IconHwnd%
		if (ObjRawGet(DictImg, IconHwnd) == "") {
			; Unseen icon
			res := IL_Add(ImageListID, "HICON:" . IconHwnd) 		
			if (res == 0) {
			   res := IL_Add(ImageListID,  "shell32.dll", 1)
			}
			ObjRawSet(DictImg, IconHwnd, res)
			IndiceImg := res			

			; Update icon in ListView
			Loop % LV_GetCount() {
				LV_GetText(aId, A_Index, 4)
				if ( id == aId ) { 
					;OutputDebug, Seleccionando %id%
					LV_Modify(A_Index, "Icon" . IndiceImg)
				}
			}
			
		} else {
			; Icon already in list
			IndiceImg := ObjRawGet(DictImg, IconHwnd)
		}

		
		; add new window
		if (isNewWindow) {
			if ( id == activa ) {
				; highlight active window
				LV_Add("Icon" . IndiceImg . " Select", , title, IndiceImg, id)
			} else {
				LV_Add("Icon" . IndiceImg, , title, IndiceImg, id)
			}
		}

    }
	
	; Remove windows that were deleted
	For id, oldStamp in DictLastSeen {
		if ( 0+oldStamp != 0+stamp ) {
			DictLastSeen.Delete(id)
			Loop % LV_GetCount() {
				;OutputDebug,aid %aId%
				LV_GetText(aId, A_Index, 4)
				
				if (id == aId) {
					;OutputDebug, Elminio fila LV %id%
					LV_Delete(A_Index)
				}
			}
		}
	
	}
	
	Gui,Show, x-4 w200 y-3 h%A_ScreenHeight% NoActivate, AlexTaskbar
	showState=1

	return
}


; update clock text
updateClock:
{

 ; only update once per second
 if ( lastClockUpdate == A_NowUTC )
   return
 lastClockUpdate := A_NowUTC
 
 timeText = %A_YYYY%-%A_MM%-%A_DD%           :%a_sec%
 minuteText = %a_hour%:%a_min%
 
 GuiControl, , clockMinutes,%minuteText%
 GuiControl, , clockTime, %timeText%
 
 return
}




; Mouse left click handler
MyClick:
{
	rowClick := A_EventInfo
    OutputDebug, rowClick %rowClick%  EVENTINFO %A_EventInfo%  GUIEVENT: %A_GuiEvent%

	if ( A_GuiEvent == "RightClick" ) {
		;MsgBox,SI
		;lastClickItem:=A_EventInfo
		Menu, rightMenu, Add, Close, MyRightClick
		Menu, rightMenu, Show
		GoSub,UpdateTaskbar
		
		return
	}


	; If starting Drag&Drop
	If (A_GuiEvent == "D")
	{
		dragging := True
		OutputDebug, START DRAG
		MouseGetPos,,yDrag
		CutItem := A_EventInfo
		Loop, % LV_GetCount("Col") {
			LV_GetText(HoldText%A_Index%, CutItem, A_Index)
		}
		HotKey, LButton UP, DragDropEnd, On
		
		return
	}


	; If normal click
	if ( A_GuiEvent == "Normal" ) {
	
		; If ending Drag&Drop
		If (WaitClick)
		{
			OutputDebug, END DROP. Columnas %HoldText1% , 3 %HoldText3%, %HoldText2%
			WaitClick := False
			LV_Delete(CutItem)
			LV_Insert(A_EventInfo, "Icon" . HoldText3, , HoldText2, HoldText3, HoldText4 )
		} Else {
			; Really normal click

			if ( rowClick != 0 ) {
				LV_GetText(clickWID, rowClick, 4)
				
				; activate or minimize clicked window
				if ( clickWID == activa ) {
					WinMinimize,ahk_id %clickWID%				
				} else {
					WinActivate,ahk_id %clickWID%				
				}
			}  	
		}
		
		return
	}

	return
}


; right click handler
MyRightClick:
{
	OutputDebug, %A_ThisMenuItem% on %rowClick%
	if ( A_ThisMenuItem == "Close" && rowClick != 0 ) {
		LV_GetText(clickWID, rowClick, 4)
		WinClose,ahk_id %clickWID%
	}

	return
}


; double click on clock
ClockClick:
{
	If (A_GuiEvent == "DoubleClick") {
		; open calendar
		Run,%calendarApp%
	}
	return
}


; end of drag and drop sequence
DragDropEnd:
	dragging := False
	ReplaceSystemCursor()
	
	HotKey, LButton UP, DragDropEnd, Off
	MouseGetPos,,, WinID, ConID
	OutputDebug, DRAGDROP_END, %myHWND% vs %WinID%
 	If (WinID = myHWND )
	{
		;OutputDebug, CUMPLE
		WaitClick := True 
		Send, {Click}
	}
Return


; periodic timer
PeriodicTimer:
 MouseGetPos x, y

 candidateActiva := WinExist("A")
 if (candidateActiva != myHWND)
	activa := candidateActiva

 ; if have to show
 if ( x < 2 && showState==0 ) {
   GoSub,UpdateTaskbar
 } else {
   ; if have to hide
   if ( x >= TaskbarWidth && showState == 1 ) {
	showState=0
	OutputDebug,HIDE
	Gui, Hide
   }
 }

 if ( showState == 1 ) {
 
   ; if we are drag&dropping   
   if ( dragging ) {
		OutputDebug, showState = %showState%
	   if ( y < yDrag )
		 ReplaceSystemCursor("IDC_ARROW", "IDC_UPARROW")
	   else
		 ReplaceSystemCursor("IDC_ARROW", "IDC_SIZEALL")
   }

   ; update clock	
   GoSub,updateClock
 }
return



; To replace cursor while drag&dropping
ReplaceSystemCursor(old := "", new := "")
{
   static IMAGE_CURSOR := 2, SPI_SETCURSORS := 0x57
        , exitFunc := Func("ReplaceSystemCursor").Bind("", "")
        , setOnExit := false
        , SysCursors := {  IDC_ARROW      : 32512
						, IDC_UPARROW    : 32516
                        , IDC_SIZEALL    : 32646 }
   if !old {
      DllCall("SystemParametersInfo", "UInt", SPI_SETCURSORS, "UInt", 0, "UInt", 0, "UInt", 0)
      OnExit(exitFunc, 0), setOnExit := false
   }
   else  {
      hCursor := DllCall("LoadCursor", "Ptr", 0, "UInt", SysCursors[new], "Ptr")
      hCopy := DllCall("CopyImage", "Ptr", hCursor, "UInt", IMAGE_CURSOR, "Int", 0, "Int", 0, "UInt", 0, "Ptr")
      DllCall("SetSystemCursor", "Ptr", hCopy, "UInt", SysCursors[old])
      if !setOnExit
         OnExit(exitFunc), setOnExit := true
   }
}



; extract the icon from an active window
getIconFromWindow(windowDef) {
	WM_GETICON := 0x007F
	ICON_SMALL := 0
	ICON_BIG := 1

	GCLP_HICON := -14
	GCLP_HICONSM := -34

	MyHwnd := windowDef
	SendMessage, WM_GETICON, ICON_SMALL, 96, , ahk_id %MyHwnd%
	if (ErrorLevel != "FAIL")
	{
		IconHwnd := ErrorLevel
	}
	if (IconHwnd = 0)
	{
		IconHwnd := DllCall("GetClassLongPtr", "Ptr", MyHwnd, "Int", GCLP_HICON)
	}	

    ;MsgBox, %IconHwnd%
	return IconHwnd
}
