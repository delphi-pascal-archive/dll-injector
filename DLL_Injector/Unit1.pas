{Автор - Зорков Игорь - zorkovigor@mail.ru

Пример инжекта DLL в Windows 2000, 2003, XP, Vista, Server, 7 включая системные процессы

В XP sp3 что бы инжектироваться в процессы NETWORK SERVICE и LOCAL_SERVICE dll должна быть в папке :\windows/system32}

unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, TlHelp32, Buttons, StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Edit1: TEdit;
    SpeedButton1: TSpeedButton;
    OpenDialog1: TOpenDialog;
    Label1: TLabel;
    Label2: TLabel;
    Edit2: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

function GetOSVersion: Cardinal;
var
  OSVersionInfo: TOSVersionInfo;
begin
  Result := 0;
  FillChar(OSVersionInfo, Sizeof(OSVersionInfo), 0);
  OSVersionInfo.dwOSVersionInfoSize := SizeOf(OSVersionInfo);
  if GetVersionEx(OSVersionInfo) then
  begin
    if OSVersionInfo.dwPlatformId = VER_PLATFORM_WIN32_NT then
    begin
      if OSVersionInfo.dwMajorVersion = 5 then
      begin
        if OSVersionInfo.dwMinorVersion = 0 then
          Result := 50//2000
        else if OSVersionInfo.dwMinorVersion = 2 then
          Result := 52//2003
        else if OSVersionInfo.dwMinorVersion = 1 then
          Result := 51//XP
      end;
      if OSVersionInfo.dwMajorVersion = 6 then
      begin
        if OSVersionInfo.dwMinorVersion = 0 then
          Result := 60//Vista, Server 2008
        else if OSVersionInfo.dwMinorVersion = 1 then
          Result := 61;//7
      end;
    end;
  end;
end;

function EnablePrivilege(Privilege: string): Boolean;
var
  TokenHandle: THandle;
  TokenPrivileges: TTokenPrivileges;
  ReturnLength: Cardinal;
begin
  Result := False;
  if Windows.OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, TokenHandle) then
  begin
    try
      LookupPrivilegeValue(nil, PAnsiChar(Privilege), TokenPrivileges.Privileges[0].Luid);
      TokenPrivileges.PrivilegeCount := 1;
      TokenPrivileges.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
      if AdjustTokenPrivileges(TokenHandle, False, TokenPrivileges, 0, nil, ReturnLength) then
        Result := True;
    finally
      CloseHandle(TokenHandle);
    end;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  EnablePrivilege('SeDebugPrivilege');
  Edit1.Text:= ExtractFilePath(ParamStr(0)) + 'A1_EMPTY.DLL';
  Edit2.Text:= IntToStr(GetCurrentProcessId);
end;

function IsModuleLoaded(ModulePath: PAnsiChar; ProcessID: DWORD): Boolean;
var
  hSnapshot: THandle;
  ModuleEntry32: TModuleEntry32;
begin
  Result := False;
  hSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, ProcessID);
  if (hSnapshot <> -1) then
  begin
    ModuleEntry32.dwSize := SizeOf(TModuleEntry32);
    if (Module32First(hSnapshot, ModuleEntry32)) then
      repeat
        if string(ModuleEntry32.szExePath) = string(ModulePath) then
        begin
          Result := True;
          Break;
        end;
      until
        not Module32Next(hSnapshot, ModuleEntry32);
    CloseHandle(hSnapshot);
  end;
end;

function InjectModule(ModulePath: PAnsiChar; ProcessID: DWORD): Boolean;
type
  TNtCreateThreadEx = function(
  ThreadHandle: PHANDLE;
  DesiredAccess: ACCESS_MASK;
  ObjectAttributes: Pointer;
  ProcessHandle: THANDLE;
  lpStartAddress: Pointer;
  lpParameter: Pointer;
  CreateSuspended: BOOL;
  dwStackSize: DWORD;
  Unknown1: Pointer;
  Unknown2: Pointer;
  Unknown3: Pointer): HRESULT; stdcall;
var
  lpStartAddress, lpParameter: Pointer;
  dwSize: Integer;
  hProcess, hThread, lpThreadId, lpExitCode, lpBytesWritten: Cardinal;
  NtCreateThreadEx: TNtCreateThreadEx;
