(*.F- *)
(**********************************************************************
|  Title   : Kalibracja sygnalow wejsciowych
|  Author  : Michal Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|     01.11.95: M.Postol
|       Calkowicie nowa koncepcja LookupM, OmnibearingV, LOCMOD, GSMOD.
|       Modul przeformatowany.
|    Rel. 002
|    31-12-95: M.Postol
|      wprowadzono ograniczenia na wartosci sygnalow po kalibracji
|    Rel 3.0. MPostol
|      Zmienilem komunikat o bledzie krytycznym
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE Kalibracja;

  FROM RealConversions IMPORT
    RealToString, StringToReal;

  FROM Ini IMPORT
    GetPrivateProfileString, WritePrivateProfileString;

  FROM MMMouse IMPORT
    HideCursor, ShowCursor;

  FROM SYSTEM IMPORT
    ADDRESS, ADR;

  FROM Strings IMPORT
    Insert, Assign;

  FROM Sounds IMPORT
    Sound, NoSound;

  FROM StdIO IMPORT
    sprintf;

  FROM MathLib0 IMPORT
    real, entier;

  FROM GrafUtil IMPORT
    Info;

  FROM Kl_FGenerators  IMPORT
    LookupM;
    
  FROM FIO IMPORT
    GetFileStamp, Open, Close;

  IMPORT
    Terminal;

  TYPE

  VAR
    WystapilBlad : BOOLEAN;

  MODULE ErrorHand [ 0 ];

    IMPORT
      Errors, InputSignal;

    EXPORT
      GetErrReset, SetError;

    VAR
      lastError : Errors;

    PROCEDURE GetErrReset() : Errors;

    VAR
      myErr : Errors;

    BEGIN
      myErr := lastError;
      lastError := Errors { };
      RETURN myErr;
    END GetErrReset;

    PROCEDURE SetError
              (    s : InputSignal );

    BEGIN
      INCL( lastError, s );
    END SetError;

  BEGIN
    lastError := Errors { };
  END ErrorHand;

  PROCEDURE OmnibearingV
            (     x     : INTEGER; (* wyrazone w 0.01ø *)
                  Kanal : CARDINAL;
              VAR ok    : BOOLEAN  ) : INTEGER (* wyrazone w 0.01ø *);

  VAR
    r : REAL;

    PROCEDURE Lookup
              (     X        : REAL;
                VAR pnkt_kal : ARRAY OF REAL;
                VAR st       : ARRAY OF REAL ) : REAL;

    VAR
      nextidx : CARDINAL;
      idx     : CARDINAL;
      a       : REAL;
      Xi      : REAL;
      Xiplus1 : REAL;

    BEGIN (* Lookup *)
      idx := 0;
      nextidx := 1;
      LOOP
        IF ( st[idx] <= X ) AND ( X < st[nextidx] )
        THEN
          Xi := st[idx];
          Xiplus1 := st[nextidx];
          EXIT
        ELSIF st[idx] > st[nextidx]
        THEN
          IF st[idx] <= X
          THEN
            Xi := st[idx];
            Xiplus1 := st[nextidx] + 360.0;
            EXIT;
          ELSIF X < st[nextidx]
          THEN
            Xi := st[idx] - 360.0;
            Xiplus1 := st[nextidx];
            EXIT
          END (* if st *);
        END (* if *);
        INC( idx );
        IF idx = HIGH( st )
        THEN
          nextidx := 0;
        ELSE
          INC( nextidx );
        END (* if idx *);
      END (* loop *);
      IF nextidx = 0
      THEN
        a := ( 360.0 - pnkt_kal[idx] ) / ( Xiplus1 - Xi );
      ELSE
        a := ( pnkt_kal[nextidx] - pnkt_kal[idx] ) / ( Xiplus1 - Xi );
      END (* if nextidx *);
      RETURN ( X - Xi ) * a + pnkt_kal[idx];
    END Lookup;

  BEGIN
    IF x = MIN( INTEGER )
    THEN
      ok := FALSE;
      RETURN x;
    END (* if x *);
    ok := TRUE;
    r := real( x ) / 100.0;
    IF r < 0.0
    THEN
      r := r + 360.0;
    END (* if r *);
    r := Lookup( r, OmnibearingProgi, Par[Kanal].Omnibearing );
    IF r > 180.0
    THEN
      r := r - 360.0;
    END (* if r *);
    RETURN entier( r * 100.0 );
  END OmnibearingV;

  PROCEDURE Lookup
            (     val   : REAL;
                  s     : InputSignal;
                  kanal : CommCh;
              VAR ok    : BOOLEAN     ) : REAL;


  VAR
    valCal : REAL;

  BEGIN
    CASE s OF
      LocPrcMod, GsPrcMod, VorRefPrcMod, VorVarPrcMod, SubcarPrcMod, 
      DmeSquitter, DmePrcReply :
        valCal := LookupM( val, TabKalib2P[kanal, s].punktyKal, TabKalib2P[
                           kanal, s].punktyPom, ok );
      |
      LocDev :
        valCal := LookupM( val, LOC_DEVPuntyKal, Par[kanal].LocDev, ok );
      |
      GsDev :
        valCal := LookupM( val, GS_DEVPuntyKal, Par[kanal].GsDev, ok );
      |
      VorAgc, LocAgc:
        valCal := LookupM( val, AGCwartosciProgow, Par[kanal].VorAgc, ok );
      |
      GsAgc :
        valCal := LookupM( val, AGCwartosciProgow, Par[kanal].GsAgc, ok );
      |
      AdfAgc :
        valCal := LookupM( val, AGCwartosciProgow, Par[kanal].AdfAgc, ok );
      |
      VhfAgc :
        valCal := LookupM( val, AGCwartosciProgow, Par[kanal].VhfAgc, ok );
      |
      MkrAgc :
        valCal := LookupM( val, AGCwartosciProgowM, Par[kanal].MkrAgc, ok );
      |
      DmeAgc :
        valCal := LookupM( val, AGCwartosciProgowD, Par[kanal].DmeAgc, ok );
    END (* case s *);
    IF NOT ok
    THEN
      SetError( s );
    END (* if *);
    RETURN valCal
  END Lookup;

  PROCEDURE Error
            (    s     : ARRAY OF CHAR;
                 Fatal : BOOLEAN       );

    PROCEDURE Status
              (    s : ARRAY OF CHAR );

    VAR
      ch : CHAR;

    BEGIN
      Info( s );
      Terminal.Read( ch );
      IF Fatal OR Terminal.KeyPressed( )
      THEN
        Terminal.Read( ch );
      END (* if Fatal *);
    END Status;

  BEGIN (* Error *)
    HideCursor;
    WystapilBlad := TRUE;
    Status( s );
    IF Fatal
    THEN
      Status( "Program si© zakoäczy z powodu krytycznego bˆ©du" );
      HALT;
    END (* if Fatal *);
  END Error;

  PROCEDURE LoadSegmentTables;

    PROCEDURE LoadValue
              (     Segment,
                    EntryBase,
                    Selector  : ARRAY OF CHAR;
                    Default   : REAL;
                VAR r         : REAL          );

    VAR
      Entry,
      Str,
      t     : ARRAY [ 0 .. 128 ] OF CHAR;
      ok    : BOOLEAN;
      d     : RECORD
                s1, s2 : ADDRESS;
              END;

    BEGIN
      Assign( EntryBase, Entry );
      Insert( Selector, Entry, 0FFFH );
      GetPrivateProfileString( Segment, Entry, "", Str, "kalibrac.ini" );
      StringToReal( Str, r, ok );
      IF NOT ok
      THEN
        Assign( Segment, t );
        d.s1 := ADR( t );
        d.s2 := ADR( Entry );
        sprintf( Str, "Bˆ¥d przy wczytywaniu tablicy: [%s],<%s>", d )
        ;
        Error( Str, FALSE );
        r := Default;
      END (* if *);
    END LoadValue;

    PROCEDURE LoadReal
              (     Kanal     : CARDINAL;
                    Segmnt,
                    EntryBase : ARRAY OF CHAR;
                    DefaultA  : REAL;
                VAR s         : REAL          );

    VAR
      seg : ARRAY [ 0 .. 99 ] OF CHAR;

    BEGIN
      sprintf( seg, "#%d#", Kanal );
      Insert( Segmnt, seg, 0 );
      LoadValue( seg, EntryBase, ".A", DefaultA, s );
    END LoadReal;

    PROCEDURE LoadTable
              (     Kanal  : CARDINAL;
                    Segmnt : ARRAY OF CHAR;
                VAR s      : ARRAY OF REAL );

    VAR
      idx   : ARRAY [ 0 .. 20 ] OF CHAR;
      count : CARDINAL;

    BEGIN
      FOR count := 0 TO HIGH( s ) DO
        sprintf( idx, "<%d>", count );
        LoadReal( Kanal, Segmnt, idx, 0.0, s[count] );
      END (* for count *);
    END LoadTable;

    PROCEDURE LoadChannel
              (    Kanal : CARDINAL );

      PROCEDURE LoadSegment
                (     Kanal     : CARDINAL;
                      Segmnt,
                      EntryBase : ARRAY OF CHAR;
                      DefaultA  : REAL;
                  VAR s         : Segment       );

      VAR
        seg : ARRAY [ 0 .. 99 ] OF CHAR;

      BEGIN
        sprintf( seg, "#%d#", Kanal );
        Insert( Segmnt, seg, 0 );
        LoadValue( seg, EntryBase, ".A", DefaultA, s.A );
        LoadValue( seg, EntryBase, ".B", 0.0, s.B );
      END LoadSegment;

    VAR
      E : ARRAY [ 0 .. 31 ] OF CHAR;
      i : CARDINAL;

    BEGIN
      LoadTable( Kanal, "LOC%MOD_PP", TabKalib2P[Kanal, LocPrcMod].punktyPom );
      LoadTable( Kanal, "GS%MOD_PP", TabKalib2P[Kanal, GsPrcMod].punktyPom );
      LoadTable( Kanal, "VOR.REF%MOD_PP", TabKalib2P[Kanal, VorRefPrcMod].
                 punktyPom );
      LoadTable( Kanal, "VOR.VAR%MOD_PP", TabKalib2P[Kanal, VorVarPrcMod].
                 punktyPom );
      LoadTable( Kanal, "SUBCAR%MOD_PP", TabKalib2P[Kanal, SubcarPrcMod].
                 punktyPom );
      LoadTable( Kanal, "DME.SQUITTER_PP", TabKalib2P[Kanal, DmeSquitter].
                 punktyPom );
      LoadTable( Kanal, "DME%REPLY_PP", TabKalib2P[Kanal, DmePrcReply].
                 punktyPom );
      LoadTable( Kanal, "LOC%MOD_PK", TabKalib2P[Kanal, LocPrcMod].punktyKal );
      LoadTable( Kanal, "GS%MOD_PK", TabKalib2P[Kanal, GsPrcMod].punktyKal );
      LoadTable( Kanal, "VOR.REF%MOD_PK", TabKalib2P[Kanal, VorRefPrcMod].
                 punktyKal );
      LoadTable( Kanal, "VOR.VAR%MOD_PK", TabKalib2P[Kanal, VorVarPrcMod].
                 punktyKal );
      LoadTable( Kanal, "SUBCAR%MOD_PK", TabKalib2P[Kanal, SubcarPrcMod].
                 punktyKal );
      LoadTable( Kanal, "DME.SQUITTER_PK", TabKalib2P[Kanal, DmeSquitter].
                 punktyKal );
      LoadTable( Kanal, "DME%REPLY_PK", TabKalib2P[Kanal, DmePrcReply].
                 punktyKal );
      WITH Par[Kanal] DO
        LoadTable( Kanal, "LOC.DEV", LocDev );
        LoadTable( Kanal, "GS.DEV", GsDev );
        LoadSegment( Kanal, "LOC%MOD", "Poprawka", 40.0 / 9000.0, LocPrcMod );
        LoadSegment( Kanal, "GS%MOD", "Poprawka", 80.0 / 9000.0, GsPrcMod );
        LoadSegment( Kanal, "VOR.REF%MOD", "Poprawka", 30.0 / 9000.0,
                     VorRefPrcMod );
        LoadSegment( Kanal, "VOR.VAR%MOD", "Poprawka", 30.0 / 9000.0,
                     VorVarPrcMod );
        LoadSegment( Kanal, "SUBCAR%MOD", "Poprawka", 30.0 / 9000.0,
                     SubcarPrcMod );
        FOR i := 0 TO 35 DO
          sprintf( E, "Poprawka%02d0", i );
          LoadReal( Kanal, "VOR.OMNIBEARING", E, FLOAT( i * 10 ), Omnibearing[i
                    ] );
        END (* for i *);
        LoadTable( Kanal, "VOR.AGC", VorAgc );
        LoadTable( Kanal, "GS.AGC", GsAgc );
        LoadTable( Kanal, "ADF.AGC", AdfAgc );
        LoadTable( Kanal, "VHF.AGC", VhfAgc );
        LoadTable( Kanal, "MKR.AGC", MkrAgc );
        LoadTable( Kanal, "DME.AGC", DmeAgc );
        LoadSegment( Kanal, "DME.SQUITTER", "Poprawka", 0.0, DmeSquitter );
        LoadSegment( Kanal, "DME%REPLY", "Poprawka", 0.0, DmePrcReply );
      END (* with Par *);
      LoadTable( Kanal, "AGC_Coefficient_Tab", inputCoeff[Kanal]);
    END LoadChannel;
    
  BEGIN (* LoadSegmentTables *)
    Info( "Czytane dane dla kanaˆu `0'" );
    LoadChannel( 0 );
    Info( "Czytane dane dla kanaˆu `1'" );
    LoadChannel( 1 );
    LoadTable( 0, "AGCwartosciProgow", AGCwartosciProgow );
    LoadTable( 0, "AGCwartosciProgowM", AGCwartosciProgowM );
    LoadTable( 0, "AGCwartosciProgowD", AGCwartosciProgowD );
    LoadTable( 0, "GS_DEVPuntyKal",     GS_DEVPuntyKal );
    LoadTable( 0, "LOC_DEVPuntyKal",    LOC_DEVPuntyKal );
    LoadValue( 'Auto_Cal_Delays', '', 'LocDev_delay',       10.0, LocDev_delay);
    LoadValue( 'Auto_Cal_Delays', '', 'GsDev_delay',        10.0, GsDev_delay);
    LoadValue( 'Auto_Cal_Delays', '', 'LocPrcMod_delay',    10.0, LocPrcMod_delay);
    LoadValue( 'Auto_Cal_Delays', '', 'GsPrcMod_delay',     10.0, GsPrcMod_delay);
    LoadValue( 'Auto_Cal_Delays', '', 'VorRefPrcMod_delay', 10.0, VorRefPrcMod_delay);
    LoadValue( 'Auto_Cal_Delays', '', 'VorVarPrcMod_delay', 10.0, VorVarPrcMod_delay);
    LoadValue( 'Auto_Cal_Delays', '', 'SubcarPrcMod_delay', 10.0, SubcarPrcMod_delay);
    LoadValue( 'Auto_Cal_Delays', '', 'Omnibearing_delay',  10.0, Omnibearing_delay);
    LoadValue( 'Auto_Cal_Delays', '', 'VorAgc_delay',       10.0, VorAgc_delay);
    LoadValue( 'Auto_Cal_Delays', '', 'GsAgc_delay',        10.0, GsAgc_delay);
    LoadValue( 'Auto_Cal_Delays', '', 'MkrAgc_delay',       10.0, MkrAgc_delay);
  END LoadSegmentTables;

  PROCEDURE SaveSegmentTables;

    PROCEDURE SaveValue
              (     Segment,
                    EntryBase,
                    Selector  : ARRAY OF CHAR;
                VAR r         : REAL          );

    VAR
      Entry,
      Str   : ARRAY [ 0 .. 128 ] OF CHAR;
      ok    : BOOLEAN;
      d     : RECORD
                s1, s2 : ADDRESS;
              END;

    BEGIN (* SaveValue *)
      Assign( EntryBase, Entry );
      Insert( Selector, Entry, 0FFFH );
      RealToString( r, 5, 10, Str, ok );
      WritePrivateProfileString( Segment, Entry, Str, "kalibrac.ini" );
      IF NOT ok
      THEN
        d.s1 := ADR( Segment );
        d.s2 := ADR( Entry );
        sprintf( Str, "Bˆ¥d przy zapisywaniu tablicy kalibracji:[%s],<%s>\n", d
        );
        Error( Str, TRUE );
      END (* if *);
    END SaveValue;

    PROCEDURE SaveReal
              (     Kanal     : CARDINAL;
                    Segmnt,
                    EntryBase : ARRAY OF CHAR;
                VAR s         : REAL          );

    VAR
      seg : ARRAY [ 0 .. 99 ] OF CHAR;

    BEGIN
      sprintf( seg, "#%d#", Kanal );
      Insert( Segmnt, seg, 0 );
      SaveValue( seg, EntryBase, ".A", s );
    END SaveReal;

    PROCEDURE SaveTable
              (     Kanal  : CARDINAL;
                    Segmnt : ARRAY OF CHAR;
                VAR s      : ARRAY OF REAL );

    VAR
      idx   : ARRAY [ 0 .. 20 ] OF CHAR;
      count : CARDINAL;

    BEGIN
      FOR count := 0 TO HIGH( s ) DO
        sprintf( idx, "<%d>", count );
        SaveReal( Kanal, Segmnt, idx, s[count] );
      END (* for count *);
    END SaveTable;

    PROCEDURE SaveChannel
              (    Kanal : CARDINAL );

    VAR
      E : ARRAY [ 0 .. 31 ] OF CHAR;
      i : CARDINAL;

      PROCEDURE SaveSegment
                (     Kanal     : CARDINAL;
                      Segmnt,
                      EntryBase : ARRAY OF CHAR;
                   VAR s         : Segment       );

      VAR
        seg : ARRAY [ 0 .. 99 ] OF CHAR;

      BEGIN
        sprintf( seg, "#%d#", Kanal );
        Insert( Segmnt, seg, 0 );
        SaveValue( seg, EntryBase, ".A", s.A );
        SaveValue( seg, EntryBase, ".B", s.B );
      END SaveSegment;

    BEGIN (* SaveChannel*)
      SaveTable( Kanal, "LOC%MOD_PP", TabKalib2P[Kanal, LocPrcMod].punktyPom );
      SaveTable( Kanal, "GS%MOD_PP", TabKalib2P[Kanal, GsPrcMod].punktyPom );
      SaveTable( Kanal, "VOR.REF%MOD_PP", TabKalib2P[Kanal, VorRefPrcMod].
                 punktyPom );
      SaveTable( Kanal, "VOR.VAR%MOD_PP", TabKalib2P[Kanal, VorVarPrcMod].
                 punktyPom );
      SaveTable( Kanal, "SUBCAR%MOD_PP", TabKalib2P[Kanal, SubcarPrcMod].
                 punktyPom );
      SaveTable( Kanal, "DME.SQUITTER_PP", TabKalib2P[Kanal, DmeSquitter].
                 punktyPom );
      SaveTable( Kanal, "DME%REPLY_PP", TabKalib2P[Kanal, DmePrcReply].
                 punktyPom );
      SaveTable( Kanal, "LOC%MOD_PK", TabKalib2P[Kanal, LocPrcMod].punktyKal );
      SaveTable( Kanal, "GS%MOD_PK", TabKalib2P[Kanal, GsPrcMod].punktyKal );
      SaveTable( Kanal, "VOR.REF%MOD_PK", TabKalib2P[Kanal, VorRefPrcMod].
                 punktyKal );
      SaveTable( Kanal, "VOR.VAR%MOD_PK", TabKalib2P[Kanal, VorVarPrcMod].
                 punktyKal );
      SaveTable( Kanal, "SUBCAR%MOD_PK", TabKalib2P[Kanal, SubcarPrcMod].
                 punktyKal );
      SaveTable( Kanal, "DME.SQUITTER_PK", TabKalib2P[Kanal, DmeSquitter].
                 punktyKal );
      SaveTable( Kanal, "DME%REPLY_PK", TabKalib2P[Kanal, DmePrcReply].
                 punktyKal );
      WITH Par[Kanal] DO
        SaveTable( Kanal, "LOC.DEV", LocDev );
        SaveTable( Kanal, "GS.DEV", GsDev );
        SaveSegment( Kanal, "LOC%MOD", "Poprawka", LocPrcMod );
        SaveSegment( Kanal, "GS%MOD", "Poprawka", GsPrcMod );
        SaveSegment( Kanal, "VOR.REF%MOD", "Poprawka", VorRefPrcMod );
        SaveSegment( Kanal, "VOR.VAR%MOD", "Poprawka", VorVarPrcMod );
        SaveSegment( Kanal, "SUBCAR%MOD", "Poprawka", SubcarPrcMod );
        FOR i := 0 TO 35 DO
          sprintf( E, "Poprawka%02d0", i );
          SaveReal( Kanal, "VOR.OMNIBEARING", E, Omnibearing[i] );
          SaveTable( Kanal, "MKR.AGC", MkrAgc );
        END (* for i *);
        SaveTable( Kanal, "VOR.AGC", VorAgc );
        SaveTable( Kanal, "GS.AGC", GsAgc );
        SaveTable( Kanal, "ADF.AGC", AdfAgc );
        SaveTable( Kanal, "VHF.AGC", VhfAgc );
        SaveTable( Kanal, "MKR.AGC", MkrAgc );
        SaveTable( Kanal, "DME.AGC", DmeAgc );
        SaveSegment( Kanal, "DME.SQUITTER", "Poprawka", DmeSquitter );
        SaveSegment( Kanal, "DME%REPLY", "Poprawka", DmePrcReply );
      END (* with Par *);
      SaveTable( Kanal, "AGC_Coefficient_Tab", inputCoeff[Kanal]);
    END SaveChannel;

  BEGIN
    Info( "Zapisywane dane dla kanaˆu `0'" );
    SaveChannel( 0 );
    Info( "Zapisywane dane dla kanaˆu `1'" );
    SaveChannel( 1 );
    SaveTable( 0, "AGCwartosciProgow", AGCwartosciProgow );
    SaveTable( 0, "AGCwartosciProgowM", AGCwartosciProgowM );
    SaveTable( 0, "AGCwartosciProgowD", AGCwartosciProgowD );
    SaveTable( 0, "LOC_DEVPuntyKal", LOC_DEVPuntyKal );
    SaveTable( 0, "GS_DEVPuntyKal", GS_DEVPuntyKal );
    SaveValue( 'Auto_Cal_Delays', '', 'LocDev_delay',       LocDev_delay);
    SaveValue( 'Auto_Cal_Delays', '', 'GsDev_delay',        GsDev_delay);
    SaveValue( 'Auto_Cal_Delays', '', 'LocPrcMod_delay',    LocPrcMod_delay);
    SaveValue( 'Auto_Cal_Delays', '', 'GsPrcMod_delay',     GsPrcMod_delay);
    SaveValue( 'Auto_Cal_Delays', '', 'VorRefPrcMod_delay', VorRefPrcMod_delay);
    SaveValue( 'Auto_Cal_Delays', '', 'VorVarPrcMod_delay', VorVarPrcMod_delay);
    SaveValue( 'Auto_Cal_Delays', '', 'SubcarPrcMod_delay', SubcarPrcMod_delay);
    SaveValue( 'Auto_Cal_Delays', '', 'Omnibearing_delay',  Omnibearing_delay);
    SaveValue( 'Auto_Cal_Delays', '', 'VorAgc_delay',       VorAgc_delay);
    SaveValue( 'Auto_Cal_Delays', '', 'GsAgc_delay',        GsAgc_delay);
    SaveValue( 'Auto_Cal_Delays', '', 'MkrAgc_delay',       MkrAgc_delay );
  END SaveSegmentTables;

  VAR
    for_counter : CARDINAL;
    void        : CARDINAL;
    f           : CARDINAL;
BEGIN
  FOR for_counter := 0 TO 35 DO
    OmnibearingProgi[for_counter] := FLOAT( for_counter * 10 );
  END (* for i *);
  WystapilBlad := FALSE;
  LoadSegmentTables;
  f := Open( "Kalibracja.ini" );
  WITH DataOstatniejKalibracji DO
    GetFileStamp( f, d.d, d.m, d.y, t.h, t.m, t.s );
  END;
  Close( f );
  IF WystapilBlad
  THEN
    Sound( 800 );
    FOR for_counter := 0 TO 35000 DO
      Sound( for_counter DIV 2 );
    END (* for i *);
    NoSound;
    ShowCursor;
  END (* if WystapilBlad *);
END Kalibracja.
