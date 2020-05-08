(*.F- *)
(**********************************************************************
|  Title   : Program testowania ukladu strojenia
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

MODULE TSTTune;

  IMPORT
    DebugPMD;

  FROM Tune IMPORT
    Receiver, TurnOffADF, TurnOffVOR_ILS, TuneADF, TuneILS, TuneDMEforILS,
    ILSfrqIdx, ILSfrqString, MaxNAV_Chann_Num, TuneVOR;

  VAR
    adfCurrFrq      : CARDINAL;
    vorCurrFrq      : CARDINAL;
    dmeCurrFrq      : ILSfrqIdx;
    locCurrFrq      : ILSfrqIdx;
    markerLowSense  : BOOLEAN;

  PROCEDURE DoILSMenu;

  BEGIN (* DoILSMenu *)
    TuneILS( AReceiver, locCurrFrq, markerLowSense );
    TuneILS( BReceiver, locCurrFrq, markerLowSense );
  END DoILSMenu;

BEGIN
  markerLowSense := TRUE;
  vorCurrFrq := 10800;
  dmeCurrFrq := 0;
  locCurrFrq := 0;
  adfCurrFrq := 190;
  DoILSMenu;
END TSTTune.