begin
  Result := False;
  if IsModuleLoaded(ModulePath, ProcessID) = True then
    Exit;
  hProcess := 0;
  hProcess := OpenProcess(MAXIMUM_ALLOWED, False, ProcessID);
  if hProcess = 0 then
    Exit;
  dwSize := StrLen(ModulePath) + 1;
  lpParameter := VirtualAllocEx(hProcess, nil, dwSize, MEM_COMMIT, PAGE_READWRITE);
  if (lpParameter = nil) then
  begin
    if hProcess <> 0 then
      CloseHandle(hProcess);
    Exit;
  end;
  if GetOSVersion >= 60 then
    NtCreateThreadEx := GetProcAddress(GetModuleHandleW('ntdll'), 'NtCreateThreadEx');
  lpStartAddress := GetProcAddress(GetModuleHandleW('kernel32'), 'LoadLibraryA');
  if (lpStartAddress = nil) then
    Exit;
  if GetOSVersion >= 60 then
    if (@NtCreateThreadEx = nil) then
      Exit;
  lpBytesWritten := 0;
  if (WriteProcessMemory(hProcess, lpParameter, ModulePath, dwSize, lpBytesWritten) = False) then
  begin
    VirtualFreeEx(hProcess, lpParameter, 0, MEM_RELEASE);
    if hProcess <> 0 then
      CloseHandle(hProcess);
    Exit;
  end;
  hThread := 0;
  lpThreadId := 0;
  if GetOSVersion >= 60 then
    NtCreateThreadEx(@hThread, MAXIMUM_ALLOWED, nil, hProcess, lpStartAddress, lpParameter, false, 0, 0, 0, 0)
  else
    hThread := CreateRemoteThread(hProcess, nil, 0, lpStartAddress, lpParameter, 0, lpThreadId);
  if (hThread = 0) then
  begin
    VirtualFreeEx(hProcess, lpParameter, 0, MEM_RELEASE);
    CloseHandle(hProcess);
    Exit;
  end;
  GetExitCodeThread(hThread, lpExitCode);
  if hProcess <> 0 then
    CloseHandle(hProcess);
  if hThread <> 0 then
    CloseHandle(hThread);
  Result := True;
end;

function UnInjectModule(ModulePath: PAnsiChar; ProcessID: DWORD): Boolean;
type
  TNtCreateThreadEx = function(
  ThreadHandle: PHANDLE;
  DesiredAccess: ACCESS_MASK;
  ObjectAttributes: Pointer;
  ProcessHandle: THANDLE;
  lpStartAddress: Pointer;
  lpParameter: Pointer;
  CreateSuspended: BOOL;
  dwStackSize: DWORD;
  Unknown1: Pointer;
  Unknown2: Pointer;
  Unknown3: Pointer): HRESULT; stdcall;
var
  lpStartAddress, lpParameter: Pointer;
  hProcess, hThread, lpThreadId, lpExitCode: Cardinal;
  hSnapshot: THandle;
  ModuleEntry32: TModuleEntry32;
  NtCreateThreadEx: TNtCreateThreadEx;
begin
  Result := False;
  hSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, ProcessID);
  if (hSnapshot <> -1) then
  begin
    ModuleEntry32.dwSize := SizeOf(TModuleEntry32);
    if (Module32First(hSnapshot, ModuleEntry32)) then
      repeat
        if string(ModuleEntry32.szExePath) = string(ModulePath) then
        begin
          lpParameter := ModuleEntry32.modBaseAddr;
          Break;
        end;
      until
        not Module32Next(hSnapshot, ModuleEntry32);
    CloseHandle(hSnapshot);
  end;
  hProcess := 0;
  hProcess := OpenProcess(MAXIMUM_ALLOWED, False, ProcessID);
  if hProcess = 0 then
  begin
    Result := False;
    Exit;
  end;
  if GetOSVersion >= 60 then
    NtCreateThreadEx := GetProcAddress(GetModuleHandleW('ntdll'), 'NtCreateThreadEx');
  if GetOSVersion >= 60 then
    if (@NtCreateThreadEx = nil) then
      Exit;
  lpStartAddress := GetProcAddress(GetModuleHandleW('Kernel32'), 'FreeLibrary');
  if (lpStartAddress = nil) then
  begin
    if hProcess <> 0 then
      CloseHandle(hProcess);
    Result := False;
    Exit;
  end;
  hThread := 0;
  lpThreadId := 0;
  if GetOSVersion >= 60 then
    NtCreateThreadEx(@hThread, MAXIMUM_ALLOWED, nil, hProcess, lpStartAddress, lpParameter, False, 0, 0, 0, 0)
  else
    hThread := CreateRemoteThread(hProcess, nil, 0, lpStartAddress, lpParameter, 0, lpThreadId);
  if (hThread = 0) then
  begin
    if hProcess <> 0 then
      CloseHandle(hProcess);
    Result := False;
    Exit;
  end;
  GetExitCodeThread(hThread, lpExitCode);
  if hProcess <> 0 then
    CloseHandle(hProcess);
  if hThread <> 0 then
    CloseHandle(hThread);
  Result := True;
end;

procedure TForm1.SpeedButton1Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
    Edit1.Text:= OpenDialog1.FileName;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  InjectModule(PAnsiChar(Edit1.Text), StrToInt(Edit2.Text));
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  UnInjectModule(PAnsiChar(Edit1.Text), StrToInt(Edit2.Text));
end;

end.
 