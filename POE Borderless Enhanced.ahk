/*
	v1.0
    POE Borderless Enhanced by lemasato
    Standalone script part of POE AHK Utilities
    If you have any question or find an issue, don't hesitate to post on GitHub!
    https://github.com/lemasato/POE-AHK-Utilities
    

    History of this script
        The original purpose of this script was to work around the Vulkan bug where overlays app didn't work due to "Windowed Fullscreen" working as normal exclusive "Fullscreen"
        This script originally removed the borders of the "Windowed" mode, effectively making the game borderless, fixing the issue with overlay apps.
        Altough now the Vulkan bug has now been fixed for most people, it still seems to occur for some.
        Months later, someone asked me if it would be possible to adapt it so that the taskbar would stay visible. I decided to rewrite the whole while thing adding new features.
        
    What does it do?
        - Play in borderless if you're experiencing the Vulkan fullscreen bug.
        - Play in borderless while keeping the taskbar visible.
        - Stretch the window for a widescreen-like game experience.
        - Can add black bars around the game window while playing in widescreen-like for a more enjoyable experience.
 
    How do I use it?
        1. Install AutoHotKey   https://www.autohotkey.com/download/ahk-install.exe
           During installation, choose Unicode 64
        2. Set the variables here below according to your preferences
           Documentation for each is included below, read carefully  
        3. Start the script
        4. Go in game and change your resolution to "Windowed"
           It can be "Windowed Fullscreen" but only if you don't experience the Vulkan bug where "Windowed Fullscreen" is actually working as normal exclusive "Fullscreen"

        Configuration examples:
            Run the game in borderless fullscreen while keeping the taskbar visible:
                KEEP_TASKBAR_VISIBLE := True
                EXIT_APP_AFTER_BORDERLESS := False
                USE_ONE_PIXEL_OFFSET_FIX := False
                SIMULATE_WIDE_SCREEN := False
                CUSTOM_GAME_POSITION_ENABLE := False

            Simulate playing on a widescreen (to see further in game) with black bars for better game experience:
                KEEP_TASKBAR_VISIBLE := False
                EXIT_APP_AFTER_BORDERLESS := False
                USE_ONE_PIXEL_OFFSET_FIX := False
                SIMULATE_WIDE_SCREEN := True
                USE_BLACK_BARS_WITH_WIDE_SCREEN := True
                BLACK_BARS_TRANSPARENCY_PERCENT := 0
                BLACK_BARS_ARE_CLICK_THROUGH := False
                CUSTOM_GAME_POSITION_ENABLE := False

            Simulate playing on a widescreen (to see further in game) with translucent+click-through black bars to see and click windows behind them
            For example, having the discord behind the black bars so you can see new chat messages without tabbing out and reply easily
                KEEP_TASKBAR_VISIBLE := False
                EXIT_APP_AFTER_BORDERLESS := False
                USE_ONE_PIXEL_OFFSET_FIX := False
                SIMULATE_WIDE_SCREEN := True
                USE_BLACK_BARS_WITH_WIDE_SCREEN := True
                BLACK_BARS_TRANSPARENCY_PERCENT := 20
                BLACK_BARS_ARE_CLICK_THROUGH := True
                CUSTOM_GAME_POSITION_ENABLE := False

            Have determined position and size for the game window in case you don't want the game window to take your full screen space
            In this example the game will be centered on the screen, the width will be half the screen space and the height will be 600 (minimum allowed by the game)
                KEEP_TASKBAR_VISIBLE := False
                EXIT_APP_AFTER_BORDERLESS := False
                USE_ONE_PIXEL_OFFSET_FIX := False
                SIMULATE_WIDE_SCREEN := False
                CUSTOM_GAME_POSITION_ENABLE := True
                CUSTOM_GAME_X_POSITION := A_ScreenWidth/4, CUSTOM_GAME_Y_POSITION := A_ScreenHeight/2-(600/2), CUSTOM_GAME_WIDTH := A_ScreenWidth/2, CUSTOM_GAME_HEIGHT := 600


    Tested on AutoHotKey v1.1.33.02 (July 17 2020) Unicode x64
*/

