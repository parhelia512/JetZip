{===============================================================================
     _       _    ____ _
  _ | | ___ | |_ |_  /(_) _ __ ™
 | || |/ -_)|  _| / / | || '_ \
  \__/ \___| \__|/___||_|| .__/
                         |_|
   Zip It Fast, Zip It Easy!

 Copyright © 2024-present tinyBigGAMES™ LLC
 All Rights Reserved.

 https://github.com/tinyBigGAMES/JetZip

 BSD 3-Clause License

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

 3. Neither the name of the copyright holder nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.

 ------------------------------------------------------------------------------
 This project uses the following open-source libraries:
  - zlib (https://github.com/madler/zlib)

 ------------------------------------------------------------------------------

 JetZip Usage Notes
 ===================

 ------------------------------------------------------------------------------

>>> CHANGELOG <<<

Version 0.1.0
-------------
  - Initial release.

===============================================================================}

unit JetZip;

{$IF CompilerVersion >= 36.0}
  // Code specific to Delphi Athens (12.2) and above
{$ELSE}
  {$MESSAGE ERROR 'This code requires  Delphi Athens (12.2) or later'}
{$IFEND}

{$IFNDEF WIN64}
  // Generates a compile-time error if the target platform is not Win64
  {$MESSAGE Error 'Unsupported platform'}
{$ENDIF}

{$Z4}  // Sets the enumeration size to 4 bytes
{$A8}  // Sets the alignment for record fields to 8 bytes

{$WARN SYMBOL_DEPRECATED OFF}
{$WARN SYMBOL_PLATFORM OFF}

{$WARN UNIT_PLATFORM OFF}
{$WARN UNIT_DEPRECATED OFF}

interface

uses
  WinApi.Windows,
  System.Types,
  System.SysUtils,
  System.Classes,
  System.IOUtils;

/// <summary>
/// Specifies the current version of the <c>TjetZip</c> library.
/// </summary>
/// <remarks>
/// The version follows semantic versioning format: <c>MAJOR.MINOR.PATCH</c>.
/// <list type="bullet">
///   <item>
///     <term>MAJOR</term>
///     <description>Indicates significant changes or incompatible API updates.</description>
///   </item>
///   <item>
///     <term>MINOR</term>
///     <description>Indicates new features that are backward-compatible.</description>
///   </item>
///   <item>
///     <term>PATCH</term>
///     <description>Indicates bug fixes or incremental improvements.</description>
///   </item>
/// </list>
/// This value is helpful for debugging, logging, or version checks during runtime.
/// </remarks>
/// <example>
/// <code lang="Delphi">
/// if JETZIP_VERSION <> '0.1.0' then
///   raise Exception.Create('Unsupported library version');
/// </code>
/// </example>
const
  JETZIP_VERSION = '0.1.0';

type
/// <summary>
/// The <c>TjetZip</c> class provides a comprehensive interface for managing ZIP files, including
/// opening, reading, writing, and creating archives. It supports password protection and allows
/// efficient handling of large files within ZIP archives.
/// </summary>
/// <remarks>
/// <para>The <c>TjetZip</c> class is designed to be a utility for developers who need to interact
/// with ZIP archives programmatically. It provides methods to open individual files within a ZIP
/// archive, read their contents, and perform seek operations for random access.</para>
/// <para>Additionally, the class supports creating ZIP archives from directories, with an optional
/// event-based mechanism to track progress. The archives can be password-protected for added security.</para>
/// <para>The class includes built-in buffer management to optimize I/O performance and minimize memory
/// allocations during operations.</para>
/// </remarks>
/// <example>
/// <code lang="Delphi">
/// var
///   LJetZip: TjetZip;
///   LData: array[0..1023] of Byte;
///   LBytesRead: Int64;
/// begin
///   LJetZip := TjetZip.Create;
///   try
///     if LJetZip.Open('example.zip', 'file.txt') then
///     begin
///       LBytesRead := LJetZip.Read(@LData[0], Length(LData));
///       // Process the data
///       LJetZip.Close;
///     end;
///   finally
///     LJetZip.Free;
///   end;
/// end;
/// </code>
/// </example>
{ TjetZip }
TJetZip = class
protected const
  /// <summary>
  /// Specifies the size of the temporary static buffer, used internally for data manipulation and
  /// buffering during ZIP file operations. The buffer size is optimized for performance and minimizes
  /// repeated memory allocations.
  /// </summary>
  CTempStaticBufferSize = 1024 * 4;
