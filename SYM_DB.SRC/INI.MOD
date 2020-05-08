(*  # call (o_a_copy=>off)*)
IMPLEMENTATION MODULE Ini;

IMPORT FIO, Str, FIOR, Lib;
FROM stdio IMPORT
  sprintf, sscanf;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE, Available;

CONST
  MAX_LINE_LENGTH = 80;
  EOL = 15C+12C;

TYPE
  String = ARRAY[0..MAX_LINE_LENGTH-1] OF CHAR;
  StrPtr = POINTER TO String;

TYPE
  LPSTR =  POINTER TO ARRAY [0..0FFF0H] OF CHAR;




CONST
  MaxFileLen      = 05000H;
TYPE
  BuffIdxT   = [0..MaxFileLen-1];
  BuffType   =  ARRAY BuffIdxT OF CHAR;
VAR
  currfile      : FIO.File;
  Bufor         : BuffType;
  charsInBuffer : BuffIdxT;
  SavedFileName : ARRAY [0 .. 99] OF CHAR;
  Modified      : BOOLEAN;


PROCEDURE CloseBuffer;
  BEGIN
    IF Modified THEN
      currfile := FIOR.Create(SavedFileName);
      IF currfile = MAX(CARDINAL) THEN
        Modified := FALSE;
        SavedFileName[0] := 0C;
        ErrorProc(erCannotRead);
        RETURN;
      END (* if currfile *);
      FIO.WrBin(currfile, Bufor, charsInBuffer);
      FIO.Close(currfile);
      Modified := FALSE;
      SavedFileName[0] := 0C;
    END (* if Modified *);
  END CloseBuffer;

PROCEDURE AllocateBuffer( VAR f : ARRAY OF CHAR );
  BEGIN
    IF Str.Compare(f, SavedFileName) = 0 THEN   (* juz byl otwarty *)
      IF ((charsInBuffer + 2 * MAX_LINE_LENGTH) > MaxFileLen) THEN
        ErrorProc(erOutOfMemory);
        RETURN;
      END (* if *);
      RETURN;
    END (* if Strings.CompareStr *);
    CloseBuffer;
    Str.Copy( SavedFileName, f );
    Lib.Fill( ADR(Bufor), MaxFileLen, 0 );
    currfile := FIOR.Open(SavedFileName);
    IF currfile = 0FFFFH THEN
      charsInBuffer := 0;
    ELSE
      charsInBuffer := VAL(CARDINAL, FIO.Size(currfile));
      IF ((charsInBuffer + 2 * MAX_LINE_LENGTH) > MaxFileLen) THEN
        FIO.Close(currfile);
        SavedFileName[0] := 0C;
        ErrorProc(erOutOfMemory);
        RETURN;
      END (* if *);
      IF FIO.RdBin(currfile, Bufor, charsInBuffer) # charsInBuffer THEN
        FIO.Close(currfile);
        SavedFileName[0] := 0C;
        ErrorProc(erCannotRead);
        IF Bufor[charsInBuffer-1] = CHR(1AH) (* CtrlZ *) THEN
          Bufor[charsInBuffer-1] := 0C;
          DEC(charsInBuffer);
        END (* if BuffP *);
      END (* if *);
      FIO.Close(currfile);
    END (* if currfile *);
  END AllocateBuffer;

PROCEDURE LookForSection( VAR Section : ARRAY OF CHAR;
                          VAR Pos     : CARDINAL      ) : BOOLEAN;
VAR
  T_Sec : String;
BEGIN
  sprintf( T_Sec, "[%s]", Section );
  Pos := Str.Pos( Bufor, T_Sec );
  RETURN Pos < charsInBuffer;
END LookForSection;

PROCEDURE LookForEntry(     At       : CARDINAL;
                        VAR Entry    : ARRAY OF CHAR;
                        VAR entryPos : CARDINAL      ) : BOOLEAN;
    (* zwraca pozycje za = *)

    PROCEDURE ToEOL() : BuffIdxT;
    VAR
      eolp : BuffIdxT;
    BEGIN
      eolp := At;
      WHILE (eolp < charsInBuffer) AND (Bufor[eolp] # 12C) DO
        INC(eolp);
      END (* while *);
      IF eolp < charsInBuffer THEN
        INC(eolp);
      END (* if eolp *);
      RETURN eolp;
    END ToEOL;


  VAR
    p1,
    p2,
    eqpos : CARDINAL;
    B     : String;

  BEGIN
    At := ToEOL(); (* pominiecie nazwy sekcji *)
    WHILE (Bufor[At] # "[") & (At < charsInBuffer) DO
      p1 := ToEOL();
      p2 := p1 - At;
      IF (p2 >= MAX_LINE_LENGTH) OR (p2 < 2)
      THEN
        RETURN FALSE (* error *)
      END (* if *);
      DEC(p2, 2);
      Lib.Move(ADR(Bufor[At]), ADR(B), p2);
      B[p2] := 0C;
      eqpos := Str.Pos( B, "=" );
      IF eqpos < p2 THEN
        B[eqpos] := 0C;
        (* kasowanie spacji *)
        WHILE (B[0] # 0C) & (B[ Str.Length(B) -1 ] = ' ') DO
          B[Str.Length(B)-1] := 0C;
        END;
        IF Str.Compare(B, Entry) = 0 THEN
          entryPos := At + eqpos + 1;
          RETURN TRUE
        END (* if Strings.CompareStr *);
      END (* if eqpos *);
      At := p1;
    END (* while *);
    RETURN FALSE;
  END LookForEntry;

PROCEDURE GetPrivateProfileString(     Section  : ARRAY OF CHAR;
                                       Entry    : ARRAY OF CHAR;
                                       Default  : ARRAY OF CHAR;
                                   VAR Wynik    : ARRAY OF CHAR;
                                       FileName : ARRAY OF CHAR );
VAR
  epos : CARDINAL;
  Pos  : CARDINAL;
  i    : CARDINAL;
BEGIN
  AllocateBuffer( FileName );
  Str.Copy( Wynik, Default );
  IF LookForSection( Section, Pos ) &
     LookForEntry( Pos+2, Entry, Pos )
  THEN
    Lib.Fill( ADR( Wynik ), HIGH( Wynik )+1, 0 );
    WHILE (Bufor[Pos] = ' ') & (Pos < charsInBuffer ) DO
      INC( Pos );
    END;
    i := 0;
    WHILE( Pos <= charsInBuffer ) & (Bufor[Pos] >= ' ') & ( i <= HIGH(Wynik)) DO
      Wynik[i] := Bufor[Pos];
      INC( Pos );
      INC( i );
    END;
    (* na wszelki wypadek trzeba uciac spacje z konca *)
    IF i > 0 THEN
      LOOP
        DEC( i );
        IF ( i=0 ) OR ( Wynik[i] # ' ' ) THEN
          EXIT;
        END;
        Wynik[i] := 0C;
      END;
    END;
  END;
END GetPrivateProfileString;

(*
PROCEDURE GetPrivateProfileVal(     Section  : ARRAY OF CHAR;
                                    Entry    : ARRAY OF CHAR;
                                    Fmt      : ARRAY OF CHAR;
                                    FileName : ARRAY OF CHAR );
VAR
  tmp : String;
BEGIN
  GetPrivateProfileString( Section, Entry, "", tmp, FileName );
  sscanf( tmp,
          Fmt,
          AddAddr( ADR( FileName ), SIZE( ADDRESS )),
          AddAddr( ADR( FileName ), 2*SIZE( ADDRESS )),
          AddAddr( ADR( FileName ), 3*SIZE( ADDRESS )),
          AddAddr( ADR( FileName ), 4*SIZE( ADDRESS )),
          AddAddr( ADR( FileName ), 5*SIZE( ADDRESS )),
          AddAddr( ADR( FileName ), 6*SIZE( ADDRESS )),
          AddAddr( ADR( FileName ), 7*SIZE( ADDRESS )),
          AddAddr( ADR( FileName ), 8*SIZE( ADDRESS )),
          AddAddr( ADR( FileName ), 9*SIZE( ADDRESS )),
          AddAddr( ADR( FileName ), 10*SIZE( ADDRESS ))
         );
  (* ze wzgledu na opcje compilatora "s_copy=>off" *)
END GetPrivateProfileVal;

PROCEDURE WritePrivateProfileVal(   Section  : ARRAY OF CHAR;
                                    Entry    : ARRAY OF CHAR;
                                    Fmt      : ARRAY OF CHAR;
                                    FileName : ARRAY OF CHAR );
TYPE
  L = POINTER TO LONGCARD;
VAR
  tmp : String;
BEGIN
  sprintf( tmp,
           Fmt,
           L(AddAddr( ADR( FileName ), SIZE( ADDRESS ) + 9*SIZE( LONGCARD )))^,
           L(AddAddr( ADR( FileName ), SIZE( ADDRESS ) + 8*SIZE( LONGCARD )))^,
           L(AddAddr( ADR( FileName ), SIZE( ADDRESS ) + 7*SIZE( LONGCARD )))^,
           L(AddAddr( ADR( FileName ), SIZE( ADDRESS ) + 6*SIZE( LONGCARD )))^,
           L(AddAddr( ADR( FileName ), SIZE( ADDRESS ) + 5*SIZE( LONGCARD )))^,
           L(AddAddr( ADR( FileName ), SIZE( ADDRESS ) + 4*SIZE( LONGCARD )))^,
           L(AddAddr( ADR( FileName ), SIZE( ADDRESS ) + 3*SIZE( LONGCARD )))^,
           L(AddAddr( ADR( FileName ), SIZE( ADDRESS ) + 2*SIZE( LONGCARD )))^,
           L(AddAddr( ADR( FileName ), SIZE( ADDRESS ) + SIZE( LONGCARD )))^,
           L(AddAddr( ADR( FileName ), SIZE( ADDRESS )))^
         );
  WritePrivateProfileString( Section, Entry, tmp, FileName );
END WritePrivateProfileVal;
*)

PROCEDURE DefaultError( e : ErrorKind );
BEGIN
  Lib.FatalError( 'Cannot process "ini" file');
END DefaultError;

PROCEDURE WritePrivateProfileString(   Section : ARRAY OF CHAR;
                                       Entry   : ARRAY OF CHAR;
                                       What    : ARRAY OF CHAR;
                                       FileName : ARRAY OF CHAR );

VAR
  B, C    : String;
  eol     : ARRAY[0..3] OF CHAR;
  ls      : CARDINAL;

  PROCEDURE WriteSection;

    PROCEDURE Add;
    VAR
      i : CARDINAL;
    BEGIN
      i := Str.Length( B );
      Lib.Move( ADR(B), ADR(Bufor[charsInBuffer]), i );
      INC( charsInBuffer, i );
    END Add;

  BEGIN
    sprintf( B, "[%s]"+EOL, Section );
    Add;
    sprintf( B, "%s=%s"+EOL, Entry, What );
    Add;
  END WriteSection;

  PROCEDURE LookSection():CARDINAL;
  BEGIN
    RETURN Str.Pos( Bufor, B );
  END LookSection;

  PROCEDURE SkipLine( From : CARDINAL ) : CARDINAL;
  BEGIN
    WHILE ( From < charsInBuffer ) & (Bufor[From] # 12C) DO
      INC( From );
    END;
    RETURN From+1;
  END SkipLine;

  PROCEDURE CzyToCalosc( Od : INTEGER ) : BOOLEAN;
  BEGIN
    WHILE Bufor[Od] # 0C DO
      IF Bufor[Od] = ' ' THEN
        INC( Od );
      ELSIF Bufor[Od] = '=' THEN
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END;
    END;
  END CzyToCalosc;

  PROCEDURE LookEntry():CARDINAL;
  VAR
    es : ARRAY [0..3] OF CHAR;
    body, s, p, e : CARDINAL;
    NxSrch : CARDINAL;
  BEGIN
    es := EOL+'[';
    s := Str.Pos( LPSTR(ADR(Bufor[ls]))^, es );
    (* powinno byc Buffer^[s] = CR *)
    IF s # MAX( CARDINAL ) THEN
      INC( s, ls );
      Bufor[s] := 0C;
    END;
    body := SkipLine( ls );
    p := Str.Pos( LPSTR(ADR(Bufor[body]))^, Entry );
    NxSrch := 0;
    WHILE (p # MAX(CARDINAL)) &
         (* czy to nie jest podstring *) NOT CzyToCalosc(body+NxSrch+p+Str.Length(Entry))
    DO
      INC( NxSrch, p+Str.Length(Entry));
      p := Str.Pos( LPSTR(ADR(Bufor[body+NxSrch]))^, Entry );
    END;
    IF p # MAX( CARDINAL ) THEN
      INC( p, NxSrch );
    END;
    IF s # MAX( CARDINAL ) THEN
      Bufor[s] := 15C;
    END;
    IF (p = MAX(CARDINAL)) OR (p+body > charsInBuffer) THEN
      RETURN SkipLine( ls );
    END;
    INC( p, body );
    e := SkipLine(p);
    Lib.Move( ADR( Bufor[e] ), ADR( Bufor[p]), charsInBuffer-p );
    DEC( charsInBuffer, e-p );
    RETURN p;
  END LookEntry;

  PROCEDURE Insert( VAR s : ARRAY OF CHAR; At : CARDINAL );
  VAR
    l, i : CARDINAL;
  BEGIN
    l := Str.Length(s);
    Lib.Move( ADR( Bufor[At] ), ADR( Bufor[At+l]), charsInBuffer-At );
    FOR i := 0 TO l-1 DO (* zeby nie skopiowalo sie koncowe zero *)
      Bufor[At+i] := s[i];
    END;
    INC( charsInBuffer, l );
  END Insert;

BEGIN
  AllocateBuffer( FileName );
  Modified := TRUE;
  sprintf( B, "[%s]"+EOL, Section );
  sprintf( C, "%s=%s"+EOL, Entry, What );
  ls := LookSection();
  IF ls = MAX( CARDINAL ) THEN
    eol := EOL;
    Insert( eol, charsInBuffer );
    Insert( B, charsInBuffer );
    Insert( C, charsInBuffer );
  ELSE
    (* LookEntry() Usuwa tez stare `entry' *)
    Insert( C, LookEntry() );
  END;
END WritePrivateProfileString;

PROCEDURE DeleteSection( Section : ARRAY OF CHAR;
                         FileName: ARRAY OF CHAR );
VAR
  B       : String;
  i       : CARDINAL;
  ls      : CARDINAL;

  PROCEDURE LookSection():CARDINAL;
  BEGIN
    RETURN Str.Pos( Bufor, B );
  END LookSection;



BEGIN
  AllocateBuffer( FileName );
  Modified := TRUE;
  sprintf( B, "[%s]"+EOL, Section );
  ls := LookSection();
  IF ls = MAX( CARDINAL ) THEN
    (* nie ma takiej sekcji -> olac *)
    RETURN;
  END;
  i := ls+1;
  WHILE ( i < charsInBuffer ) & (Bufor[i]#"[") DO
    INC( i );
  END;
  (* DEC( i, 3 ); (* cr,lf,'[' *) *)
  Lib.Move(ADR(Bufor[i]),ADR(Bufor[ls]),charsInBuffer-i);
  DEC(charsInBuffer,i-ls);  (* tyle ubylo *)
END DeleteSection;



VAR
  Chain : PROC;

PROCEDURE Terminator(  );
  BEGIN
    CloseBuffer;
    Chain;
  END Terminator;

BEGIN
  Modified := FALSE;
  SavedFileName[0] := 0C;
  currfile := 0FFFFH;
  charsInBuffer := 0;
  Lib.Terminate(Terminator, Chain);
  ErrorProc := DefaultError;
END Ini.