KEEP_TASKBAR_VISIBLE := False ; True    The game will not occupy the space of the taskbar and it will remain visible
                              ; False   The game will take the full screen space and the taskbar will not be visible

EXIT_APP_AFTER_BORDERLESS := False ; True   The script will close after making the game borderless
                                   ; False  The script will keep running in the background after making the game borderless

USE_ONE_PIXEL_OFFSET_FIX := False ; True     The window will be one pixel offset from the top of the screen
                                  ;            Use this if the script doesn't work for you
                                  ;            This is usually only neccessary with some AMD GPUs
                                  ; False    The one pixel offset fix will not be applied


SIMULATE_WIDE_SCREEN := False ; True    Simulate a widescreen by reducing the window height
                              ; False   The widescreen will not be simulated and the window will take the full screen space

USE_BLACK_BARS_WITH_WIDE_SCREEN := True  ; True     Black bars will surround the game window
                                         ;            /!\ Having this to True will ignore EXIT_APP_AFTER_BORDERLESS and keep the script running
                                         ;            /!\ Requires SIMULATE_WIDE_SCREEN to be enabled to work
                                         ; False    No black bars will be put around the game window

BLACK_BARS_TRANSPARENCY_PERCENT := 0 ; Any value between 0 and 100
                                     ; 0 = No transparency. 100 = Fully transparent.

BLACK_BARS_ARE_CLICK_THROUGH := False ; True    Clicking on black bars will activate the window behind it.
                                      ; False   Clicking on the black bars will not do anything.


CUSTOM_GAME_POSITION_ENABLE := False ; True     Allows to use specific x,y,width,height values for the game window
                                     ;          /!\ This will completely ignore the values of KEEP_TASKBAR_VISIBLE, SIMULATE_WIDE_SCREEN, USE_ONE_PIXEL_OFFSET_FIX
                                     ; False    Will detect and use values automatically based on KEEP_TASKBAR_VISIBLE and SIMULATE_WIDE_SCREEN
CUSTOM_GAME_X_POSITION := 0, CUSTOM_GAME_Y_POSITION := 0, CUSTOM_GAME_WIDTH := 1000, CUSTOM_GAME_HEIGHT := 700 ; Only use if CUSTOM_GAME_POSITION_ENABLE is set to True


USE_OUTPUT_LOGGING := True ; True       Will write logs in a file, used for debugging
                           ; False      No output log file will be created



/*  SCRIPT CONTENT STARTING HERE
    DONT EDIT UNLESS YOU KNOW WHAT YOU'RE DOING

    v1.0 (17 Nov 2020)
        Initial release
*/

#SingleInstance, Force
#KeyHistory 0
#Persistent
#NoEnv

OnExit("Exit")

DetectHiddenWindows, Off
FileEncoding, UTF-8 ; Cyrilic characters
SetWinDelay, 0
ListLines, Off

; Basic tray menu
Menu,Tray,Tip,POE Borderless Enhanced
Menu,Tray, Icon,% "HICON:*" . Base64PNG_to_HICON( GetEmbededIconBase64() )
Menu,Tray,NoStandard
Menu,Tray,Add,Help,Tray_Help
Menu,Tray,Add,GitHub,Tray_Github
Menu,Tray,Add
Menu,Tray,Add,Pause,Tray_Pause
Menu,Tray,Add,Reload,Tray_Reload
Menu,Tray,Add,Close,Tray_Exit
Menu,Tray,Icon
; Left click
OnMessage(0x404, "AHK_NOTIFYICON") 