protected
  /// <summary>
  /// A static array of bytes serving as a temporary buffer for data operations. This buffer is
  /// used internally by the class to optimize I/O operations by reducing frequent memory allocations.
  /// </summary>
  FTempStaticBuffer: array[0..CTempStaticBufferSize - 1] of Byte;

  /// <summary>
  /// A pointer representing the handle to the underlying ZIP file implementation.
  /// This handle is managed internally and should not be modified directly.
  /// </summary>
  FHandle: Pointer;

  /// <summary>
  /// Stores the password associated with the currently open ZIP archive. This password is
  /// required for accessing files within password-protected ZIP archives.
  /// </summary>
  FPassword: AnsiString;

  /// <summary>
  /// Holds the name of the currently open ZIP file. This is useful for logging or debugging
  /// purposes when working with multiple ZIP files.
  /// </summary>
  FFilename: AnsiString;

  /// <summary>
  /// Retrieves the size of the temporary static buffer. This method is useful for debugging
  /// or monitoring buffer usage within the class.
  /// </summary>
  /// <returns>The size of the static buffer in bytes, as a 64-bit unsigned integer.</returns>
  function GetTempStaticBufferSize(): UInt64;

  /// <summary>
  /// Provides a direct pointer to the temporary static buffer. This is used internally
  /// to perform read and write operations efficiently.
  /// </summary>
  /// <returns>A pointer to the start of the static buffer.</returns>
  function GetTempStaticBuffer(): Pointer;

public const
  /// <summary>
  /// Defines a default password used for opening and creating ZIP files when no password
  /// is explicitly specified.
  /// </summary>
  DefaultPassword = 'nt%;L}-!F&{ZVhE3u/@GR.gVa?642TKrL>+fPZ$9G[wCq[Q7?Ft,P]Rmc=W3$C}Xugev~9#Ln;Z)KA3>]NV&y(Cz';

public type
  /// <summary>
  /// Enumerates the modes available for seeking within a file inside a ZIP archive. These modes
  /// allow flexible navigation to specific positions relative to the start, current position,
  /// or end of the file.
  /// </summary>
  SeekMode = (smStart, smCurrent, smEnd);

  /// <summary>
  /// Represents the prototype for the event handler that tracks progress during the creation of
  /// a ZIP archive. This allows for real-time feedback on the progress of file addition.
  /// </summary>
  /// <param name="ASender">A pointer to the object initiating the event, typically the current
  /// instance of <c>TjetZip</c>.</param>
  /// <param name="AFilename">The name of the file currently being processed.</param>
  /// <param name="AProgress">The progress percentage (0 to 100) indicating the completion
  /// of the current file addition.</param>
  /// <param name="ANewFile">A boolean indicating whether the file currently being processed is
  /// a new file in the ZIP archive.</param>
  BuildProgressEvent = procedure(const ASender: Pointer;
    const AFilename: string; const AProgress: Integer; const ANewFile: Boolean);

