(*.F- *)
(**********************************************************************
|  Title   : Obsluga plikow dla pomiaru VOR
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE V_Files;

  IMPORT
    Files;

  FROM Files IMPORT
    Kopiuj, ReadDef, XRefKind;

  FROM FIO IMPORT
    Close, Create, Open, Write, Length, Read, CD, GetDir, File;

  FROM CommonTypes IMPORT
    (* TYPE *) GlownyOdbiornikT, OdnDlaPomOdlT, refTab, OdnDlaPomBleduT,
               signTabC,
    (* CONST *) NilValC, NilValI, SigNilVal;

  FROM Messages IMPORT
    Message, NewMessage, Display;

  FROM SYSTEM IMPORT
    ADR, WORD;

  FROM V_results IMPORT
    Signals;

  FROM V_Odb IMPORT
    (* VAR *) obr, var, ref, sub, agc, flg;

  FROM ScannerI IMPORT
    pilErr;

  FROM RTSMain IMPORT
    Terminate, Status;

  FROM CommonData IMPORT
    OdnDlaPomBledu, OdnDlaPomOdl, SciezkaOpisuPomiaru;

  IMPORT
    Strings;

  CONST
    Pomiar = FALSE;

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
    FileSig  : ARRAY Signals, GlownyOdbiornikT OF CARDINAL;
    NameRes  : ARRAY OdnDlaPomBleduT OF NameDsc;
    FileRes  : ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF CARDINAL;

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
    Strings.Assign( SciezkaOpisuPomiaru, Dir );
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
      ok := Write(FileSig[Obr, odb], ADR(obr[odb]), 2);
      ok := Write(FileSig[Var, odb], ADR(var[odb]), 2);
      ok := Write(FileSig[Ref, odb], ADR(ref[odb]), 2);
      ok := Write(FileSig[Sub, odb], ADR(sub[odb]), 2);
      ok := Write(FileSig[Agc, odb], ADR(agc[odb]), 2);
    END (* for odb *);
  END SaveData;

  PROCEDURE LoadData
            (    nowySegment : BOOLEAN ) : BOOLEAN;

      PROCEDURE Rd( F : File; VAR w : WORD );
        BEGIN
          w := WORD(SigNilVal);
          IF (F # MAX(CARDINAL)) THEN
            ok := ok & Read( F, ADR( w ), 2 );
          END;
        END Rd;

  VAR
    odb : GlownyOdbiornikT;
    ok  : BOOLEAN;

  BEGIN
    ok := TRUE;
    Files.LoadData(Pomiar, flg, nowySegment, pilErr);
    FOR odb := goA TO goB DO
      Rd(FileSig[Obr, odb], obr[odb]);
      Rd(FileSig[Var, odb], var[odb]);
      Rd(FileSig[Ref, odb], ref[odb]);
      Rd(FileSig[Sub, odb], sub[odb]);
      Rd(FileSig[Agc, odb], agc[odb]);
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
    END (* for ix *);
  END CloseFiles;

  PROCEDURE OpenSignalFiles
            (    odnDlaOdl : OdnDlaPomOdlT ) : CARDINAL;
  VAR
    odniesienie : XRefKind;

  BEGIN
    CASE odnDlaOdl OF
      poDMEA :
        odniesienie := DME_Axref;
      |
      poDMEB :
        odniesienie := DME_Bxref;
      |
      poGPS :
        odniesienie := GPSRxref;
      |
      poZadanaPredkosc :
        odniesienie := Speedxref;
    END (* case odnDlaOdl *);
    Files.OpenSignalFiles(odniesienie, Pomiar);
    StartFiles(FALSE);
    RETURN VAL(CARDINAL, Length(FileSig[Obr, goA]) DIV VAL(LONGINT, 2));
  END OpenSignalFiles;

  PROCEDURE ReadAllSignals
            ( VAR signalsAVcont : SignalsCVDsc;
              VAR refCV         : refTab;
              VAR refDisCV      : WORD         );
  VAR
    sigIdx : Signals;
    odb    : GlownyOdbiornikT;

  BEGIN
    Files.ReadAllSignals(refCV, refDisCV, Pomiar);
    FOR odb := goA TO goB DO
      FOR sigIdx := MIN(Signals) TO MAX(Signals) DO
        ReadDef(FileSig[sigIdx, odb], signalsAVcont[sigIdx, odb], NilValI);
      END (* for sigIdx *);
    END (* for odb *);
  END ReadAllSignals;

  PROCEDURE CloseSignalFiles;

  BEGIN
    Files.CloseSignalFiles(Pomiar);
    CloseFiles;
  END CloseSignalFiles;

  PROCEDURE StartFileRes
            (    new : BOOLEAN );
  VAR
    FileProc : PROCEDURE
                 (     ARRAY OF CHAR ) : CARDINAL;
    odb  : GlownyOdbiornikT;
    odn  : OdnDlaPomBleduT;
    blad : BOOLEAN;

  BEGIN
    blad := FALSE;
    IF new
    THEN
      FileProc := Create;
    ELSE
      FileProc := Open;
    END (* if Create *);
    FOR odb := goA TO goB DO
      FOR odn := pbTeodolit TO pbGPS DO
        FileRes[odn, odb] := FileProc(NameRes[odn, odb]);
        blad := blad OR (FileRes[odn, odb] = NilValC);
      END (* for odn *);
    END (* for odb *);
  END StartFileRes;

  PROCEDURE WriteFileRes
            (    odn : OdnDlaPomBleduT;
                 odb : GlownyOdbiornikT;
                 dev : INTEGER          );
  VAR
    ok : BOOLEAN;

  BEGIN
    ok := Write(FileRes[odn, odb], ADR(dev), 2);
  END WriteFileRes;

  PROCEDURE StopFileRes;
  VAR
    odb : GlownyOdbiornikT;
    odn : OdnDlaPomBleduT;

  BEGIN
    FOR odn := pbTeodolit TO pbGPS DO
      FOR odb := goA TO goB DO
        Close(FileRes[odn, odb]);
      END (* for odb *);
    END (* for odn *);
  END StopFileRes;

  PROCEDURE KopiujWszystkiePliki
            ( VAR DoKatalogu : ARRAY OF CHAR );
  VAR
    odb    : GlownyOdbiornikT;
    sigIdx : Signals;
    odn    : OdnDlaPomBleduT;

  BEGIN (* KopiujWszystkiePliki *)
    Files.KopiujWszystkiePliki(DoKatalogu, Pomiar);
    FOR odb := goA TO goB DO
      FOR sigIdx := MIN(Signals) TO MAX(Signals) DO
        Kopiuj(NamesSig[sigIdx, odb], DoKatalogu);
      END (* for sigIdx *);
      FOR odn := pbTeodolit TO pbGPS DO
        Kopiuj(NameRes[odn, odb], DoKatalogu);
      END (* for odn *);
    END (* for odb *);
  END KopiujWszystkiePliki;

  PROCEDURE GetSigFileName
            (     sig  : Signals;
                  odb  : GlownyOdbiornikT;
              VAR name : ARRAY OF CHAR    );

  BEGIN
    Strings.Assign(NamesSig[sig, odb], name);
  END GetSigFileName;

  PROCEDURE GetResFileName
            (     odn  : OdnDlaPomBleduT;
                  odb  : GlownyOdbiornikT;
              VAR name : ARRAY OF CHAR    );

  BEGIN
    Strings.Assign(NameRes[odn, odb], name);
  END GetResFileName;

  PROCEDURE InitLocals;
  VAR
    sigIdx : Signals;
    odb    : GlownyOdbiornikT;
    odn    : OdnDlaPomBleduT;

    PROCEDURE AssignName
              (     inStr : ARRAY OF CHAR;
                VAR name  : NameDsc       );
    VAR
      odb : GlownyOdbiornikT;

    BEGIN
      FOR odb := goA TO goB DO
        Strings.Assign(inStr, name[odb]);
        name[odb, 7] := CHR(ORD(odb) + ORD('A'));
      END (* for Pomiar *);
    END AssignName;

  BEGIN
    NewMessage(FileErr, "V_Files: Nie mozna utworzyc pliku", BITSET(0E0F1H));
    AssignName("V_OBR___.DAT", NamesSig[Obr]);
    AssignName("V_VAR___.DAT", NamesSig[Var]);
    AssignName("V_REF___.DAT", NamesSig[Ref]);
    AssignName("V_SUB___.DAT", NamesSig[Sub]);
    AssignName("V_AGC___.DAT", NamesSig[Agc]);
    AssignName("V_DVGPS_.DAT", NameRes[pbGPS]);
    AssignName("V_DVTEO_.DAT", NameRes[pbTeodolit]);
    FOR odb := goA TO goB DO
      FOR sigIdx := MIN(Signals) TO MAX(Signals) DO
        FileSig[sigIdx, odb] := NilValC;
      END (* for sigIdx *);
      FOR odn := pbTeodolit TO pbGPS DO
        FileRes[odn, odb] := NilValC;
      END (* for odn *);
    END (* for ix *);
  END InitLocals;

BEGIN
  InitLocals;
END V_Files.
