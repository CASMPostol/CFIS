(*.F- *)
(**********************************************************************
|  Title   : Obsluga danych statycznych
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    02-26-97 09:59pm: MM
|       Poprawione 2 bledy:
|             1. Przy braku danych byla przyjmowana skala 0..Podzielnik co
|                powodowalo blad w wyswietlaniu logarytmicznym
|             2. Bledy w wyniku zlego skalowania w wyniku proby narysowania
|                pustego wykresu po wykresie "wielowykresowym"
|    03-13-97 01:25pm: MM
|          Nie zamykal plikow w przypadku, gdy plik do pokazania ma dlugosc
|          zero.
|    03-19-97 11:39am: MM
|          Poprawiony zostal blad niekasowania dodatkowych wykresow po
|          zmianie z wykresu "poczwornego" na "pojedynczy"
|    03-21-97 10:41am: MM
|          Teraz jest najpierw wykres a potem jego opis
|    09-05-96: M.Postol
|      zla skala katowa !!! podobno przed wyjazdem poprawiles - nadal nie
|      jest dobrze, bo pokazuje np. -200!!, -150, -50, 0, 50.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
(*
 *)

IMPLEMENTATION MODULE Zoom;


IMPORT
  MMMouse, Strings;
FROM XMSTable IMPORT
  XmsTable, GetElem, PutElem, Allocate, Deallocate, AssignNil, IsValid, Size;
FROM Timer IMPORT
  Wait, TInOneSecond;
FROM SYSTEM IMPORT
  ADDRESS, ADR, SIZE, WORD;
FROM MANAGER IMPORT
  STARTPROCESS;
FROM RTSMain IMPORT
  Terminate, Status;
FROM Buttons IMPORT
  Button, CreateButton, DisposeButton, EnableButton;
FROM GrafTypes IMPORT
  RECT, AssignRect, MoveRect, BLUE, LT_BLUE, WHITE;
FROM Graphics IMPORT
  InvertW;
FROM MMMouse IMPORT
  Region, RegisterRegion, UnregisterRegion, Event, EventSet, ButtonSet,
  GetRegion, GetRegionRect;
FROM HiLevGraf IMPORT
  FillRect, WrStr;
FROM ShortCuts IMPORT
  kbAltZ, kbAltM, kbAltX, kbAltO, kbAlt1, kbAlt2, kbAlt3, kbAlt4;
FROM GrafUtil IMPORT
  Info, InfoBeep;
FROM FIO IMPORT
  File, Open, Read, Close, Length;
(*
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
*)
FROM MathLib0 IMPORT
  real, entier;
FROM StdIO IMPORT
  sprintf;
FROM Wykres IMPORT
  OpisLog, PokazWykresNSLog, PokazWykresZXms;
FROM CommonTypes IMPORT
  NilValI;


CONST
  WYS_BUTTONOW = 25;
  WYS_WYKRESU = (600-16-WYS_BUTTONOW) DIV LICZBA_WYKRESOW;


(*
TYPE
  Tabl  = ARRAY[0..MAX(INTEGER)-1] OF INTEGER;
  PTabl = POINTER TO Tabl;
*)

VAR
  OpisWykresu : ARRAY Wykres OF
    RECORD
      Rect       : RECT;
(*
      y          : ARRAY[0..3] OF PTabl;
*)
      y          : ARRAY[0..3] OF XmsTable;
(**)
      Reg        : Region;
      Log        : BOOLEAN;
      Full       : BOOLEAN;
      PosMarkerY : ARRAY[0..5] OF REAL;
      NrY        : CARDINAL;
      Podzielnik : REAL;
      Opis       : ARRAY [0..29] OF CHAR;
      MinY,
      MaxY       : REAL;
    END;
(*
  x_odn          : PTabl;
  x_time         : PTabl;
*)
  x_odn          : XmsTable;
  x_time         : XmsTable;
(**)
  PosMarkerX     : ARRAY [0..9] OF REAL;
  NrX            : CARDINAL;
  PrzeskokWGore  : CARDINAL;
  PrzeskokWDol   : CARDINAL;
  podz           : REAL; (* albo 100, albo 500 *)
  xFirst         : CARDINAL;
  xLast          : CARDINAL;
  ZnacznikPrzerwy: INTEGER;
  ObslugaWylaczona: BOOLEAN;

  ZoomOutPoziom  : Button;
  ZoomOutPion    : ARRAY Wykres OF Button;
  Koniec         : Button;

  XStack         : ARRAY [0..9] OF
                     RECORD
                       left, right : INTEGER;
                     END;
  XStackDepth    : INTEGER;
  YStack         : ARRAY Wykres OF
                     ARRAY [0..9] OF
                       RECORD
                         top, bottom : REAL;
                       END;
  YStackDepth    : ARRAY Wykres OF INTEGER;


PROCEDURE Init;
  VAR
    R : RECT;
    w : Wykres;
    i : CARDINAL;
  BEGIN
    xFirst := 0;
    xLast := 1;
    AssignRect( R, 0, WYS_BUTTONOW, 799, WYS_BUTTONOW + WYS_WYKRESU -1 );
    FOR w := 0 TO LICZBA_WYKRESOW-1 DO
      WITH OpisWykresu[w] DO
        Full := FALSE;
        Rect := R;
        FillRect( R, CHR( BLUE+w ) );
        FOR i := 0 TO HIGH(y) DO
(*
          y[i] := NIL;
*)
          AssignNil( y[i] );
        END;
        RegisterRegion( EventSet{Motion, LeftDown, LeftUp, RightDown, RegionOut},
                        Rect,
                        ObslugaMyszy,
                        NIL,
                        Reg );

        MoveRect( R, 0, WYS_WYKRESU );
        MinY := 0.0;
        MaxY := 1.0;
      END;
    END;
    AssignRect( R, 0, 0, 80, WYS_BUTTONOW );
    ZoomOutPoziom := CreateButton( R, "Zoom", 1, kbAltZ, ZoomOutPoziomP );
    MoveRect( R, R.right-R.left+5, 0 );

    ZoomOutPion[0] := CreateButton( R, "Zoom(1)", 6, kbAlt1, ZoomOutPionP1 );
    MoveRect( R, R.right-R.left+5, 0 );
    ZoomOutPion[1] := CreateButton( R, "Zoom(2)", 6, kbAlt2, ZoomOutPionP2 );
    MoveRect( R, R.right-R.left+5, 0 );
    ZoomOutPion[2] := CreateButton( R, "Zoom(3)", 6, kbAlt3, ZoomOutPionP3 );
    MoveRect( R, R.right-R.left+5, 0 );
    ZoomOutPion[3] := CreateButton( R, "Zoom(4)", 6, kbAlt4, ZoomOutPionP4 );
    MoveRect( R, R.right-R.left+5, 0 );

    Koniec := CreateButton( R, "Zmien", 1, kbAltM, Run );
    Info("");
(*
    x_odn := NIL;
    x_time := NIL;
*)
    AssignNil( x_odn );
    AssignNil( x_time );
(**)
    XStackDepth := 0;
    FOR w := MIN( Wykres ) TO MAX( Wykres ) DO
      YStackDepth[w] := 0;
    END;
  END Init;

VAR
  Key[0:417H] : BITSET;

PROCEDURE KtoryWykres(  ) : Wykres;
  VAR
    R : Region;
    w : Wykres;
  BEGIN
    R := GetRegion();
    FOR w := MIN(Wykres) TO MAX(Wykres) DO
      WITH OpisWykresu[w] DO
        IF R = Reg THEN
          RETURN w;
        END;
      END;
    END;
  END KtoryWykres;

PROCEDURE ObslugaMyszy( ev    : EventSet;
                        bs    : ButtonSet;
                        x, ys : INTEGER );
  VAR
    tmp  : CARDINAL;
    tmpR : REAL;
    w : Wykres;
  BEGIN
    IF ObslugaWylaczona THEN
      RETURN;
    END;
    tmp := VAL( CARDINAL,
                    VAL( LONGINT, x ) * VAL( LONGINT, xLast-xFirst+1 ) DIV 800L
                  ) + xFirst;
    w := KtoryWykres();
    WITH OpisWykresu[w] DO
      tmpR := real( WYS_WYKRESU-ys) * (MaxY-MinY) / FLOAT( WYS_WYKRESU ) + MinY;
      IF LeftDown IN ev THEN
        IF 2 IN Key THEN
          IF PushY(w) THEN
            MaxY := tmpR;
            IF MaxY-MinY < Podzielnik THEN
              MaxY := MinY + Podzielnik;
            END;
          END;
          Redraw( w, Full );
        ELSE
          IF (tmp < xLast) & PushX() THEN
            xFirst := tmp;
          END;
          RedrawAll;
        END;
      ELSIF RightDown IN ev THEN
        IF 2 IN Key THEN
          IF PushY(w) THEN
            MinY := tmpR;
            IF MaxY-MinY < Podzielnik THEN
              MinY := MaxY - Podzielnik;
            END;
          END;
          Redraw( w, Full );
        ELSE
          IF (tmp > xFirst) & PushX() THEN
            xLast := tmp;
          END;
          RedrawAll;
        END;
      END;
    END;
  END ObslugaMyszy;

PROCEDURE RedrawAll;
  VAR
    w : Wykres;
  BEGIN
    FOR w := MIN( Wykres ) TO MAX( Wykres ) DO
      Redraw( w, OpisWykresu[w].Full );
    END;
  END RedrawAll;

PROCEDURE ZoomOutPoziomP(  );
  BEGIN
    PopX;
  END ZoomOutPoziomP;

PROCEDURE ZoomOutPionP1(  );
  BEGIN
    PopY(0);
  END ZoomOutPionP1;

PROCEDURE ZoomOutPionP2(  );
  BEGIN
    PopY(1);
  END ZoomOutPionP2;

PROCEDURE ZoomOutPionP3(  );
  BEGIN
    PopY(2);
  END ZoomOutPionP3;

PROCEDURE ZoomOutPionP4(  );
  BEGIN
    PopY(3);
  END ZoomOutPionP4;

PROCEDURE Run(  );
  VAR
    w : Wykres;
  BEGIN
    EnableButton( ZoomOutPoziom, FALSE );
    FOR w := MIN( Wykres ) TO MAX( Wykres ) DO
      EnableButton( ZoomOutPion[w], FALSE );
    END;
    EnableButton( Koniec, FALSE );
    ObslugaWylaczona := TRUE;
    STARTPROCESS( ZmienP, 1000H, 0);
  END Run;

PROCEDURE EnableAll(  );
  VAR
    w : Wykres;
  BEGIN
    EnableButton( ZoomOutPoziom, TRUE );
    FOR w := MIN( Wykres ) TO MAX( Wykres ) DO
      EnableButton( ZoomOutPion[w], TRUE );
    END;
    EnableButton( Koniec, TRUE );
    ObslugaWylaczona := FALSE;
  END EnableAll;

PROCEDURE ZmienPDefault(  );
  BEGIN

  END ZmienPDefault;

PROCEDURE Done;
  VAR
    w : Wykres;
    i : CARDINAL;
  BEGIN
    FOR w := 0 TO LICZBA_WYKRESOW-1 DO
      WITH OpisWykresu[w] DO
        UnregisterRegion( Reg );
        FOR i := 0 TO HIGH(y) DO
(*
          IF y[i] # NIL THEN
            DEALLOCATE( y[i], y[i]^[0] );
          END;
*)
          Deallocate( y[i] );
(**)
        END;
      END;
      DisposeButton( ZoomOutPion[w] );
    END;
    DisposeButton( ZoomOutPoziom );
    DisposeButton( Koniec );
(*
    IF x_odn # NIL THEN
      DEALLOCATE( x_odn, x_odn^[0] );
    END;
    IF x_time # NIL THEN
      DEALLOCATE( x_time, x_time^[0] );
    END;
*)
    Deallocate( x_odn );
    Deallocate( x_time );
(**)
  END Done;

  PROCEDURE FillData( VAR y : XmsTable );
    VAR
      i, s : CARDINAL;
    BEGIN
      s := Size( x_time );
      Deallocate( y );
      y := Allocate( s*2 );
      PutElem( y, 0, s-1  );
      FOR i := 1 TO s DO
        PutElem( y, i, NilValI );
      END;
    END FillData;

(*
PROCEDURE LoadData( VAR y        : PTabl;
                    VAR FileName : ARRAY OF CHAR ) : BOOLEAN;
*)
PROCEDURE LoadData( VAR y        : XmsTable;
                        Fill     : BOOLEAN;
                    VAR FileName : ARRAY OF CHAR ) : BOOLEAN;
  VAR
    f : File;
    s : CARDINAL;
    str : ARRAY[0..99] OF CHAR;
    a : ADDRESS;
    Buf : ARRAY[0..99] OF CARDINAL;
    LastLoaded : CARDINAL;
    IleCzytac : CARDINAL;
    i : CARDINAL;
  BEGIN
    IF FileName[0] = 0C THEN
      RETURN FALSE;
    ELSE
      f := Open( FileName );
      IF f = MAX( CARDINAL ) THEN
        a := ADR( FileName );
        sprintf( str, "Nie mo¾na otworzy† pliku <%s>", a );
        Info( str );
        IF Fill THEN
          FillData( y );
        END;
        RETURN FALSE;
      END;
    END;
(**)
    s := VAL( CARDINAL, Length( f ));
    IF s = 0 THEN
      IF Fill THEN
        FillData( y );
      END;
      Close( f );
      RETURN FALSE;
    END;
(*
    IF y # NIL THEN
      DEALLOCATE( y, y^[0] );
    END;
*)
    Deallocate( y );

    y := Allocate( s+2 );
    PutElem( y, 0, s DIV 2 );
    LastLoaded := 1;
    WHILE s > 0 DO
(*
      IF NOT Read( f, ADR( y^[1] ), s ) THEN
        Info( "Nie mo¾na czyta† z pliku" );
        DEALLOCATE( y, y^[0] );
      END;
*)
      IleCzytac := SIZE( Buf );
      IF IleCzytac > s THEN
        IleCzytac := s;
      END;
      IF NOT Read( f, ADR( Buf ), IleCzytac ) THEN
        Info( "Nie mo¾na czyta† z pliku" );
        Deallocate( y );
      END;
      DEC( s, IleCzytac );
      FOR i := 0 TO IleCzytac DIV 2 -1 DO
        PutElem( y, LastLoaded, Buf[i] );
        INC( LastLoaded );
      END;
(**)
    END;
    Close( f );
    RETURN TRUE;
  END LoadData;

PROCEDURE Assign( w          : Wykres;
                  NrWykresu  : CARDINAL;
                  FileName   : ARRAY OF CHAR;
                  opis       : ARRAY OF CHAR;
                  podzielnik : REAL;
                  log        : BOOLEAN
                );
  VAR
    y_min, y_max : INTEGER;
    i, j         : CARDINAL;
    mx, mn       : INTEGER;
    px, pn       : INTEGER;
  BEGIN
    EnableAll;
    WITH OpisWykresu[w] DO
      FOR i := NrWykresu+1 TO HIGH(y) DO
        Deallocate( y[i] ); (* zwalnia zasoby *)
      END;
      IF NrWykresu = 0 THEN
        MinY := 0.0;
        MaxY := 1.0;
      END;
      Podzielnik := podzielnik;
      Log := log;
      YStackDepth[w] := 0;
      Strings.Assign( opis, Opis );
      IF NOT LoadData( y[NrWykresu], TRUE, FileName ) THEN
        Redraw( w, Full );
        RETURN;
      END;
      y_min := INTEGER(GetElem( y[0], 1 ));
      y_max := y_min;
      mn := 1;
      mx := 1;
      px := 0;
      pn := 0;
      FOR j := 0 TO HIGH( y ) DO
        FOR i := 1 TO CARDINAL(GetElem(y[j],0 )) DO
          IF INTEGER( GetElem(y[j], i)) # MIN( INTEGER ) THEN
            IF (y_min > INTEGER( GetElem(y[j], i))) OR (y_min = MIN(INTEGER)) THEN
                y_min := INTEGER( GetElem(y[j], i));
              mn := i;
              pn := j;
            ELSIF y_max < INTEGER( GetElem(y[j], i)) THEN
              y_max := INTEGER( GetElem(y[j], i));
              mx := i;
              px := j;
            END;
          END;
        END;
      END;
      IF (y_min=0) & (y_max=0) THEN
        y_max := 1;
      END;
      MinY := real(y_min);
      MaxY := real(y_max);
      IF MinY < 0.0 THEN
        MinY := MinY*1.05;
      ELSE
        MinY := MinY*0.95;
      END;
      IF MaxY < 0.0 THEN
        MaxY := MaxY*0.95;
      ELSE
        MaxY := MaxY*1.05;
      END;
      IF MaxY-MinY < Podzielnik THEN
        MaxY := MinY + Podzielnik;
      END;
(*      Terminate( Warning );*)
      Redraw( w, Full );
      EnableAll;
    END;
  END Assign;

PROCEDURE DobierzDzialki(     Min, Max : REAL;
                          VAR a        : ARRAY OF REAL;
                          VAR a_ile    : CARDINAL );
  VAR
    Dzialka : ARRAY[0..2] OF CARDINAL;
    war, id : REAL;
    d_idx   : CARDINAL;
    i       : CARDINAL;
    sg      : REAL;
  BEGIN
    IF Min < Max THEN
      sg := 1.0;
    ELSE
      sg := -1.0;
    END;
    a_ile := 1;
    Dzialka[0] := 1;
    Dzialka[1] := 2;
    Dzialka[2] := 5;
    id := 0.1;
    d_idx := 0;
    IF ABS(Max-Min) > 1.0E-3 THEN
      WHILE ABS(Max-Min)/10.0 < id DO
        id := id / 10.0;
      END;
    END;
    war := (Max-Min) / FLOAT(HIGH( a )+1);
    WHILE (FLOAT( Dzialka[ d_idx ] ) * id < ABS(war)) DO
      IF d_idx = HIGH( Dzialka ) THEN
        id := 10.0*id;
        d_idx := 0;
      ELSE
        INC( d_idx );
      END;
    END;
    id := id*FLOAT( Dzialka[d_idx] );
    IF Min < Max THEN
      a[0] := real( entier( Min/id ))*id+id*sg;
    ELSE
      a[0] := real( entier( Min/id ))*id;
    END;
    FOR i := 1 TO HIGH(a) DO
      a[i] := a[i-1]+id*sg;
      IF (Max > Min) & (a[i] < Max) OR
         (Max < Min) & (a[i] > Max)
      THEN
        INC( a_ile );
      END;
    END;
  END DobierzDzialki;

PROCEDURE PushX( ) : BOOLEAN;
  BEGIN
    IF XStackDepth <= HIGH( XStack ) THEN
      WITH XStack[XStackDepth] DO
        left := xFirst;
        right := xLast;
      END;
      INC( XStackDepth );
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END;
  END PushX;

PROCEDURE PopX(  );
  BEGIN
    IF XStackDepth > 0 THEN
      DEC( XStackDepth );
      WITH XStack[XStackDepth] DO
        xFirst := left;
        xLast := right;
      END;
      RedrawAll;
    END;
  END PopX;

PROCEDURE PushY( w : Wykres ) : BOOLEAN;
  BEGIN
    IF YStackDepth[w] <= HIGH( YStack[w] ) THEN
      WITH YStack[w][YStackDepth[w]] DO
        top := OpisWykresu[w].MaxY;
        bottom := OpisWykresu[w].MinY;
      END;
      INC( YStackDepth[w] );
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END;
  END PushY;

PROCEDURE PopY( w : Wykres );
  BEGIN
    IF YStackDepth[w] > 0 THEN
      DEC( YStackDepth[w] );
      WITH YStack[w][YStackDepth[w]] DO
        OpisWykresu[w].MinY := bottom;
        OpisWykresu[w].MaxY := top;
      END;
      RedrawAll;
    END;
  END PopY;

PROCEDURE ZmiennaNiezalezna(     FileName    : ARRAY OF CHAR;
                                 FunkcjaKata : BOOLEAN
                           ) : BOOLEAN;
  VAR
    i, j : CARDINAL;
  BEGIN
    IF NOT LoadData( x_odn, FALSE, FileName ) THEN
      RETURN FALSE;
    END;
    IF NOT LoadData( x_time, FALSE, FileName ) THEN
      RETURN FALSE;
    END;
    IF (FunkcjaKata) THEN
      ZnacznikPrzerwy := MIN(INTEGER);
      podz := 100.0;
    ELSE
      ZnacznikPrzerwy := -1;
      podz := 500.0;
    END;
    FOR i := 1 TO CARDINAL(GetElem(x_time,0 )) DO
      PutElem( x_time, i, i );
    END;
    xFirst := 1;
    xLast  := CARDINAL( GetElem( x_odn, 0 ));
    XStackDepth := 0;
    i := xFirst;
    j := xLast;
    LOOP
      IF (i>=j) THEN
        InfoBeep( "Nie ma pomiaru wg. tego parametru", 1, 300 );
        Wait(TInOneSecond());
        RETURN FALSE;
      END;
      IF INTEGER( GetElem( x_odn, i )) = ZnacznikPrzerwy THEN
        INC(i);
      ELSIF INTEGER( GetElem( x_odn, j )) = ZnacznikPrzerwy THEN
        DEC(j);
      ELSE
        EXIT;
      END;
    END;
    PrzeskokWGore := MAX(CARDINAL); (* nie ma przeskoku *)
    PrzeskokWDol  := MAX(CARDINAL); (* nie ma przeskoku *)
    j := xFirst;
    IF FunkcjaKata THEN
      FOR i := xFirst+1 TO xLast DO
        IF INTEGER( GetElem(x_odn,i)) # ZnacznikPrzerwy THEN
          IF (INTEGER( GetElem(x_odn,j)) < -15000) &
             (INTEGER( GetElem(x_odn,i)) > +15000) THEN
            PrzeskokWGore := i;
          END;
          IF (INTEGER( GetElem(x_odn,j)) > +15000) &
                (INTEGER( GetElem(x_odn,i)) < -15000)
          THEN
            PrzeskokWDol := i;
          END;
          j := i;
        END;
      END;
    END;
    RETURN TRUE;
(*    Terminate( Warning );*)
  END ZmiennaNiezalezna;

PROCEDURE MinV(  ) : CARDINAL;
  VAR
    i : CARDINAL;
  BEGIN
    i := xFirst;
    WHILE INTEGER( GetElem( x_odn, i )) = ZnacznikPrzerwy DO
      INC(i);
    END;
    RETURN i;
  END MinV;

PROCEDURE MaxV(  ) : CARDINAL;
  VAR
    i : CARDINAL;
  BEGIN
    i := xLast;
    WHILE INTEGER( GetElem( x_odn, i )) = ZnacznikPrzerwy DO
      DEC(i);
    END;
    RETURN i;
  END MaxV;

PROCEDURE MinMax( VAR min, max : CARDINAL );
  VAR
    i : CARDINAL;
    i_e,
    p_e : WORD;
  BEGIN
    min := MinV();
    max := min;
    KierunekZmian := 0;
    p_e := WORD(0);
    FOR i := xFirst+1 TO MaxV() DO
      IF INTEGER( GetElem( x_odn, i )) # ZnacznikPrzerwy THEN
        i_e := GetElem( x_odn, i);
        IF ZnacznikPrzerwy = -1 THEN (* po odleglosci *)
          IF ABS( KierunekZmian ) < 32000 THEN
            IF CARDINAL( i_e ) < CARDINAL( p_e ) THEN
              DEC( KierunekZmian );
            ELSE
              INC( KierunekZmian );
            END;
          END;
          IF CARDINAL( i_e ) < CARDINAL( GetElem( x_odn, min)) THEN
            min := i;
          ELSIF CARDINAL( i_e ) > CARDINAL( GetElem( x_odn, max)) THEN
            max := i;
          END;
        ELSE (* po kacie *)
          IF ABS( KierunekZmian ) < 32000 THEN
            IF INTEGER( i_e ) < INTEGER( p_e ) THEN
              DEC( KierunekZmian );
            ELSE
              INC( KierunekZmian );
            END;
          END;
          IF INTEGER( i_e ) < INTEGER( GetElem( x_odn, min)) THEN
            min := i;
          ELSIF INTEGER( i_e ) > INTEGER( GetElem( x_odn, max)) THEN
            max := i;
          END;
        END;
        p_e := i_e;
      END;
    END;
  END MinMax;

PROCEDURE Redraw( w : Wykres; FullScreen : BOOLEAN );
  VAR
    curR : RECT;
    MinX,
    MaxX : REAL;
    mx,
    mn   : CARDINAL;
    i, j : CARDINAL;
  BEGIN
    MinMax( mn, mx );

(*
    i := x_odn^[mn];
    j := x_odn^[mx];
*)
    i := MinV();
    j := MaxV();

    IF ZnacznikPrzerwy = -1 THEN (* po odleglosci *)
      MinX := FLOAT(CARDINAL( GetElem( x_odn, i))) / podz;
      MaxX := FLOAT(CARDINAL( GetElem( x_odn, j))) / podz;
    ELSE
      MaxX := real(INTEGER( GetElem( x_odn, j))) / podz;
      MinX := real(INTEGER( GetElem( x_odn, i))) / podz;
    END;


    IF (i > PrzeskokWGore) # (j > ABS(PrzeskokWGore)) THEN
      IF KierunekZmian >= 0 THEN (* i.e. uporzadkowane rosnaco *)
        MaxX := MaxX+360.0;
      ELSE
        MinX := MinX+360.0;
      END;
    ELSIF (i > PrzeskokWDol) # (j > ABS(PrzeskokWDol)) THEN
      IF KierunekZmian >= 0 THEN (* i.e. uporzadkowane rosnaco *)
        MinX := MinX-360.0;
      ELSE
        MaxX := MaxX-360.0;
      END;
    END;

(*
    MaxX := real(x_odn^[mn]) / podz;
    MinX := real(x_odn^[mx]) / podz;
*)
(*
    INC( PMDLicznik );
    IF PMDLicznik = 6 THEN
      Terminate( Warning );
    END;
 *)
    IF MinX = MaxX THEN
      PosMarkerX[0] := MinX;
      NrX := 1;
    ELSE
      DobierzDzialki( MinX, MaxX, PosMarkerX, NrX );
(*
      INC( PMDLicznik );
      IF PMDLicznik = 26 THEN
        Terminate( Warning );
      END;
*)
    END;
    WITH OpisWykresu[w] DO
      Full := FullScreen;
      IF FullScreen THEN
        AssignRect( curR,
                    0, WYS_BUTTONOW,
                    799, WYS_BUTTONOW+WYS_WYKRESU*LICZBA_WYKRESOW-1 );
      ELSE
        curR := Rect;
      END;
      DobierzDzialki( MinY/Podzielnik, MaxY/Podzielnik, PosMarkerY, NrY );
      IF Log & (MinY = 0.0) THEN
        MinY := MaxY/Podzielnik/10.0;
      END;
      FillRect( curR, CHR(BLUE+w) );
      FOR i := 0 TO HIGH( y ) DO
        IF IsValid(y[i]) THEN
          PokazWykresZXms(  x_time,
                            y[i],
                            ZnacznikPrzerwy=-1,
                            xFirst,
                            xLast,
                            xFirst,
                            xLast,
(*
                            mn,
                            mx,
*)
                            curR,
                            MinY,
                            MaxY,
                            WHITE-i,
                            FALSE,
                            Log );
        END;
      END;
      OpisLog( curR,
               MinX, MaxX,
               MinY/Podzielnik, MaxY/Podzielnik,
               PosMarkerX, NrX,
               PosMarkerY, NrY,
               ZnacznikPrzerwy#-1, (* tzn. kat *)
               BLUE+w,
               LT_BLUE+w,
               FALSE,
               Log,
               FALSE );
      WrStr( Opis,
             799-Strings.Length(Opis)*8,
             curR.top+1,
             CHR(LT_BLUE+w),
             CHR( BLUE+w ) );
    END;
  END Redraw;

VAR
  KierunekZmian : INTEGER;
  PMDLicznik : CARDINAL;
BEGIN
  PMDLicznik := 0;
  ZmienP := ZmienPDefault;
END Zoom.