public
  /// <summary>
  /// Initializes a new instance of the <c>TjetZip</c> class. The constructor sets up internal
  /// structures and prepares the instance for ZIP file operations.
  /// </summary>
  constructor Create(); virtual;

  /// <summary>
  /// Releases the resources used by the <c>TjetZip</c> instance. This includes closing any
  /// open ZIP files and freeing associated memory.
  /// </summary>
  destructor Destroy(); override;

  /// <summary>
  /// Opens a specific file within a ZIP archive for reading. If the file is password-protected,
  /// the password must be provided. This method sets up internal structures for sequential or
  /// random access to the file's data.
  /// </summary>
  /// <param name="AZipFilename">The full path to the ZIP file to open.</param>
  /// <param name="AFilename">The name of the file within the ZIP archive to access.</param>
  /// <param name="APassword">The password to use for accessing the ZIP file. Defaults to
  /// <c>DefaultPassword</c> if not provided.</param>
  /// <returns><c>True</c> if the file was successfully opened; otherwise, <c>False</c>.</returns>
  function Open(const AZipFilename, AFilename: string;
    const APassword: string = TJetZip.DefaultPassword): Boolean;

  /// <summary>
  /// Checks if a ZIP file is currently open. This is useful for verifying the state of the instance
  /// before performing operations such as reading or seeking.
  /// </summary>
  /// <returns><c>True</c> if a ZIP file is open; otherwise, <c>False</c>.</returns>
  function IsOpen(): Boolean;

  /// <summary>
  /// Closes the currently open ZIP file and releases associated resources. After calling this
  /// method, the instance can be used to open another ZIP file.
  /// </summary>
  procedure Close();

  /// <summary>
  /// Retrieves the size of the currently open file within the ZIP archive. This method provides
  /// the total size of the file in bytes.
  /// </summary>
  /// <returns>The size of the file as a 64-bit signed integer.</returns>
  function Size(): Int64;

  /// <summary>
  /// Navigates to a specified position within the currently open file. The position is determined
  /// based on the provided offset and seek mode.
  /// </summary>
  /// <param name="AOffset">The offset to seek to, relative to the seek mode.</param>
  /// <param name="ASeek">The seek mode, indicating whether the offset is relative to the start,
  /// current position, or end of the file.</param>
  /// <returns>The new position within the file after seeking, as a 64-bit signed integer.</returns>
  function Seek(const AOffset: Int64; const ASeek: SeekMode): Int64;

  /// <summary>
  /// Reads a specified number of bytes from the currently open file into a provided buffer. This method
  /// supports efficient sequential and random access reading.
  /// </summary>
  /// <param name="AData">A pointer to the buffer where the data will be stored.</param>
  /// <param name="ASize">The number of bytes to read from the file.</param>
  /// <returns>The actual number of bytes read, which may be less than <c>ASize</c> if the end of
  /// the file is reached.</returns>
  function Read(const AData: Pointer; const ASize: Int64): Int64;

  /// <summary>
  /// Retrieves the current position within the file. This position is zero-based and represents
  /// the number of bytes from the start of the file.
  /// </summary>
  /// <returns>The current position as a 64-bit signed integer.</returns>
  function Pos(): Int64;

  /// <summary>
  /// Determines if the end of the file (EOF) has been reached. This method is useful for
  /// checking whether further reading operations can be performed.
  /// </summary>
  /// <returns><c>True</c> if the end of the file has been reached; otherwise, <c>False</c>.</returns>
  function Eos(): Boolean;

  /// <summary>
  /// Creates a new ZIP archive from the contents of a specified directory. Progress can be
  /// tracked through an optional event handler.
  /// </summary>
  /// <param name="AZipFilename">The name of the ZIP archive to create.</param>
  /// <param name="ADirectoryName">The directory whose contents will be added to the ZIP archive.</param>
  /// <param name="ASender">An optional pointer to the object initiating the operation, used for
  /// event tracking.</param>
  /// <param name="AHandler">An optional event handler to track progress during the operation.</param>
  /// <param name="APassword">An optional password for securing the archive. Defaults to
  /// <c>DefaultPassword</c>.</param>
  /// <returns><c>True</c> if the archive was successfully created; otherwise, <c>False</c>.</returns>
  function Build(const AZipFilename, ADirectoryName: string;
    const ASender: Pointer = nil;
    const AHandler: TJetZip.BuildProgressEvent = nil;
    const APassword: string = DefaultPassword): Boolean;
end;

implementation

{$L JetZip.o}

