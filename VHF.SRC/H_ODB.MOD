(*.F- *)
(**********************************************************************
|  Title   : Przetwarzanie danych dla odbiornika VHF on-line
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    08-12-96: created
|    01-02-97: M.Postol
|      Procedura Start zeruje dane i nie inicjuje ScannerI. ScannerI jest
|      inicjowany w IniData
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE H_Odb [ 0 ];

  FROM CommonTypes IMPORT
    (* TYPE *) GlownyOdbiornikT,
    (* CONST *) Com_Aud_flg, SigNilVal;

  FROM ScannerI IMPORT
    (* VAR *) Simul,
    (* PROCEDURE *) SetEvalPROC;

  FROM Kalibracja IMPORT
    (* TYPE *) InputSignal;

  FROM DGH_utils IMPORT
    ReadValue, BinInputSignal, BinaryValSet;

  FROM DGHIni IMPORT
    SignalNames;

  FROM DGHInterface IMPORT
    TurnOn;

  FROM Random IMPORT
    RandomInt;

  PROCEDURE Oblicz;

    PROCEDURE ReadRec;

    BEGIN
      IF Simul
      THEN
        audio_H := FALSE;
        agc := RandomInt(1000) + 100;
      ELSE
        audio_H := BinaryValSet(COMAudio, goA);
        ReadValue(agc, VhfAgc, goA, 1.0);
      END (* if Simul *);
    END ReadRec;

  BEGIN (* Oblicz *)
    flg := {};
    ReadRec;
    IF audio_H
    THEN
      INCL(flg, Com_Aud_flg);
    END (* if NAV *);
  END Oblicz;

  PROCEDURE Start;

  BEGIN
  END Start;

  PROCEDURE Zatrzymaj;

  BEGIN
  END Zatrzymaj;

  PROCEDURE Wznow;

  BEGIN
  END Wznow;

  PROCEDURE IniData;

  BEGIN
    flg := {};
    agc := SigNilVal;
    TurnOn(COMaAudio);
    TurnOn(AGCforCOMa);
    SetEvalPROC(Oblicz, TRUE);
  END IniData;

  PROCEDURE PoprawDane();

  BEGIN
  END PoprawDane;

BEGIN
  IniData();
END H_Odb.
