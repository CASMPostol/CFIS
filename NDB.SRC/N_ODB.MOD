(*.F- *)
(**********************************************************************
|  Title   : Przetwarzanie danych dla odbiornika NDB on-line
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    12-12-96: M.Postol
|      bardzo duzo zmian
|    01-02-97: M.Postol
|      Procedura Start zeruje dane i nie inicjuje ScannerI. ScannerI jest
|      inicjowany w IniData
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE N_Odb [ 0 ];

  IMPORT
    MathLib0;

  FROM CommonTypes IMPORT
    (* TYPE *) GlownyOdbiornikT,
    (* CONST *) SigNilVal, NDBA_Aud_Flg;

  FROM ScannerI IMPORT
    (* VAR *) Simul, RefAlfa,
    (* PROCEDURE *) SetEvalPROC;

  FROM SpecConv IMPORT
    SubAngle100, AddAngle100, GorszeBoMniejsze, GorszeBoWieksze;

  FROM Kalibracja IMPORT
    (* TYPE *) InputSignal;

  FROM DGH_utils IMPORT
    ReadValue, BinInputSignal, TurnOnVORSig, BinaryValSet;

  FROM DGHIni IMPORT
    SignalNames;

  FROM DGHInterface IMPORT
    GetAnalogVal;

  FROM ADFAngle IMPORT
    GetADFAngle;

  FROM MathLib0 IMPORT
    entier, real, sin, cos;

  FROM GPSRead IMPORT
    DtaSignType, GetCurrDataSign, GetDirection;

  FROM FIltr1St IMPORT
    MemFContiner, InitMemFiltr, MemFiltr;

  FROM RTSMain IMPORT
    Terminate, Status;

  FROM DGH_utils IMPORT
    TurnOnADFSig;

  VAR
    DevNr       : ARRAY GlownyOdbiornikT OF CARDINAL;
    DevErrSum   : ARRAY GlownyOdbiornikT OF REAL;
    CollectData : BOOLEAN;
    dirCon      : MemFContiner;
    IdSygnalow  : ARRAY GlownyOdbiornikT OF RECORD
                                              sin, cos :
                                                SignalNames;
                                            END;
    licznik     : CARDINAL;  (* dla celow testowych *)

  PROCEDURE PoprawDane
            (    rec : GlownyOdbiornikT );

  BEGIN
    IF DEVVAL[rec] # SigNilVal
    THEN
      INC(DevNr[rec]);
      DevErrSum[rec] := DevErrSum[rec] + real(DEVVAL[rec]);
      DEVAV[rec] := entier(DevErrSum[rec] / FLOAT(DevNr[rec]));
      GorszeBoMniejsze(DEVMIN[rec], DEVVAL[rec]);
      GorszeBoWieksze(DEVMAX[rec], DEVVAL[rec])
    END (* if DEVVAL *);
  END PoprawDane;

  PROCEDURE Oblicz;
  VAR
    rec : GlownyOdbiornikT;
  CONST
    pi = 3.1415926;
    
    PROCEDURE ReadRec;
    VAR
      rec : GlownyOdbiornikT;

    BEGIN
      IF Simul
      THEN
        INC(licznik);
        FOR rec := goA TO goB DO
          sin[rec] := entier(MathLib0.sin(real(RefAlfa) * pi/ 18000.0 ) * 1000.0);
          cos[rec] := entier(MathLib0.cos(real(RefAlfa) * pi/ 18000.0) * 1000.0);
        END (* for rec *);
        IF licznik MOD 40 < 20
        THEN
          agc[goA] := 4;
          agc[goB] := 6;
        ELSE
          agc[goA] := 6;
          agc[goB] := 4;
        END (* if licznik *);
        (* agc[goA] := RandomInt(1000)+3; agc[goB] := RandomInt(1000)+3; *)
      ELSE
        FOR rec := goA TO goB DO
          audio_N[rec] := BinaryValSet(ADFAudio, rec);
          ReadValue(agc[rec], AdfAgc, rec, 1.0);
          sin[rec] := ReadAnalog(IdSygnalow[rec].sin);
          cos[rec] := ReadAnalog(IdSygnalow[rec].cos);
        END (* for rec *);
      END (* if Simul *);
      FOR rec := goA TO goB DO
        berN[rec] := GetADFAngle(sin[rec], cos[rec]);
      END;
    END ReadRec;
    
  VAR
    sign : DtaSignType;
    dirR : REAL;
    dirF : INTEGER;
    
  BEGIN (* Oblicz *)
    ReadRec;
    dirR := GetDirection(sign) * 100.0;
    IF dirR > 18000.0  THEN
      dirR  := dirR - 36000.0
    END;
    dirF := MemFiltr(dirCon, dirR, sign);
    dirF := SubAngle100(RefAlfa, dirF);
    dirF := AddAngle100(dirF, 18000);
    flg := {};
    FOR rec := goA TO goB DO
      dir[rec] := entier(dirR + 0.5);
      IF audio_N[rec]
      THEN
        INCL(flg, NDBA_Aud_Flg + ORD(rec));
      END (* if NAV *);
      DEVVAL[rec] := SubAngle100(berN[rec], dirF);
      IF CollectData
      THEN
        PoprawDane(rec);
      END (* if CollectData *);
    END (* for rec *);
  END Oblicz;

  PROCEDURE ClearContiners;
  VAR
    rec : GlownyOdbiornikT;
  BEGIN
    FOR rec := goA TO goB DO
      DEVVAL[rec] := SigNilVal;
      DEVMIN[rec] := SigNilVal;
      DEVMAX[rec] := SigNilVal;
      DEVAV[rec] := SigNilVal;
      DevNr[rec] := 0;
      DevErrSum[rec] := 0.0;
    END (* for i *);
  END ClearContiners;
  
  PROCEDURE Start;

  BEGIN
    ClearContiners;
    CollectData := TRUE;
  END Start;

  PROCEDURE Zatrzymaj;
    (* zatrzymuje zliczanie AV,MP,MM *)

  BEGIN
    CollectData := FALSE;
  END Zatrzymaj;

  PROCEDURE Wznow;
    (* wznawia zliczanie AV,MP,MM *)

  BEGIN
    CollectData := TRUE;
  END Wznow;

  PROCEDURE IniData;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    Zatrzymaj;
    FOR rec := goA TO goB DO
      sin[rec] := SigNilVal;
      cos[rec] := SigNilVal;
      agc[rec] := SigNilVal;
      berN[rec] := SigNilVal;
    END (* for i *);
    InitMemFiltr(dirCon, GetCurrDataSign(), 6);
    ClearContiners;
    TurnOnVORSig;
    SetEvalPROC(Oblicz, TRUE);
  END IniData;

  PROCEDURE ReadAnalog
            (    sn : SignalNames ) : INTEGER;
  VAR
    ds  : DtaSignType;
    val : INTEGER;

  BEGIN
    IF NOT GetAnalogVal(sn, val, ds)
    THEN
      val := SigNilVal;
    END (* if *);
    RETURN val;
  END ReadAnalog;

  PROCEDURE Wlacz();

  BEGIN
    IdSygnalow[goA].sin := SINforADFa;
    IdSygnalow[goA].cos := COSforADFa;
    IdSygnalow[goB].sin := SINforADFb;
    IdSygnalow[goB].cos := COSforADFb;
    TurnOnADFSig;
  END Wlacz;

BEGIN
  licznik := 0;
  Wlacz;
  IniData();
END N_Odb.
