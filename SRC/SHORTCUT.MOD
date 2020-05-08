(*.F- *)
(**********************************************************************
|  Title   : Keyboard and shortcuts management
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    23-06-96: M.Postol
|      Od dawna wiadomo, ze ten modul nie dziala, podobnie jak Buttons
|      Problem 1: uzytkownik kasuje shortcut, a w tym momencie poza monitorem
|      KbdScan spokojnie wykonuje procedure, ktorej adres w zwiazku ze
|      skasowaniem opisu jest calkiem przypadkowy - debug nie mial szans tego
|      zlapac.
|      Problem 2: NEW i DISPOSE nie moga byc wykonywane w monitorze - to
|      blokuje wszystko na bardzo dlugo.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE ShortCuts;

  FROM SYSTEM IMPORT
    ADDRESS, SETREG, GETREG, AX, SWI;

  FROM Storage IMPORT
    ALLOCATE, DEALLOCATE;

  FROM MANAGER IMPORT
    STARTPROCESS, WAITS, SEND, InitS, SIGNAL, Assert;

  FROM Termbase IMPORT
    AssignRead;

  FROM RTSMain IMPORT
    Terminate, Status;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  TYPE
    List =
      POINTER TO SCDsc;
    SCDsc   =
      RECORD
        KeyStroke :
          CARDINAL;
        Proc      :
          ShortCutProc;
        Data      :
          ADDRESS;
        busy      :
          BOOLEAN;
        waiting   :
          SIGNAL;
        Active    :
          CARDINAL;
        Next      :
          List;
      END;

  CONST
    Alive = 31415;
    Dead  = 27182;

  MODULE monitor [ 0 ];

    IMPORT
      WAITS, SEND, InitS, SIGNAL, List, kbNoKey, Assert, Alive, ShortCutProc, 
      ADDRESS;

    EXPORT
      FindAMark, Insert, Unmark, RemoveToKill, PutKeyStrokeIntoBuffer, Read,
      KeyPressed, Rd, ClearBuffer;

    VAR
      ShortCutList : List;
      SavedChar  : CARDINAL;
      FreeKey    : SIGNAL;
      NumEl      : CARDINAL;
      
    PROCEDURE KeyPressed() : BOOLEAN;

    BEGIN
      RETURN SavedChar # kbNoKey;
    END KeyPressed;

    PROCEDURE PutKeyStrokeIntoBuffer
              (    KeyStroke : CARDINAL );

    BEGIN
      SavedChar := KeyStroke;
      SEND(FreeKey);
    END PutKeyStrokeIntoBuffer;

    PROCEDURE ClearBuffer;

    BEGIN
      SavedChar := kbNoKey
    END ClearBuffer;

    PROCEDURE Read
              ( VAR ch : CHAR );

    BEGIN
      IF SavedChar = kbNoKey
      THEN
        WAITS(FreeKey);
      END (* if SavedChar *);
      ch := CHR(SavedChar MOD 256);
      IF (ch = 0C) OR (ch = 377C)
      THEN
        SavedChar := SavedChar DIV 256;
      ELSE
        SavedChar := kbNoKey;
      END (* if *);
    END Read;

    PROCEDURE Rd
              ( VAR ch,
                    scan : CHAR );

    BEGIN
      Read(ch);
      IF (SavedChar # kbNoKey)
      THEN
        Read(scan);
      END (* if *);
    END Rd;

    PROCEDURE Insert
              (    shrt : List );

    BEGIN
      INC(NumEl);
      WITH shrt^ DO
        Next := ShortCutList;
        ShortCutList := shrt;
      END (* with butt *);
    END Insert;

    PROCEDURE RemoveToKill
              (     key     : CARDINAL;
                VAR shrtcut : List     );

      PROCEDURE Remove
                (        key : CARDINAL;
                 VAR shrtcut : List );
      VAR
        t : List;

      BEGIN
        DEC(NumEl);
        Assert(ShortCutList^.Active = Alive);
        IF ShortCutList^.KeyStroke = key
        THEN
          shrtcut := ShortCutList;
          ShortCutList := ShortCutList^.Next;
          IF ShortCutList <> NIL
          THEN
            Assert(ShortCutList^.Active = Alive);
          END (* if ShortCutList *);
        ELSE
          t := ShortCutList;
          WHILE t^.Next^.KeyStroke # key DO
            t := t^.Next;
            Assert(t^.Active = Alive);
          END (* while *);
          shrtcut := t^.Next;
          t^.Next := shrtcut^.Next;
          shrtcut^.Next := NIL;
        END (* if ShortCutList *);
      END Remove;

    BEGIN (* RemoveToKill *)
      Remove(key, shrtcut);
      WITH shrtcut^ DO
        IF busy
        THEN
          WAITS(waiting);
        END (* if removable *);
        busy := TRUE;
      END (* with shrtcut *);
    END RemoveToKill;

      PROCEDURE  Find(key      : CARDINAL): List;
      VAR
        shortcut: List;
      BEGIN
        shortcut := ShortCutList;
        WHILE (shortcut # NIL) & (shortcut^.KeyStroke # key) DO
          Assert(shortcut^.Active = Alive);
          shortcut := shortcut^.Next;
        END (* while *);
        RETURN shortcut;
      END Find;

    PROCEDURE FindAMark
              ( VAR shortcut : List;
                    key      : CARDINAL ) : BOOLEAN;
    BEGIN
      shortcut := Find(key);
      IF shortcut = NIL
      THEN   (* nie ma takiego shortcut'a *)
        SavedChar := key;   (* jednoznakowy bufor *)
        SEND(FreeKey);
        RETURN FALSE;
      ELSIF NOT shortcut^.busy
      THEN
        shortcut^.busy := TRUE;
        RETURN TRUE
      ELSE
        RETURN FALSE;
      END (* if shortcut *);
    END FindAMark;

    PROCEDURE Unmark
              (    shortcut : List );

    BEGIN
      Assert(shortcut^.Active = Alive);
      WITH shortcut^ DO
        busy := FALSE;
        SEND(waiting);
      END (* with shortcut *);
    END Unmark;

  BEGIN
    NumEl := 0;
    ShortCutList := NIL;
    SavedChar := kbNoKey;
    InitS(FreeKey);
  END monitor;

  PROCEDURE KbdScan;
  VAR
    key      : CARDINAL;
    shortcut: List;

    PROCEDURE GetChar
              ( VAR key : CARDINAL );
    VAR
      kbH  [ 40H:1AH ] : CHAR;
      kbT  [ 40H:1CH ] : CHAR;

    BEGIN
      WHILE kbH = kbT DO
        Wait(TInOneSecond() DIV 10);
      END (* while kbH *);
      SETREG(AX, 0);
      SWI(16H);
      GETREG(AX, key);
    END GetChar;

  BEGIN
    WHILE NOT Kill DO
      GetChar(key);
      IF FindAMark(shortcut, key) THEN
        WITH shortcut^ DO
          Proc(Data);
        END;
        Unmark(shortcut);
      END (* if FindAMark *);
    END (* while *);
  END KbdScan;

  PROCEDURE DefineShortCut
            (    key  : CARDINAL;
                 proc : ShortCutProc;
                 data : ADDRESS      );
  VAR
    shrt : List;

  BEGIN
    IF key = kbNoKey  THEN
      RETURN
    END;
    NEW(shrt);
    WITH shrt^ DO
      KeyStroke := key;
      Proc := proc;
      Data := data;
      busy := FALSE;
      InitS(waiting);
      Active := Alive;
      Next := NIL;
    END (* with shrt *);
    Insert(shrt);
  END DefineShortCut;

  PROCEDURE DeleteShortCut
            (    KeyStroke : CARDINAL );
  VAR
    l : List;

    PROCEDURE Kill
              (    shrtcut : List );

    BEGIN
      WITH shrtcut^ DO
        Assert(Active = Alive);
        Active := Dead;
      END (* with shrtcut *);
      DISPOSE(shrtcut);
    END Kill;

  BEGIN
    IF KeyStroke = kbNoKey  THEN
      RETURN
    END;
    RemoveToKill(KeyStroke, l);
    Kill(l);
  END DeleteShortCut;

  VAR
    done : BOOLEAN;

BEGIN
  Kill := FALSE;
  STARTPROCESS(KbdScan, 1100H, 0);   (* i ani bajta mniej !, dolozylem mu 100
                                        bo sie wywala *)
  AssignRead(Read, KeyPressed, done);
  IF NOT done
  THEN
    Terminate(Stopped);
  END (* if *);
END ShortCuts.
