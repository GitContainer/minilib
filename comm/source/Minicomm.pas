{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit MiniComm;

interface

uses
  mnCommClasses, mnCommStreams, mnCommThreads, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('MiniComm', @Register);
end.
