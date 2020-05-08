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

IMPLEMENTATION MODULE L_Files;

  IMPORT
    Files, Strings;

  FROM Files IMPORT
    Kopiuj, ReadDef, XRefKind;

  FROM FIO IMPORT
    Close, Create, Open, Write, Length, Read, File, GetDir, CD;

  FROM CommonTypes IMPORT
    (* TYPE *) GlownyOdbiornikT, OdnDlaPomOdlT, OdnDlaPomBleduT,
    (* CONST *) NilValC, NilValI, refTab;

  FROM L_CommonTypes IMPORT
    Signals, SignalsCVDsc, ProceduraT, CzyToJestPromien;

  FROM Messages IMPORT
    Message, NewMessage, Display;

  FROM SYSTEM IMPORT
    ADR, WORD;

  FROM L_Odb IMPORT
    devL, modL, agcL, agcM, navOdbFlg;

  FROM Strings IMPORT
    Assign;

  FROM ScannerI IMPORT
    pilErr;

  FROM MANAGER IMPORT
    Assert;

  FROM CommonData IMPORT
    SciezkaOpisuPomiaru;

  FROM RTSMain IMPORT
    Terminate, Status;

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
    NameRes        : ARRAY resultT, OdnDlaPomBleduT OF NameDsc;
    FileRes        : ARRAY resultT, OdnDlaPomBleduT, GlownyOdbiornikT OF
  CARDINAL;
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
      ok := Write(FileSig[devL_Sg, rec], ADR(devL[rec]), 2);
      ok := Write(FileSig[modL_Sg, rec], ADR(modL[rec]), 2);
      ok := Write(FileSig[agcL_Sg, rec], ADR(agcL[rec]), 2);
      ok := Write(FileSig[agcM_Sg, rec], ADR(agcM[rec]), 2);
    END (* for rec *);
  END SaveData;

  PROCEDURE LoadData
            (    nowySegment : BOOLEAN ) : BOOLEAN;

    PROCEDURE Rd
              (     F : File;
                VAR w : WORD );
    BEGIN
      IF (F # MAX(CARDINAL)) THEN
        ok := ok & Read(F, ADR(w), 2);
      END (* if *);
    END Rd;

  VAR
    rec : GlownyOdbiornikT;
    ok  : BOOLEAN;

  BEGIN
    Files.LoadData(Pomiar, navOdbFlg, nowySegment, pilErr);
    ok := TRUE;
    FOR rec := goA TO goB DO
      Rd(FileSig[devL_Sg, rec], devL[rec]);
      Rd(FileSig[modL_Sg, rec], modL[rec]);
      Rd(FileSig[agcL_Sg, rec], agcL[rec]);
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
            (    procedura      : ProceduraT;
                 odnDlaOdl      : OdnDlaPomOdlT;
                 odnDlaPomBledu : OdnDlaPomBleduT ) : CARDINAL;
  VAR
    odniesienie : XRefKind;

  BEGIN
    IF CzyToJestPromien(procedura)
    THEN
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
    ELSE
      CASE odnDlaPomBledu OF
        pbGPS :
          odniesienie := GPSAxref;
        |
        pbTeodolit :
          odniesienie := TEOAxref;
      END (* case *);
    END (* if *);
    Files.OpenSignalFiles(odniesienie, Pomiar);
    StartFiles(FALSE);
    RETURN VAL(CARDINAL, Length(FileSig[devL_Sg, goA]) DIV VAL(LONGINT, 2));
  END OpenSignalFiles;

  PROCEDURE ReadAllSignals
            ( VAR signalsCV : SignalsCVDsc;
              VAR refCV     : refTab;
              VAR refDisCV  : WORD         );
  VAR
    sigIdx : Signals;
    odb    : GlownyOdbiornikT;

  BEGIN
    Files.ReadAllSignals(refCV, refDisCV, Pomiar);
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
    ref    : OdnDlaPomBleduT;
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
        FOR ref := pbTeodolit TO pbGPS DO
          FOR odb := goA TO goB DO
            Kopiuj(NameRes[res, ref, odb], DoKatalogu);
          END (* for rec *);
        END (* for odn *);
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
    odn      : OdnDlaPomBleduT;
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
      FOR odn := pbTeodolit TO pbGPS DO
        FileRes[res, odn, odb] := FileProc(NameRes[res, odn, odb]);
        blad := blad OR (FileRes[res, odn, odb] = NilValC);
      END (* for odn *);
    END (* for odb *);
  END OpenFileRes;

  PROCEDURE WriteFileRes
            (    res : resultT;
                 odn : OdnDlaPomBleduT;
                 odb : GlownyOdbiornikT;
                 val : INTEGER          );
  VAR
    ok : BOOLEAN;

  BEGIN
    Assert(odn <> pbnieZdef);
    ok := Write(FileRes[res, odn, odb], ADR(val), 2);
  END WriteFileRes;

  PROCEDURE CloseFileRes
            (    res : resultT );
  VAR
    odn : OdnDlaPomBleduT;
    odb : GlownyOdbiornikT;

  BEGIN (* CloseFileRes *)
    FOR odn := pbTeodolit TO pbGPS DO
      FOR odb := goA TO goB DO
        Close(FileRes[res, odn, odb]);
      END (* for odb *);
    END (* for odn *);
  END CloseFileRes;

  PROCEDURE GetResFileName
            (     res  : resultT;
                  odn  : OdnDlaPomBleduT;
                  odb  : GlownyOdbiornikT;
              VAR name : ARRAY OF CHAR    );

  BEGIN
    Assert(odn <> pbnieZdef);
    Assign(NameRes[res, odn, odb], name);
  END GetResFileName;

  PROCEDURE InitLocals;
  VAR
    sigIdx : Signals;
    odb    : GlownyOdbiornikT;
    odn    : OdnDlaPomBleduT;
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
    AssignName("L_DEV___.DAT", NamesSig[devL_Sg]);
    AssignName("L_MOD___.DAT", NamesSig[modL_Sg]);
    AssignName("L_AGCL__.DAT", NamesSig[agcL_Sg]);
    AssignName("L_AGCM__.DAT", NamesSig[agcM_Sg]);
    AssignName("L_G_DIF_.RES", NameRes[Dif, pbGPS]);
    AssignName("L_T_DIF_.RES", NameRes[Dif, pbTeodolit]);
    AssignName("L_G_DFA_.RES", NameRes[DifAV, pbGPS]);
    AssignName("L_T_DFA_.RES", NameRes[DifAV, pbTeodolit]);
    AssignName("L_G_BP__.RES", NameRes[boundP, pbGPS]);
    AssignName("L_T_BP__.RES", NameRes[boundP, pbTeodolit]);
    AssignName("L_G_BM__.RES", NameRes[boundM, pbGPS]);
    AssignName("L_T_BM__.RES", NameRes[boundM, pbTeodolit]);
    AssignName("L_G_SW__.RES", NameRes[SecWith, pbGPS]);
    AssignName("L_T_SW__.RES", NameRes[SecWith, pbTeodolit]);
    FOR odb := goA TO goB DO
      FOR sigIdx := MIN(Signals) TO MAX(Signals) DO
        FileSig[sigIdx, odb] := NilValC;
      END (* for sigIdx *);
      FOR res := MIN(resultT) TO MAX(resultT) DO
        FOR odn := pbTeodolit TO pbGPS DO
          FileResCreated[res] := FALSE;
          FileRes[res, odn, odb] := NilValC;
        END (* for odn *);
      END (* for res *);
    END (* for odb *);
  END InitLocals;

BEGIN
  InitLocals;
END L_Files.
