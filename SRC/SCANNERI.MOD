(*.F- *)
(**********************************************************************
|  Title   : Przegladanie wejsc analogowych i cyfrowych
|  Author  : D.Arendt
|  System  : LOGITECH MODULA-2/86
|  History :
|   18-02-96: M.Postol
|     procedura Start zostala zmieniona by umozliwic przekazanie
|     parametrow lotu
|   17-03-95: M.Postol
|     duzo roznych zmian - generalne porzadki
|   02-05-96: M.Postol
|     DME wywalilem do D_Odb, tu zostalo tylko czytanie odleglosci
|   01-10-96: M.Postol
|     TEO wykazywal brak danych bo nie mial z GPS odleglosci - zmienilem
|     kolejnosc, najpierw jest wyznaczana odleglosc, filtrowana przez
|     poddtrzymanie, a nastepnie dopiero czytane TEO i liczony kat
|  04-10-96: M.Postol
|     AlfaF dla teodolitu ustawiane jest na NIL od razu gdy nie moe policzyc
|     polozenia
|   27-10-96 : M.Postol
|     wstawilem TeoAlfaF
|   05-12-96: M.Postol
|     Zwiekszylem stos proceseu
|   15-12-96: M.Postol
|      Zmiana definicji ScannerI
|   12-15-96 12:44pm: M. Morawski
|     W programach archiwalnych nie mozna wlaczyc symulatora
|   01-02-97: M.Postol
|     Zmiany w V_Odb wymagaja inicjacji
|   05-02-97: M.Postol
|     blad przy wyznaczaniu TeoAlfaF
|   21-02-97: M.Postol
|    blad przy wyznaczniu kata w GetGPSSpread
|   25-02-97: M.Postol
|    wprowadzilem mozliwosc ustawiania procedur dla obliczania predkosci i kata
|    dla symulatora wew.
|   31-03-97: M.Postol
|    wylaczono symulator wewnetrzny.
|   10-05-97: M.Postol
|     - zdefiniowalem DeltaF, bo ciagle byly problemy z GPS'em
|     - w GetGPSSpread flaga GPS byla ustawiana zawsze, gdy nie bylo danych,
|     - wlacza symulacje dla biosa MM, CAS_P210, MP i symulacja jest ustawiana
|       tylko na poczatku programu
|     - zdefiniowalem procedure CurrGPSAlfaOffset potrzebna dla DME w LOCarch
|     - wywalilem OdnDlaPomBledu
|     - wywalilem parametry w Start, ktore sa zdefiniowane w CommonData
|
|    1997-01-29 T. Rozmarynowski
|     - licznik w odczycie GPS
|     - inicjacja zmiennych GPS_A, GPS_R
|     - wprowadzenie flagi poprawek DGPS DIFFMODE
|     - w procedurze GetAndCountTEO nieslusznie bylo zmieniane slowo stanu
|       TEO
|     - rejestrowanie stanu pracy roznicowej wstawianie GPSDiff_flg dp flg
|       stan pracy rozniicowej
|     - odczytywanie z modulu theodolit czy transmitowane sa poprawki
|       procedura GetTeo i ustawianie TEO_DGPSpoprawki
|
|    Rel. 3.0. M. Postol
|      -  weryfikacja i porzadkowanie
|      -  zmienilem typ TEO_OK na taki sam jak TheodolitRead, aby uniknac 
|         niepotrzebnej konwersji
|      -  Blad przy wyznaczaniu parametrow z gps w trybie VOR trasowy
|    Rel. 3.14. M.Postol
|      - GetGPS wyznacza odleglosc do DME niezaleznie - dla pom LOC/DME
|      - uproscilem procedure Chksimul - nie sprawdza klawiszy.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE ScannerI [ 0 ];

  IMPORT
    GPSRead, TheodolitRead, AltInterface, Int_DME, PI_PA;

  FROM GPSRead IMPORT
    StanyGPS, StanGPS;
    
  FROM TheodolitRead IMPORT
    GetTheoR, TheodolitView, TeoState, TeoStates, PolozenieTeodolitu;
  
  FROM FIltr1St IMPORT
    ContinerBT, InitContB, FiltrB, InitContBCoun, BinaryCounter,
    BinaryCounterCon;

  FROM CommonTypes IMPORT
    (* TYPE *) GlownyOdbiornikT, OdnDlaPomBleduT, OdnDlaPomOdlT, signTabBin,
               PolozenieBiegunowe, PolozenieGeo,
    (* CONST *) SigNilVal, NilValC, NilValI, DisNilVal, GPS_flg, GPSDiff_flg;

  FROM MANAGER IMPORT
    STARTPROCESS, Condition, InitC, WAITC, Broadcast, Assert;

  FROM Timer IMPORT
    Wait;

  FROM GeoArithmetic IMPORT
    Geo2Kat, PolozenieBiegunoweMtx, IndxPolozenia;

  FROM MathLib0 IMPORT
    real;

  FROM DGHInterface IMPORT
    GetBinaryVal, WaitForNewData;

  FROM DGH_utils IMPORT
    BinaryValSet, BinInputSignal;

  FROM SpecConv IMPORT
    AddAngle100, SubAngle100, RAngle100, entierCheck;

  IMPORT
    Strings, DGHIni, DGHInterface;

  FROM CommonData IMPORT
    (* VAR *) OdnDlaPomOdl, OdnDlaPomBledu, Promien, Predkosc;

  CONST
    MaxEVAL     = 4;
    MaxDist     = 65535.0 / 500.0 - 2.0;
    pilEvBitPos = 10;
    MaxpilEvFil = 3;
    SCROLLOCK   = 4;
    CZAS_PROBKI = 1.0 / 3600.0 (* s*) / 5.0 (* probek/s*) * 500.0;

  TYPE
    DtaSignType =
      CARDINAL;

  VAR
    AcqQ               : Condition;
    RUN                : BOOLEAN;
    AlfaSigma          : REAL;
    DisSigma           : REAL;
    EvalPROC           : ARRAY [ 0 .. MaxEVAL - 1 ] OF PROC;
    pilotEvNrCOn       : BinaryCounterCon;
    pilotEvNr          : CARDINAL;
    pilEvCon           : ContinerBT;
    pilEvBit           : BOOLEAN;
    Sim_Dis_CP         : Sim_Dis_PROC;
    Sim_Alfa_CP        : Sim_Alfa_PROC;
    SpecKeys            [ 40H:17H ] : SET OF [ 0 .. 7 ];
    GPSEcounting       : PROCEDURE
                           ( VAR BITSET );
    TEOEcounting       : PROCEDURE
                           (     CARDINAL );
    locTogether        : BOOLEAN;
    AlfaGPSWatcDog     : CARDINAL;
    AlfaTeoWatcDog     : CARDINAL;
    currOdnDlaPomOdl   : OdnDlaPomOdlT;
    currOdnDlaPomBledu : OdnDlaPomBleduT;
    currPredkosc       : REAL;
    currPromien        : CARDINAL;
    currAlfaOff        : INTEGER;
    azymANieElew       : BOOLEAN;
    TEO_dtaSign        : DtaSignType;
    GPS_dtaSign        : GPSRead.DtaSignType;

  PROCEDURE DistR2C
            ( DisR : REAL): CARDINAL;
  BEGIN
    IF DisR < MaxDist THEN
      RETURN TRUNC( DisR * 500.0 + 0.5 );
    ELSE
      RETURN NilValC;
    END (* IF *);
  END DistR2C;
  
  PROCEDURE GetGPS
            ( VAR flg : BITSET );

  VAR
    pg          : PolozenieGeo;
    pb          : PolozenieBiegunoweMtx;
    currdtaSign : GPSRead.DtaSignType;

  BEGIN
    GPS_OK := GPSRead.GPSReceive( pg, GPS_GDOP, GPS_SAT, GPS_PREC,
                                  GPS_DIFFMODE, currdtaSign );
    IF GPS_dtaSign # currdtaSign
    THEN
      IF GPS_DIFFMODE
      THEN
        INCL( flg, GPSDiff_flg );   (* stan paracy roznicowy*)
      ELSE
        EXCL( flg, GPSDiff_flg );   (* stan paracy nie roznicowy*)
      END (* if GPS_DIFFMODE *);
      GPS_dtaSign := currdtaSign;
      Geo2Kat( pg, pb );
      WITH pb[ MIN( IndxPolozenia ) ] DO
        GPS_A := Kat;
        GPS_R := Odleglosc;
      END (* WITH *);
      DeltaDME[ goA ] := 0;
      DeltaDME[ goB ] := DistR2C( pb[ 1 ].Odleglosc );
      (* Tu zaklada sie, ze polozenie nadajnikow DME zostalo zadeklarowane 
         jako drugie w kolejnosc lub zostalo zadaklarowane tylko jedno 
         polozenie odniesienia w module GeoArithmetic. Inne polozenie DME 
         jest przewidziane dla wspolnego pomiaru LOC/DME.
      *)
      IF GPS_A > 180.0
      THEN
        GPS_A := GPS_A - 360.0;
      END (* if GPS_A *);
      Alfa.Together[pbGPS] := SubAngle100( RAngle100( GPS_A ), currAlfaOff );
      AlfaF.Together[pbGPS] := Alfa.Together[pbGPS];
      Delta[ poGPS ] := DistR2C(GPS_R);
      DeltaF[poGPS]  := Delta[poGPS];
      AlfaGPSWatcDog := 0;
    ELSE
      Alfa.Together[pbGPS] := NilValI;
      Delta[ poGPS ]       := NilValC;
      DeltaDME[ goA ]      := NilValC;
      DeltaDME[ goB ]      := NilValC;
      INCL( flg, GPS_flg );
      IF AlfaGPSWatcDog > 6
      THEN
        AlfaF.Together[pbGPS] := NilValI;   (* nie nowy to zaznacz po chwili *)
        DeltaF[poGPS] := DisNilVal;
      ELSE
        INC( AlfaGPSWatcDog );
      END (* if AlfaGPSWatcDog *);
    END (* if GPS_OK *);
  END GetGPS;

  PROCEDURE GetGPSSpread
            ( VAR flg : BITSET );

  VAR
    pg          : PolozenieGeo;
    pb          : PolozenieBiegunoweMtx;
    rec         : GlownyOdbiornikT;
    currdtaSign : GPSRead.DtaSignType;

  BEGIN
    GPS_OK := GPSRead.GPSReceive( pg, GPS_GDOP, GPS_SAT, GPS_PREC,
                                  GPS_DIFFMODE, currdtaSign );
    IF GPS_dtaSign # currdtaSign
    THEN
      IF GPS_DIFFMODE
      THEN
        INCL( flg, GPSDiff_flg );   (* stan paracy roznicowy*)
      ELSE
        EXCL( flg, GPSDiff_flg );   (* stan paracy nie roznicowy*)
      END (* if GPS_DIFFMODE *);
      GPS_dtaSign := currdtaSign;
      Geo2Kat( pg, pb );
      FOR rec := MIN( GlownyOdbiornikT ) TO MAX( GlownyOdbiornikT ) DO
        IF rec = goA
        THEN
          WITH pb[ MIN( IndxPolozenia ) ] DO
            GPS_A := Kat;
            GPS_R := Odleglosc;
          END (* WITH *);
          IF GPS_A > 180.0
          THEN
            GPS_A := GPS_A - 360.0;
          END (* if GPS_A *);
        END (* if rec *);
        DeltaDME[ rec ] := DistR2C( pb[ ORD(rec) ].Odleglosc );
        (* Tu zaklada sie, ze polozenie (odniesienie) odbiornika A bylo
           zadeklarowane jako pierwsze w module GeoArithmetic. 
        *)
        Alfa.Spread[rec] := SubAngle100( RAngle100( pb[ ORD(rec) ].Kat ), currAlfaOff );
        AlfaF.Spread[rec] := Alfa.Spread[rec];
      END; (* FOR rec *)
      Delta   [ poGPS ] := DistR2C( GPS_R );
      DeltaF[poGPS] := Delta[poGPS];
      AlfaGPSWatcDog := 0;
    ELSE
      Delta   [ poGPS ] := NilValC;
      DeltaDME[ goA   ] := NilValC;
      DeltaDME[ goB   ] := NilValC;
      INCL( flg, GPS_flg );
      FOR rec := MIN( GlownyOdbiornikT ) TO MAX( GlownyOdbiornikT ) DO
        Alfa.Spread[rec] := NilValI;
      END (* for rec *);
      IF AlfaGPSWatcDog > 6
      THEN
        FOR rec := MIN( GlownyOdbiornikT ) TO MAX( GlownyOdbiornikT ) DO
          AlfaF.Spread[rec] := NilValI;   (* nie nowy to zaznacz po chwili *)
          DeltaF[poGPS] := DisNilVal;
        END (* for rec *);
      ELSE
        INC( AlfaGPSWatcDog );
      END (* if AlfaGPSWatcDog *);
    END (* if GPS_OK *);
  END GetGPSSpread;

  PROCEDURE GetAndCountTEODummy
            (    RefDis : CARDINAL );

  BEGIN
  END GetAndCountTEODummy;

  PROCEDURE GetAndCountTEO
            (    RefDis : CARDINAL );

    PROCEDURE GetTeo
              (     RefDis : CARDINAL;
                VAR TEO_A  : REAL;
                VAR TEO_E  : REAL     ) : BOOLEAN;

    VAR
      pb          : PolozenieBiegunowe;
      currdtaSign : DtaSignType;

    BEGIN (* Teo *)
      TEO_OK :=  GetTheoR( currdtaSign, pb.Kat, TEO_E );
      IF tgpsRSZepsuty IN TEO_OK
      THEN
        TEO_DGPSpoprawki := FALSE;
      ELSE
        TEO_DGPSpoprawki := TRUE;
      END (* if *);
      IF TEO_dtaSign = currdtaSign
      THEN
        RETURN FALSE;
      END (* if *);
      TEO_dtaSign := currdtaSign;
      (* IF NOT (NewData IN TEO_OK) OR (Flag_Set IN TEO_OK) THEN RETURN FALSE;
         END (* if *) ; *)
      IF ( currOdnDlaPomOdl <> poZadanaPredkosc ) AND
         ( PolozenieTeodolitu.Odleglosc > 0.0001 )
      THEN
        IF RefDis = NilValC
        THEN
          INCL( TEO_OK, tBledy );
          EXCL( TEO_OK, tNoweDane );
          RETURN FALSE;
        ELSE
          pb.Odleglosc := FLOAT( RefDis ) / 500.0;
          IF pb.Odleglosc < 30.0 * PolozenieTeodolitu.Odleglosc
          THEN
            INCL( TEO_OK, tBledy );
            EXCL( TEO_OK, tNoweDane );
            RETURN FALSE;
          ELSIF tNoweDane IN TEO_OK
          THEN
            TheodolitView( pb, pb );
            TEO_A := pb.Kat;
          END (* if pb.Odleglosc *);
        END (* if RefDis *);
      ELSE
        TEO_A := pb.Kat;
      END (* if currOdnDlaPomOdl *);
      IF TEO_A > 180.0
      THEN
        TEO_A := TEO_A - 360.0;
      END (* if TEO_A *);
      RETURN TRUE;
    END GetTeo;

  BEGIN (* GetAndCountTEO *)
    IF GetTeo( RefDis, TEO_A, TEO_E )
    THEN   (* sygnal z TEO nowy *)
      IF azymANieElew
      THEN
        Alfa.Together[pbTeodolit] := RAngle100( TEO_A );
      ELSE
        Alfa.Together[pbTeodolit] := RAngle100( TEO_E );
      END (* if azymANieElew *);
      TeoAlfaF := RAngle100( TEO_A );
      AlfaF.Together[pbTeodolit] := Alfa.Together[pbTeodolit];
      AlfaTeoWatcDog := 0;
    ELSE
      Alfa.Together[pbTeodolit] := NilValI;   (* nie nowy to zaznacz od razu *)
      IF ( AlfaTeoWatcDog > 8 ) OR ( tBledy IN TEO_OK )
      THEN
        AlfaF.Together[pbTeodolit] := NilValI;   (* nie nowy to zaznacz po
                                                    chwili *)
        TeoAlfaF := NilValI;
      ELSE
        INC( AlfaTeoWatcDog );
      END (* if TEO_OK *);
    END (* if NewData *);
  END GetAndCountTEO;

  PROCEDURE Sim_Dis() : CARDINAL;

  VAR
    res : INTEGER;

  BEGIN
    IF DisSigma > CZAS_PROBKI * currPredkosc
    THEN
      DisSigma := DisSigma - CZAS_PROBKI * currPredkosc;
    ELSE
      DisSigma := -DisSigma + CZAS_PROBKI * currPredkosc;
    END (* if DisSigma *);
    IF entierCheck( DisSigma, res ) AND ( res > 0 )
    THEN
      RETURN res;
    ELSE
      RETURN DisNilVal;
    END (* if entierCheck *);
  END Sim_Dis;

  PROCEDURE AssSim_Dis
            (    currSim_Dis_CP : Sim_Dis_PROC );

  BEGIN
    Sim_Dis_CP := currSim_Dis_CP;
  END AssSim_Dis;

  PROCEDURE Sim_Alfa() : INTEGER;

  BEGIN
    AlfaSigma := AlfaSigma + 0.2;
    RETURN RAngle100( AlfaSigma );
  END Sim_Alfa;

  PROCEDURE AssSim_Alfa
            (    currSim_Alfa_CP : Sim_Alfa_PROC );

  BEGIN
    Sim_Alfa_CP := currSim_Alfa_CP;
  END AssSim_Alfa;

  PROCEDURE InitDataSimul;

  BEGIN
    RefAlfa := SigNilVal;
    AlfaSigma := 150.0;
    DisSigma := 15.0 * 500.0;
    GPS_A := 0.0;
    GPS_R := FLOAT( RefDis ) / 500.0;
    ABOVESL := 3000;   (* 900m *)
    TEO_OK :=  TeoStates{ tNoweDane };
    currPredkosc := 150.0;
  END InitDataSimul;

  PROCEDURE SIMDATA;

  VAR
    DABIOSDATE  [ 0FFFFH:5 ] : ARRAY [ 0 .. 7 ] OF CHAR;

  VAR
    procIdx      : CARDINAL;
    lastDs       : DGHInterface.DtaSignType;
    Licz         : CARDINAL;
    DistWatchDog : CARDINAL;
    odnOdlIdx    : OdnDlaPomOdlT;

    PROCEDURE TurnDGH_ON;

    BEGIN
      lastDs := DGHInterface.GetCurrDataSign( );
      (* DME *)
      DGHInterface.TurnOn( DGHIni.DMEDistanceA );
      DGHInterface.TurnOn( DGHIni.DMEDistanceB );
      DGHInterface.TurnOn( DGHIni.DME_SRCa );
      DGHInterface.TurnOn( DGHIni.DME_SRCb );
      DGHInterface.TurnOn( DGHIni.Altimeter );
    END TurnDGH_ON;

    PROCEDURE ReadDME;

    VAR
      tmp   : INTEGER;
      rec   : GlownyOdbiornikT;
      Btmp  : BITSET;
      Trace : signTabBin;
      ds    : DGHInterface.DtaSignType;

    BEGIN
      FOR rec := goA TO goB DO
        Trace[rec] := BinaryValSet( DME_SRC, rec );
      END (* for rec *);
      IF Trace[goA] AND GetBinaryVal( DGHIni.DMEDistanceA, Btmp, ds )
      THEN
        tmp := Int_DME.DMEConvert( Btmp );
        IF VAL( CARDINAL, tmp ) < ( DisNilVal DIV 5 )
        THEN
          Delta[poDMEA] := VAL( CARDINAL, tmp ) * 5;
        ELSE
          Delta[poDMEA] := DisNilVal;
        END (* if VAL *);
        DeltaF[poDMEA] := Delta[poDMEA];
      ELSE
        Delta[poDMEA] := DisNilVal;
      END (* if GetBinaryVal *);
      DeltaF[poDMEA] := Delta[poDMEA];
      IF Trace[goB] AND GetBinaryVal( DGHIni.DMEDistanceB, Btmp, ds )
      THEN
        tmp := Int_DME.DMEConvert( Btmp );
        IF VAL( CARDINAL, tmp ) < ( DisNilVal DIV 5 )
        THEN
          Delta[poDMEB] := VAL( CARDINAL, tmp ) * 5;
        ELSE
          Delta[poDMEB] := DisNilVal;
        END (* if VAL *);
      ELSE
        Delta[poDMEB] := DisNilVal;
      END (* if GetBinaryVal *);
      DeltaF[poDMEB] := Delta[poDMEB];
    END ReadDME;

    PROCEDURE ReadALT;

    VAR
      Btmp : BITSET;
      ds   : DGHInterface.DtaSignType;

    BEGIN
      IF GetBinaryVal( DGHIni.Altimeter, Btmp, ds )
      THEN
        FiltrB( pilEvCon, NOT ( pilEvBitPos IN Btmp ), pilEvBit );
        pilotEvNr := BinaryCounter( pilEvBit, pilotEvNrCOn );
        ABOVESL := AltInterface.ALTConvert( Btmp );
      ELSE
        ABOVESL := NilValI;
      END (* if GetBinaryVal *);
    END ReadALT;

    PROCEDURE OdlegWgPredk() : CARDINAL;

    CONST
      MaxDist = 65536.0;

    BEGIN
      DisSigma := DisSigma + CZAS_PROBKI * currPredkosc;
      IF DisSigma < MaxDist
      THEN
        RETURN TRUNC( DisSigma )
      ELSE
        RETURN NilValC;
      END (* if DisSigma *);
    END OdlegWgPredk;

  BEGIN (* SIMDATA *)
    DistWatchDog := 10;
    GPS_SAT := 4;
    GPS_GDOP := 5;
    GPS_PREC := 70;
    DisSigma := 0.0;
    Licz := 0;
    IF Simul
    THEN
      InitDataSimul;
    ELSE
      TurnDGH_ON;
    END (* if Simul *);
    FOR odnOdlIdx := MIN( OdnDlaPomOdlT ) TO MAX( OdnDlaPomOdlT ) DO
      Delta[odnOdlIdx] := DisNilVal;
      DeltaF[odnOdlIdx] := DisNilVal;
    END (* for odnOdlIdx *);
    LOOP
      IF Simul
      THEN
        flg := { };
        (* $R-*)
        INC( Licz );
        (* $R=*)
        Wait( 200 );
        IF NOT RUN
        THEN
          EXIT
        END (* if *);
        RefDis := Sim_Dis_CP( );
        GPS_R := FLOAT( RefDis ) / 500.0;
        FOR odnOdlIdx := MIN( OdnDlaPomOdlT ) TO MAX( OdnDlaPomOdlT ) DO
          Delta[odnOdlIdx] := RefDis;
          DeltaF[odnOdlIdx] := RefDis;
        END (* for odnOdlIdx *);
        RefAlfa := Sim_Alfa_CP( );
        IF azymANieElew
        THEN
          TEO_A := real( RefAlfa ) / 100.0;
          TEO_E := 3.0;
        ELSE
          TEO_A := 0.0;
          TEO_E := real( RefAlfa );
        END (* if azymANieElew *);
        Alfa.Together[pbGPS] := RefAlfa;
        Alfa.Together[pbTeodolit] := RefAlfa;
        GPS_A := real( AddAngle100( RefAlfa, currAlfaOff ) ) / 100.0;
        AlfaF := Alfa;
        EXCL( TEO_OK, tRSZepsuty );
        INCL( TEO_OK, tNoweDane );
      ELSE   (* normalny pomiar *)
        WaitForNewData( lastDs );
        IF NOT RUN
        THEN
          EXIT
        END (* if *);
        ReadALT;
        ReadDME;
        flg := { };
        GPSEcounting( flg );
        Delta[poZadanaPredkosc] := OdlegWgPredk( );
        DeltaF[poZadanaPredkosc] := Delta[poZadanaPredkosc];
        IF Delta[currOdnDlaPomOdl] <> DisNilVal
        THEN
          RefDis := Delta[currOdnDlaPomOdl];
          DistWatchDog := 0;
        ELSIF DistWatchDog < 6
        THEN
          INC( DistWatchDog );
        ELSE
          RefDis := Delta[currOdnDlaPomOdl]
        END (* if Delta *);
        TEOEcounting( RefDis );
        IF locTogether
        THEN
          IF currOdnDlaPomBledu > pbnieZdef
          THEN
            RefAlfa := AlfaF.Together[currOdnDlaPomBledu];
          ELSE
            RefAlfa := SigNilVal;
          END (* if currOdnDlaPomBledu *);
        ELSE
          RefAlfa := AlfaF.Spread[goA];
        END (* if locTogether *);
      END (* if Simul *);
      procIdx := 0;
      WHILE ( procIdx < MaxEVAL ) DO
        IF EvalPROC[procIdx] # PROC( NIL )
        THEN
          EvalPROC[procIdx];
        END (* if EvalPROC *);
        INC( procIdx );
      END (* while *);
      Broadcast( AcqQ );
    END (* loop *)
  END SIMDATA;

  PROCEDURE SetEvalPROC
            (    P   : PROC;
                 add : BOOLEAN );

    PROCEDURE FindIt() : CARDINAL;

    VAR
      ix : CARDINAL;

    BEGIN
      FOR ix := 0 TO MaxEVAL - 1 DO
        IF P = EvalPROC[ix]
        THEN
          RETURN ix;
        END (* if P *);
      END (* for ix *);
      RETURN NilValC;
    END FindIt;

    PROCEDURE FindFree() : CARDINAL;

    VAR
      ix : CARDINAL;

    BEGIN
      FOR ix := 0 TO MaxEVAL - 1 DO
        IF EvalPROC[ix] = PROC( NIL )
        THEN
          RETURN ix;
        END (* if EvalPROC *);
      END (* for ix *);
      (* ma byc blad *)
    END FindFree;

  VAR
    nr : CARDINAL;

  BEGIN
    nr := FindIt( );
    IF add
    THEN
      IF nr = NilValC
      THEN
        nr := FindFree( );
        EvalPROC[nr] := P;
      END (* if nr *);
    ELSIF nr # NilValC
    THEN
      EvalPROC[nr] := PROC( NIL );
    END (* if add *);
  END SetEvalPROC;

  PROCEDURE NewDataAvailable;

  BEGIN
    WAITC( AcqQ );
  END NewDataAvailable;

  PROCEDURE Start
            (    GPSAlfaOffset     : INTEGER;
                 aktAzymANieElew   : BOOLEAN;
                 locationsTogether : BOOLEAN );

  VAR
    ix : CARDINAL;

  BEGIN
    GPS_GDOP := SigNilVal;
    GPS_SAT  := SigNilVal;
    GPS_PREC := NilValC;
    RefDis   := NilValC;
    RefAlfa  := NilValI;
    currOdnDlaPomOdl := OdnDlaPomOdl;
    currOdnDlaPomBledu := OdnDlaPomBledu;
    currPredkosc := Predkosc;
    currPromien := Promien;
    currAlfaOff := GPSAlfaOffset;
    azymANieElew := aktAzymANieElew;
    Sim_Dis_CP := Sim_Dis;
    Sim_Alfa_CP := Sim_Alfa;
    FOR ix := 0 TO MaxEVAL - 1 DO
      EvalPROC[ix] := PROC( NIL );
    END (* for ix *);
    GPS_OK := StanGPS { NieMaTransmisji  };
    TEO_OK := TeoStates { tRSZepsuty };
    RUN := TRUE;
    pilotEvNr := 0;
    pilEvBit := FALSE;
    InitContB( pilEvCon, MaxpilEvFil, pilEvBit );
    InitContBCoun( pilotEvNrCOn, FALSE );
    AlfaTeoWatcDog := 10;
    AlfaGPSWatcDog := 10;
    TEO_dtaSign := TheodolitRead.GetCurrDataSign( );
    GPS_dtaSign := GPSRead.GetCurrDataSign( );
    locTogether := locationsTogether;
    IF locationsTogether
    THEN
      GPSEcounting := GetGPS;
      TEOEcounting := GetAndCountTEO;
    ELSE
      GPSEcounting := GetGPSSpread;
      TEOEcounting := GetAndCountTEODummy;
    END (* if locationsTogether *);
    STARTPROCESS( SIMDATA, 01200H, 0 );
  END Start;

  PROCEDURE LocationsTogether() : BOOLEAN;

  BEGIN
    RETURN locTogether;
  END LocationsTogether;

  PROCEDURE CurrGPSAlfaOffset() : INTEGER;

  BEGIN
    RETURN currAlfaOff;
  END CurrGPSAlfaOffset;

  PROCEDURE Stop;

  BEGIN
    RUN := FALSE;
    Wait( 500 );
  END Stop;

  PROCEDURE InitPilotEventId
            ( VAR ident : DtaSignType );

  BEGIN
    ident := pilotEvNr;
  END InitPilotEventId;

  PROCEDURE GetPilotEvent
            ( VAR ident : DtaSignType ) : BOOLEAN;

  BEGIN
    IF ident <> pilotEvNr
    THEN
      ident := pilotEvNr;
      RETURN TRUE;
    END (* if ident *);
    RETURN FALSE;
  END GetPilotEvent;

  VAR
    ix : CARDINAL;

  PROCEDURE Chksimul;

  VAR
    BIOS_Date  [ 0f000h:0fff5h ] : ARRAY [ 0 .. 7 ] OF CHAR;

  BEGIN
    Simul := 
       ( Strings.CompareStr( BIOS_Date, "04/13/96" ) = 0 ) OR 
       ( Strings.CompareStr( BIOS_Date, "12/10/96" ) = 0 );
  END Chksimul;

BEGIN
  GPS_A := 0.0;
  GPS_R := 0.0;
  GPS_DIFFMODE := FALSE;
  TeoAlfaF := SigNilVal;
  azymANieElew := TRUE;
  GPS_OK := StanGPS { NieMaTransmisji  };
  TEO_OK := TeoStates { tRSZepsuty };
  InitC( AcqQ );
  FOR ix := 0 TO MaxEVAL - 1 DO
    EvalPROC[ix] := PROC( NIL );
  END (* for ix *);
  Assert( PI_PA.PomiarANieArchiwum );
  Chksimul;
END ScannerI.