global POEGameExeList := "PathOfExile.exe,PathOfExile_x64.exe,PathOfExileSteam.exe,PathOfExile_x64Steam.exe,PathOfExile_KG.exe,PathOfExile_x64_KG.exe,PathOfExileEGS.exe,PathOfExile_x64EGS.exe"
Loop, Parse, POEGameExeList, % ","
{
    POEGameExeArr.Push(A_LoopField)
    GroupAdd, POEGameGroup, ahk_exe %A_LoopField%
}
global DoneOnceGameHandles := {}
global LOGS_FILE := A_ScriptDir "\POE Borderless Enhanced LOGS.txt"

Register_ShellHook()
OnShellMessage(4, WinActive("A"))
funcObj := Func("DeleteInactiveGameHandles").Bind()
SetTimer,% funcObj,% 60*60000 ; 1 hour
FileDelete,% LOGS_FILE

if (USE_OUTPUT_LOGGING=True) {
    FileAppend,% ""
    . "`nKEEP_TASKBAR_VISIBLE: " (KEEP_TASKBAR_VISIBLE=True?"True":KEEP_TASKBAR_VISIBLE=False?"False":KEEP_TASKBAR_VISIBLE)
    . "`nEXIT_APP_AFTER_BORDERLESS: " (EXIT_APP_AFTER_BORDERLESS=True?"True":EXIT_APP_AFTER_BORDERLESS=False?"False":EXIT_APP_AFTER_BORDERLESS)
    . "`nUSE_ONE_PIXEL_OFFSET_FIX: " (USE_ONE_PIXEL_OFFSET_FIX=True?"True":USE_ONE_PIXEL_OFFSET_FIX=False?"False":USE_ONE_PIXEL_OFFSET_FIX)
    . "`nSIMULATE_WIDE_SCREEN: " (SIMULATE_WIDE_SCREEN=True?"True":SIMULATE_WIDE_SCREEN=False?"False":SIMULATE_WIDE_SCREEN)
    . "`nUSE_BLACK_BARS_WITH_WIDE_SCREEN: " (USE_BLACK_BARS_WITH_WIDE_SCREEN=True?"True":USE_BLACK_BARS_WITH_WIDE_SCREEN=False?"False":USE_BLACK_BARS_WITH_WIDE_SCREEN)
    . "`nBLACK_BARS_TRANSPARENCY_PERCENT: " (BLACK_BARS_TRANSPARENCY_PERCENT=True?"True":BLACK_BARS_TRANSPARENCY_PERCENT=False?"False":BLACK_BARS_TRANSPARENCY_PERCENT)
    . "`nBLACK_BARS_ARE_CLICK_THROUGH: " (BLACK_BARS_ARE_CLICK_THROUGH=True?"True":BLACK_BARS_ARE_CLICK_THROUGH=False?"False":BLACK_BARS_ARE_CLICK_THROUGH)
    . "`nCUSTOM_GAME_POSITION_ENABLE: " (CUSTOM_GAME_POSITION_ENABLE=True?"True":CUSTOM_GAME_POSITION_ENABLE=False?"False":CUSTOM_GAME_POSITION_ENABLE)
    . "`nCUSTOM_GAME_X_POSITION: " CUSTOM_GAME_X_POSITION
    . "`nCUSTOM_GAME_Y_POSITION: " CUSTOM_GAME_Y_POSITION
    . "`nCUSTOM_GAME_WIDTH: " CUSTOM_GAME_WIDTH
    . "`nCUSTOM_GAME_HEIGHT: " CUSTOM_GAME_HEIGHT
    . "`nUSE_OUTPUT_LOGGING: " (USE_OUTPUT_LOGGING=True?"True":USE_OUTPUT_LOGGING=False?"False":USE_OUTPUT_LOGGING)
    ,% LOGS_FILE
}
return

