(*.F- *)
(**********************************************************************
|  Title   : Common procedures for file handling
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    01-10-96: M.Postol
|      przy bardzo dlugich lotach wywalal sie na indeksie INTEGER w
|      interpolacji, zmienim mu go na CARDINAL - to wystarczy na 3.8h lotu
|    12-05-97: M.Morawski
|      zmiana sposobu weryfikacji wersji danych
|    Rel.3.0. M.Postol
|      LoadData byly niepotrzebne instrukcje
|      wstawilwm zapamietywanie GDOP
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE Files;

  FROM ScannerI IMPORT
    Alfa, Delta, GPS_GDOP, GPS_SAT, flg, ABOVESL, GPS_PREC;

  IMPORT
    Strings, FCBS;

  FROM StdIO IMPORT
    sprintf;

  FROM FIO IMPORT
    Close, Create, Open, Write, Read, Delete, Rename, CD, GetDir, Length,
    MkDir, Seek, SeekMode;

  FROM Messages IMPORT
    Message, NewMessage, Display;

  FROM SYSTEM IMPORT
    ADDRESS, WORD, BYTE, SIZE, ADR;

  FROM CommonTypes IMPORT
    (* TYPE *) OdnDlaPomOdlT, refTab, OdnDlaPomBleduT,
    (* CONST *) NilValC, SigNilVal, DisNilVal, NowySegment;

  FROM Strings IMPORT
    Assign, Insert;

  FROM MathLib0 IMPORT
    entier, real;

  FROM SpecConv IMPORT
    SubAngle100, AddAngle100;

  FROM MANAGER  IMPORT
    Assert;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM GrafUtil IMPORT
    Info;

  FROM RTSMain IMPORT
    Terminate, Status;

  TYPE
    NamString =
      ARRAY [0 .. 12] OF CHAR;
    NameDsc   =
      ARRAY BOOLEAN OF NamString;
    AlfaRefT  =
      [pbTeodolit .. pbGPS];

  VAR
    FileErr   : Message;
    DirErr    : Message;
    NamesAn   : ARRAY DateKind OF NameDsc;
    NamesDist : ARRAY OdnDlaPomOdlT OF NameDsc;
    NamesAlfa : ARRAY AlfaRefT OF NameDsc;
    NamesComm : ARRAY CommSig OF NameDsc;
    filesDist : ARRAY OdnDlaPomOdlT, BOOLEAN OF CARDINAL;
    filesAlfa : ARRAY AlfaRefT, BOOLEAN OF CARDINAL;
    filesComm : ARRAY CommSig, BOOLEAN OF CARDINAL;
    xRefFile  : ARRAY BOOLEAN OF CARDINAL;
    xRefDefV  : ARRAY BOOLEAN OF WORD;
    homeDir   : ARRAY [0 .. 80] OF CHAR;

  PROCEDURE Kopiuj
            (     Co         : ARRAY OF CHAR;
              VAR DoKatalogu : ARRAY OF CHAR );
  VAR
    Tmp1      : ARRAY [0 .. 15] OF CHAR;
    Tmp       : ARRAY [0 .. 127] OF CHAR;
    RenameErr : Message;
    a         : ADDRESS;

  BEGIN
    Assign(Co, Tmp1);
    Assign(DoKatalogu, Tmp);
    Insert(Co, Tmp, 0FFFH);
    Delete(Tmp);
    IF NOT Rename(Tmp, Tmp1)
    THEN
      a := ADR(Tmp1);
      sprintf(Tmp1, "Nie mo¾na skopiowac danych do pliku `%s'", a);
      NewMessage(RenameErr, Tmp1, BITSET(0E0F1H));
      Display(RenameErr);
    END (* if *);
  END Kopiuj;

  PROCEDURE ReadDef
            (     file   : CARDINAL;
              VAR val    : WORD;
                  defVal : WORD     );

  BEGIN
    IF (file = NilValC) OR NOT Read(file, ADR(val), 2)
    THEN
      val := defVal;
    END (* if *);
  END ReadDef;

  PROCEDURE CreateFiles
            (    Pomiar : BOOLEAN );
  VAR
    alfaIdx : AlfaRefT;
    distIdx : OdnDlaPomOdlT;
    commIdx : CommSig;
    blad    : BOOLEAN;

  BEGIN
    blad := FALSE;
    FOR alfaIdx := MIN(AlfaRefT) TO MAX(AlfaRefT) DO
      filesAlfa[alfaIdx, Pomiar] := Create(NamesAlfa[alfaIdx, Pomiar]);
      blad := blad OR (filesAlfa[alfaIdx, Pomiar] = NilValC)
    END (* for alfaIdx *);
    FOR distIdx := MIN(OdnDlaPomOdlT) TO MAX(OdnDlaPomOdlT) DO
      filesDist[distIdx, Pomiar] := Create(NamesDist[distIdx, Pomiar]);
      blad := blad OR (filesDist[distIdx, Pomiar] = NilValC)
    END (* for distIdx *);
    FOR commIdx := MIN(CommSig) TO MAX(CommSig) DO
      filesComm[commIdx, Pomiar] := Create(NamesComm[commIdx, Pomiar]);
      blad := blad OR (filesComm[commIdx, Pomiar] = NilValC)
    END (* for commIdx *);
    IF blad
    THEN
      Display(FileErr);
    END (* if blad *);
  END CreateFiles;

  PROCEDURE OpenFiles
            (    Pomiar : BOOLEAN );
  VAR
    alfaIdx : AlfaRefT;
    distIdx : OdnDlaPomOdlT;
    commIdx : CommSig;
    blad    : BOOLEAN;

  BEGIN
    blad := FALSE;
    FOR alfaIdx := MIN(AlfaRefT) TO MAX(AlfaRefT) DO
      filesAlfa[alfaIdx, Pomiar] := Open(NamesAlfa[alfaIdx, Pomiar]);
      blad := blad OR (filesAlfa[alfaIdx, Pomiar] = NilValC)
    END (* for alfaIdx *);
    FOR distIdx := MIN(OdnDlaPomOdlT) TO MAX(OdnDlaPomOdlT) DO
      filesDist[distIdx, Pomiar] := Open(NamesDist[distIdx, Pomiar]);
      blad := blad OR (filesDist[distIdx, Pomiar] = NilValC)
    END (* for distIdx *);
    FOR commIdx := MIN(CommSig) TO MAX(CommSig) DO
      filesComm[commIdx, Pomiar] := Open(NamesComm[commIdx, Pomiar]);
      blad := blad OR (filesComm[commIdx, Pomiar] = NilValC)
    END (* for commIdx *);
    IF blad
    THEN
      Display(FileErr);
    END (* if blad *);
  END OpenFiles;

  PROCEDURE SaveData
            (    Pomiar      : BOOLEAN;
                 flags       : BITSET;
                 nowySegment : BOOLEAN;
                 pilErr      : INTEGER );
  VAR
    distIdx  : OdnDlaPomOdlT;
    alfaIdx  : AlfaRefT;
    ok       : BOOLEAN;
    flagsRes : BITSET;

  BEGIN
    flagsRes := flags + flg;
    IF nowySegment
    THEN
      INCL(flagsRes, NowySegment);
    END (* if nowySegment *);
    (* Odleglosc *)
    FOR distIdx := MIN(OdnDlaPomOdlT) TO MAX(OdnDlaPomOdlT) DO
      ok := Write(filesDist[distIdx, Pomiar], ADR(Delta[distIdx]), 2);
    END (* for distIdx *);
    (* Odniesienie kata *)
    FOR alfaIdx := MIN(AlfaRefT) TO MAX(AlfaRefT) DO
      ok := Write(filesAlfa[alfaIdx, Pomiar], ADR(Alfa.Together[alfaIdx]), 2);
    END (* for alfaIdx *);
    (* wspolne sygnaly *)
    ok := Write(filesComm[CS_GPS_EPE, Pomiar],  ADR(GPS_PREC), 2);
    ok := Write(filesComm[CS_GPS_GDOP, Pomiar], ADR(GPS_GDOP), 2);
    ok := Write(filesComm[CS_GPS_NOS, Pomiar],  ADR(GPS_SAT), 2);
    ok := Write(filesComm[CS_PilError, Pomiar], ADR(pilErr), 2);
    ok := Write(filesComm[CS_Flags, Pomiar],    ADR(flagsRes), 2);
    ok := Write(filesComm[CS_Alt_Sg, Pomiar],   ADR(ABOVESL), 2);
  END SaveData;

  PROCEDURE LoadData
            (    Pomiar      : BOOLEAN;
             VAR flags       : BITSET;
                 pilErr      : INTEGER );

  VAR
    distIdx  : OdnDlaPomOdlT;
    alfaIdx  : AlfaRefT;

  BEGIN
    (* Odleglosc *)
    FOR distIdx := MIN(OdnDlaPomOdlT) TO MAX(OdnDlaPomOdlT) DO
      ReadDef(filesDist[distIdx, Pomiar], Delta[distIdx], DisNilVal);
    END (* for distIdx *);
    (* Odniesienie kata *)
    FOR alfaIdx := MIN(AlfaRefT) TO MAX(AlfaRefT) DO
      ReadDef(filesAlfa[alfaIdx, Pomiar], Alfa.Together[alfaIdx], SigNilVal);
    END (* for alfaIdx *);
    (* wspolne sygnaly *)
    ReadDef(filesComm[CS_GPS_EPE, Pomiar],  GPS_PREC, SigNilVal);
    ReadDef(filesComm[CS_GPS_GDOP, Pomiar], GPS_GDOP, SigNilVal);
    ReadDef(filesComm[CS_GPS_NOS, Pomiar],  GPS_SAT, SigNilVal);
    ReadDef(filesComm[CS_PilError, Pomiar], pilErr, SigNilVal);
    ReadDef(filesComm[CS_Flags, Pomiar],    flags, {});
    ReadDef(filesComm[CS_Alt_Sg, Pomiar],   ABOVESL, SigNilVal);
    flg := flags;
  END LoadData;

  PROCEDURE CloseFiles
            (    Pomiar  : BOOLEAN );
  VAR
    alfaIdx : AlfaRefT;
    distIdx : OdnDlaPomOdlT;
    commIdx : CommSig;

  BEGIN
    FOR alfaIdx := MIN(AlfaRefT) TO MAX(AlfaRefT) DO
      Close(filesAlfa[alfaIdx, Pomiar]);
    END (* for alfaIdx *);
    FOR distIdx := MIN(OdnDlaPomOdlT) TO MAX(OdnDlaPomOdlT) DO
      Close(filesDist[distIdx, Pomiar]);
    END (* for distIddx *);
    FOR commIdx := MIN(CommSig) TO MAX(CommSig) DO
      Close(filesComm[commIdx, Pomiar]);
    END (* for commIdx *);
  END CloseFiles;

  PROCEDURE OpenSignalFiles
            (    xRef   : XRefKind;
                 Pomiar : BOOLEAN  );
  VAR
    alfaIdx : AlfaRefT;
    blad    : BOOLEAN;
    commSig : CommSig;
  BEGIN
    blad := FALSE;
    FOR alfaIdx := MIN(AlfaRefT) TO MAX(AlfaRefT) DO
      filesAlfa[alfaIdx, Pomiar] := Open(NamesAlfa[alfaIdx, Pomiar]);
      blad := blad OR (filesAlfa[alfaIdx, Pomiar] = NilValC)
    END (* for alfaIdx *);
    FOR commSig := MIN(CommSig) TO MAX(CommSig) DO
      filesComm[commSig, Pomiar] := Open(NamesComm[commSig, Pomiar]);
      blad := blad OR (filesComm[commSig, Pomiar] = NilValC)
    END (* for alfaIdx *);
    CASE xRef OF
      TEOAxref :
        xRefFile[Pomiar] := Open(NamesAlfa[pbTeodolit, Pomiar]);
        xRefDefV[Pomiar] := WORD(SigNilVal);
      |
      GPSAxref :
        xRefFile[Pomiar] := Open(NamesAlfa[pbGPS, Pomiar]);
        xRefDefV[Pomiar] := WORD(SigNilVal);
      |
      GPSRxref :
        xRefFile[Pomiar] := Open(NamesDist[poGPS, Pomiar]);
        xRefDefV[Pomiar] := WORD(DisNilVal);
      |
      DME_Axref :
        xRefFile[Pomiar] := Open(NamesDist[poDMEA, Pomiar]);
        xRefDefV[Pomiar] := WORD(DisNilVal);
      |
      DME_Bxref :
        xRefFile[Pomiar] := Open(NamesDist[poDMEB, Pomiar]);
        xRefDefV[Pomiar] := WORD(DisNilVal);
      |
      Speedxref :
        xRefFile[Pomiar] := Open(NamesDist[poZadanaPredkosc, Pomiar]);
        xRefDefV[Pomiar] := WORD(DisNilVal);
    END (* case xRef *);
    blad := blad OR (xRefFile[Pomiar] = NilValC);
    IF blad
    THEN
      Display(FileErr);
    END (* if blad *);
  END OpenSignalFiles;

  PROCEDURE ReadXref
            ( VAR xRefCV : WORD;
                  Pomiar : BOOLEAN );

  BEGIN
    ReadDef(xRefFile[Pomiar], xRefCV, xRefDefV[Pomiar]);
  END ReadXref;

  PROCEDURE ReadFlgs
            ( VAR flgs   : BITSET;
                  Pomiar : BOOLEAN );

  BEGIN
    ReadDef(filesComm[CS_Flags, Pomiar], flgs, {});
  END ReadFlgs;

  PROCEDURE ReadAllSignals
            ( VAR refCV  : refTab;
              VAR xRefCV : WORD;
              VAR flg    : BITSET;
                  Pomiar : BOOLEAN );

  VAR
    odn : OdnDlaPomBleduT;

  BEGIN
    FOR odn := pbTeodolit TO HIGH(refCV.Together) DO
      ReadDef(filesAlfa[odn, Pomiar], refCV.Together[odn], SigNilVal);
    END (* for odn *);
    ReadXref(xRefCV, Pomiar);
    ReadFlgs(flg, Pomiar);
  END ReadAllSignals;

  PROCEDURE CloseSignalFiles
            (    Pomiar : BOOLEAN );
  VAR
    alfaIdx : AlfaRefT;
    commSig : CommSig;

  BEGIN
    FOR alfaIdx := MIN(AlfaRefT) TO MAX(AlfaRefT) DO
      Close(filesAlfa[alfaIdx, Pomiar]);
    END (* for alfaIdx *);
    FOR commSig := MIN(CommSig) TO MAX(CommSig) DO
      Close(filesComm[commSig, Pomiar]);
    END (* for commSig *);
    Close(xRefFile[Pomiar]);
  END CloseSignalFiles;

  PROCEDURE RemoveBSl
            ( VAR Path : ARRAY OF CHAR );
  VAR
    lastChar : CARDINAL;

  BEGIN
    lastChar := Strings.Length(Path);
    IF lastChar = 0
    THEN
      RETURN
    END (* if lastChar *);
    DEC(lastChar);
    IF Path[lastChar] = "\"
    THEN
      Path[lastChar] := 0C;
    END (* if Path *);
  END RemoveBSl;

  PROCEDURE KopiujWszystkiePliki
            ( VAR DoKatalogu : ARRAY OF CHAR;
                  Pomiar     : BOOLEAN       );
  VAR
    alfaIdx : AlfaRefT;
    distIdx : OdnDlaPomOdlT;
    dateIdx : DateKind;
    commIdx : CommSig;

    PROCEDURE TworzK();
    VAR
      Tmp : ARRAY [0 .. 127] OF CHAR;

    BEGIN (* TworzK *)
      Assign(DoKatalogu, Tmp);
      RemoveBSl(Tmp);
      IF NOT ExistDIR(Tmp)
      THEN
        IF NOT MkDir(Tmp)
        THEN
          Assert(FALSE);
          Display(DirErr);
        END (* if *);
      END (* if *);
    END TworzK;

  BEGIN
    TworzK;
    FOR alfaIdx := MIN(AlfaRefT) TO MAX(AlfaRefT) DO
      Kopiuj(NamesAlfa[alfaIdx, Pomiar], DoKatalogu);
    END (* for alfaIdx *);
    FOR distIdx := MIN(OdnDlaPomOdlT) TO MAX(OdnDlaPomOdlT) DO
      Kopiuj(NamesDist[distIdx, Pomiar], DoKatalogu);
    END (* for distIdx *);
    FOR dateIdx := MIN(DateKind) TO MAX(DateKind) DO
      Kopiuj(NamesAn[dateIdx, Pomiar], DoKatalogu);
    END (* for dateIdx *);
    FOR commIdx := MIN(CommSig) TO MAX(CommSig) DO
      Kopiuj(NamesComm[commIdx, Pomiar], DoKatalogu);
    END (* for commIdx *);
  END KopiujWszystkiePliki;

  PROCEDURE LoadAResult
            ( VAR date                 : ARRAY OF BYTE;
                  what                 : DateKind;
                  Pomiar               : BOOLEAN;
                  OptionalVersion_From,
                  OptionalVersion_To   : CARDINAL       ) : BOOLEAN;
  VAR
    file : CARDINAL;
    ver  : CARDINAL;
  BEGIN
    file := Open(NamesAn[what, Pomiar]);
    IF file = NilValC THEN
      RETURN FALSE
    END (* if *);
    IF (OptionalVersion_From # NilValC) &
       (OptionalVersion_To   # NilValC)
    THEN
      IF NOT Read( file, ADR(ver), 2 ) OR
         (ver < OptionalVersion_From) OR
         (ver > OptionalVersion_To)
      THEN
        Info( 'Niewˆa˜ciwa wersja programu !!!');
        Wait( 3*TInOneSecond());
        Terminate( Warning );
      END;
      Assert( Seek( file, 0l, sBegin )=0l );
    END;
    IF NOT Read(file, ADR(date), SIZE(date)) THEN
      RETURN FALSE;
    END;
    Close(file);
    RETURN TRUE;
  END LoadAResult;

  PROCEDURE SaveAResult
            ( VAR date   : ARRAY OF BYTE;
                  what   : DateKind;
                  Pomiar : BOOLEAN       );
  VAR
    file : CARDINAL;

  BEGIN
    file := Create(NamesAn[what, Pomiar]);
    IF (file = NilValC) OR NOT Write(file, ADR(date), SIZE(date))
    THEN
      Display(FileErr);
    END (* if *);
    Close(file);
  END SaveAResult;

  PROCEDURE ExistDIR
            ( VAR Dir : ARRAY OF CHAR ) : BOOLEAN;
  VAR
    ok  : BOOLEAN;
    Tmp : ARRAY [0 .. 127] OF CHAR;

  BEGIN
    GetDir(Tmp);
    ok := CD(Dir);
    IF CD(Tmp)
    THEN   (* wraca gdzie byl *)
    END (* if CD *);
    RETURN ok;
  END ExistDIR;

  PROCEDURE ChangeDir
            (    Path : ARRAY OF CHAR ) : BOOLEAN;

  BEGIN
    RemoveBSl(Path);
    RETURN CD(Path);
  END ChangeDir;

  PROCEDURE GoHomeDir;

  BEGIN
    IF NOT CD(homeDir)
    THEN
      Display(DirErr);
    END (* if CD *);
  END GoHomeDir;

  PROCEDURE AssignName
            (     inStr : ARRAY OF CHAR;
              VAR name  : NameDsc       );
  VAR
    Pomiar : BOOLEAN;

  BEGIN
    FOR Pomiar := FALSE TO TRUE DO
      Assign(inStr, name[Pomiar]);
      name[Pomiar, 7] := CHR(ORD(Pomiar) + ORD('0'));
    END (* for Pomiar *);
  END AssignName;

  TYPE
    Sub =
      PROCEDURE
        (     WORD,
              WORD ) : REAL;
        (* a, minusb : INTEGER *)
    Add =
      PROCEDURE
        (     WORD,
              WORD,
              REAL ) : WORD;
        (* = a + b * wspolczynnik *)

  PROCEDURE SubstituteAngle100
            (    A,
                 minusB : WORD ) : REAL;

  BEGIN
    RETURN real(SubAngle100(INTEGER(A), INTEGER(minusB)));
  END SubstituteAngle100;

  PROCEDURE addAngle100
            (    A,
                 plusB : WORD;
                 wsp   : REAL ) : WORD;
  VAR
    wspI : INTEGER;

  BEGIN
    wspI := entier(FLOAT(CARDINAL(plusB)) * wsp + 0.5);
    RETURN WORD(AddAngle100(INTEGER(A), wspI));
  END addAngle100;

  PROCEDURE subNormal
            (    A,
                 minusB : WORD ) : REAL;

  BEGIN
    IF CARDINAL(A) > CARDINAL(minusB)
    THEN
      RETURN FLOAT(CARDINAL(A) - CARDINAL(minusB));
    ELSE
      RETURN -FLOAT(CARDINAL(minusB) - CARDINAL(A));
    END (* if CARDINAL *);
  END subNormal;

  PROCEDURE addNormal
            (    A,
                 plusB : WORD;
                 wsp   : REAL ) : WORD;

  BEGIN
    RETURN WORD(TRUNC(FLOAT(CARDINAL(A)) + FLOAT(CARDINAL(plusB)) * wsp + 0.5))
    ;
  END addNormal;

  PROCEDURE FInterpolacja
            (    MFileN : ARRAY OF CHAR;
                 FFileN : ARRAY OF CHAR;
                 kat    : BOOLEAN;
             VAR last   : WORD       );
    (* tworzy interpolacje danych w pliku MFileN, na podstawie flagi okpos z
       pliku flag FFileN *)

  CONST
    len     = 10;  (* mozna interpolowac na 10 probek *)
    tmpname = "TEMP.TMP";
  VAR
    nillVAl : WORD;
    SubProc : Sub;
    AddProc : Add;
    FFile   : CARDINAL;
    MFile   : CARDINAL;
    RFile   : CARDINAL;
    samples : CARDINAL;
    sib,
    idx     : CARDINAL;
    ii      : INTEGER;
    wspA    : REAL;
    flg     : BITSET;
    buff    : ARRAY [0 .. len] OF WORD;
    Tmpname : ARRAY [0 .. 10] OF CHAR;
    ok      : BOOLEAN;

  BEGIN
    IF kat
    THEN
      nillVAl := WORD(SigNilVal);
      SubProc := SubstituteAngle100;
      AddProc := addAngle100;
    ELSE
      nillVAl := WORD(DisNilVal);
      SubProc := subNormal;
      AddProc := addNormal;
    END (* if kat *);
    last := nillVAl;
    FFile := Open(FFileN);
    MFile := Open(MFileN);
    RFile := Create(tmpname);
    samples := VAL(CARDINAL, Length(MFile) DIV VAL(LONGINT, 2));
    IF samples > 10  THEN
    sib := len;   (* nie bylo dobrego odczytu od dawna, nie ma go w buforze *)
    FOR idx := 0 TO samples - 1 DO
      ReadDef(FFile, flg, {0..15});
      ReadDef(MFile, buff[sib], nillVAl);
      IF NowySegment IN flg
      THEN   (* przerwa w pomiarze, nie wolno interpolowac *)
        IF sib = len
        THEN
          ok := Write(RFile, ADR(buff[len]), 2);
        ELSE
          ok := Write(RFile, ADR(buff), 2 * (sib + 1));
          sib := len;   (* sib =len nie ma dobrego poczatku *)
        END (* if sib *);
      END (* if Gap_in_data *);
      IF buff[sib] <> nillVAl
      THEN
        last := buff[sib];
        IF sib # len
        THEN
          IF sib # 0
          THEN   (* buff[0] zawiera dobry odczyt i buff[sib] tez *)
            wspA := SubProc(buff[sib], buff[0]) / FLOAT(sib);
            FOR ii := 1 TO sib - 1 DO
              buff[ii] := AddProc(buff[0], ii, wspA);
            END (* for ii *);
          END (* if sib *);
          ok := Write(RFile, ADR(buff), 2 * sib);
        END (* if sib *);
        buff[0] := buff[sib];   (* nowy poczatek *)
        sib := 1;
      ELSIF sib < len - 1
      THEN   (* napelniaj bufor *)
        INC(sib);
      ELSIF sib = len - 1
      THEN   (* nie mozna tak dlugo czekac , wywal bufor *)
        ok := Write(RFile, ADR(buff), 2 * len);
        INC(sib);   (* sib =len nie ma dobrego poczatku *)
      ELSE   (* jak, nie ma to przepisuj 1:1 *)
        ok := Write(RFile, ADR(buff[len]), 2);
      END (* if *);
    END (* for i *);
    IF sib < len
    THEN   (* w buforze jest jeszcze cos waznego *)
      ok := Write(RFile, ADR(buff), 2 * sib);
    END (* if sib *);
    END;
    Close(FFile);
    Close(RFile);
    Close(MFile);
    Delete(MFileN);
    Tmpname := tmpname;
    ok := Rename(MFileN, Tmpname);
  END FInterpolacja;

  PROCEDURE SigInterpolacja
            (    Signal : XRefKind;
                 Pomiar : BOOLEAN;
             VAR last   : WORD );
  VAR
    SigName : NamString;
    FlgName : NamString;
    kat     : BOOLEAN;

  BEGIN
    FlgName := NamesComm[CS_Flags, Pomiar];
    CASE Signal OF
      TEOAxref :
        kat := TRUE;
        SigName := NamesAlfa[pbTeodolit, Pomiar];
      |
      GPSAxref :
        kat := TRUE;
        SigName := NamesAlfa[pbGPS, Pomiar];
      |
      GPSRxref :
        kat := FALSE;
        SigName := NamesDist[poGPS, Pomiar];
      |
      DME_Axref :
        kat := FALSE;
        SigName := NamesDist[poDMEA, Pomiar];
      |
      DME_Bxref :
        kat := FALSE;
        SigName := NamesDist[poDMEB, Pomiar];
      |
      Speedxref :
        RETURN;
    END (* case Signal *);
    FInterpolacja(SigName, FlgName, kat, last);
  END SigInterpolacja;

  PROCEDURE GetALfaRefFName
            (     sig      : OdnDlaPomBleduT;
                  Pomiar   : BOOLEAN;
              VAR name     : ARRAY OF CHAR);
  BEGIN
    Assign(NamesAlfa[sig, Pomiar], name);
  END GetALfaRefFName;

  PROCEDURE GetDisRefFName
            (     sig      : OdnDlaPomOdlT;
                  Pomiar   : BOOLEAN;
              VAR name     : ARRAY OF CHAR);
  BEGIN
    Assign(NamesDist[sig, Pomiar], name);
  END GetDisRefFName;

  PROCEDURE GetCommSigFName
            (     sig      : CommSig;
                  Pomiar   : BOOLEAN;
              VAR name     : ARRAY OF CHAR);
  BEGIN
    Assign(NamesComm[sig, Pomiar], name);
  END GetCommSigFName;

  PROCEDURE OpenCommSigFName
            (     sig      : CommSig;
                  Pomiar   : BOOLEAN;
              VAR file     : CARDINAL);
  BEGIN
    file := Open(NamesComm[sig, Pomiar]);
  END OpenCommSigFName;

  PROCEDURE CloseCommSigFName
            ( VAR file     : CARDINAL);
  BEGIN
    Close(file);
  END CloseCommSigFName;

  PROCEDURE ReadCommSigFName
            ( VAR val      : INTEGER;
                  file     : CARDINAL);
  BEGIN
    ReadDef(file, val, SigNilVal);
  END ReadCommSigFName;

  PROCEDURE Init;
  VAR
    alfaIdx : AlfaRefT;
    distIdx : OdnDlaPomOdlT;
    commIdx : CommSig;
    Pomiar  : BOOLEAN;

  BEGIN
    (* Analiza *)
    AssignName("ANALIZA_.DAT", NamesAn[Analiza]);
    AssignName("Events__.DAT", NamesAn[Events]);
    (* Odleglosc *)
    AssignName("DMEA____.DAT", NamesDist[poDMEA]);
    AssignName("DMEB____.DAT", NamesDist[poDMEB]);
    AssignName("GPSR____.DAT", NamesDist[poGPS]);
    AssignName("PreDis__.DAT", NamesDist[poZadanaPredkosc]);
    (* Odniesienie kata *)
    AssignName("TEOA____.DAT", NamesAlfa[pbTeodolit]);
    AssignName("GPSA____.DAT", NamesAlfa[pbGPS]);
    (* wspolne sygnaly *)
    AssignName("EPE_____.DAT", NamesComm[CS_GPS_EPE]);
    AssignName("GDOP____.DAT", NamesComm[CS_GPS_GDOP]);
    AssignName("NOS_____.DAT", NamesComm[CS_GPS_NOS]);
    AssignName("PILERR__.DAT", NamesComm[CS_PilError]);
    AssignName("FLG_____.DAT", NamesComm[CS_Flags]);
    AssignName("ALTITUDE.DAT", NamesComm[CS_Alt_Sg]);
    FOR Pomiar := FALSE TO TRUE DO
      xRefFile[Pomiar] := NilValC;
      FOR alfaIdx := MIN(AlfaRefT) TO MAX(AlfaRefT) DO
        filesAlfa[alfaIdx, Pomiar] := NilValC;
      END (* for alfaIdx *);
      FOR distIdx := MIN(OdnDlaPomOdlT) TO MAX(OdnDlaPomOdlT) DO
        filesDist[distIdx, Pomiar] := NilValC;
      END (* for distIdx *);
      FOR commIdx := MIN(CommSig) TO MAX(CommSig) DO
        filesComm[commIdx, Pomiar] := NilValC;
      END (* for commIdx *);
    END (* for Pomiar *);
    NewMessage(FileErr, "Files: Powstal krytyczny bˆad w systemie plikow",
               BITSET(0E0F1H));
    NewMessage(DirErr, "Files: Nie mo¾na utworzy† kartoteki ", BITSET(0E0F1H));
    GetDir(homeDir);
  END Init;

BEGIN
  FCBS.Set(100);
  Init;
END Files.
