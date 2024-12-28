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

program Testbed;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  JetZip in '..\..\src\JetZip.pas',
  UTestbed in 'UTestbed.pas';

begin
  try
    RunTests();
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