MakeBorderless(winHwnd) {
    global WS_POPUP := 0x80000000, WS_THICKFRAME := 0x00040000, WS_CAPTION = 0x00C00000, WS_VISIBLE := 0x10000000, WS_CLIPSIBLINGS := 0x04000000
    global KEEP_TASKBAR_VISIBLE, EXIT_APP_AFTER_BORDERLESS, USE_ONE_PIXEL_OFFSET_FIX
    global SIMULATE_WIDE_SCREEN, USE_BLACK_BARS_WITH_WIDE_SCREEN, BLACK_BARS_TRANSPARENCY_PERCENT, BLACK_BARS_ARE_CLICK_THROUGH
    global CUSTOM_GAME_POSITION_ENABLE, CUSTOM_GAME_X_POSITION, CUSTOM_GAME_Y_POSITION, CUSTOM_GAME_WIDTH, CUSTOM_GAME_HEIGHT
    global USE_OUTPUT_LOGGING, LOGS_FILE

    global DoneOnceGameHandles
    global hGuiBlackBarMain

    WinGet, activeStyles, Style,% "ahk_id " winHwnd
    hasBorders := activeStyles&+WS_THICKFRAME?True : activeStyles&+WS_CAPTION?True : False
    if ( DoneOnceGameHandles[winHwnd] != True ) || ( activeStyles && hasBorders ) || ( SIMULATE_WIDE_SCREEN=True && !hGuiBlackBarMain ) { ; Only if not borderless or if we want widescreen and it wasn't done yet    
        monitorIndex := GetMonitorIndexFromWindow(winHwnd)
        taskBarSize := GetTaskBarSize()
        taskBarLocation := GetTaskBarLocation()
        monitorPosition := GetMonitorPosition(monitorIndex)

        ; WinSet, Style,% "-" WS_POPUP+WS_THICKFRAME+WS_CAPTION, % "ahk_id " winHwnd
        DEFAULT_WINDOWED_FULLSCREEN_POE_STYLE := WS_POPUP+WS_VISIBLE+WS_CLIPSIBLINGS
        FINAL_STYLE := DEFAULT_WINDOWED_FULLSCREEN_POE_STYLE
        FINAL_STYLE := activeStyles & +WS_THICKFRAME ? FINAL_STYLE+WS_THICKFRAME : FINAL_STYLE
        FINAL_STYLE := activeStyles & +WS_CAPTION ? FINAL_STYLE+WS_CAPTION : FINAL_STYLE
        WinSet, Style,% DEFAULT_WINDOWED_FULLSCREEN_POE_STYLE, % "ahk_id " winHwnd
        
        WinMove,% "ahk_id " winHwnd,% winText:=""
        ,% newWinX := CUSTOM_GAME_POSITION_ENABLE=True ? CUSTOM_GAME_X_POSITION : KEEP_TASKBAR_VISIBLE ? monitorPosition.LeftWA : monitorPosition.Left
        ,% newWinY := CUSTOM_GAME_POSITION_ENABLE=True ? CUSTOM_GAME_Y_POSITION : KEEP_TASKBAR_VISIBLE ? monitorPosition.TopWA + (USE_ONE_PIXEL_OFFSET_FIX=True?1:0) : monitorPosition.Top + (USE_ONE_PIXEL_OFFSET_FIX=True?1:0)
        ,% newWinW := CUSTOM_GAME_POSITION_ENABLE=True ? CUSTOM_GAME_WIDTH : KEEP_TASKBAR_VISIBLE ? monitorPosition.RightWA - monitorPosition.LeftWA : monitorPosition.Right - monitorPosition.Left
        ,% newWinH := CUSTOM_GAME_POSITION_ENABLE=True ? CUSTOM_GAME_HEIGHT : SIMULATE_WIDE_SCREEN=True ? 1 : ( KEEP_TASKBAR_VISIBLE=True ? monitorPosition.BottomWA - monitorPosition.TopWA : monitorPosition.Bottom - monitorPosition.Top )

        if (USE_OUTPUT_LOGGING=True) {
            WinGet, newStyles, Style,% "ahk_id " winHwnd
            FileAppend,% "`n`nCurrent window style of " winHwnd ": " activeStyles ". New: " newStyles
            . "`nBorders detected: " hasBorders
            . "`nGame window is on screen " monitorIndex
            . "`nTask bar detected on " taskBarLocation " with x" taskBarSize.X " y" taskBarSize.Y " w" taskBarSize.W " h" taskBarSize.H
            . "`nMonitor position detected on Left:" monitorPosition.Left " (WA " monitorPosition.LeftWA "), Top:" monitorPosition.Top " (WA " monitorPosition.TopWA
            .    "), Right:" monitorPosition.Right " (WA " monitorPosition.RightWA "), Bottom:" monitorPosition.Bottom " (WA " monitorPosition.BottomWA ")"
            . "`nGame window will be moved to x" newWinX " y" newWinY " w" newWinW " h" newWinH
            ,% LOGS_FILE
        }

        if (EXIT_APP_AFTER_BORDERLESS=True && USE_BLACK_BARS_WITH_WIDE_SCREEN != True) {
            if (USE_OUTPUT_LOGGING=True)
                FileAppend,% "`n`nEXIT_APP_AFTER_BORDERLESS enabled. Exiting",% LOGS_FILE
            ExitApp
        }
        if (SIMULATE_WIDE_SCREEN=True && CUSTOM_GAME_POSITION_ENABLE=False) {
            availableMonitorHeightSpace := KEEP_TASKBAR_VISIBLE ? monitorPosition.BottomWA - monitorPosition.TopWA + (taskBarLocation="Top"?taskBarSize.H:0) : monitorPosition.Bottom - monitorPosition.Top
            WinGetPos, winX, winY, winW, winH, % "ahk_id " winHwnd
            WinMove,% "ahk_id " winHwnd,,,% (availableMonitorHeightSpace/2) - (winH/2) ; + (KEEP_TASKBAR_VISIBLE && IsIn(taskBarLocation,"Top") ? taskBarSize.H : 0)
            if (USE_OUTPUT_LOGGING=True)
                FileAppend,% "`n`nSIMULATE_WIDE_SCREEN is enabled"
                . "`nAvailable monitor height space: " availableMonitorHeightSpace
                . "`nGame window has been moved to y" (availableMonitorHeightSpace/2) - (winH/2)
                ,% LOGS_FILE
        }
        if (SIMULATE_WIDE_SCREEN=True && USE_BLACK_BARS_WITH_WIDE_SCREEN=True) {
            Loop {
                index := A_Index
                if (index=1 && USE_OUTPUT_LOGGING=True)
                    FileAppend,% "`n`nWaiting for game window height to automatically be updated by the game",% LOGS_FILE
                WinGetPos, newWinX, newWinY, newWinW, newWinH, % "ahk_id " winHwnd
                if (newWinX != winX || newWinY != winY || newWinW != winW || newWinH != winH)
                    Break
                Sleep 100
            }
            WinGetPos, winX, winY, winW, winH, % "ahk_id " winHwnd

            if (index=1 && USE_OUTPUT_LOGGING=True)
                FileAppend,% "`n`nGame updated window height automatically: x" winX " y" winY " w" winW " h" winH,% LOGS_FILE

            blackBarsGuis := {}
            blackBarsGuis["Main"] := [monitorPosition.Left
                                        ,monitorPosition.Top
                                        ,monitorPosition.Right - monitorPosition.Left
                                        ,monitorPosition.Bottom - monitorPosition.Top]
                                blackBarsGuis["Top"] := [KEEP_TASKBAR_VISIBLE ? monitorPosition.LeftWA : monitorPosition.Left
                                        ,KEEP_TASKBAR_VISIBLE ? monitorPosition.TopWA : monitorPosition.Top
                                        ,KEEP_TASKBAR_VISIBLE ? monitorPosition.RightWA - monitorPosition.LeftWA : monitorPosition.Right - monitorPosition.Left
                                        ,KEEP_TASKBAR_VISIBLE ? winY - monitorPosition.TopWA : winY - monitorPosition.Top]
                                blackBarsGuis["Bottom"] := [KEEP_TASKBAR_VISIBLE ? monitorPosition.LeftWA : monitorPosition.Left
                                        ,winY+winH
                                        ,KEEP_TASKBAR_VISIBLE ? monitorPosition.RightWA - monitorPosition.LeftWA : monitorPosition.Right - monitorPosition.Left
                                        ,KEEP_TASKBAR_VISIBLE ? monitorPosition.BottomWA - monitorPosition.TopWA - winY - winH + (taskBarLocation="Top"?taskBarSize.H:0) : monitorPosition.Bottom - monitorPosition.Top - winY - winH]

            if (USE_OUTPUT_LOGGING=True)
                FileAppend,% "`n`nBlack bars location determined:"
                . "`nMain: x" blackBarsGuis.Main.1 " y" blackBarsGuis.Main.2 " w" blackBarsGuis.Main.3 " h" blackBarsGuis.Main.4
                . "`nTop: x" blackBarsGuis.Top.1 " y" blackBarsGuis.Top.2 " w" blackBarsGuis.Top.3 " h" blackBarsGuis.Top.4
                . "`nBottom: x" blackBarsGuis.Bottom.1 " y" blackBarsGuis.Bottom.2 " w" blackBarsGuis.Bottom.3 " h" blackBarsGuis.Bottom.4
                ,% LOGS_FILE

            for index, guiName in ["Main","Top","Bottom"] {
                Gui, BlackBar%guiName%:New,% "+ToolWindow +LastFound -Resize -SysMenu +0x04000000 -Caption -Border -0x40000 +E0x08000000 " (guiName!="Main"?"+ParentBlackBarMain":"") " +HwndhGuiBlackBar" guiName
                Gui, BlackBar%guiName%:Color,% guiName="Main"?"Red":"Black",% guiName="Main"?"Red":"Black"
                if (guiName="Main") {
                    WinSet, TransColor,% "Red " 255 - ( (255/100)*BLACK_BARS_TRANSPARENCY_PERCENT )
                    if (BLACK_BARS_ARE_CLICK_THROUGH) {
                        if (BLACK_BARS_TRANSPARENCY_PERCENT=0)
                            WinSet, TransColor,% "Red " 254
                        WinSet, ExStyle, +0x20
                    }
                }
                Gui, BlackBar%guiName%:Show,% "x" blackBarsGuis[guiName].1 " y" blackBarsGuis[guiName].2 " w" blackBarsGuis[guiName].3 " h" blackBarsGuis[guiName].4 " NoActivate"
            }
        }
        DoneOnceGameHandles[winHwnd] := True
    }
}

