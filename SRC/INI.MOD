(********************************
*
*  10-11-96 04:00pm MM:
*        Zaklada sie, ze aktualny dysk nie bedzie zmieniany.
*        ale aktualna kartoteke mozna sobie zmienic
*  09-10-97 05:52pm:
*        Byly 2 bledy w kasowaniu sekcji
*
****************************************)

IMPLEMENTATION MODULE Ini;

  IMPORT
    DOSEntry, Timer, Strings, Semafory;

  FROM SYSTEM IMPORT
    ADR, ADDRESS, DOSCALL;

  FROM RTSMain IMPORT
    InstallTermProc;

  FROM FIO IMPORT
    Open, Create, Close, Write, Read, Length, File, GetDir, CD;

  FROM BlockOps IMPORT
    BlockMove, BlockPosition, BlockClear;

  FROM MANAGER IMPORT
    Assert;

  FROM Sounds IMPORT
    Sound, NoSound;

  CONST
    MaxFileLen      = 05000H;
    MAX_LINE_LENGTH = 80;

  TYPE
    StringIdxT =
      [0 .. MAX_LINE_LENGTH - 1];
    BuffIdxT   =
      [0 .. MaxFileLen];
    BuffType   =
      ARRAY BuffIdxT OF CHAR;
    BuffPtr    =
      POINTER TO BuffType;
    String     =
      ARRAY StringIdxT OF CHAR;

  VAR
    ini           : Semafory.Semafor;
    currfile      : File;
    BuffP         : BuffPtr;
    Bufor         : BuffType;
    charsInBuffer : BuffIdxT;
    SavedFileName,
    LastDir       : ARRAY [0 .. 99] OF CHAR;
    Modified      : BOOLEAN;

  PROCEDURE DefaultError
            (    e : ErrorKind );

  BEGIN
    Assert(FALSE);
  END DefaultError;

  PROCEDURE FormSectionString
            ( VAR Section,
                  TSec    : ARRAY OF CHAR );
  VAR
    l : BuffIdxT;

  BEGIN
    Assert(HIGH(TSec) > Strings.Length(Section) + 6);
    Strings.Assign(Section, TSec);
    Strings.Insert("[", TSec, 0);
    Strings.Insert("]", TSec, 0FFFFH);
    l := Strings.Length(TSec);
    TSec[l] := 15C;
    TSec[l + 1] := 12C;
    TSec[l + 2] := 0C;
  END FormSectionString;

  PROCEDURE LookForSection
            (     FB      : BuffPtr;
                  FS      : BuffIdxT;
              VAR Section : ARRAY OF CHAR;
              VAR secpos  : BuffIdxT      ) : BOOLEAN;
  VAR
    TSec : String;
    pos  : CARDINAL;
    l    : StringIdxT;

  BEGIN
    FormSectionString(Section, TSec);
    l := Strings.Length(TSec);
    pos := BlockPosition(ADDRESS(FB), FS, ADR(TSec), l);
    IF pos # MAX(CARDINAL)
    THEN
      secpos := pos + l;
      RETURN TRUE
    ELSE
      RETURN FALSE
    END (* if pos *);
  END LookForSection;

  PROCEDURE LookForEntry
            (     FB       : BuffPtr;
                  FS,
                  currPos  : BuffIdxT;
              VAR Entry    : ARRAY OF CHAR;
              VAR entryPos : BuffIdxT      ) : BOOLEAN;
    (* zwraca pozycje za = *)

    PROCEDURE ToEOL() : BuffIdxT;
    VAR
      eolp : BuffIdxT;

    BEGIN
      eolp := currPos;
      WHILE (eolp < FS) AND (FB^[eolp] # 12C) DO
        INC(eolp);
      END (* while *);
      IF eolp < FS
      THEN
        INC(eolp);
      END (* if eolp *);
      RETURN eolp;
    END ToEOL;
  VAR
    p1,
    p2,
    eqpos : BuffIdxT;
    B     : String;

  BEGIN
    WHILE (FB^[currPos] # "[") DO
      p1 := ToEOL();
      p2 := p1 - currPos;
      IF (p2 >= MAX_LINE_LENGTH) OR (p2 < 2)
      THEN
        RETURN FALSE (* error *)
      END (* if *);
      DEC(p2, 2);
      BlockMove(ADR(B), ADR(FB^[currPos]), p2);
      B[p2] := 0C;
      eqpos := Strings.Pos("=", B);
      IF eqpos < p2
      THEN
        B[eqpos] := 0C;
        IF Strings.CompareStr(B, Entry) = 0
        THEN
          entryPos := currPos + eqpos + 1;
          RETURN TRUE
        END (* if Strings.CompareStr *);
      END (* if eqpos *);
      currPos := p1;
    END (* while *);
    RETURN FALSE;
  END LookForEntry;

  PROCEDURE GetPrivateProfileString
            (     Section  : ARRAY OF CHAR;
                  Entry    : ARRAY OF CHAR;
                  Default  : ARRAY OF CHAR;
              VAR Buffer   : ARRAY OF CHAR;
                  FileName : ARRAY OF CHAR );
  VAR
    B    : String;
    Bpos,
    idx  : BuffIdxT;

  BEGIN
    Semafory.Set(ini);
    AllocateBuffer(FileName);
    Assert(Strings.Length(Default) <= HIGH(Buffer));
    Strings.Assign(Default, Buffer);
    IF charsInBuffer <> 0
    THEN
      IF LookForSection(BuffP, charsInBuffer, Section, Bpos)
      THEN
        IF LookForEntry(BuffP, charsInBuffer, Bpos, Entry, Bpos)
        THEN
          idx := 0;
          WHILE (idx < HIGH(Buffer)) AND (Bpos < charsInBuffer) AND
                (BuffP^[Bpos] # 15C) DO
            Buffer[idx] := BuffP^[Bpos];
            INC(idx);
            INC(Bpos);
          END (* while *);
          Buffer[idx] := 0C;
        END (* if LookForEntry *);
      END (* if LookForSection *);
    END (* if charsInBuffer *);
    Semafory.Free(ini);
  END GetPrivateProfileString;

  PROCEDURE DeleteSection
            (    Section  : ARRAY OF CHAR;
                 FileName : ARRAY OF CHAR );
  VAR
    B  : String;
    i  : BuffIdxT;
    ls : BuffIdxT;

  BEGIN
    Semafory.Set(ini);
    AllocateBuffer(FileName);
    FormSectionString(Section, B);
    IF LookForSection(BuffP, charsInBuffer, Section, ls)
    THEN
    (* nie ma takie sekcji -> olac *)
      Modified := TRUE;
      i := ls;
      WHILE (i < charsInBuffer) &
            NOT( (BuffP^[i] = "[") & (BuffP^[i-1] = 12C (*lf*) )) DO
        INC(i);
      END (* while *);
      DEC(ls, Strings.Length(B));
      BlockMove(ADR(BuffP^[ls]), ADR(BuffP^[i]), charsInBuffer - i);
      DEC(charsInBuffer, i - ls);   (* tyle ubylo *)
    END (* if LookForSection *);
    Semafory.Free(ini);
  END DeleteSection;

  VAR
    check : CARDINAL;

  PROCEDURE WritePrivateProfileString
            (    Section  : ARRAY OF CHAR;
                 Entry    : ARRAY OF CHAR;
                 What     : ARRAY OF CHAR;
                 FileName : ARRAY OF CHAR );
  VAR
    B,
    C     : String;
    len   : StringIdxT;
    ls    : BuffIdxT;
    SecS  : BuffIdxT;
    lenhi : StringIdxT;

  BEGIN
    Semafory.Set(ini);
    DEC(check);
    Assert(Strings.Length(Section) > 0);
    Assert(Strings.Length(Entry) > 1);
    AllocateBuffer(FileName);
    Modified := TRUE;
    FormSectionString(Section, B);
    Strings.Assign(Entry, C);
    Strings.Insert('=', C, 0FFFFH);
    Strings.Insert(What, C, 0FFFFH);
    lenhi := Strings.Length(C);
    IF lenhi >= (MAX_LINE_LENGTH - 3)
    THEN
      lenhi := (MAX_LINE_LENGTH - 3);
    END (* if lenhi *);
    C[lenhi] := 15C;
    C[lenhi + 1] := 12C;
    INC(lenhi, 2);
    IF NOT LookForSection(BuffP, charsInBuffer, Section, ls)
    THEN
      len := Strings.Length(B);
      BlockMove(ADR(BuffP^[charsInBuffer]), ADR(B), len);   (* dodaj sekcje na
                                                               koncu *)
      INC(charsInBuffer, len);
      BlockMove(ADR(BuffP^[charsInBuffer]), ADR(C), lenhi);   (* dodaj tresc na
                                                                 koncu *)
      INC(charsInBuffer, lenhi);
    ELSE
      IF LookForEntry(BuffP, charsInBuffer, ls, Entry, ls)
      THEN   (* usun stare *)
        len := Strings.Length(Entry) + 1;   (* i znak "=" *)
        BlockMove(ADR(BuffP^[ls - len]), ADR(BuffP^[ls]), charsInBuffer - ls);
        DEC(charsInBuffer, len);   (* tyle ubylo *)
        DEC(ls, len);   (* na poczatek linii *)
        SecS := ls;
        WHILE (SecS < charsInBuffer) AND (BuffP^[SecS] # 12C) DO
          INC(SecS);
        END (* while *);
        INC(SecS);   (* koniec *)
        BlockMove(ADR(BuffP^[ls]), ADR(BuffP^[SecS]), charsInBuffer - SecS);
        DEC(charsInBuffer, SecS - ls);   (* ubylo *)
      END (* if LookForEntry *);
      (* wstaw w miejsce SecS *)
      BlockMove(ADR(BuffP^[ls + lenhi]), ADR(BuffP^[ls]), charsInBuffer - ls);
      (* rozsun *)
      BlockMove(ADR(BuffP^[ls]), ADR(C), lenhi);   (* wstaw *)
      INC(charsInBuffer, lenhi);
    END (* if *);
    INC(check);
    Semafory.Free(ini);
  END WritePrivateProfileString;

  PROCEDURE Expand
            ( VAR src,
                  dest : ARRAY OF CHAR );
  VAR
    Path     : ARRAY [0 .. 64] OF CHAR;
    DriveStr : ARRAY [0 .. 3] OF CHAR;
    err,
    i        : CARDINAL;
    drive    : CARDINAL;

  BEGIN
    DOSCALL(047H, 0, ADR(Path), err);   (* Get Current directory from default
                                           drive *)
    Strings.Insert('\', Path, 0FFFH);
    DOSCALL(19H, drive);   (* get current drive *)
    DriveStr := "A:\";
    DriveStr[0] := CHR(drive + ORD('A'));
    Strings.Assign(src, dest);
    IF src[0] = '.'
    THEN
      IF src[1] = '.'
      THEN
        i := Strings.Length(Path) - 1;
        WHILE Path[i - 1] # '\' DO
          DEC(i);
        END (* while Path *);
        Path[i] := 0C;
        Strings.Delete(dest, 0, 3);
      ELSE
        Strings.Delete(dest, 0, 2);
      END (* if src *);
    ELSIF src[0] = '\'
    THEN
      Path[0] := 0C;
    ELSIF src[1] = ':'
    THEN
      DriveStr[0] := 0C;
    END (* if src *);
    Strings.Insert(Path, dest, 0);
    Strings.Insert(DriveStr, dest, 0);
    FOR i := 0 TO Strings.Length(dest) - 1 DO
      dest[i] := CAP(dest[i]);
    END (* for i *);
  END Expand;

  PROCEDURE CloseBuffer;
  VAR
    Folder : ARRAY[0..99] OF CHAR;
  BEGIN
    (* Sound(1000); *)
    IF Modified
    THEN
      Assert(SavedFileName[0] # 0C);
      Assert(currfile = MAX(CARDINAL));
      GetDir( Folder );
      IF NOT CD( LastDir ) THEN
        HALT; (* O do cholery!!! *)
      END;
      currfile := Create(SavedFileName);
      IF NOT CD( Folder ) THEN (* po otwarciu pliku powrot do poprzedniej karoteki *)
        HALT; (* O do cholery!!! *)
      END;
      IF currfile = MAX(CARDINAL)
      THEN
        Modified := FALSE;
        SavedFileName[0] := 0C;
        ErrorProc(erCannotRead);
        RETURN;
      END (* if currfile *);
      IF NOT Write(currfile, ADR(Bufor), charsInBuffer)
      THEN
        Modified := FALSE;
        Close(currfile);
        SavedFileName[0] := 0C;
        ErrorProc(erCannotRead);
        RETURN;
      END (* if *);
      Close(currfile);
      Modified := FALSE;
      SavedFileName[0] := 0C;
    END (* if Modified *);
    (* NoSound; *)
  END CloseBuffer;

  PROCEDURE AllocateBuffer
            ( VAR f : ARRAY OF CHAR );
  VAR
    fn : ARRAY [0 .. 50] OF CHAR;

  BEGIN
    Strings.Assign(f, fn);
    (* Expand( f, fn );*)
    IF Strings.CompareStr(fn, SavedFileName) = 0
    THEN   (* juz byl otwarty *)
      Assert(currfile = MAX(CARDINAL));
      IF ((charsInBuffer + 2 * MAX_LINE_LENGTH) > MaxFileLen)
      THEN
        ErrorProc(erOutOfMemory);
        RETURN;
      END (* if *);
      RETURN;
    END (* if Strings.CompareStr *);
    CloseBuffer;
    Strings.Assign(f, SavedFileName);
    BlockClear(BuffP, MaxFileLen);
    currfile := Open(SavedFileName);
    IF currfile = 0FFFFH
    THEN
      charsInBuffer := 0;
    ELSE
      charsInBuffer := VAL(CARDINAL, Length(currfile));
      IF ((charsInBuffer + 2 * MAX_LINE_LENGTH) > MaxFileLen)
      THEN
        Close(currfile);
        SavedFileName[0] := 0C;
        ErrorProc(erOutOfMemory);
        RETURN;
      END (* if *);
      IF NOT Read(currfile, ADR(Bufor), charsInBuffer)
      THEN
        Close(currfile);
        SavedFileName[0] := 0C;
        ErrorProc(erCannotRead);
        RETURN;
        IF BuffP^[charsInBuffer] = CHR(1AH) (* CtrlZ *)
        THEN
          BuffP^[charsInBuffer] := 0C;
          DEC(charsInBuffer);
        END (* if BuffP *);
      END (* if *);
      Close(currfile);
    END (* if currfile *);
    GetDir( LastDir );
  END AllocateBuffer;

BEGIN
  Modified := FALSE;
  BuffP := ADR(Bufor);
  check := 1;
  Semafory.Init(ini);
  SavedFileName[0] := 0C;
  currfile := 0FFFFH;
  charsInBuffer := 0;
  InstallTermProc(CloseBuffer);
  ErrorProc := DefaultError;
END Ini.
