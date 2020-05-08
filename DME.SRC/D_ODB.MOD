(*.F- *)
(**********************************************************************
|  Title   : Procedury wyliczajace parametry online dla dobiornika dme
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    01-02-97: M.Postol
|      Procedura Start zeruje dane i nie inicjuje ScannerI. ScannerI jest
|      inicjowany w IniData
|    12-05-97: M.Postol
|      blad przy odtwarzaniu sily sygnalu w prog arch
|      zmiany przy symulacji
|    Rel. 3.0 MPostol
|      Do obliczenien distErrF wziolem odleglosc po filtrowaniu.
|      Sygnal Trace byl filtrowany co powodowalo zle odczyty odleglosci 
|      z dme. Podtrzymywac mozna ewentualnie odleglosc!!!
|      Wartosc wyswietlana bledu jest podtrzymywana.
|    Rel. 3.12. MPostol
|      Dist jest podstawiany, gdy nie ma MEM'a. Na duzych odleglosciach 
|      odczytywanie odleglosci, gdy MEM daje duze bledy odleglosci.
|    Rel. 3.14. MPostol
|      Modul uwzglednia mozliwosc innego polozenia DME niz w punkcie odniesienia -
|      Zmiana wprowadzona dla pomiaru LOC/DME
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE D_Odb;

  FROM CommonTypes IMPORT
    (* TYPE *) GlownyOdbiornikT, OdnDlaPomOdlT,
    (* CONST *) NilValI, NilValC, DMEB_trc, DMEA_trc, DMEA_mem, DMEA_Aud_flg,
                SigNilVal, DisNilVal, C_czas_podtrzymania;

  FROM ScannerI IMPORT
    DeltaDME, SetEvalPROC, Simul, RefDis;

  FROM SpecConv IMPORT
    GorszeBoMniejsze, SubWCheck;

  FROM Kalibracja IMPORT
    (* TYPE *) InputSignal;

  FROM DGH_utils IMPORT
    ReadValue, BinInputSignal, TurnOnDMESig, BinaryValSet;

  FROM DGHInterface IMPORT
    GetBinaryVal;

  FROM SYSTEM IMPORT
    INBYTE;

  FROM Random IMPORT
    RandomInt, RandomCard;

  IMPORT
    DGHIni, DGHInterface, Int_DME;

  FROM FIltr1St  IMPORT
    MemFIntContiner, MemFiltrInt, InitMemFIntContiner;
     
  VAR
    CollectData              : BOOLEAN;
    distErrF_MemFIntContiner : ARRAY GlownyOdbiornikT OF MemFIntContiner;
    
  PROCEDURE Oblicz;
  VAR
    rec : GlownyOdbiornikT;
    d   : CARDINAL;

    PROCEDURE ReadDME;
    VAR
      tmp  : INTEGER;
      rec  : GlownyOdbiornikT;
      Btmp : BITSET;
      ds   : DGHInterface.DtaSignType;

    PROCEDURE ReadSimul;

    BEGIN
      Agc[goA] := -RandomInt(10) - 70;
      Agc[goB] := -RandomInt(10) - 70;
      Mem[goA] := FALSE;
      Mem[goB] := FALSE;
      IF ODD(RefDis DIV 200)  THEN
        Dis[goA] := RefDis + RandomCard(300);
        Dis[goB] := RefDis + RandomCard(300);
        DisI[goA] := Dis[goA] DIV 5;
        DisI[goB] := Dis[goB] DIV 5;
        Trace[goA] := TRUE;
        Trace[goB] := TRUE;
      ELSE
        Dis[goA] := DisNilVal;
        Dis[goB] := DisNilVal;
        Trace[goA] := FALSE;
        INCL(flg, DMEA_trc);
        Trace[goB] := FALSE;
        INCL(flg, DMEB_trc);
      END;
      Mem[goA] := Trace[goA];
      Mem[goB] := Trace[goB];
      Audio[goA] := Trace[goA];
      Audio[goB] := Trace[goB];
      Reply[goA] := RandomInt(200) + 700;
      Reply[goB] := RandomInt(200) + 700;
      Squitter[goA] := RandomInt(300) + 2700;
      Squitter[goB] := RandomInt(300) + 2700;
    END ReadSimul;

    BEGIN
      flg := {};
      IF Simul
      THEN
        ReadSimul;
        RETURN;
      ELSE
        FOR rec := goA TO goB DO
          Trace[rec] := BinaryValSet(DME_SRC, rec);
          Mem[rec] := BinaryValSet(DME_MEM, rec);
          Audio[rec] := BinaryValSet(DMEAudio, rec);
          ReadValue(Squitter[rec], DmeSquitter, rec, 1.0);
          ReadValue(Reply[rec], DmePrcReply, rec, 10.0);
          ReadValue(Agc[rec], DmeAgc, rec, 1.0);
        END (* for rec *);
      END;
      IF Trace[goA] AND GetBinaryVal(DGHIni.DMEDistanceA, Btmp, ds)
      THEN
        tmp := Int_DME.DMEConvert(Btmp);
        DisI[goA] := tmp;
        IF ( VAL(CARDINAL, tmp) < (DisNilVal DIV 5) ) AND NOT Mem[goA]
        THEN
          Dis[goA]  := VAL(CARDINAL, tmp) * 5;
        ELSE
          Dis[goA]  := DisNilVal;
        END;
      ELSE
        INCL(flg, DMEA_trc);
        Dis[goA]  := DisNilVal;
        DisI[goA] := SigNilVal;
      END (* if GetBinaryVal *);
      IF Trace[goB] AND GetBinaryVal(DGHIni.DMEDistanceB, Btmp, ds)
      THEN
        tmp := Int_DME.DMEConvert(Btmp);
        DisI[goB] := tmp;
        IF (VAL(CARDINAL, tmp) < (DisNilVal DIV 5)) AND NOT Mem[goB]
        THEN
          Dis[goB]  := VAL(CARDINAL, tmp) * 5;
        ELSE
          Dis[goB]  := DisNilVal;
        END;
      ELSE
        INCL(flg, DMEB_trc);
        DisI[goB] := SigNilVal;
        Dis[goB]  := DisNilVal;
      END (* if Trace *);
    END ReadDME;

  BEGIN (* Oblicz *)
    flg := {};
    ReadDME;
    FOR rec := goA TO goB DO
      IF Mem[rec]
      THEN
        INCL(flg, DMEA_mem + ORD(rec));
      END (* if *);
      IF Audio[rec]
      THEN
        INCL(flg, DMEA_Aud_flg + ORD(rec));
      END (* if DME *);
      IF NOT Mem[rec] THEN
        distErr[rec]  := SubWCheck(Dis[rec], DeltaDME[rec] );
      ELSE
        distErr[rec] := SigNilVal;
      END;
      distErrF[rec] := MemFiltrInt(distErrF_MemFIntContiner[rec], 
                                   distErr[rec]);
      IF CollectData
      THEN
        INC(samples);
        PoprawDane(rec);
      END (* if CollectData *);
    END (* for rec *);
  END Oblicz;

  PROCEDURE PoprawDane
            (    rec : GlownyOdbiornikT );

  BEGIN
    GorszeBoMniejsze(SSmin[rec], Agc[rec]);
  END PoprawDane;

  PROCEDURE ClearContiners;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      InitMemFIntContiner( distErrF_MemFIntContiner[rec], 
                           C_czas_podtrzymania);
      SSmin[rec]    := SigNilVal;
      distErr[rec]  := SigNilVal;
      distErrF[rec] := SigNilVal;
      Dis[rec]      := DisNilVal;
      DisI[rec]     := SigNilVal;
    END;
  END ClearContiners;
  
  PROCEDURE Start;

  BEGIN
    CollectData := TRUE;
    ClearContiners;
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
    samples := 0;
    FOR rec := goA TO goB DO
      Dis[rec] := DisNilVal;
      Reply[rec] := SigNilVal;
      Squitter[rec] := SigNilVal;
      Agc[rec] := SigNilVal;
      Audio[rec] := FALSE;
      Mem[rec] := TRUE;
      Trace[rec] := FALSE;   (* szuka,znaczy nie wie,1=brak danych *)
      flg := {};;
      distErr[rec] := SigNilVal;
      SSmin[rec] := SigNilVal;
    END (* for rec *);
    ClearContiners;
    TurnOnDMESig;
    SetEvalPROC(Oblicz, TRUE);
  END IniData;

BEGIN
  Zatrzymaj;
  samples := 0;
END D_Odb.
