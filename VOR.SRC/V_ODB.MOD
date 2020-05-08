(*.F- *)
(**********************************************************************
|  Title   : Procedury wyliczajace parametry online dla dobiornika nav.
|  Author  : D.Arendt
|  System  : LOGITECH MODULA-2/86
|  History :
|    04.02.96: new
|    01-02-97: M.Postol
|      Procedura Start zeruje dane i nie inicjuje ScannerI. ScannerI jest
|      inicjowany w IniData
|    16-05-97: M.Postol
|      zmienilem znak bledu namiaru
|    03-06-97: M.Postol
|      drobne zmiany przy symulacji
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE V_Odb [ 0 ];

  FROM FIltr1St IMPORT
    ContinerBT, InitContB, FiltrB;

  FROM CommonTypes IMPORT
    (* TYPE *) GlownyOdbiornikT, OdnDlaPomBleduT,
    (* CONST *) SigNilVal, NAVA_flg, NAVA_Aud_flg;

  FROM ScannerI IMPORT
    (* VAR *) AlfaF, Simul, RefAlfa,
    (* PROCEDURE *) SetEvalPROC, LocationsTogether;

  FROM SpecConv IMPORT
    SubAngle100, GorszeBoMniejsze, GorszeBoWieksze, AddAngle100;

  FROM Kalibracja IMPORT
    (* TYPE *) InputSignal;

  FROM DGH_utils IMPORT
    ReadValue, BinInputSignal, TurnOnVORSig, BinaryValSet, ReadOmniber;

  FROM MathLib0 IMPORT
    entier, real;

  FROM Random IMPORT
    RandomInt;

  CONST
    NavFlgConTau = 3;

  VAR
    DevNr             : ARRAY GlownyOdbiornikT OF CARDINAL;
    DevErrSum         : ARRAY GlownyOdbiornikT OF REAL;
    CollectData       : BOOLEAN;
    OdnDlaPomBledu    : OdnDlaPomBleduT;
    navFlgCon         : ARRAY GlownyOdbiornikT OF ContinerBT;
    locationsTogether : BOOLEAN;

  VAR
    licznik : CARDINAL;  (* dla symulatora *)

  PROCEDURE Oblicz;
  VAR
    rec : GlownyOdbiornikT;

    PROCEDURE ReadNAV;
    VAR
      rec   : GlownyOdbiornikT;
      input : BOOLEAN;

    BEGIN
      FOR rec := goA TO goB DO
        input := BinaryValSet(SFLGforNAV, rec);
        FiltrB(navFlgCon[rec], input, navFlg[rec]);
        audio[rec] := BinaryValSet(NAVAudio, rec);
        ReadValue(var[rec], VorVarPrcMod, rec, 10.0);
        ReadValue(ref[rec], VorRefPrcMod, rec, 10.0);
        ReadValue(sub[rec], SubcarPrcMod, rec, 10.0);
        ReadValue(agc[rec], VorAgc, rec, 1.0);
        IF navFlg[rec]
        THEN
          IF input
          THEN
            ReadOmniber(obr[rec], rec);
          END (* if input *);
        ELSE
          obr[rec] := SigNilVal;
        END (* if navFlg *);
      END (* for rec *);
      IF Simul
      THEN
        INC(licznik);
        var[goA] := RandomInt(30) + 300;
        ref[goA] := RandomInt(16) + 160;
        sub[goA] := RandomInt(30) + 300;
        IF licznik MOD 40 < 50
        THEN
          agc[goA] := 4;
          agc[goB] := 6;
          navFlg[goA] := TRUE;
          navFlg[goB] := FALSE;
        ELSE
          navFlg[goA] := FALSE;
          navFlg[goB] := TRUE;
          agc[goA] := 6;
          agc[goB] := 4;
        END (* if licznik *);
        IF navFlg[goA]
        THEN
          obr[goA] := AddAngle100(RandomInt(20) + 30, RefAlfa);
        ELSE
          obr[goA] := SigNilVal;
        END (* if navFlg *);
        IF navFlg[goB]
        THEN
          obr[goB] := AddAngle100(RandomInt(200) - 100, RefAlfa);
        ELSE
          obr[goB] := SigNilVal;
        END (* if navFlg *);
        (* agc[goA] := RandomInt(1000)+3; agc[goB] := RandomInt(1000)+3; *)
        var[goB] := RandomInt(30) + 300;
        ref[goB] := RandomInt(20) + 160;
        sub[goB] := RandomInt(30) + 300;
      END (* if Simul *);
    END ReadNAV;

  BEGIN (* Oblicz *)
    flg := {};
    ReadNAV;
    FOR rec := goA TO goB DO
      IF navFlg[rec]
      THEN
        INCL(flg, NAVA_flg + ORD(rec));
      END (* if NAV *);
      IF audio[rec]
      THEN
        INCL(flg, NAVA_Aud_flg + ORD(rec));
      END (* if NAV *);
      IF locationsTogether
      THEN
        DEVVAL[rec] := SubAngle100(AlfaF.Together[OdnDlaPomBledu], obr[rec]);
      ELSE
        DEVVAL[rec] := SubAngle100(AlfaF.Spread[rec], obr[rec]);
      END (* if locationsTogether *);
      IF CollectData
      THEN
        PoprawDane(rec);
      END (* if CollectData *);
    END (* for rec *);
  END Oblicz;

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
      InitContB(navFlgCon[rec], NavFlgConTau, TRUE);
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

  PROCEDURE IniData
            (    currOdnDlaPomBledu : OdnDlaPomBleduT );
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    Zatrzymaj;
    FOR rec := goA TO goB DO
      obr[rec] := SigNilVal;
      var[rec] := SigNilVal;
      ref[rec] := SigNilVal;
      sub[rec] := SigNilVal;
      agc[rec] := SigNilVal;
      OdnDlaPomBledu := currOdnDlaPomBledu;
      locationsTogether := LocationsTogether();
    END (* for i *);
    ClearContiners;
    SetEvalPROC(Oblicz, TRUE);
  END IniData;

BEGIN
  licznik := 0;
  Zatrzymaj;
  locationsTogether := TRUE;
  TurnOnVORSig;
END V_Odb.