DeleteInactiveGameHandles() {
    global DoneOnceGameHandles, POEGameGroup
    global USE_OUTPUT_LOGGING, LOGS_FILE
    for handle, value in DoneOnceGameHandles {
        if !WinExist("ahk_group POEGameGroup ahk_id " handle) {
            DoneOnceGameHandles.Remove(handle)
            if (USE_OUTPUT_LOGGING=True)
                FileAppend,% "`n`nGame window " handle " removed from object list has it doesn't exist anymore",% LOGS_FILE
        }
    }
}

OnShellMessage(wParam, lParam) {
    global POEGameExeList, hGuiBlackBarMain, LastActivePOEWinHandle
	if !IsIn(wParam, "1,2,4,5,32772") ; 1=HSHELL_WINDOWCREATED // 2= HSHELL_WINDOWDESTROYED // 4=HSHELL_WINDOWACTIVATED // 5= HSHELL_GETMINRECT // 32772=HSHELL_RUDEAPPACTIVATED
		return

	if (lParam) { ; Retrieve process infos based on lparam
		WinGet, activeWinExe, ProcessName, ahk_id %lParam%
		WinGet, activeWinHwnd, ID, ahk_id %lParam%
		WinGet, activeWinPID, PID, ahk_id %lParam%
	}
	else if (!lParam || !activeWinExe || !activeWinHwnd) { ; Retrieve process infos of currently active window
		WinGet, activeWinExe, ProcessName, A
		WinGet, activeWinHwnd, ID, A
		WinGet, activeWinPID, PID, A
	}

	if IsIn(activeWinExe, POEGameExeList) {
        LastActivePOEWinHandle := activeWinHwnd
        funcObj := Func("MakeBorderless").Bind(activeWinHwnd)
        SetTimer,% funcObj, -500
    }
    if (hGuiBlackBarMain) {
        if IsIn(activeWinExe, POEGameExeList) || ( !WinExist("ahk_group POEGameGroup") && DoneOnceGameHandles.Count() ) {
            ; Set BlackBarMain behind game window in Z-pos
            DllCall("SetWindowPos", "Ptr", &hGuiBlackBarMain, "Ptr", &activeWinHwnd
			, "int", 0, "int", 0, "int", 0, "int", 0
			, "uint", 0x13) ; NOSIZE | NOMOVE | NOACTIVATE ( 0x1 | 0x2 | 0x10 )

            ; Workaround to prevent task bar from appearing on top of BlackBarMain
            Gui, BlackBarMain:+AlwaysOnTop
            Gui, BlackBarMain:Show,NA
            Gui, BlackBarMain:-AlwaysOnTop
            ; Set Taskbar behind BlackBarMain in Z-pos
            DllCall("SetWindowPos", "Ptr", &GetTaskBarHandle(), "Ptr", &hGuiBlackBarMain
			, "int", 0, "int", 0, "int", 0, "int", 0
			, "uint", 0x13) ; NOSIZE | NOMOVE | NOACTIVATE ( 0x1 | 0x2 | 0x10 )

            
        }
        if ( !WinExist("ahk_group POEGameGroup") && DoneOnceGameHandles.Count() ) {
            DeleteInactiveGameHandles()
            Gui, BlackBarMain:Hide
        }
    }
}

