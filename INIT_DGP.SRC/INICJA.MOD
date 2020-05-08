(*.F- *)
(**********************************************************************
|  Title   : Inicjowanie stacji referencyjnej
|  Author  :
|  System  : LOGITECH MODULA-2/86
|  History :
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE INIcja;
 
(*  IMPORT
    FCBS, DebugPMD, DOSEntry;*)
    
 FROM TypDanych IMPORT
    MainStates, TypUrzadzenia,ParametryUrzadzenia,PolozenieBiegunWysokosc;

  FROM CommonTypes IMPORT
      PolozenieGeo,WspGeo,DisNilValR, NilValC, DisNilVal;

  FROM GrafTypes IMPORT
    RECT, AssignRect,  WHITE, BLUE, MAGENTA,BLACK,LT_RED;

  FROM HiLevGraf IMPORT
    WrStr, SetPaletteEntry,WrStrXY,Wr2fStrXY;


  FROM StdIO IMPORT
    sprintf5,sprintf4,sprintf3,sprintf2,sprintf;

FROM RealConversions IMPORT
  StringToReal;

  FROM MANAGER IMPORT
    STARTPROCESS, InitS, InitC, SIGNAL, SEND, WAITS, WAITC, Assert, Condition;

  FROM BitByteOps IMPORT
    ByteXor,ByteAnd;

  FROM NumberConversion IMPORT
    StringToCard, StringToInt;


FROM GrafUtil IMPORT
  Info, InfoBeep;

  FROM Strings IMPORT
    Length, Insert, CompareStr,Concat,Copy,Delete;
  FROM Math IMPORT
    ACos, Sqr, M_PI;
  FROM MathLib0 IMPORT
    (* real, *) cos, sqrt, sin;



      FROM Timer IMPORT
    Wait, TInOneSecond;
      FROM RS232Code IMPORT
         Init, Write, Read,BusyRead,StartReading;




CONST
 szybkoscTransmisji = 9600;
 liczBitStopu = 1;
 parzystosc = FALSE;
 rodzParzyst = FALSE;
 liczBitDan = 8;
 GId = 0;
 GRtcm = 0;
TYPE
StanyZnacznik = (Znacznik,Koniec);
    str110 =
      ARRAY [ 0 .. 200 ] OF CHAR;
   part   =
      ( head,
        body,
        CRC );

    stanyGPS =
      ( inicjacja,
        odczyt,
        koniecWatchDog );



VAR
  Stan :StanyZnacznik;
    actPart                        : part;
    posInRecBuf                    : CARDINAL;
    sumaModC                       : CHAR;
    sumaModF                       : CARDINAL;
    bufor                          : str110; 
  iloscramekCom2,
      NumberOfSattelites:REAL;
currentSign:CARDINAL;
polozenieGPSinicjac  :PolozenieGeo;
polozebGPSinicjac :PolozenieBiegunWysokosc;
    StanHGPS    : stanyGPS;


  PROCEDURE GetCurrDataSign() : DtaSignType;

  BEGIN
    RETURN currentSign;
  END GetCurrDataSign;



   
  PROCEDURE GPSReceive
            ( VAR IloscramekCom2            : REAL;
              VAR NOS                       : REAL;
              VAR dtaSign                   : CARDINAL  );

    (* czytanie z GPS*)

    PROCEDURE GetFrame();

    TYPE
      str14 =
        ARRAY [ 0 .. 14 ] OF CHAR;

    VAR
      ok          : BOOLEAN;
      buforT      : str14;  (* bufor pomocniczy do konwersji*)
      bufPosition : CARDINAL;

      PROCEDURE szukaniePola
                ( VAR bufor : ARRAY OF CHAR;
                  VAR n     : CARDINAL      ) : BOOLEAN;

      VAR
        c : CHAR;

      BEGIN
        REPEAT
          c := bufor[n];
          INC( n );
        UNTIL ( c = ',' ) OR ( c = 0C );
        RETURN c <> 00C;
      END szukaniePola;

      PROCEDURE DekomozycjaRamki
                ( VAR bufor  : ARRAY OF CHAR;
                  VAR n      : CARDINAL;
                  VAR buforT : ARRAY OF CHAR );

      VAR
        k : CARDINAL;

      BEGIN
        k := 0;
        WHILE ( bufor[n] <> ',' ) AND ( bufor[n] <> 0C ) AND ( k <= HIGH(
              buforT ) ) DO
          buforT[k] := bufor[n];
          INC( k );
          INC( n )
        END (* while *);
        IF k < HIGH( buforT )
        THEN
          buforT[k] := 00C;
        ELSE
          WHILE ( bufor[n] <> ',' ) AND ( bufor[n] <> 0C ) DO
            INC( n );
          END (* while *);
        END (* if k *);
      END DekomozycjaRamki;

      PROCEDURE GetStrFromGps
                ( VAR s : str110 ) : BOOLEAN;

      VAR
        cChar : CHAR;

        PROCEDURE ConvertHexChar
                  (     c  : CHAR;
                    VAR ok : BOOLEAN ) : CARDINAL;

        BEGIN
          ok := TRUE;
          IF ( c >= '0' ) AND ( c <= '9' )
          THEN
            RETURN ORD( c ) - ORD( '0' )
          ELSIF ( c >= 'A' ) AND ( c <= 'F' )
          THEN
            RETURN ORD( c ) - ORD( 'A' ) + 10;
          ELSE
            ok := FALSE;
            RETURN 0
          END (* if *);
        END ConvertHexChar;

        PROCEDURE RdChar
                  ( VAR ch : CHAR ) : BOOLEAN;
        VAR
        okRdChar :BOOLEAN;
        BEGIN
          BusyRead (ch,okRdChar);
          IF  okRdChar THEN
          ch := CHAR( ByteAnd( ch, 7FH ) );
           RETURN TRUE
          ELSE

           RETURN FALSE
          END;
        END RdChar;

      BEGIN (* GetStrFromGps *)
        (* szukanie poczatka ramki*)
        (* w nowej wersji szukanie pocz ramki Tomek*)
        LOOP
          IF NOT RdChar( cChar )
          THEN
            RETURN FALSE;
          END (* if RdChar *);
          CASE actPart OF
            head :
              IF cChar = '$'
              THEN
                actPart := body;
                sumaModC := 0C;   (* znacznik sumy*)
                posInRecBuf := 0;
              END (* if cChar *);
            |
            body :
              Assert( posInRecBuf <= HIGH( s ) );
              IF cChar = '*'
              THEN
                s[posInRecBuf] := 0C;
                actPart := CRC;
                sumaModF := 0;
                posInRecBuf := 16;
              ELSE
                s[posInRecBuf] := cChar;
                INC( posInRecBuf );
                sumaModC := CHAR( ByteXor( sumaModC, cChar ) );
              END (* if *);
            |
            CRC :
              IF cChar <= ' '
              THEN
                actPart := head;
              ELSE
                sumaModF := ConvertHexChar( cChar, ok ) * posInRecBuf +
                            sumaModF;
                posInRecBuf := posInRecBuf DIV 16;
                IF posInRecBuf = 0
                THEN
                  actPart := head;
                  IF sumaModF = ORD( sumaModC )
                  THEN
                    RETURN TRUE;
                  END (* if sumaModF *);
                END (* if i *);
              END (* if *);
          END (* case actPart *);
        END (* loop *);
      END GetStrFromGps; (* koniec czytania ramki*)

      PROCEDURE GetReal
                ( VAR bufor       : ARRAY OF CHAR;
                  VAR bufPosition : CARDINAL      ) : REAL;

      VAR
        buforT    : str14;
        wynikReal : REAL;

      BEGIN
        DekomozycjaRamki( bufor, bufPosition, buforT );
        StringToReal( buforT, wynikReal, ok );
        RETURN wynikReal
      END GetReal;

      PROCEDURE GetCardinal
                ( VAR bufor       : ARRAY OF CHAR;
                  VAR bufPosition : CARDINAL      ) : CARDINAL;

      VAR
        buforT        : str14;
        wynikCardianl : CARDINAL;
        ok            : BOOLEAN;

      BEGIN
        DekomozycjaRamki( bufor, bufPosition, buforT );
        StringToCard( buforT, wynikCardianl, ok );
        IF ok
        THEN
          RETURN wynikCardianl
        END (* if ok *);
        RETURN NilValC
      END GetCardinal;


      PROCEDURE An_Frame_DOPA;

      TYPE
        ramkaDOPA =
          ( headerD,
            weekD,
            secondsD,
            gdopD,
            pdopD,
            htdopD,
            hdopD,
            tdopD,
            satsD,
            sats1D,
            sat2D,
            sats3D,
            sat4D,
            sats6D,
            sat6D,
            sats7D,
            sat8D,
            sats9D,
            sat10D,
            sats11D,
            sat12D,
            endD );

      VAR
        stanDOPA    : ramkaDOPA;
        bufPosition : CARDINAL;
        gdopR       : REAL;

      BEGIN
        bufPosition := 0;   (* GDOP*)
        stanDOPA := headerD;
        LOOP
          IF NOT szukaniePola( bufor, bufPosition )
          THEN
            EXIT
          END (* if *);
          IF stanDOPA < endD
          THEN
            INC( stanDOPA );
          END (* if CzescRamki *);
          CASE stanDOPA OF
            satsD :
              NumberOfSattelites := GetReal( bufor, bufPosition );
          ELSE
            ;
          END (* case CzescRamki *);
        END (* while szukaniePola *);
      END An_Frame_DOPA;

      PROCEDURE An_Frame_CMSA;

      TYPE
        ramkaCMSA =
          ( headerC,
            weekC,
            secondsC,
            xon1C,
            cts1C,
            parity1C,
            overrun1C,
            framing1C,
            rx1C,
            tx1C,
            xon2C,
            cts2C,
            parity2C,
            overrun2C,
            framing2C,
            rx2C,
            tx2C,
            rtcmparC,
            rtcmaparC,
            rtcmgoodC,
            dcsaparC,
            dcsagoodC,
            dcsbparC,
            dcsbgoodC,
            endC );

      VAR
        stanCMSA    : ramkaCMSA;
        bufPosition : CARDINAL;
        gdopR       : REAL;

      BEGIN
        bufPosition := 0;   (* GDOP*)
        stanCMSA := headerC;
        LOOP
          IF NOT szukaniePola( bufor, bufPosition )
          THEN
            EXIT
          END (* if *);
          IF stanCMSA < endC
          THEN
            INC( stanCMSA );
          END (* if CzescRamki *);
          CASE stanCMSA OF
            tx2C :
              iloscramekCom2 := GetReal( bufor, bufPosition );
          ELSE
            ;
          END (* case CzescRamki *);
        END (* while szukaniePola *);
      END An_Frame_CMSA;


    BEGIN (* GetFrame *)
      ok := TRUE;
      LOOP   (* poczatek glownej funkcji programu*)
        IF GetStrFromGps( bufor )
        THEN

                INC( currentSign );              
          
          Copy( bufor, 0, 4, buforT );
          buforT[4] := 0C;
          IF (buforT[0] = 'D') AND ( buforT[1] = 'O' )
           THEN
            (*WrStrXY(bufor,11,30, BLACK,WHITE);       *)
            An_Frame_DOPA;
          ELSIF ( buforT[0] = 'C' ) AND ( buforT[1] = 'M' )
          THEN
            (*WrStrXY(bufor,11,50, BLACK,WHITE);      *)
            An_Frame_CMSA;
          END;   (* koniec dekompozycji ramki*)
        ELSE
          EXIT;
        END (* if GetStrFromGps *);
      END (* loop *);
    END GetFrame;

  BEGIN (* GPSReadPos *)
    GetFrame;
    IloscramekCom2:= iloscramekCom2;           
    dtaSign := currentSign;
      NOS := NumberOfSattelites;
      RETURN
  END GPSReceive;



  PROCEDURE Kat2Geo
            ( pk      :PolozenieBiegunWysokosc;
              pgb     :PolozenieGeo;
              VAR pg  : PolozenieGeo  (*wynikowe do inicjacji GPS*)
                     );
  CONST
    DzielnikMin = 10000;


  VAR
    OdlegloscRownol   : REAL;
    OdlegloscPoludn   : REAL;
    KatWRadianach     : REAL;
    SredniRownoleznik : WspGeo;  (* dokola ziemia jest plaska *)
  PROCEDURE Odl2Geo
            (     OdlWMilach    : REAL;
                  DlugoscMinuty : REAL;
              VAR k             : WspGeo );
  VAR
    mf : REAL;
    mi : CARDINAL;

  BEGIN
    mf := OdlWMilach / DlugoscMinuty;   (* calkowita ilosc minut katawych *)
    mi := TRUNC(ABS(mf));
    k.Stopnie := mi DIV 60;
    k.Minuty := mi MOD 60;
    k.DziesTys := TRUNC((ABS(mf) - FLOAT(mi)) * FLOAT(DzielnikMin));
    IF mf < 0.0
    THEN
      Odwr(k);
    END (* if mf *);
  END Odl2Geo;

  PROCEDURE Odwr
            ( VAR a : WspGeo );

  BEGIN
    WITH a DO
      Stopnie := 360 - Stopnie;
      IF (Minuty # 0) OR (DziesTys # 0)
      THEN
        DEC(Stopnie);
        Minuty := 60 - Minuty;
        IF DziesTys # 0
        THEN
          DEC(Minuty);
          DziesTys := DzielnikMin - DziesTys;
        END (* if DziesTys *);
      END (* if *);
      IF Stopnie = 360
      THEN
        Stopnie := 0;
      END (* if Stopnie *);
      IF Minuty = 60
      THEN
        Minuty := 0;
      END (* if Minuty *);
    END (* with a *);
  END Odwr;

 PROCEDURE DodajPolozenieGeo
            (     a,
                  b : WspGeo;
              VAR c : WspGeo );

  BEGIN
    c.Stopnie := a.Stopnie + b.Stopnie;
    c.Minuty := a.Minuty + b.Minuty;
    c.DziesTys := a.DziesTys + b.DziesTys;
    INC(c.Minuty, c.DziesTys DIV DzielnikMin);
    c.DziesTys := c.DziesTys MOD DzielnikMin;
    INC(c.Stopnie, c.Minuty DIV 60);
    c.Minuty := c.Minuty MOD 60;
  END DodajPolozenieGeo;

  PROCEDURE SredniPolozenieGeo
            (     a,
                  b : WspGeo;
              VAR c : WspGeo );
  VAR
    reszta : CARDINAL;

  BEGIN
    DodajPolozenieGeo(a, b, c);
    reszta := (c.Stopnie MOD 2) * 60;
    c.Stopnie := c.Stopnie DIV 2;
    INC(c.Minuty, reszta);
    reszta := (c.Minuty MOD 2) * DzielnikMin;
    c.Minuty := c.Minuty DIV 2;
    INC(c.DziesTys, reszta);
    c.DziesTys := c.DziesTys DIV 2;
  END SredniPolozenieGeo;

  PROCEDURE Rad
            ( VAR a : WspGeo ) : REAL;
  VAR
    KatWStopniach : REAL;

  BEGIN
    KatWStopniach := FLOAT(ABS(a.Stopnie)) + FLOAT(a.Minuty) / 60.0 + FLOAT(
                     a.DziesTys) / (60.0 * FLOAT(DzielnikMin));
    IF (a.Stopnie < 0)
    THEN
      KatWStopniach := -KatWStopniach
    END (* if *);
    RETURN KatWStopniach * M_PI / 180.0;
  END Rad;


  BEGIN
    KatWRadianach := pk.Kat * M_PI / 180.0;
    OdlegloscRownol := pk.Odleglosc * sin(KatWRadianach);
    OdlegloscPoludn := pk.Odleglosc * cos(KatWRadianach);
    Odl2Geo(OdlegloscPoludn, 1.0, pg.Szerokosc);
    
      DodajPolozenieGeo(pg.Szerokosc,pgb.Szerokosc, pg.Szerokosc);
      pg.Szerokosc.Stopnie := pg.Szerokosc.Stopnie MOD 360;
      SredniPolozenieGeo(pg.Szerokosc, pgb.Szerokosc, SredniRownoleznik);
      Odl2Geo(OdlegloscRownol, cos(Rad(SredniRownoleznik)), pg.Dlugosc);
      DodajPolozenieGeo(pg.Dlugosc, pgb.Dlugosc, pg.Dlugosc);
    pg.Dlugosc.Stopnie := pg.Dlugosc.Stopnie MOD 360;
  END Kat2Geo;

PROCEDURE WyslijRSbufor(buf :ARRAY OF CHAR);
VAR
i : CARDINAL;
eos:ARRAY [0..2] OF CHAR;
buf1 :ARRAY [0..80] OF CHAR;
wynikWrite :BOOLEAN;

BEGIN
  i := 0;

  eos[0] := CHR( 0DH );   (* nowa linnia*)
  eos[1] := CHR( 0AH );   (* powrot karetki*)
  eos[2] := CHR( 0H );   (* powrot karetki*)
          Concat( buf, eos, buf1 );

WHILE (buf1[i] # 0C) AND (i < Length(buf1)) DO
(*      WrStrXY(buf[i],11+i*10,250,WHITE, WHITE);
     wynikWrite:= Write (1,buf1[i]);*)
     Write (buf1[i]);
      INC(i);
END;
END WyslijRSbufor;



  PROCEDURE WatchDog;

  VAR
    wd_currSign : CARDINAL;
    wd_prevSign : CARDINAL;
    NOS         : REAL;
    waitTime    : CARDINAL;
    s,bufor1 :ARRAY [0..110] OF CHAR;
    IloscramekCom2 : REAL;

  BEGIN
    wd_prevSign := GetCurrDataSign( );
    StanHGPS := inicjacja;
    waitTime := 0;
    IloscramekCom2:=0.0;
    NOS:=0.0;
    LOOP
      Wait( waitTime );
      CASE StanHGPS OF
        inicjacja :
        
             (* ramka polozenia DGPS *)
             sprintf3( s,
             "%d.%02d%d ",
              polozenieGPSinicjac.Szerokosc.Stopnie,
              polozenieGPSinicjac.Szerokosc.Minuty,
              polozenieGPSinicjac.Szerokosc.DziesTys);
             Concat( 'fix position ', s, bufor );

             sprintf3( s,
             "%d.%02d%d ",
              polozenieGPSinicjac.Dlugosc.Stopnie,
              polozenieGPSinicjac.Dlugosc.Minuty,
              polozenieGPSinicjac.Dlugosc.DziesTys);

             Concat( bufor, s, bufor1 );

             sprintf3( s,
             "%3.1lf %d %d",
              polozebGPSinicjac.Wysokosc,
              GId,
              GRtcm);

            Concat( bufor1, s, bufor );
            (* inicjacja DGPS *)
         WyslijRSbufor('log com1 cmsa ontime 1');
         WyslijRSbufor('log com1 dopa ontime 1');
         WyslijRSbufor(bufor);          
         WyslijRSbufor('com2 1200,n,8,1,n,off');
         WyslijRSbufor('log com2 dcsa ontime 1');
  
          StanHGPS := odczyt;
          waitTime := TInOneSecond( ) * 5;
          actPart := head;
        |
        odczyt :
        GPSReceive(IloscramekCom2,
                   NOS,
                   wd_currSign);
          IF wd_currSign = wd_prevSign
          THEN
            (*NumberOfSattelites := NilValC;*)
            StanHGPS := inicjacja;
            waitTime := 0;
          ELSE
            wd_prevSign := wd_currSign;
            waitTime := TInOneSecond( ) * 2;
          END (* if wd_currSign *);
       |
       koniecWatchDog:
           EXIT
      END (* case StanHGPS *);
    END (* loop *);
  END WatchDog;



   PROCEDURE  Inicjacja(
                        GPSinicjac:PolozenieGeo;
                        polozebGPS :PolozenieBiegunWysokosc
                        ) ;



  BEGIN
     (* inicjacja zmiennych *)
     iloscramekCom2:=  0.0;
     NumberOfSattelites := 0.0;
     polozenieGPSinicjac :=GPSinicjac;      
     polozebGPSinicjac   :=polozebGPS;
     (* proces czytania w WatchDogu*)
     
     STARTPROCESS( WatchDog, 0800H, 0 );

END Inicjacja;

PROCEDURE KoniecGPS();
BEGIN
StanHGPS:=koniecWatchDog;
WyslijRSbufor('unlogall');
END KoniecGPS;

  VAR
  wynikInicjac :BOOLEAN;


BEGIN
      (* inicjacja portu szeregowego *)         
      Init(szybkoscTransmisji,liczBitStopu,
           parzystosc,rodzParzyst,
           liczBitDan,wynikInicjac);   
      StartReading;
      IF NOT wynikInicjac THEN
       Info("Blad inicjacji portu szeregowego");
      END;


END INIcja.


