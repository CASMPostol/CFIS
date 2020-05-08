(*.F- *)
(**********************************************************************
|  Title   : Obsluga plikow dla pomiaru NDB
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    12-11-96: M.Postol
|      bardzo duzo zmian
|    15-12-96: M.Postol
|      zmiana definicji refTab.
|    Rel 3.0. M.Postol
|      Zmiana definicji Czas
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE N_Files;

  IMPORT
    Files, Strings;

  FROM Files IMPORT
    Kopiuj, ReadDef, XRefKind;

  FROM FIO IMPORT
    Close, Create, Open, Write, Length, File, GetDir, CD, Read;

  FROM CommonTypes IMPORT
    (* TYPE *) GlownyOdbiornikT, OdnDlaPomBleduT,
    (* CONST *) NilValC, refTab, SigNilVal;

  FROM Messages IMPORT
    Message, NewMessage, Display;

  FROM SYSTEM IMPORT
    ADR, WORD;

  FROM N_Odb IMPORT
    berN, agc, sin, cos, flg, dir;

  FROM Strings IMPORT
    Assign;

  FROM CommonData IMPORT
    SciezkaOpisuPomiaru;

  FROM RTSMain IMPORT
    Terminate, Status;

  FROM N_CommonTypes IMPORT
    ProceduraT;

  FROM ScannerI IMPORT
    pilErr;

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
    NameRes        : NameDsc;
    FileRes        : ARRAY GlownyOdbiornikT OF CARDINAL;
    FileResCreated : BOOLEAN;

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
    Assign(SciezkaOpisuPomiaru, Dir);
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
    Files.SaveData(Pomiar, flg, nowySegment, pilErr);
    FOR rec := goA TO goB DO
      ok := Write(FileSig[obr_Sg, rec], ADR(berN[rec]), 2);
      ok := Write(FileSig[sin_Sg, rec], ADR(sin[rec]), 2) OR ok;
      ok := Write(FileSig[cos_Sg, rec], ADR(cos[rec]), 2) OR ok;
      ok := Write(FileSig[agc_Sg, rec], ADR(agc[rec]), 2) OR ok;
      ok := Write(FileSig[dir_Sg, rec], ADR(dir[rec]), 2) OR ok;
    END (* for rec *);
    IF NOT ok
    THEN
      Display(FileErr);
    END (* if blad *);
  END SaveData;

  PROCEDURE LoadData
            ( ) : BOOLEAN;

  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    Files.LoadData(Pomiar, flg, pilErr);
    FOR rec := goA TO goB DO
      ReadDef(FileSig[obr_Sg, rec], berN[rec], SigNilVal);
      ReadDef(FileSig[sin_Sg, rec], sin[rec],  SigNilVal);
      ReadDef(FileSig[cos_Sg, rec], cos[rec],  SigNilVal);
      ReadDef(FileSig[agc_Sg, rec], agc[rec],  SigNilVal);
      ReadDef(FileSig[dir_Sg, rec], dir[rec],  SigNilVal);
    END (* for rec *);
    RETURN TRUE;
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
            (    procedura : ProceduraT ) : CARDINAL;
  VAR
    odniesienie : XRefKind;

  BEGIN
    CASE procedura OF
      pOrbita :
        odniesienie := GPSAxref;
      |
      pPromien :
        odniesienie := GPSRxref;
    END (* case procedura *);
    Files.OpenSignalFiles(odniesienie, Pomiar);
    StartFiles(FALSE);
    RETURN VAL(CARDINAL, Length(FileSig[obr_Sg, goA]) DIV VAL(LONGINT, 2));
  END OpenSignalFiles;

  PROCEDURE ReadAllSignals
            ( VAR signalsCV     : SignalsCVDsc;
              VAR refAlfa       : INTEGER;
              VAR refDisCV      : WORD         );
  VAR
    sigIdx : Signals;
    rec    : GlownyOdbiornikT;
    refCV  : refTab;
    flg    : BITSET;

  BEGIN
    Files.ReadAllSignals(refCV, refDisCV, flg, Pomiar);
    refAlfa := refCV.Together[pbGPS];
    FOR rec := goA TO goB DO
      FOR sigIdx := MIN(Signals) TO MAX(Signals) DO
        ReadDef(FileSig[sigIdx, rec], signalsCV[sigIdx, rec], SigNilVal);
      END (* for sigIdx *);
    END (* for rec *);
  END ReadAllSignals;

  PROCEDURE CloseSignalFiles;

  BEGIN
    Files.CloseSignalFiles(Pomiar);
    CloseFiles;
  END CloseSignalFiles;

  PROCEDURE KopiujWszystkiePliki
            ( VAR DoKatalogu : ARRAY OF CHAR );
  VAR
    rec    : GlownyOdbiornikT;
    sigIdx : Signals;

  BEGIN
    Files.KopiujWszystkiePliki(DoKatalogu, Pomiar);
    FOR rec := goA TO goB DO
      FOR sigIdx := MIN(Signals) TO MAX(Signals) DO
        Kopiuj(NamesSig[sigIdx, rec], DoKatalogu);
      END (* for sigIdx *);
      IF FileResCreated
      THEN
        Kopiuj(NameRes[rec], DoKatalogu);
      END (* if FileResCreated *);
    END (* for rec *);
    FileResCreated := FALSE;
  END KopiujWszystkiePliki;

  PROCEDURE GetSigFileName
            (     sig  : Signals;
                  rec  : GlownyOdbiornikT;
              VAR name : ARRAY OF CHAR    );

  BEGIN
    Assign(NamesSig[sig, rec], name);
  END GetSigFileName;

  PROCEDURE OpenFileRes
            (    new : BOOLEAN );
  VAR
    rec      : GlownyOdbiornikT;
    blad     : BOOLEAN;
    FileProc : PROCEDURE
                 (     ARRAY OF CHAR ) : CARDINAL;

  BEGIN (* OpenFileRes *)
    blad := FALSE;
    IF new
    THEN
      FileProc := Create;
      FileResCreated := TRUE;
    ELSE
      FileProc := Open;
    END (* if Create *);
    FOR rec := goA TO goB DO
      FileRes[rec] := FileProc(NameRes[rec]);
      blad := (FileRes[rec] = NilValC) OR blad;
    END (* for rec *);
  END OpenFileRes;

  PROCEDURE WriteFileRes
            (    rec : GlownyOdbiornikT;
                 val : INTEGER          );
  VAR
    ok : BOOLEAN;

  BEGIN
    ok := Write(FileRes[rec], ADR(val), 2);
  END WriteFileRes;

  PROCEDURE CloseFileRes;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN (* CloseFileRes *)
    FOR rec := goA TO goB DO
      Close(FileRes[rec]);
    END (* for rec *);
  END CloseFileRes;

  PROCEDURE GetResFileName
            (     rec  : GlownyOdbiornikT;
              VAR name : ARRAY OF CHAR    );

  BEGIN
    Assign(NameRes[rec], name);
  END GetResFileName;

  PROCEDURE InitLocals;
  VAR
    sigIdx : Signals;
    rec    : GlownyOdbiornikT;

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
    AssignName("N_OBR___.DAT", NamesSig[obr_Sg]);
    AssignName("N_AGC___.DAT", NamesSig[agc_Sg]);
    AssignName("N_SIN___.DAT", NamesSig[sin_Sg]);
    AssignName("N_COS___.DAT", NamesSig[cos_Sg]);
    AssignName("N_DIR___.DAT", NamesSig[dir_Sg]);
    AssignName("N_DEV___.DAT", NameRes);
    FOR rec := goA TO goB DO
      FOR sigIdx := MIN(Signals) TO MAX(Signals) DO
        FileSig[sigIdx, rec] := NilValC;
      END (* for sigIdx *);
      FileResCreated := FALSE;
      FileRes[rec] := NilValC;
    END (* for rec *);
  END InitLocals;

BEGIN
  InitLocals;
END N_Files.