Register_ShellHook() {
    Gui, ShellHook:Destroy
	Gui, ShellHook:New, +HwndhGuiShellHook
	DllCall("RegisterShellHookWindow", UInt, hGuiShellHook)
	MsgNum := DllCall("RegisterWindowMessage", Str, "SHELLHOOK")
	OnMessage(MsgNum, "OnShellMessage", True)
}

GetMonitorPosition(monIndex=1) {
    SysGet, Mon, Monitor,% monIndex
    SysGet, MonWA, MonitorWorkArea,% monIndex
    MonitorPosition := {"Left": MonLeft, "Right": MonRight, "Top": MonTop, "Bottom": MonBottom
                       ,"LeftWA": MonWALeft, "RightWA": MonWARight, "TopWA": MonWATop, "BottomWA": MonWABottom}    
    return MonitorPosition
}

GetTaskBarHandle() {
    WinGet, handle, ID, ahk_class Shell_TrayWnd
    return handle
}

GetTaskBarLocation() {
    WinGetPos, x, y, w, h, ahk_class Shell_TrayWnd
    location := x=0 && w=A_ScreenWidth && y != 0 ? "Bottom"
              : x=0 && w=A_ScreenWidth && y = 0 ? "Top"
              : x=0 && h=A_ScreenHeight && y = 0 ? "Left"
              : x != 0 && h=A_ScreenHeight && y = 0 ? "Right"
              : "Unknown"
    return location
}

