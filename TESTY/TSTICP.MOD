MODULE  TstICP;

  IMPORT
    DebugPMD, DOSEntry, ErrorMess, OdbILS;

  FROM Strings IMPORT
    ConstAssign, Concat, Length, Insert;

  FROM Graphics IMPORT
    MaxHor, MaxVer, Wr16StrXY;
FROM CommonTypes IMPORT GlownyOdbiornikT, OdnDlaPomOdlT, OdnDlaPomBleduT;
FROM ICP_CntrolProc  IMPORT
  StartCPLoop, ProceduraT;

  FROM GrafTypes IMPORT
    WHITE, BLACK, BLUE, GREEN, RECT, AssignRect, MoveRect;
FROM Database  IMPORT
 LoadVorData;
 
FROM Tune  IMPORT
  TuneILS, Receiver, ILSfrqString;
  
FROM ScannerI  IMPORT
  Start;
  
  VAR
  dumm       : CARDINAL;
  locCurrFrq : CARDINAL;
  markerLowSense : BOOLEAN;
  string1 : ARRAY [0..50] OF CHAR;
  string2 : ARRAY [0..50] OF CHAR;
  
  PROCEDURE WriteILSFrq;
  VAR
    lastStr : ARRAY [0 .. 80] OF CHAR;

  BEGIN (* WriteILSFrq *)
    ILSfrqString(locCurrFrq, lastStr);
    Insert('czestotliwosc ILS = ', lastStr, 0);
    Wr16StrXY(lastStr, 450, 490, WHITE, BLUE);
  END WriteILSFrq;

BEGIN
  markerLowSense := TRUE;
  string1 := "Piaseczno";
  string2 := "12345678";
  LoadVorData(string1, string2);
  locCurrFrq := 1; (* 108.15 *)
  TuneILS(AReceiver, locCurrFrq, markerLowSense);
  TuneILS(BReceiver, locCurrFrq, markerLowSense);
  WriteILSFrq;
  Start(poGPS, pbGPS, 100.0, 40*500);
  OdbILS.IniData(300, 0, pbGPS);
  OdbILS.Start;
  StartCPLoop(Kierunek, 750, goA);
  LOOP
     dumm := dumm;
  END;
END TstICP.
