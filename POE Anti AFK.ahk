/*
	v1.0.1
    POE Anti AFK by lemasato
    Standalone script part of POE AHK Utilities
    If you have any question or find an issue, don't hesitate to post on GitHub!
    https://github.com/lemasato/POE-AHK-Utilities
    

	What does it do?
		- Prevent from getting flagged as AFK.  

	How do I use it?
		1. Install AutoHotKey.  
		https://www.autohotkey.com/download/ahk-install.exe  
		During installation, choose Unicode 64  
		2. Change the KEY_TO_PRESS variable value to your flask key.  
		3. Start the script.  

    Tested on AutoHotKey v1.1.33.02 (July 17 2020) Unicode x64
*/

KEY_TO_PRESS := "1" ; The key to press to prevent appearing as AFK
                    ; I recommend to set this as one of your flask

PAUSE_SCRIPT_WHILE_GAME_ACTIVE := True ; True       The script will not press the anti-afk key while the game window is active
                                       ; False      The script will press the anti-afk key whether the game window is active or not



/*  SCRIPT CONTENT STARTING HERE
    DONT EDIT UNLESS YOU KNOW WHAT YOU'RE DOING
	
	v1.0.1 (07 Dec 2020)
		Changed default "a" binding to "1" to fit default in-game bindings.
    v1.0 (03 Dec 2020)
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
Menu,Tray,Tip,POE Anti AFK
Menu,Tray, Icon,% "HICON:*" . Base64PNG_to_HICON( GetEmbededIconBase64() )
Menu,Tray,NoStandard
Menu,Tray,Add,Pause while game active?,Tray_PauseWhileGameActiveToggle
Menu,Tray,% PAUSE_SCRIPT_WHILE_GAME_ACTIVE=True?"Check":"Uncheck",Pause while game active?
Menu,Tray,Add
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
global POEGameExeArr:= []
Loop, Parse, POEGameExeList,% ","
{
    POEGameExeArr.Push(A_LoopField)
    GroupAdd, POEGameGroup, ahk_exe %A_LoopField%
}

funcObj := Func("AntiAfk").Bind()
SetTimer,% funcObj,% "-" Random(483, 852)*1000 ; between 8 and 14 mins
return

AntiAfk() { 
    global POEGameExeArr, KEY_TO_PRESS, PAUSE_SCRIPT_WHILE_GAME_ACTIVE

    Loop % POEGameExeArr.Count() {
		matchingPIDs := Get_Windows_PID(POEGameExeArr[A_Index], "ahk_exe")
		Loop, Parse, matchingPIDs,% ","
		{
			if !WinActive("ahk_pid " A_LoopField) || ( WinActive("ahk_pid " A_LoopField) && PAUSE_SCRIPT_WHILE_GAME_ACTIVE=False ) {
                ControlSend, ,% "{" KEY_TO_PRESS " Down}",% "ahk_pid " A_LoopField
                Sleep,% Random(207, 708)
                ControlSend, ,% "{" KEY_TO_PRESS " Up}",% "ahk_pid " A_LoopField
            }
		}
	}
    funcObj := Func("AntiAfk").Bind()
    SetTimer,% funcObj,% "-" Random(483, 852)*1000 ; between 8 and 14 mins
}

Random(num1, num2) {
	Random, ran, num1, num2
	return ran
}

Get_Windows_PID(_filter="", _filterType="", _delimiter=",") {
	returnList := Get_Windows_List(_filter, _filterType, _delimiter, "PID")
	return returnList
}

Get_Windows_List(_filter, _filterType, _delimiter, _what) {

	_whatAllowed := "ID,PID,ProcessID,Exe,ProcessName,Title"
	if !IsIn(_what, _whatAllowed) {
		Msgbox %A_ThisFunc%(): "%_what%" is not allowed`nAllowed: %_whatAllowed%
		return
	}
	_filterTypeAllowed := "ahk_exe,ahk_id,ahk_pid,Title"
	if !IsIn(_filterType, _filterTypeAllowed) {
		Msgbox %A_ThisFunc%(): "%_filterType%" is not allowed`nAllowed: %_filterTypeAllowed%
		return
	}

	; Assign Cmd
	Cmd := (IsIn(_what, "PID,ProcessID"))?("PID")
			:(IsIn(_what, "Exe,ProcessName"))?("ProcessName")
			:(_what)

	; Assign filter
	filter := (IsIn(_filterType, "ahk_exe,ahk_id,ahk_pid"))?(_filterType " " _filter):(_filter)

	; Assign return
	valuesList := ""
	if IsIn(_delimiter, "Array,[]")
		returnList := []
	else
		returnList := ""

	; Loop through pseudo array
	WinGet, winHwnds, List
	Loop, %winHwnds% {
		loopField := winHwnds%A_Index%
		if (_what = "Title")
			WinGetTitle, value, %filter% ahk_id %loopField%
		else 
			WinGet, value, %Cmd%, %filter% ahk_id %loopField%

		if (value) && !IsIn(value, valuesList) {
			valuesList := (valuesList)?(valuesList "," value):(value)

			if IsIn(_delimiter, "Array,[]")
				returnList.Push(value)
			else
				returnList := (returnList)?(returnList . _delimiter . value):(value)
		}
	}

	Return returnList
}

IsIn(_string, _list) {
	if _string in %_list%
		return True
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

Tray_PauseWhileGameActiveToggle:
    PAUSE_SCRIPT_WHILE_GAME_ACTIVE := !PAUSE_SCRIPT_WHILE_GAME_ACTIVE
    Menu,Tray,% PAUSE_SCRIPT_WHILE_GAME_ACTIVE=True?"Check":"Uncheck",Pause while game active?
return
Tray_Github:
    Run,% "https://github.com/lemasato/POE-AHK-Utilities"
Tray_Help:
    MsgBox,4096,POE Anti AFK,All documentation is included in the source`nOpen the script in a text editor and check it out! :)
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
)
return b64
}

GetEmbededPauseIconBase64() {
    b64 =
(
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
y9fweA/wcV1gZ2DWMxwwAAAABJRU5ErkJggg==
)
return b64
}