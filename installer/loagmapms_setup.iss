; ============================================================
;  LoagmaPMS — Inno Setup Installer Script
;  Version is passed via /DAppVersion=x.y.z from release.bat
;  or falls back to "1.0.0" when compiled manually.
; ============================================================

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#define AppName      "LoagmaPMS"
#define AppPublisher "Loagma"
#define AppExeName   "LoagmaPMS.exe"
#define BuildDir     "..\client\build\windows\x64\runner\Release"
#define IconFile     "..\client\windows\runner\resources\app_icon.ico"

[Setup]
AppId={{B3F2A1C4-7D8E-4F3A-9B2C-1E5D6A7F8B9C}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisherURL=https://loagma.in
AppSupportURL=https://loagma.in
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
AllowNoIcons=yes
OutputDir=output
OutputBaseFilename=LoagmaPMS_Setup_v{#AppVersion}
VersionInfoVersion={#AppVersion}
SetupIconFile={#IconFile}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
ShowLanguageDialog=no
DisableDirPage=no
DisableProgramGroupPage=yes
CloseApplications=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"

[Files]
; Main executable
Source: "{#BuildDir}\{#AppExeName}"; DestDir: "{app}"; Flags: ignoreversion

; Flutter DLLs
Source: "{#BuildDir}\flutter_windows.dll";      DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\dartjni.dll";              DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\pdfium.dll";               DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\printing_plugin.dll";       DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\share_plus_plugin.dll";     DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\url_launcher_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion

; Data folder (assets, fonts, shaders, etc.)
Source: "{#BuildDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}";           Filename: "{app}\{#AppExeName}"; IconFilename: "{app}\{#AppExeName}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}";     Filename: "{app}\{#AppExeName}"; IconFilename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
