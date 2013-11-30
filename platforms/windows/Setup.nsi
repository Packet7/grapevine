; Grapevine.nsi
;
; This script is based on example1.nsi, but it remember the directory, 
; has uninstall support and (optionally) installs start menu shortcuts.
;
; It will install Grapevine.nsi into a directory that the user selects,

;--------------------------------

;--------------------------------
;Include Modern UI

  !include "MUI2.nsh"
;Interface Settings

  !define MUI_ABORTWARNING

;--------------------------------
;Pages

  !insertmacro MUI_PAGE_LICENSE "License.txt"
  ;!insertmacro MUI_PAGE_COMPONENTS
  ;!insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  !define MUI_FINISHPAGE_RUN
  !define MUI_FINISHPAGE_RUN_TEXT "Launch Grapevine"
  !define MUI_FINISHPAGE_RUN_FUNCTION "LaunchGrapevine"
  !insertmacro MUI_PAGE_FINISH

  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  
;--------------------------------
;Languages
 
  !insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Installer Sections

; The name of the installer
Name "Grapevine"

; The file to write
OutFile "Grapevine.exe"

; The default installation directory
InstallDir $PROGRAMFILES\Grapevine

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\NSIS_Grapevine" "Install_Dir"

; Request application privileges for Windows Vista
RequestExecutionLevel admin

;--------------------------------

UninstPage uninstConfirm
UninstPage instfiles

;--------------------------------

; The stuff to install
Section "Grapevine (required)"

  SectionIn RO
  
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR
  
  ; Put file there
  File "Grapevine\Release\Grapevine.exe"
  
  ; Write the installation path into the registry
  WriteRegStr HKLM SOFTWARE\NSIS_Grapevine "Install_Dir" "$INSTDIR"
  
  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Grapevine" "DisplayName" Grapevine"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Grapevine" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Grapevine" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Grapevine" "NoRepair" 1
  WriteUninstaller "uninstall.exe"
  
SectionEnd

; Optional section (can be disabled by the user)
Section "Start Menu Shortcuts"

  CreateDirectory "$SMPROGRAMS\Grapevine"
  CreateShortCut "$SMPROGRAMS\Grapevine\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  CreateShortCut "$SMPROGRAMS\Grapevine\Grapevine.lnk" "$INSTDIR\Grapevine.nsi" "" "$INSTDIR\Grapevine.nsi" 0
  CreateShortCut "$SMPROGRAMS\Startup\Grapevine.lnk" "$INSTDIR\Grapevine.exe"

SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"
  
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Grapevine"
  DeleteRegKey HKLM SOFTWARE\NSIS_Grapevine

  ; Remove files and uninstaller
  Delete $INSTDIR\Grapevine.exe
  Delete $INSTDIR\uninstall.exe

  ; Remove shortcuts, if any
  Delete "$SMPROGRAMS\Grapevine\*.*"
  Delete "$SMPROGRAMS\Startup\Grapevine.lnk"

  ; Remove directories used
  RMDir "$SMPROGRAMS\Grapevine"
  RMDir "$INSTDIR"

SectionEnd

Function LaunchGrapevine
  ExecShell "" "$SMPROGRAMS\Startup\Grapevine.lnk"
FunctionEnd