GetTaskBarSize() {
    WinGetPos, x, y, w, h, ahk_class Shell_TrayWnd
    return {X:x,Y:y,W:w,H:h}
}

GetMonitorIndexFromWindow(windowHandle) {
    ; https://autohotkey.com/board/topic/69464-how-to-determine-a-window-is-in-which-monitor/#entry440355
    
	; Starts with 1.
	monitorIndex := 1

	VarSetCapacity(monitorInfo, 40)
	NumPut(40, monitorInfo)
	
	if (monitorHandle := DllCall("MonitorFromWindow", "uint", windowHandle, "uint", 0x2)) 
		&& DllCall("GetMonitorInfo", "uint", monitorHandle, "uint", &monitorInfo) 
	{
		monitorLeft   := NumGet(monitorInfo,  4, "Int")
		monitorTop    := NumGet(monitorInfo,  8, "Int")
		monitorRight  := NumGet(monitorInfo, 12, "Int")
		monitorBottom := NumGet(monitorInfo, 16, "Int")
		workLeft      := NumGet(monitorInfo, 20, "Int")
		workTop       := NumGet(monitorInfo, 24, "Int")
		workRight     := NumGet(monitorInfo, 28, "Int")
		workBottom    := NumGet(monitorInfo, 32, "Int")
		isPrimary     := NumGet(monitorInfo, 36, "Int") & 1

		SysGet, monitorCount, MonitorCount

		Loop, %monitorCount%
		{
			SysGet, tempMon, Monitor, %A_Index%

			; Compare location to determine the monitor index.
			if ((monitorLeft = tempMonLeft) and (monitorTop = tempMonTop)
				and (monitorRight = tempMonRight) and (monitorBottom = tempMonBottom))
			{
				monitorIndex := A_Index
				break
			}
		}
	}
	
	return monitorIndex
}

