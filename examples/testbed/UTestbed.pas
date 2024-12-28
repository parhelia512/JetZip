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

===============================================================================}

unit UTestbed;

interface

procedure RunTests();

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  jetZip;

const
  CZipFilename = 'Data.zip';

procedure Pause();
begin
  WriteLn;
  Write('Press ENTER to continue...');
  ReadLn;
  WriteLn;
end;

// Build progress event handler
procedure BuildProgress(const ASender: Pointer; const AFilename: string; const AProgress: Integer; const ANewFile: Boolean);
begin
  if aNewFile then WriteLn;
  Write(Format(#13+'Adding %s(%d%s)...', [ExtractFileName(string(aFilename)), aProgress, '%']));
end;

procedure Test01();
var
  LZip: TJetZip;
begin
  // Ceare a JetZip instance
  LZip := TJetZip.Create();
  try
    // Create a zip archive from the files in specified folder
    // Call the build progress event handler to display build progress
    if LZip.Build(CZipFilename, 'res', nil, BuildProgress) then
      WriteLn(#10+'Success!')
    else
      WriteLn(#10+'Failed!');
  finally
    // Close zip archive and free instance
    LZip.Free();
  end;
end;

procedure Test02();
var
  LZip: TJetZip;
  LFile: TFileStream;
  LBuffer: array[0..1024] of Byte;
  LBytesRead: Int64;
begin
  // Remove extracted file
  if TFile.Exists('jetzip.png') then
    TFile.Delete('jetzip.png');

  // Create a JetZip instance
  LZip := TJetZip.Create();
  try
    // Open file inside zip archive
    if LZip.Open(CZipFilename, 'res/jetzip.png') then
    begin

      // Create new exteranl file for extraction
      WriteLn('Saving image "jetzip.png"...');
      LFile := TFile.Create('jetzip.png');
      try
        // Seek to start of zip entry
        LZip.Seek(0, smStart);

        // Loop until EOF is reached
        while not LZip.Eos() do
        begin
          // Read in enough bytes to full buffer
          LBytesRead := LZip.Read(@LBuffer[0], Length(LBuffer));

          // Write to extracted file the number of bytes read
          LFile.Write(LBuffer, LBytesRead);
        end;

        // Check of extracted file exist
        if TFile.Exists('jetzip.png') then
          WriteLn('Extracted image "jetzip.png"!')
        else
          WriteLn('Failed to extract image "jetzip.png"!');

      finally
        // Close extracted file and free object instance
        LFile.Free();
      end;
    end;
  finally
    // Close zip archive and free object instance
    LZip.Free();
  end;
end;

procedure RunTests();
var
  LNum: Integer;
begin
  LNum := 01;

  case LNum of
    01: Test01();
    02: Test02();
  end;

  Pause();
end;

end.
