(*.F- *)
(**********************************************************************
|  Title   : Obsluga plikow dla pomiaru DME
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    27-10-96: m.pOSTOL
|      Created
|    15-12-96: M.Postol
|      zmiana definicji refTab.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE G_Files;

  IMPORT
    Files, Strings;

  FROM Files IMPORT
    Kopiuj, ReadDef, XRefKind;

  FROM FIO IMPORT
    Close, Create, Open, Write, Length, File, GetDir, CD, Read;

  FROM CommonTypes IMPORT
    (* TYPE *) GlownyOdbiornikT, OdnDlaPomOdlT, OdnDlaPomBleduT,
    (* CONST *) NilValC, NilValI, refTab;

  FROM Messages IMPORT
    Message, NewMessage, Display;

  FROM SYSTEM IMPORT
    ADR, WORD;

  FROM G_Odb IMPORT
    devG, devL, mod, agc, agcM, navOdbFlg;

  FROM Strings IMPORT
    Assign;

  FROM CommonData IMPORT
    SciezkaOpisuPomiaru;

  FROM RTSMain IMPORT
    Terminate, Status;

  FROM ScannerI IMPORT
    pilErr;

  FROM L_CommonTypes IMPORT
    SignalsCVDsc;

  CONST
    Pomiar = FALSE;

  TYPE
    NamString =
      ARRAY [0 .. 12] OF CHAR;
    NameDsc   =
      ARRAY GlownyOdbiornikT OF NamString;

  VAR
    FileErr        : Message;
    NamesSig       : ARRAY Signals OF NameDsc;
    FileSig        : ARRAY Signals, GlownyOdbiornikT OF CARDINAL;
    NameRes        : ARRAY resultT OF NameDsc;
    FileRes        : ARRAY resultT, GlownyOdbiornikT OF CARDINAL;
    FileResCreated : ARRAY resultT OF BOOLEAN;

  PROCEDURE StartFiles
            (    new : BOOLEAN );
  VAR
    rec      : GlownyOdbiornikT;
    blad     : BOOLEAN;
    sigIdx   : Signals;
    FileProc : PROCEDURE
                 (     ARRAY OF CHAR ) : CARDINAL;

  BEGIN (* StartFiles *)
    blad := FALSE;
    IF new
    THEN
      FileProc := Create;
    ELSE
      FileProc := Open;
    END (* if Create *);
    FOR rec := goA TO goB DO
      FOR sigIdx := MIN(Signals) TO MAX(Signals) DO
        FileSig[sigIdx, rec] := FileProc(NamesSig[sigIdx, rec]);
        blad := blad OR (FileSig[sigIdx, rec] = NilValC)
      END (* for sigIdx *);
    END (* for rec *);
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
    Dir    : ARRAY [0 .. 99] OF CHAR;

  BEGIN
    GetDir(CurDir);
    Strings.Assign(SciezkaOpisuPomiaru, Dir);
    Dir[Strings.Length(Dir) - 1] := 0C;
    IF NOT CD(Dir)
    THEN
      Terminate(Warning);   (* jakas grubsza sprawa *)
    END (* if *);
    Files.OpenFiles(Pomiar);
    StartFiles(FALSE);
    IF NOT CD(CurDir)
    THEN
      Terminate(Warning);   (* jakas grubsza sprawa *)
    END (* if *);
  END OpenFiles;

  PROCEDURE SaveData
            (    nowySegment : BOOLEAN );
  VAR
    rec : GlownyOdbiornikT;
    ok  : BOOLEAN;

  BEGIN
    Files.SaveData(Pomiar, navOdbFlg, nowySegment, pilErr);
    FOR rec := goA TO goB DO
      ok := Write(FileSig[devG_Sg, rec], ADR(devG[rec]), 2);
      ok := Write(FileSig[devL_Sg, rec], ADR(devL[rec]), 2);
      ok := Write(FileSig[modG_Sg, rec], ADR(mod[rec]), 2);
      ok := Write(FileSig[agcG_Sg, rec], ADR(agc[rec]), 2);
      ok := Write(FileSig[agcM_Sg, rec], ADR(agcM[rec]), 2);
    END (* for rec *);
  END SaveData;

  PROCEDURE LoadData
            (    nowySegment : BOOLEAN ) : BOOLEAN;

    PROCEDURE Rd
              (     F : File;
                VAR w : WORD );
    BEGIN
      IF (F # MAX(CARDINAL))
      THEN
        ok := ok & Read(F, ADR(w), 2);
      END (* if *);
    END Rd;
  VAR
    rec : GlownyOdbiornikT;
    ok  : BOOLEAN;

  BEGIN
    ok := TRUE;
    Files.LoadData(Pomiar, navOdbFlg, nowySegment, pilErr);
    FOR rec := goA TO goB DO
      Rd(FileSig[devG_Sg, rec], devG[rec]);
      Rd(FileSig[devL_Sg, rec], devL[rec]);
      Rd(FileSig[modG_Sg, rec], mod[rec]);
      Rd(FileSig[agcG_Sg, rec], agc[rec]);
      Rd(FileSig[agcM_Sg, rec], agcM[rec]);
    END (* for rec *);
    RETURN ok;
  END LoadData;

  PROCEDURE CloseFiles;
  VAR
    sigIdx : Signals;
    rec    : GlownyOdbiornikT;

  BEGIN
    Files.CloseFiles(Pomiar);
    FOR rec := goA TO goB DO
      FOR sigIdx := MIN(Signals) TO MAX(Signals) DO
        Close(FileSig[sigIdx, rec]);
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
    RETURN VAL(CARDINAL, Length(FileSig[devL_Sg, goA]) DIV VAL(LONGINT, 2));
  END OpenSignalFiles;

  PROCEDURE ReadAllSignals
            ( VAR signalsCV : SignalsCVDsc;
              VAR elew      : INTEGER;
              VAR refDisCV  : WORD         );
  VAR
    sigIdx : Signals;
    odb    : GlownyOdbiornikT;
    refCV  : refTab;

  BEGIN
    Files.ReadAllSignals(refCV, refDisCV, Pomiar);
    elew := refCV.Together[pbTeodolit];
    FOR odb := goA TO goB DO
      FOR sigIdx := MIN(Signals) TO MAX(Signals) DO
        ReadDef(FileSig[sigIdx, odb], signalsCV[sigIdx, odb], NilValI);
      END (* for sigIdx *);
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
    res    : resultT;

  BEGIN
    Files.KopiujWszystkiePliki(DoKatalogu, Pomiar);
    FOR odb := goA TO goB DO
      FOR sigIdx := MIN(Signals) TO MAX(Signals) DO
        Kopiuj(NamesSig[sigIdx, odb], DoKatalogu);
      END (* for sigIdx *);
    END (* for rec *);
    FOR res := MIN(resultT) TO MAX(resultT) DO
      IF FileResCreated[res]
      THEN
        FOR odb := goA TO goB DO
          Kopiuj(NameRes[res, odb], DoKatalogu);
        END (* for rec *);
      END (* if FileResCreated *);
      FileResCreated[res] := FALSE;
    END (* for res *);
  END KopiujWszystkiePliki;

  PROCEDURE GetSigFileName
            (     sig  : Signals;
                  odb  : GlownyOdbiornikT;
              VAR name : ARRAY OF CHAR    );

  BEGIN
    Assign(NamesSig[sig, odb], name);
  END GetSigFileName;

  PROCEDURE OpenFileRes
            (    new : BOOLEAN;
                 res : resultT );
  VAR
    odb      : GlownyOdbiornikT;
    blad     : BOOLEAN;
    FileProc : PROCEDURE
                 (     ARRAY OF CHAR ) : CARDINAL;

  BEGIN (* OpenFileRes *)
    blad := FALSE;
    IF new
    THEN
      FileProc := Create;
      FileResCreated[res] := TRUE;
    ELSE
      FileProc := Open;
    END (* if Create *);
    FOR odb := goA TO goB DO
      FileRes[res, odb] := FileProc(NameRes[res, odb]);
      blad := blad OR (FileRes[res, odb] = NilValC);
    END (* for odb *);
  END OpenFileRes;

  PROCEDURE WriteFileRes
            (    res : resultT;
                 odb : GlownyOdbiornikT;
                 val : INTEGER          );
  VAR
    ok : BOOLEAN;

  BEGIN
    ok := Write(FileRes[res, odb], ADR(val), 2);
  END WriteFileRes;

  PROCEDURE CloseFileRes
            (    res : resultT );
  VAR
    odb : GlownyOdbiornikT;

  BEGIN (* CloseFileRes *)
    FOR odb := goA TO goB DO
      Close(FileRes[res, odb]);
    END (* for odb *);
  END CloseFileRes;

  PROCEDURE GetResFileName
            (     res  : resultT;
                  odb  : GlownyOdbiornikT;
              VAR name : ARRAY OF CHAR    );

  BEGIN
    Assign(NameRes[res, odb], name);
  END GetResFileName;

  PROCEDURE InitLocals;
  VAR
    sigIdx : Signals;
    odb    : GlownyOdbiornikT;
    res    : resultT;

    PROCEDURE AssignName
              (     inStr : ARRAY OF CHAR;
                VAR name  : NameDsc       );
    VAR
      rec : GlownyOdbiornikT;

    BEGIN
      FOR rec := goA TO goB DO
        Assign(inStr, name[rec]);
        name[rec, 7] := CHR(ORD(rec) + ORD('A'));
      END (* for Pomiar *);
    END AssignName;

  BEGIN
    NewMessage(FileErr, "Powstal krytyczny bˆad: Nie mozna utworzyc pliku",
               BITSET(0E0F1H));
    AssignName("G_DEVL__.DAT", NamesSig[devL_Sg]);
    AssignName("G_DEVG__.DAT", NamesSig[devG_Sg]);
    AssignName("G_MOD___.DAT", NamesSig[modG_Sg]);
    AssignName("G_AGCG__.DAT", NamesSig[agcG_Sg]);
    AssignName("G_AGCM__.DAT", NamesSig[agcM_Sg]);
    AssignName("G_T_DIF_.DAT", NameRes[Dif]);
    AssignName("G_T_DFA_.DAT", NameRes[DifAV]);
    AssignName("G_T_BP__.DAT", NameRes[boundP]);
    AssignName("G_T_BM__.DAT", NameRes[boundM]);
    AssignName("G_T_SW__.DAT", NameRes[SecWith]);
    FOR odb := goA TO goB DO
      FOR sigIdx := MIN(Signals) TO MAX(Signals) DO
        FileSig[sigIdx, odb] := NilValC;
      END (* for sigIdx *);
      FOR res := MIN(resultT) TO MAX(resultT) DO
        FileResCreated[res] := FALSE;
        FileRes[res, odb] := NilValC;
      END (* for res *);
    END (* for odb *);
  END InitLocals;

BEGIN
  InitLocals;
END G_Files.
