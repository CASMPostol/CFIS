(*.F- *)
(**********************************************************************
|  Title   : DGH.INI reader
|  Author  : R. Maleck
|  System  : LOGITECH MODULA-2/86
|  History :
|    12-09-96:M.Postol
|      SwitchCntrl do sterowania przelacznikow przybyl
|    04-10-95: M.Postol
|      inicjacja nowego pola locErrorCnd   
|    07-02-97: M.Postol
|      zmodyfikowalem ReadDGHIniFile, by bala nizalezna od kolejnosci w typie 
|      wyliczeniowym 
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE DGHIni;

  FROM SYSTEM IMPORT
    ADR, SIZE;

  FROM Ini IMPORT
    GetPrivateProfileString;

  FROM Strings IMPORT
    CompareStr;

  FROM BlockOps IMPORT
    BlockClear;

  CONST
    FileName = "DGH.INI";  (* nazwa pliku z danymi o modulach DGH *)

  TYPE
    TblNames =
      ARRAY SignalNames OF ARRAY [ 0 .. 20 ] OF CHAR;

  CONST
    AIWP  =  8;
    AOWP  =  0; (* bylo 24, po przeniesieniu na koniec nie czeba czekac *)
    DIWP  =  8;
    DOWP  =  7;
    
  VAR
    TableOfNames : TblNames;
    SignalDescr  : SignalDsc;


  PROCEDURE InitTableOfNames();
    (* Procedura inicjuje tablice (indeksowana nazwami sygnalow) nazw sygnalow
    *)

  BEGIN
    TableOfNames[MODforLOCa] := "MODforLOCa";
    TableOfNames[MODforGSa] := "MODforGSa";
    TableOfNames[VARa] := "VARa";
    TableOfNames[REFa] := "REFa";
    TableOfNames[SUBCARa] := "SUBCARa";
    TableOfNames[AGCforNAVa] := "AGCforNAVa";
    TableOfNames[AGCforGSa] := "AGCforGSa";
    TableOfNames[AGCforMKRa] := "AGCforMKRa";
    TableOfNames[AGCforDMEa] := "AGCforDMEa";
    TableOfNames[SQUITTERforDMEa] := "SQUITTERforDMEa";
    TableOfNames[REPLYforDMEa] := "REPLYforDMEa";
    TableOfNames[AGCforADFa] := "AGCforADFa";
    TableOfNames[AGCforCOMa] := "AGCforCOMa";
    TableOfNames[SINforADFa] := "SINforADFa";
    TableOfNames[COSforADFa] := "COSforADFa";
    TableOfNames[OutMKRa] := "OutMKRa";
    TableOfNames[MidMKRa] := "MidMKRa";
    TableOfNames[InnMKRa] := "InnMKRa";
    TableOfNames[SFLGforNAVa] := "SFLGforNAVa";
    TableOfNames[SFLGforGSa] := "SFLGforGSa";
    TableOfNames[NAVaAudio] := "NAVaAudio";
    TableOfNames[DMEaAudio] := "DMEaAudio";
    TableOfNames[ADFaAudio] := "ADFaAudio";
    TableOfNames[COMaAudio] := "COMaAudio";
    TableOfNames[DME_MEMa] := "DME_MEMa";
    TableOfNames[DME_SRCa] := "DME_SRCa";
    TableOfNames[MODforLOCb] := "MODforLOCb";
    TableOfNames[MODforGSb] := "MODforGSb";
    TableOfNames[VARb] := "VARb";
    TableOfNames[REFb] := "REFb";
    TableOfNames[SUBCARb] := "SUBCARb";
    TableOfNames[AGCforNAVb] := "AGCforNAVb";
    TableOfNames[AGCforGSb] := "AGCforGSb";
    TableOfNames[AGCforMKRb] := "AGCforMKRb";
    TableOfNames[AGCforDMEb] := "AGCforDMEb";
    TableOfNames[SQUITTERforDMEb] := "SQUITTERforDMEb";
    TableOfNames[REPLYforDMEb] := "REPLYforDMEb";
    TableOfNames[AGCforADFb] := "AGCforADFb";
    TableOfNames[AGCforCOMb] := "AGCforCOMb";
    TableOfNames[SINforADFb] := "SINforADFb";
    TableOfNames[COSforADFb] := "COSforADFb";
    TableOfNames[OutMKRb] := "OutMKRb";
    TableOfNames[MidMKRb] := "MidMKRb";
    TableOfNames[InnMKRb] := "InnMKRb";
    TableOfNames[SFLGforNAVb] := "SFLGforNAVb";
    TableOfNames[SFLGforGSb] := "SFLGforGSb";
    TableOfNames[NAVbAudio] := "NAVbAudio";
    TableOfNames[DMEbAudio] := "DMEbAudio";
    TableOfNames[ADFbAudio] := "ADFbAudio";
    TableOfNames[DME_MEMb] := "DME_MEMb";
    TableOfNames[DME_SRCb] := "DME_SRCb";
    TableOfNames[DMEDistanceA] := "DMEDistanceA";
    TableOfNames[DMEDistanceB] := "DMEDistanceB";
    TableOfNames[Altimeter] := "Altimeter";
    TableOfNames[CockpitCPLOCNeedle] := "CockpitCPLOCNeedle";
    TableOfNames[CockpitCPGSNeedle] := "CockpitCPGSNeedle";
    TableOfNames[ConsoleCPLOCNeedle] := "ConsoleCPLOCNeedle";
    TableOfNames[ConsoleCPGSNeedle] := "ConsoleCPGSNeedle";
    TableOfNames[CockpitDisplaySP] := "CockpitDisplaySP";
    TableOfNames[CockpitDisplayD1] := "CockpitDisplayD1";
    TableOfNames[CockpitDisplayD2] := "CockpitDisplayD2";
    TableOfNames[CockpitDisplayD3] := "CockpitDisplayD3";
    TableOfNames[CockpitDisplayD4] := "CockpitDisplayD4";
    TableOfNames[CockpitDisplayMsg] := "CockpitDisplayMsg";
    TableOfNames[NAVaON] := "NAVaON";
    TableOfNames[NAVbON] := "NAVbON";
    TableOfNames[ILSaEnergize] := "ILSaEnergize";
    TableOfNames[ILSbEnergize] := "ILSbEnergize";
    TableOfNames[MKRaHiLoSense] := "MKRaHiLoSense";
    TableOfNames[MKRbHiLoSense] := "MKRbHiLoSense";
    TableOfNames[ADFaON] := "ADFaON";
    TableOfNames[ADFbON] := "ADFbON";
    TableOfNames[DMEaTune] := "DMEaTune";
    TableOfNames[DMEbTune] := "DMEbTune";
    TableOfNames[SwitchCntrl] := "SwitchCntrl";
    TableOfNames[Terminator] := "Terminator";
  END InitTableOfNames;


  PROCEDURE FillSignalTable
            (    name : SignalNames );
    (* Procedura czyta plik DGH.INI szukajac w pliku sekcji o nazwie name i
       wypelnia tablice signals parametrami z pol sekcji o nazwach: ModuleType
       - typ modulu DGH (we i wy analogowe i cyfrowe) Address - adres modulu
       DGH Channel - numer konwertera RS-232/RS-485, z ktorym modul pracuje Na
       podstawie pola ModuleType ustalany jest format komendy kierowanej do
       modulu WE: name - indeks do tablicy TableOfNames, zawierajacej nazwy
       sygnalow WY: TableOfNames[name] *)

  CONST
    Default = "Default";

  VAR
    OK     : BOOLEAN;
    Entry,
    Result : ARRAY [ 0 .. 40 ] OF CHAR;
    i      : CARDINAL;

  BEGIN
    WITH signals[name] DO
      Entry := "Address";
      GetPrivateProfileString( TableOfNames[name], Entry, Default, Result,
                               FileName );
      address := Result[0];
      Entry := "Channel";
      GetPrivateProfileString( TableOfNames[name], Entry, Default, Result,
                               FileName );
      IF CompareStr( Result, "First" ) = 0
      THEN
        channel := First
      END (* if CompareStr *);
      IF CompareStr( Result, "Second" ) = 0
      THEN
        channel := Second
      END (* if CompareStr *);
      Entry := "ModuleType";
      GetPrivateProfileString( TableOfNames[name], Entry, Default, Result,
                               FileName );
      IF CompareStr( Result, "AnalogInput" ) = 0
      THEN
        type := AnalogInput;
        active := FALSE;
        command[0] := "#";
        command[1] := address;
        command[2] := 15C;
        FOR i := 3 TO 14 DO
          command[i] := 0C;
        END (* for i *);
        commandLen := 3;
        controlled := TRUE;
        resultOK := 0;
        analogVAL := 0;
        waitPeriod := AIWP; 
      END (* if CompareStr *);
      IF CompareStr( Result, "AnalogOutput" ) = 0
      THEN
        type := AnalogOutput;
        active := FALSE;
        command := "$ AO+00000.00";
        command[1] := address;
        command[13] := 15C;
        command[14] := 0C;
        commandLen := 14;
        controlled := FALSE;
        resultOK := 0;
        analogVAL := 0;
        waitPeriod := AOWP;   (* 23 *)
      END (* if CompareStr *);
      IF CompareStr( Result, "DigitalInput" ) = 0
      THEN
        type := DigitalInput;
        active := FALSE;
        command := "# DI";
        command[1] := address;
        command[4] := 15C;
        FOR i := 5 TO 14 DO
          command[i] := 0C;
        END (* for i *);
        commandLen := 5;
        controlled := TRUE;
        resultOK := 0;
        binaryVAL := { };
        waitPeriod := DIWP;   (* 7 *)
      END (* if CompareStr *);
      IF CompareStr( Result, "DigitalOutput" ) = 0
      THEN
        type := DigitalOutput;
        active := FALSE;
        command := "$ DO0000";
        command[1] := address;
        command[8] := 15C;
        FOR i := 9 TO 14 DO
          command[i] := 0C;
        END (* for i *);
        commandLen := 9;
        controlled := FALSE;
        resultOK := 0;
        binaryVAL := { };
        waitPeriod := DOWP;   (* 5 *)
      END (* if CompareStr *);
      locErrorCnd := 0;
    END;   (* with signals[name] *)
  END FillSignalTable;


  PROCEDURE ReadDGHIniFile();

  VAR
    s : SignalNames;

  BEGIN
    InitTableOfNames( );
    FOR s := MIN(SignalNames)  TO MAX(SignalNames) DO
      FillSignalTable( s );
    END;   (* for s *)
  END ReadDGHIniFile;

BEGIN
  BlockClear( ADR( signals ), SIZE( signals ) );
  ReadDGHIniFile( );
  WITH signals[CockpitDisplaySP] DO
    command[4] := '0';
    command[5] := '1';
    command[6] := '0';
    command[7] := '0';
  END (* with signals *);
END DGHIni.