{$REGION ' MINIZIP '}
const
  Z_ERRNO                   = -1;
  Z_OK                      = 0;
  Z_DEFLATED                = 8;
  Z_DEFAULT_STRATEGY        = 0;

  ZIP_OK                    = (0);
  ZIP_EOF                   = (0);
  ZIP_ERRNO                 = (Z_ERRNO);
  ZIP_PARAMERROR            = (-102);
  ZIP_BADZIPFILE            = (-103);
  ZIP_INTERNALERROR         = (-104);

  UNZ_OK                    = (0);
  UNZ_END_OF_LIST_OF_FILE   = (-100);
  UNZ_ERRNO                 = (Z_ERRNO);
  UNZ_EOF                   = (0);
  UNZ_PARAMERROR            = (-102);
  UNZ_BADZIPFILE            = (-103);
  UNZ_INTERNALERROR         = (-104);
  UNZ_CRCERROR              = (-105);

  APPEND_STATUS_CREATE      = (0);
  APPEND_STATUS_CREATEAFTER = (1);
  APPEND_STATUS_ADDINZIP    = (2);

type
  Ptm_zip_s          = ^tm_zip_s;
  Pzip_fileinfo      = ^zip_fileinfo;
  Ptm_unz_s          = ^tm_unz_s;
  Punz_file_info64_s = ^unz_file_info64_s;

  voidp              = Pointer;
  unzFile            = voidp;
  zipFile            = voidp;

  uInt               = Cardinal;
  uLong              = Longword;
  Bytef              = &Byte;
  PBytef             = ^Bytef;

  tm_zip_s = record
    tm_sec: Integer;
    tm_min: Integer;
    tm_hour: Integer;
    tm_mday: Integer;
    tm_mon: Integer;
    tm_year: Integer;
  end;

  tm_zip = tm_zip_s;

  zip_fileinfo = record
    tmz_date: tm_zip;
    dosDate: uLong;
    internal_fa: uLong;
    external_fa: uLong;
  end;

  tm_unz_s = record
    tm_sec: Integer;
    tm_min: Integer;
    tm_hour: Integer;
    tm_mday: Integer;
    tm_mon: Integer;
    tm_year: Integer;
  end;

  tm_unz = tm_unz_s;

  unz_file_info64_s = record
    version: uLong;
    version_needed: uLong;
    flag: uLong;
    compression_method: uLong;
    dosDate: uLong;
    crc: uLong;
    compressed_size: UInt64;
    uncompressed_size: UInt64;
    size_filename: uLong;
    size_file_extra: uLong;
    size_file_comment: uLong;
    disk_num_start: uLong;
    internal_fa: uLong;
    external_fa: uLong;
    tmu_date: tm_unz;
  end;

  unz_file_info64 = unz_file_info64_s;
  Punz_file_info64 = ^unz_file_info64;

function crc32(crc: uLong; const buf: PBytef; len: uInt): uLong; cdecl; external;
function unzOpen64(const path: Pointer): unzFile; cdecl; external;
function unzLocateFile(&file: unzFile; const szFileName: PUTF8Char;
  iCaseSensitivity: Integer): Integer; cdecl; external;
function unzClose(&file: unzFile): Integer; cdecl; external;
function unzOpenCurrentFilePassword(&file: unzFile;
  const password: PUTF8Char): Integer; cdecl; external;
function unzGetCurrentFileInfo64(&file: unzFile; pfile_info: Punz_file_info64;
  szFileName: PUTF8Char; fileNameBufferSize: uLong; extraField: Pointer;
  extraFieldBufferSize: uLong; szComment: PUTF8Char;
  commentBufferSize: uLong): Integer; cdecl; external;
function unzReadCurrentFile(&file: unzFile; buf: voidp;
  len: Cardinal): Integer; cdecl; external;
function unzCloseCurrentFile(&file: unzFile): Integer; cdecl; external;
function unztell64(&file: unzFile): UInt64; cdecl; external;
function zipOpen64(const pathname: Pointer;
  append: Integer): zipFile; cdecl; external;
