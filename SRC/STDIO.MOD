(*.F- *)
(**********************************************************************
|  Title   : Konwersje sterowane napisem
|  Author  : MMorawski
|  System  : LOGITECH MODULA-2/86 
|  History :
|    06-18-97 09:34pm: MM
|     Dolozono specjalistyczne konwersje:
|         %x -> Odleglosci w 500tnych czesciach
|         %y -> Wartosci wyrazone w 10tych czesciach
|         %z -> Wartosci wyrazone w setnych czesciach
|    Rel 3.02 M.Postol
|      Uzupelnilem komentarze
|      Wprowadzilem sprawdzanie wartosc NIL
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE StdIO;

FROM SYSTEM IMPORT
  BYTE, ADR, ADDRESS, SIZE;
FROM NumberConversion IMPORT
  IntToString, NumToString, LongIntToString, CardToString;
FROM RealConversions IMPORT
  RealToString;
FROM Strings IMPORT
  Length, Assign, Insert;


TYPE
  SHORTINT = CHAR;
  SHORTCARD = CHAR;

CONST
  NAJWIEKSZA_STRUKTURA = 50;
  GWIAZDKI             = '*****';


PROCEDURE sprintf( VAR Res  : ARRAY OF CHAR;
                       Fmt  : ARRAY OF CHAR;
                   VAR data : ARRAY OF BYTE );
VAR
  buff       : ARRAY[0..255] OF CHAR;
  buff_pom   : ARRAY[0..7] OF CHAR;
  rjust      : BOOLEAN ;
  short,
  long	     : BOOLEAN;
  fwidth     : CARDINAL ;
  fsize      : CARDINAL ;
  places     : CARDINAL ;
  lr         : REAL ;
  li         : LONGINT ;
  i,j,h,l,p  : CARDINAL ;
  storechar  : BOOLEAN ;
  c          : CHAR ;
  Ok         : BOOLEAN ;
  base       : CARDINAL ;
  zera	     : BOOLEAN;
  ForceSign  : BOOLEAN;
  PossSigned : BOOLEAN;
  f          : RECORD
                 CASE BOOLEAN OF
  		   FALSE: a : ADDRESS|
  		   TRUE : p :POINTER TO
                   RECORD CASE CARDINAL OF
                            0 : si  : SHORTINT |
                            1 : i   : INTEGER |
                            2 : li  : LONGINT |
                            3 : sc  : SHORTCARD |
                            4 : c   : CARDINAL |
                            6 : r   : REAL |
                            8 : ch  : CHAR |
                            9 : a   : ADDRESS |
                           10 : b   : BOOLEAN |
                           11 : str : POINTER TO ARRAY[0..255] OF CHAR ;
                          END ;
                    END ;
                  END;
                END;

PROCEDURE GetNum (): CARDINAL;     (* leaves i and c changed *)

VAR
  n, nc: CARDINAL;

BEGIN
  n := 0 ;
  FOR nc := 0 TO 2 DO
    IF (c<'0')OR(c>'9') THEN RETURN n END ;
    n := n*10+ORD(c)-ORD('0');
    c := Fmt[i] ;
    INC(i) ;
  END ;
  RETURN n ;
END GetNum ;

PROCEDURE IntConv( Base : CARDINAL; Signed : BOOLEAN );
BEGIN
  IF long THEN
    fsize := SIZE( LONGINT );
  ELSIF short THEN
    fsize := 1;
  ELSE
    fsize := SIZE( INTEGER );
  END;
  IF long THEN
    LongIntToString( f.p^.li, buff, SIZE( buff )-1 );
  ELSE
    IF Signed THEN
      IF short THEN
        NumToString( ORD(f.p^.sc), Base, buff, SIZE( buff )-1 );
      ELSE
        NumToString( f.p^.c, Base, buff, SIZE( buff )-1 );
      END;
    ELSE
      IF short THEN
        IntToString( VAL(INTEGER, ORD(f.p^.si)-80H), buff, SIZE( buff )-1 );
      ELSE
        IntToString( f.p^.i, buff, SIZE( buff )-1 );
      END;
    END;
  END;
  StripSpaces;
END IntConv;

PROCEDURE StripSpaces;
VAR
  i, j, l : CARDINAL;
BEGIN
  l := Length( buff );
  i := 0;
  WHILE ( i < l ) & (buff[i] = ' ') DO
    INC( i );
  END;
  IF i = 0 THEN
    RETURN;
  ELSIF i = l THEN
    buff[0] := 0C;
    RETURN;
  END;
  j := 0;
  WHILE i < l DO
    buff[j] := buff[i];
    INC(i);
    INC(j);
  END;
  buff[j] := 0C;
END StripSpaces;

PROCEDURE BuildNumber(  );
  BEGIN
    StripSpaces(  );
    Insert( '.', buff, 0FFFH );
    IF buff_pom[0] = ' ' THEN
      buff_pom[0] := '0';
    END;
    Insert( buff_pom, buff, 0FFFH );
  END BuildNumber;

BEGIN
  h := HIGH(Res) ;
  l := Length(Fmt);
  Res[0] := 0C ;
  i := 0 ; j := 0 ;
  f.a := ADR( data );
  LOOP
    fsize := 0;
    IF i=l THEN EXIT END ;
    storechar := TRUE ;
    zera := FALSE;
    c := Fmt[i] ; INC(i) ;
    IF c = '\' THEN
      c := Fmt[i] ; INC(i) ;
      CASE CAP(c) OF
              'B':c:=CHR(8);
       |      'F':c:=CHR(12);
       |      'E':c:=CHR(27);
       |      'N':Res[j] := CHR(13); INC(j) ; c := CHR(10);
       |      'T':c:=CHR(9);
       |      '\':c:='\';
       | '0'..'9':DEC(i) ; c:= CHR(GetNum()) ;
      END ;
    ELSIF (c='%')AND(i<>l) THEN
      ForceSign := FALSE;
      c := Fmt[i] ; INC(i) ;
      (* pattern found *)
      rjust:=TRUE ; places:=5 ;
      storechar := FALSE ;
      IF c='-' THEN
        rjust := FALSE ; c := Fmt[i] ; INC(i) ;
      END ;
      IF c='+' THEN
        ForceSign := TRUE ; c := Fmt[i] ; INC(i) ;
      END ;
      zera := c='0';
      fwidth := GetNum() ;
      IF c='.' THEN
         c := Fmt[i] ; INC(i) ;
         places := GetNum() ;
      END;
      c := CAP(c) ;
      long := FALSE;
      short := FALSE;
      IF c = 'L' THEN
        long := TRUE;
        c := CAP( Fmt[i] );
        INC(i);
      ELSIF c = 'K' THEN
        short := TRUE;
        c := CAP( Fmt[i] );
        INC(i);
      END;
      Ok := TRUE ;
      buff[0] := 0C ;
      PossSigned := FALSE;
      CASE c OF
        'I', 'D':
            IF f.p^.i =  MIN( INTEGER ) THEN
              fsize := 2;
              buff := GWIAZDKI;
            ELSE
             IntConv( 10, FALSE );
             PossSigned := TRUE;
            END;
      | 'U': IntConv( 10, TRUE );
      | 'H': IntConv( 16, TRUE );
      | 'P':
            fsize := SIZE( ADDRESS );
            sprintf( buff, "%04x:%04x", f.p^.a );
      | 'R', 'F', 'G', 'E':
            PossSigned := TRUE;
            fsize := 8;
            IF c = 'E' THEN
              RealToString(f.p^.r,-VAL( INTEGER, places),SIZE(buff)-1,buff,Ok) ;
            ELSE
              RealToString(f.p^.r,places,SIZE(buff)-1,buff,Ok) ;
            END;
            StripSpaces(  );
      | 'S':
            Assign(f.p^.str^, buff) ;
            fsize := SIZE( ADDRESS );
      | 'C':
            buff[0] := f.p^.ch ;
            buff[1] := CHR(0) ;
            fsize := 1;
      | 'B':
            fsize := 1;
            IF f.p^.b THEN
              buff := 'TRUE'
            ELSE
              buff := 'FALSE'
            END ;
      | 'X':
            fsize := 2;
            IF f.p^.c = MAX( CARDINAL ) THEN
              buff := GWIAZDKI;
            ELSE
              CardToString( f.p^.c DIV 500, buff, SIZE( buff )-1 );
              CardToString( f.p^.c MOD 500 DIV 5, buff_pom, 2 );
              BuildNumber;
            END;
      | 'Y':
            fsize := 2;
            IF f.p^.i = MIN( INTEGER ) THEN
              buff := GWIAZDKI;
            ELSE
              IntToString( f.p^.i DIV 10, buff, SIZE( buff )-1 );
              IntToString( ABS(f.p^.i) MOD 10, buff_pom, 1 );
              BuildNumber;
              IF (f.p^.i < 0) & (f.p^.i > -10) THEN
                Insert( '-', buff, 0 );
              END;
            END;
      | 'Z':
            fsize := 2;
            IF f.p^.i = MIN( INTEGER ) THEN
              buff := GWIAZDKI;
            ELSE
              IntToString( f.p^.i DIV 100, buff, SIZE( buff )-1 );
              IntToString( ABS(f.p^.i) MOD 100, buff_pom, 2 );
              BuildNumber;
              IF (f.p^.i < 0) & (f.p^.i > -100) THEN
                Insert( '-', buff, 0 );
              END;
            END;
      ELSE
        storechar := TRUE ;
      END;
      Res[j] := CHR(0) ;
      IF NOT Ok THEN
        buff := '????'
      END ;
      p := Length(buff) ;
      IF PossSigned & ForceSign THEN
        IF buff[0] # '-' THEN
          INC( p );
          IF zera THEN
            Res[j] := '+';
            INC(j);
          END;
        END;
      END;
      IF rjust THEN
        WHILE (p < fwidth) DO
          IF zera THEN
            Res[j] := '0' ;
          ELSE
            Res[j] := ' ' ;
          END;
          INC(j) ;
          INC(p) ;
        END ;
        IF NOT zera & PossSigned & ForceSign THEN
          ForceSign := FALSE;
          IF buff[0] # '-' THEN
            Res[j] := "+";
            INC(j);
          END;
        END;
        Res[j] := CHR(0) ;
        Insert(buff, Res, 07FFFH ) ;
        j := Length(Res);
      ELSE
        Res[j] := CHR(0) ;
        IF PossSigned & ForceSign THEN
          ForceSign := FALSE;
          IF buff[0] # '-' THEN
            Res[j] := "+";
            Res[j+1] := 0C;
          END;
        END;
        Insert(buff, Res, 07FFFH ) ;
        j := Length(Res);
        WHILE (p<fwidth) DO
          Res[j] := ' ' ; INC(j) ; INC(p) ;
        END ;
      END ;
    END ;
    IF storechar THEN
       Res[j] := c ; INC(j) ;
    END ;
    IF (j>h) THEN EXIT END ;
    INC( f.a.OFFSET, fsize );
  END ;
  IF (j<=h) THEN Res[j] := CHR(0) END ;
END sprintf;


PROCEDURE sprintf4( VAR str   : ARRAY OF CHAR;
                        fmt   : ARRAY OF CHAR;
                        data1,
                        data2,
                        data3,
                        data4 : ARRAY OF BYTE );

TYPE
  Struct  = ARRAY[0..4*NAJWIEKSZA_STRUKTURA-1] OF BYTE;
  BytePtr = POINTER TO Struct;
VAR
  Tabl : Struct; (* bo najwieksza dana moze miec 8 bajtow *)
  s    : BytePtr;
  i, j : CARDINAL;
BEGIN
  s := ADR( data1 );
  j := 0;
  FOR i := 0 TO HIGH( data1 ) DO
    Tabl[j] := s^[i];
    INC(j);
  END;
  s := ADR( data2 );
  FOR i := 0 TO HIGH( data2 ) DO
    Tabl[j] := s^[i];
    INC(j);
  END;
  s := ADR( data3 );
  FOR i := 0 TO HIGH( data3 ) DO
    Tabl[j] := s^[i];
    INC(j);
  END;
  s := ADR( data4 );
  FOR i := 0 TO HIGH( data4 ) DO
    Tabl[j] := s^[i];
    INC(j);
  END;
  sprintf( str, fmt, Tabl );
END sprintf4;

PROCEDURE sprintf5( VAR str   : ARRAY OF CHAR;
                        fmt   : ARRAY OF CHAR;
                        data1,
                        data2,
                        data3,
                        data4,
                        data5 : ARRAY OF BYTE );

TYPE
  Struct  = ARRAY[0..5*NAJWIEKSZA_STRUKTURA-1] OF BYTE;
  BytePtr = POINTER TO Struct;
VAR
  Tabl : Struct; (* bo najwieksza dana moze miec 8 bajtow *)
  s    : BytePtr;
  i, j : CARDINAL;
BEGIN
  s := ADR( data1 );
  j := 0;
  FOR i := 0 TO HIGH( data1 ) DO
    Tabl[j] := s^[i];
    INC(j);
  END;
  s := ADR( data2 );
  FOR i := 0 TO HIGH( data2 ) DO
    Tabl[j] := s^[i];
    INC(j);
  END;
  s := ADR( data3 );
  FOR i := 0 TO HIGH( data3 ) DO
    Tabl[j] := s^[i];
    INC(j);
  END;
  s := ADR( data4 );
  FOR i := 0 TO HIGH( data4 ) DO
    Tabl[j] := s^[i];
    INC(j);
  END;
  s := ADR( data5 );
  FOR i := 0 TO HIGH( data5 ) DO
    Tabl[j] := s^[i];
    INC(j);
  END;
  sprintf( str, fmt, Tabl );
END sprintf5;

PROCEDURE sprintf3( VAR str   : ARRAY OF CHAR;
                        fmt   : ARRAY OF CHAR;
                        data1,
                        data2,
                        data3 : ARRAY OF BYTE );

TYPE
  Struct  = ARRAY[0..3*NAJWIEKSZA_STRUKTURA-1] OF BYTE;
  BytePtr = POINTER TO Struct;
VAR
  Tabl : Struct; (* bo najwieksza dana moze miec 8 bajtow *)
  s    : BytePtr;
  i, j : CARDINAL;
BEGIN
  s := ADR( data1 );
  j := 0;
  FOR i := 0 TO HIGH( data1 ) DO
    Tabl[j] := s^[i];
    INC(j);
  END;
  s := ADR( data2 );
  FOR i := 0 TO HIGH( data2 ) DO
    Tabl[j] := s^[i];
    INC(j);
  END;
  s := ADR( data3 );
  FOR i := 0 TO HIGH( data3 ) DO
    Tabl[j] := s^[i];
    INC(j);
  END;
  sprintf( str, fmt, Tabl );
END sprintf3;


PROCEDURE sprintf2( VAR str   : ARRAY OF CHAR;
                        fmt   : ARRAY OF CHAR;
                        data1,
                        data2 : ARRAY OF BYTE );

TYPE
  Struct  = ARRAY[0..2*NAJWIEKSZA_STRUKTURA-1] OF BYTE;
  BytePtr = POINTER TO Struct;
VAR
  Tabl : Struct; (* bo najwieksza dana moze miec 8 bajtow *)
  s    : BytePtr;
  i, j : CARDINAL;
BEGIN
  s := ADR( data1 );
  j := 0;
  FOR i := 0 TO HIGH( data1 ) DO
    Tabl[j] := s^[i];
    INC(j);
  END;
  s := ADR( data2 );
  FOR i := 0 TO HIGH( data2 ) DO
    Tabl[j] := s^[i];
    INC(j);
  END;
  sprintf( str, fmt, Tabl );
END sprintf2;


END StdIO.