IsIn(_string, _list) {
	if _string in %_list%
		return True
}

IsNum(str) {
	if str is number
		return true
	return false
}

Exit(ExitReason, ExitCode) {

	if ExitReason not in Reload
	{
		ExitApp
	}
}

Reload() {
    Sleep 10
	Reload
	Sleep 10000
}

Tray_Github:
    Run,% "https://github.com/lemasato/POE-AHK-Utilities"
Tray_Help:
    MsgBox,4096,POE Borderless Enhanced,All documentation is included in the source`nOpen the script in a text editor and check it out! :)
return
Tray_Pause:
    suspendToggle := !suspendToggle
    if (suspendToggle) {
        Menu,Tray, Icon,% "HICON:*" . Base64PNG_to_HICON( GetEmbededPauseIconBase64() ),,1
        Menu, Tray, Check, Pause
        Pause, On
    }
    else {
        Menu,Tray, Icon,% "HICON:*" . Base64PNG_to_HICON( GetEmbededIconBase64() ),,1
        Pause, Off
        Menu, Tray, UnCheck, Pause
    }
return
Tray_Reload:
    Reload()
return
Tray_Exit:
    ExitApp
return

Base64PNG_to_HICON(Base64PNG, W:=0, H:=0) {     ;   By SKAN on D094/D357 @ tiny.cc/t-36636
Local BLen:=StrLen(Base64PNG), Bin:=0,     nBytes:=Floor(StrLen(RTrim(Base64PNG,"="))*3/4)                     
  Return DllCall("Crypt32.dll\CryptStringToBinary", "Str",Base64PNG, "UInt",BLen, "UInt",1
            ,"Ptr",&(Bin:=VarSetCapacity(Bin,nBytes)), "UIntP",nBytes, "UInt",0, "UInt",0)
       ? DllCall("CreateIconFromResourceEx", "Ptr",&Bin, "UInt",nBytes, "Int",True, "UInt"
                 ,0x30000, "Int",W, "Int",H, "UInt",0, "UPtr") : 0            
}


GetEmbededIconBase64() {
b64 =
(
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
T1h7Y4AP8HB1bCZhLtKfoAAAAASUVORK5CYII=
)
return b64
}

GetEmbededPauseIconBase64() {
    b64 =
(
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
==
)
return b64
}