function zipOpenNewFileInZip3_64(&file: zipFile; const filename: PUTF8Char;
  const zipfi: Pzip_fileinfo; const extrafield_local: Pointer;
  size_extrafield_local: uInt; const extrafield_global: Pointer;
  size_extrafield_global: uInt; const comment: PUTF8Char; method: Integer;
  level: Integer; raw: Integer; windowBits: Integer; memLevel: Integer;
  strategy: Integer; const password: PUTF8Char; crcForCrypting: uLong;
  zip64: Integer): Integer; cdecl; external;
function zipWriteInFileInZip(&file: zipFile; const buf: Pointer;
  len: Cardinal): Integer; cdecl; external;
function zipCloseFileInZip(&file: zipFile): Integer; cdecl; external;
function zipClose(&file: zipFile;
  const global_comment: PUTF8Char): Integer; cdecl; external;
{$ENDREGION}

{$REGION ' JETZIP ' }
function TJetZip.GetTempStaticBufferSize(): UInt64;
begin
  Result := CTempStaticBufferSize;
end;

function TJetZip.GetTempStaticBuffer(): Pointer;
begin
  Result := @FTempStaticBuffer[0]
end;

constructor TJetZip.Create();
begin
  inherited;
end;

destructor TJetZip.Destroy();
begin
  inherited;
end;

function TJetZip.Open(const AZipFilename, AFilename: string; const APassword: string): Boolean;
var
  LPassword: PAnsiChar;
  LZipFilename: PAnsiChar;
  LFilename: PAnsiChar;
  LFile: unzFile;
