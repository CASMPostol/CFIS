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

MODULE TSTflg;

  IMPORT
    DebugPMD;

FROM RTSMain IMPORT
  Terminate, Status;
FROM Terminal IMPORT
  Read, WriteString, Write, WriteLn;
  FROM Tune IMPORT
    Receiver, TurnOffADF, TurnOffVOR_ILS, TuneADF, TuneILS, TuneDMEforILS,
    ILSfrqIdx, ILSfrqString, MaxNAV_Chann_Num, TuneVOR, SetCPFlags;


CONST
  LOC_SFLG  = TRUE;
  GS_SFLG   = TRUE;
  TO_SFLG   = FALSE;
  FROM_SFLG = TRUE;
  force     = TRUE;
VAR
  ch  : CHAR;
BEGIN
  SetCPFlags( LOC_SFLG, GS_SFLG, TO_SFLG, FROM_SFLG, force);
  WriteString("Napisz cos");
  Read(ch);
  Terminate( Stopped );
END TSTflg.
