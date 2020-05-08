(*.F- *)
(**********************************************************************
|  Title   : Obsluga plikow dla pomiaru VHF
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    08-12-96: created
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE H_Files;

  IMPORT
    Files, Strings;

  FROM Files IMPORT
    Kopiuj, ReadDef, XRefKind;

  FROM FIO IMPORT
    Close, Create, Open, Write, Length, File, GetDir, CD, Read;

  FROM CommonTypes IMPORT
    (* CONST *) NilValC, NilValI, refTab, Str99, PolozenieGeo;

  FROM Messages IMPORT
    Message, NewMessage, Display;

  FROM SYSTEM IMPORT
    ADR, WORD;

  FROM H_Odb IMPORT
    agc, flg;

  FROM Strings IMPORT
    ConstAssign, Assign;

  FROM CommonData IMPORT
    SciezkaOpisuPomiaru;

  FROM RTSMain IMPORT
    Terminate, Status;

  FROM ScannerI IMPORT
    pilErr;

  FROM Czas IMPORT
    Godzina, Data;

  FROM GPSRead IMPORT
    GPSScan, StanGPS, StanyGPS;

  FROM StdIO IMPORT
    sprintf2;

  FROM MANAGER IMPORT
    Assert;

  FROM H_Oblot IMPORT
    CoKtoraProbka;

  FROM H_CommonTypes IMPORT
    ProceduraT;

  CONST
    Pomiar    = FALSE;
    POLOZENIE = 'polozeni.dat';

  TYPE
    NamString =
      ARRAY [ 0 .. 12 ] OF CHAR;
    NameDsc   =
      NamString;

  VAR
    FileErr  : Message;
    NamesSig : NameDsc;
    FileSig  : CARDINAL;
        (* ********)
    PolFile  : File;
    Licznik  : CARDINAL;


  PROCEDURE StartFiles
            (    new : BOOLEAN );

  VAR
    blad     : BOOLEAN;
    FileProc : PROCEDURE
                 (     ARRAY OF CHAR ) : CARDINAL;

  BEGIN (* StartFiles *)
    blad := FALSE;
    IF new
    THEN
      FileProc := Create;
      PolFile := Create( POLOZENIE );
    ELSE
      FileProc := Open;
      PolFile := MAX( CARDINAL );
    END (* if Create *);
    FileSig := FileProc( NamesSig );
    blad := FileSig = NilValC;
    IF blad
    THEN
      Display( FileErr );
    END (* if blad *);
  END StartFiles;


  PROCEDURE CreateFiles;

  BEGIN
    Files.CreateFiles( Pomiar );
    StartFiles( TRUE );
  END CreateFiles;


  PROCEDURE OpenFiles;

  VAR
    CurDir : Str99;
    Dir    : Str99;

  BEGIN
    GetDir( CurDir );
    Assign( SciezkaOpisuPomiaru, Dir );
    Dir[Strings.Length( Dir ) - 1] := 0C;
    IF NOT CD( Dir )
    THEN
      Terminate( Warning );   (* jakas grubsza sprawa *)
    END (* if *);
    Files.OpenFiles( Pomiar );
    StartFiles( FALSE );
    IF NOT CD( CurDir )
    THEN
      Terminate( Warning );   (* jakas grubsza sprawa *)
    END (* if *);
  END OpenFiles;


  PROCEDURE SaveData
            (    nowySegment : BOOLEAN );

  VAR
    ok : BOOLEAN;


    PROCEDURE ZapiszPolozenie(): BOOLEAN;

    VAR
      str : Str99;
      Cz : RECORD
        d, M, y   : CARDINAL;
        h, m, s   : CARDINAL;
      END;
      pg  : PolozenieGeo;
      ok  : BOOLEAN;

    BEGIN
      IF Licznik = 0
      THEN
        IF GPSScan( pg ) - StanGPS { SaNoweDane } = StanGPS { }
        THEN
          WITH Cz DO
            Godzina( h, m, s );
            Data( d, M, y );
          END;
          sprintf2( str, "%02d.%02d.%4d  %02d:%02d:%02d     %3dø%02d'%02dE %2dø%02d'%02dN\n",
                    Cz, pg );
          ok := Write( PolFile, ADR( str ), Strings.Length( str ) );
        END (* if GPSScan *);
        Licznik := CoKtoraProbka + 1;
      ELSE
        DEC( Licznik );
      END (* if Licznik *);
      RETURN ok;
    END ZapiszPolozenie;

  BEGIN
    Files.SaveData( Pomiar, flg, nowySegment, pilErr );
    ok := Write( FileSig, ADR( agc ), 2 );
    ok := ok AND ZapiszPolozenie( );
  END SaveData;


  PROCEDURE LoadData
            (    nowySegment : BOOLEAN ) : BOOLEAN;

  VAR
    ok : BOOLEAN;


    PROCEDURE Rd
              (     F : File;
                VAR w : WORD );

    BEGIN
      IF ( F # MAX( CARDINAL ) )
      THEN
        ok := ok & Read( F, ADR( w ), 2 );
      END (* if *);
    END Rd;

  BEGIN
    Files.LoadData( Pomiar, flg, nowySegment, pilErr );
    Rd( FileSig, agc );
    RETURN ok;
  END LoadData;


  PROCEDURE CloseFiles;

  BEGIN
    Files.CloseFiles( Pomiar );
    Close( FileSig );
    Close( PolFile );
  END CloseFiles;


  PROCEDURE OpenSignalFiles
            (    procedura : ProceduraT ) : CARDINAL;

  BEGIN
    CASE procedura OF
      pOrbita :
        Files.OpenSignalFiles( GPSAxref, Pomiar ); |
      pPromien :
        Files.OpenSignalFiles( GPSRxref, Pomiar );
    END (* case procedura *);
    StartFiles( FALSE );
    RETURN VAL( CARDINAL, Length( FileSig ) DIV VAL( LONGINT, 2 ) );
  END OpenSignalFiles;


  PROCEDURE ReadAllSignals
            ( VAR signalsCV : INTEGER;
              VAR refDisCV  : WORD    );

  VAR
    refCV : refTab;

  BEGIN
    Files.ReadAllSignals( refCV, refDisCV, Pomiar );
    ReadDef( FileSig, signalsCV, NilValI );
  END ReadAllSignals;


  PROCEDURE CloseSignalFiles;

  BEGIN
    Files.CloseSignalFiles( Pomiar );
    CloseFiles;
  END CloseSignalFiles;


  PROCEDURE KopiujWszystkiePliki
            ( VAR DoKatalogu : ARRAY OF CHAR );

  BEGIN
    Files.KopiujWszystkiePliki( DoKatalogu, Pomiar );
    Kopiuj( NamesSig, DoKatalogu );
    Kopiuj( POLOZENIE, DoKatalogu );
  END KopiujWszystkiePliki;


  PROCEDURE GetSigFileName
            ( VAR name : ARRAY OF CHAR );

  BEGIN
    Assign( NamesSig, name );
  END GetSigFileName;


  PROCEDURE InitLocals;

  BEGIN
    NewMessage( FileErr, "Powstaˆ krytyczny bˆ¥d: Nie mo¾na utworzyc pliku",
                BITSET( 0E0F1H ) );
    ConstAssign( "H_AGC___.DAT", NamesSig );
    FileSig := NilValC;
  END InitLocals;

BEGIN
  Licznik := 0;
  InitLocals;
END H_Files.