begin
  Result := False;

  LPassword := PAnsiChar(AnsiString(APassword));
  LZipFilename := PAnsiChar(AnsiString(StringReplace(string(AZipFilename), '/', '\', [rfReplaceAll])));
  LFilename := PAnsiChar(AnsiString(StringReplace(string(AFilename), '/', '\', [rfReplaceAll])));

  LFile := unzOpen64(LZipFilename);
  if not Assigned(LFile) then Exit;

  if unzLocateFile(LFile, LFilename, 0) <> UNZ_OK then
  begin
    unzClose(LFile);
    Exit;
  end;

  if unzOpenCurrentFilePassword(LFile, LPassword) <> UNZ_OK then
  begin
    unzClose(LFile);
    Exit;
  end;

  FHandle := LFile;
  FPassword := LPassword;
  FFilename := LFilename;

  Result := True;
end;

function  TJetZip.IsOpen(): Boolean;
begin
  Result := Assigned(FHandle);
end;

procedure TJetZip.Close();
begin
  if not Assigned(FHandle) then Exit;

  Assert(unzCloseCurrentFile(FHandle) = UNZ_OK);
  Assert(unzClose(FHandle) = UNZ_OK);
  FHandle := nil;
end;

function  TJetZip.Size(): Int64;
var
  LInfo: unz_file_info64;
begin
  Result := -1;
  if not Assigned(FHandle) then Exit;

  unzGetCurrentFileInfo64(FHandle, @LInfo, nil, 0, nil, 0, nil, 0);
  Result := LInfo.uncompressed_size;
end;

function  TJetZip.Seek(const AOffset: Int64; const ASeek: SeekMode): Int64;
var
  LFileInfo: unz_file_info64;
  LCurrentOffset, LBytesToRead: UInt64;
  LOffset: Int64;

  procedure SeekToLoc;
  begin
    LBytesToRead := UInt64(LOffset) - unztell64(FHandle);
    while LBytesToRead > 0 do
    begin
      if LBytesToRead > GetTempStaticBufferSize() then
        unzReadCurrentFile(FHandle, GetTempStaticBuffer(), GetTempStaticBufferSize())
      else
        unzReadCurrentFile(FHandle, GetTempStaticBuffer(), LBytesToRead);

      LBytesToRead := UInt64(LOffset) - unztell64(FHandle);
    end;
  end;
begin
  Result := -1;
  if not Assigned(FHandle) then Exit;

  if (FHandle = nil) or (unzGetCurrentFileInfo64(FHandle, @LFileInfo, nil, 0, nil, 0, nil, 0) <> UNZ_OK) then
  begin
    Exit;
  end;

  LOffset := AOffset;

  LCurrentOffset := unztell64(FHandle);
  if LCurrentOffset = -1 then Exit;

  case ASeek of
    // offset is already relative to the start of the file
    smStart: ;

    // offset is relative to current position
    smCurrent: Inc(LOffset, LCurrentOffset);

    // offset is relative to end of the file
    smEnd: Inc(LOffset, LFileInfo.uncompressed_size);
  else
    Exit;
  end;

  if LOffset < 0 then Exit

  else if AOffset > LCurrentOffset then
    begin
      SeekToLoc();
    end
  else // offset < current_offset
    begin
      unzCloseCurrentFile(FHandle);
      unzLocateFile(FHandle, PAnsiChar(FFilename), 0);
      unzOpenCurrentFilePassword(FHandle, PAnsiChar(FPassword));
      SeekToLoc();
    end;

  Result := unztell64(FHandle);
end;

function  TJetZip.Read(const AData: Pointer; const ASize: Int64): Int64;
begin
  Result := -1;
  if not Assigned(FHandle) then Exit;

  Result := unzReadCurrentFile(FHandle, AData, ASize);
end;

function  TJetZip.Pos(): Int64;
begin
  Result := -1;
  if not Assigned(FHandle) then Exit;

  Result := unztell64(FHandle);
end;

function  TJetZip.Eos(): Boolean;
begin
  Result := False;
  if not Assigned(FHandle) then Exit;

  Result := Boolean(Pos() >= Size());
end;

procedure TZipFileIO_BuildProgress(const ASender: Pointer; const AFilename: string; const AProgress: Integer; const ANewFile: Boolean);
begin
  if aNewFile then WriteLn;
  Write(Format(#13+'Adding %s(%d%s)...', [ExtractFileName(string(aFilename)), aProgress, '%']));
end;

function TJetZip.Build(const AZipFilename, ADirectoryName: string; const ASender: Pointer; const AHandler: TJetZip.BuildProgressEvent; const APassword: string): Boolean;
var
  LFileList: TStringDynArray;
  LArchive: PAnsiChar;
  LFilename: string;
  LFilename2: PAnsiChar;
  LPassword: PAnsiChar;
  LZipFile: zipFile;
  LZipFileInfo: zip_fileinfo;
  LFile: System.Classes.TStream;
  LCrc: Cardinal;
  LBytesRead: Integer;
  LFileSize: Int64;
  LProgress: Single;
  LNewFile: Boolean;
  LHandler: BuildProgressEvent;
  LSender: Pointer;

  function GetCRC32(aStream: System.Classes.TStream): uLong;
  var
    LBytesRead: Integer;
    LBuffer: array of Byte;
  begin
    Result := crc32(0, nil, 0);
    repeat
      LBytesRead := AStream.Read(GetTempStaticBuffer()^, GetTempStaticBufferSize());
      Result := crc32(Result, PBytef(GetTempStaticBuffer()), LBytesRead);
    until LBytesRead = 0;

    LBuffer := nil;
  end;
begin
  Result := False;

  // check if directory exists
  if not TDirectory.Exists(ADirectoryName) then Exit;

  // init variabls
  FillChar(LZipFileInfo, SizeOf(LZipFileInfo), 0);

  // scan folder and build file list
  LFileList := TDirectory.GetFiles(ADirectoryName, '*',
    TSearchOption.soAllDirectories);

  LArchive := PAnsiChar(AnsiString(AZipFilename));
  LPassword := PAnsiChar(AnsiString(APassword));

  // create a zip file
  LZipFile := zipOpen64(LArchive, APPEND_STATUS_CREATE);

  // init handler
  LHandler := AHandler;
  LSender := ASender;

  if not Assigned(LHandler) then
    LHandler := TZipFileIO_BuildProgress;

  // process zip file
  if LZipFile <> nil then
  begin
    // loop through all files in list
    for LFilename in LFileList do
    begin
      // open file
      LFile := TFile.OpenRead(LFilename);

      // get file size
      LFileSize := LFile.Size;

      // get file crc
      LCrc := GetCRC32(LFile);

      // open new file in zip
      LFilename2 := PAnsiChar(AnsiString(LFilename));
      if ZipOpenNewFileInZip3_64(LZipFile, LFilename2, @LZipFileInfo, nil, 0,
        nil, 0, '',  Z_DEFLATED, 9, 0, 15, 9, Z_DEFAULT_STRATEGY,
        LPassword, LCrc, 1) = Z_OK then
      begin
        // make sure we start at star of stream
        LFile.Position := 0;

        LNewFile := True;

        // read through file
        repeat
          // read in a buffer length of file
          LBytesRead := LFile.Read(GetTempStaticBuffer()^, GetTempStaticBufferSize());

          // write buffer out to zip file
          zipWriteInFileInZip(LZipFile, GetTempStaticBuffer(), LBytesRead);

          // calc file progress percentage
          LProgress := 100.0 * (LFile.Position / LFileSize);

          // show progress
          if Assigned(LHandler) then
          begin
            LHandler(LSender, LFilename, Round(LProgress), LNewFile);
          end;

          LNewFile := False;

        until LBytesRead = 0;

        // close file in zip
        zipCloseFileInZip(LZipFile);

        // free file stream
        LFile.Free;
      end;
    end;

    // close zip file
    zipClose(LZipFile, '');
  end;

  // return true if new zip file exits
  Result := TFile.Exists(LFilename);
end;

{$ENDREGION}

{$REGION ' CRUNTIME '}
const
  kernel32 = 'kernel32.dll';
  ucrt = 'api-ms-win-crt-stdio-l1-1-0.dll';

{ kenerl32}
procedure ___chkstk_ms; stdcall; external kernel32 name '__chkstk';

{ ucrt }
procedure _ftelli64; cdecl; external ucrt;
procedure _fseeki64; cdecl; external ucrt;
procedure memmove; cdecl; external ucrt;
procedure malloc; cdecl; external ucrt;
procedure memset; cdecl; external ucrt;
procedure __intrinsic_setjmpex; cdecl; external ucrt;
procedure _time64; cdecl; external ucrt;
procedure strcmp; cdecl; external ucrt;
procedure memcpy; external ucrt;
procedure strchr; cdecl; external ucrt;
procedure longjmp; cdecl; external ucrt;
procedure strcpy; cdecl; external ucrt;
procedure _errno; cdecl; external ucrt;
procedure strerror; cdecl; external ucrt;
procedure fopen; cdecl; external ucrt;
procedure ferror; cdecl; external ucrt;
procedure fclose; cdecl; external ucrt;
procedure fread; cdecl; external ucrt;
procedure realloc; cdecl; external ucrt;
procedure free; cdecl; external ucrt;
procedure fwrite; cdecl; external ucrt;
procedure memchr; cdecl; external ucrt;
procedure fseek; cdecl; external ucrt;
procedure ftell; cdecl; external ucrt;
procedure clock; cdecl; external ucrt;
procedure rand; cdecl; external ucrt;
procedure srand; cdecl; external ucrt;
procedure fopen64; cdecl; external ucrt name 'fopen';
procedure lseek; cdecl; external ucrt;
procedure open; cdecl; external ucrt;
procedure wcstombs; cdecl; external ucrt;
procedure _wopen; cdecl; external ucrt;
procedure write; cdecl; external ucrt;
procedure close; cdecl; external ucrt;
procedure read; cdecl; external ucrt;

{ ucrt_extra }
procedure snprintf; cdecl; external name 'ucrt_extra_snprintf';
procedure vsnprintf; cdecl; external name 'ucrt_extra_vsnprintf';
{$ENDREGION}

end.
