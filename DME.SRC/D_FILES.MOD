(*.F- *)
(**********************************************************************
|  Title   : Obsluga plikow dla pomiaru DME
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE D_Files;

  IMPORT
    Files, Strings;

  FROM Files IMPORT
    Kopiuj, ReadDef, XRefKind;

  FROM FIO IMPORT
    Close, Create, Open, Write, Length, Read, CD, GetDir, File;

  FROM CommonTypes IMPORT
    (* TYPE *) GlownyOdbiornikT, signTabC,
    (* CONST *) NilValC, NilValI;

  FROM D_CommonTypes  IMPORT
    ProceduraT;

  FROM Messages IMPORT
    Message, NewMessage, Display;

  FROM SYSTEM IMPORT
    ADR, WORD;

  FROM D_results IMPORT
    Signals;

  FROM D_Odb IMPORT
    Squitter, Reply, Agc, Dis, flg;

  FROM Strings IMPORT
    Assign;

  FROM ScannerI IMPORT
    pilErr;

  FROM CommonData IMPORT
    SciezkaOpisuPomiaru;         (* uzywane tylko w danych archiwalnych *)

  FROM RTSMain IMPORT
    Terminate, Status;

  CONST
    Pomiar = TRUE;

  TYPE
    NamString =
      ARRAY [0 .. 12] OF CHAR;
    NameDsc   =
      ARRAY GlownyOdbiornikT OF NamString;
    TabRec    =
      ARRAY GlownyOdbiornikT OF CARDINAL;

  VAR
    FileErr  : Message;
    NamesSig : ARRAY Signals OF NameDsc;
    NamesDis : NameDsc;
    FileSig  : ARRAY Signals, GlownyOdbiornikT OF CARDINAL;
    FileDis  : TabRec;

  PROCEDURE StartFiles
            (    new : BOOLEAN );
  VAR
    odb      : GlownyOdbiornikT;
    blad     : BOOLEAN;
    sigIdx   : Signals;
    FileProc : PROCEDURE
                 (     ARRAY OF CHAR ) : CARDINAL;

  BEGIN
    blad := FALSE;
    IF new
    THEN
      FileProc := Create;
    ELSE
      FileProc := Open;
    END (* if Create *);
    FOR odb := goA TO goB DO
      FOR sigIdx := MIN(Signals) TO MAX(Signals) DO
        FileSig[sigIdx, odb] := FileProc(NamesSig[sigIdx, odb]);
        blad := blad OR (FileSig[sigIdx, odb] = NilValC);
      END (* for sigIdx *);
      FileDis[odb] := FileProc(NamesDis[odb]);
    END (* for odb *);
    IF blad
    THEN
      Display(FileErr);
    END (* if blad *);
  END StartFiles;

  PROCEDURE CreateFiles;

  BEGIN
    Files.CreateFiles(Pomiar);
    StartFiles(TRUE);
  END CreateFiles;

  PROCEDURE OpenFiles;
  VAR
    CurDir,
    Dir    : ARRAY[0..99] OF CHAR;
  BEGIN
    GetDir( CurDir );
    Assign( SciezkaOpisuPomiaru, Dir );
    Dir[ Strings.Length( Dir )-1 ] := 0C;
    IF NOT CD( Dir ) THEN
      Terminate( Warning ); (* jakas grubsza sprawa *)
    END;
    Files.OpenFiles(Pomiar);
    StartFiles(FALSE);
    IF NOT CD( CurDir ) THEN
      Terminate( Warning ); (* jakas grubsza sprawa *)
    END;
  END OpenFiles;

  PROCEDURE SaveData
            (    nowySegment : BOOLEAN );
  VAR
    odb : GlownyOdbiornikT;
    ok  : BOOLEAN;

  BEGIN
    Files.SaveData(Pomiar, flg, nowySegment, pilErr);
    FOR odb := goA TO goB DO
      ok := Write(FileSig[Squiter, odb], ADR(Squitter[odb]), 2);
      ok := Write(FileSig[Replay, odb], ADR(Reply[odb]), 2);
      ok := Write(FileSig[AGC, odb], ADR(Agc[odb]), 2);
      ok := Write(FileDis[odb], ADR(Dis[odb]), 2);
    END (* for odb *);
  END SaveData;

  PROCEDURE LoadData
            (    nowySegment : BOOLEAN ) : BOOLEAN;
  VAR
    odb : GlownyOdbiornikT;
    ok  : BOOLEAN;

      PROCEDURE Rd( F : File; VAR w : WORD );
        BEGIN
          IF (F # MAX(CARDINAL)) THEN
            ok := ok & Read( F, ADR( w ), 2 );
          END;
        END Rd;

  BEGIN
    Files.LoadData(Pomiar, flg, nowySegment, pilErr);
    ok := TRUE;
    FOR odb := goA TO goB DO
      Rd(FileSig[Squiter, odb], Squitter[odb]);
      Rd(FileSig[Replay, odb], Reply[odb]);
      Rd(FileSig[AGC, odb], Agc[odb]);
      Rd(FileDis[odb], Dis[odb]);
    END (* for odb *);
    RETURN ok;
  END LoadData;

  PROCEDURE CloseFiles;
  VAR
    sigIdx : Signals;
    odb    : GlownyOdbiornikT;

  BEGIN
    Files.CloseFiles(Pomiar);
    FOR odb := goA TO goB DO
      FOR sigIdx := MIN(Signals) TO MAX(Signals) DO
        Close(FileSig[sigIdx, odb]);
      END (* for sigIdx *);
      Close(FileDis[odb]);
    END (* for ix *);
  END CloseFiles;

  PROCEDURE OpenSignalFiles
            (    procedura : ProceduraT ) : CARDINAL;

  BEGIN
    CASE procedura OF
      pOkragBlad, pOkragZakres :
        Files.OpenSignalFiles(GPSAxref, Pomiar);
      |
      pPromienBlad, pPromienZakres :
        Files.OpenSignalFiles(GPSRxref, Pomiar);
    END (* case procedura *);
    StartFiles(FALSE);
    RETURN VAL(CARDINAL, Length(FileDis[goA]) DIV VAL(LONGINT, 2));
  END OpenSignalFiles;

  PROCEDURE ReadAllSignals
            ( VAR signalsAVcont : SignalsCVDsc;
              VAR dmeDistCV     : signTabC;
              VAR xRefCV        : WORD         );
  VAR
    sigIdx : Signals;
    odb    : GlownyOdbiornikT;

  BEGIN
    Files.ReadXref(xRefCV, Pomiar);
    FOR odb := goA TO goB DO
      FOR sigIdx := MIN(Signals) TO MAX(Signals) DO
        ReadDef(FileSig[sigIdx, odb], signalsAVcont[sigIdx, odb], NilValI);
      END (* for sigIdx *);
      ReadDef(FileDis[odb], dmeDistCV[odb], NilValC);
    END (* for odb *);
  END ReadAllSignals;

  PROCEDURE CloseSignalFiles;

  BEGIN
    Files.CloseSignalFiles(Pomiar);
    CloseFiles;
  END CloseSignalFiles;

  PROCEDURE KopiujWszystkiePliki
            ( VAR DoKatalogu : ARRAY OF CHAR );
  VAR
    odb    : GlownyOdbiornikT;
    sigIdx : Signals;

  BEGIN (* KopiujWszystkiePliki *)
    Files.KopiujWszystkiePliki(DoKatalogu, Pomiar);
    FOR odb := goA TO goB DO
      FOR sigIdx := MIN(Signals) TO MAX(Signals) DO
        Kopiuj(NamesSig[sigIdx, odb], DoKatalogu);
      END (* for sigIdx *);
      Kopiuj(NamesDis[odb], DoKatalogu);
    END (* for odb *);
  END KopiujWszystkiePliki;

  PROCEDURE GetFileName
            (     sig  : Signals;
                  odb  : GlownyOdbiornikT;
              VAR name : ARRAY OF CHAR    );

  BEGIN
    Assign(NamesSig[sig, odb], name);
  END GetFileName;

  PROCEDURE InitLocals;
  VAR
    sigIdx : Signals;
    odb    : GlownyOdbiornikT;

    PROCEDURE AssignName
              (     inStr : ARRAY OF CHAR;
                VAR name  : NameDsc       );
    VAR
      odb : GlownyOdbiornikT;

    BEGIN
      FOR odb := goA TO goB DO
        Assign(inStr, name[odb]);
        name[odb, 7] := CHR(ORD(odb) + ORD('A'));
      END (* for Pomiar *);
    END AssignName;

  BEGIN
    NewMessage(FileErr, "D_Files: Nie mozna utworzyc pliku", BITSET(0E0F1H));
    AssignName("D_SQT___.DAT", NamesSig[Replay]);
    AssignName("D_RPL___.DAT", NamesSig[Squiter]);
    AssignName("D_AGC___.DAT", NamesSig[AGC]);
    AssignName("D_DIS___.DAT", NamesDis);
    FOR odb := goA TO goB DO
      FOR sigIdx := MIN(Signals) TO MAX(Signals) DO
        FileSig[sigIdx, odb] := NilValC;
      END (* for sigIdx *);
      FileDis[odb] := NilValC;
    END (* for ix *);
  END InitLocals;

BEGIN
  InitLocals;
END D_Files.
