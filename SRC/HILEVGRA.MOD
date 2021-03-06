(* $R+*)
(* $S+*)
(* $T+*)
(* $O+*)
(*.F- *)
(**********************************************************************
|  Title   : Obsluga grafiki
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    16-09-96: M.Postol
|      ShowDIB - ustawia palete tylko na rozkaz
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE HiLevGraf;

  IMPORT
    XMSService, FIO;

  FROM SYSTEM IMPORT
    BYTE, ADR, SIZE, OUTBYTE;

  FROM GrafTypes IMPORT
    RECT, POINT, Intersection;

  FROM Storage IMPORT
    ALLOCATE, DEALLOCATE;

  FROM Graphics IMPORT
    SetWindow, MaxHor, MaxVer, DP, _Wr16StrXY, _WrStrXY, _Wr2StrXY, _Wr2fStrXY;

  IMPORT
    Graphics;

  FROM BlockOps IMPORT
    BlockClear;

  FROM Strings IMPORT
    Length, Insert, Assign;

  FROM MMMouse IMPORT
    HideConditionally, ShowCursor;

  FROM Semafory IMPORT
    Semafor, Init, Set, Free;

  IMPORT
    MathLib0;

  TYPE
    LONGCARD         =
      LONGINT;
    SHORTCARD        =
      CHAR;
    BITMAPFILEHEADER =
      RECORD
        bfType      : CARDINAL;
        bfSize      : LONGCARD;
        bfRexerved1 : CARDINAL;
        bfReserved2 : CARDINAL;
        bfOffBits   : LONGCARD;
      END;
    BITMAPINFOHEADER =
      RECORD
        biSize          : LONGCARD;
        biWidth         : LONGINT;
        biHeight        : LONGINT;
        biPlanes        : CARDINAL;
        biBitCount      : CARDINAL;
        biCompression   : LONGCARD;
        biSizeImage     : LONGCARD;
        biXPelsPerMeter : LONGINT;
        biYPelsPerMeter : LONGINT;
        biClrUsed       : LONGCARD;
        biClrIportant   : LONGCARD;
      END;
    RGBQUAD          =
      RECORD
        rgbBlue     : SHORTCARD;
        rgbGreen    : SHORTCARD;
        rgbRed      : SHORTCARD;
        rgbReserved : SHORTCARD;
      END;
    RGBQUAD_TABLE    =
      ARRAY [ 0 .. 255 ] OF RGBQUAD;
    BITMAPINFO       =
      RECORD
        bmiHeader : BITMAPINFOHEADER;
        bmiColors : RGBQUAD_TABLE;
      END;

  TYPE
    HDIB    =
      POINTER TO DIBDesc;
    DIBDesc =
      RECORD
        Width, Height     : INTEGER;
        LiniNaBank, Bankow     : CARDINAL;
        handle     : XMSService.XMS_Handle;
      (* prev : CARDINAL;*)
        rgbq       : RGBQUAD_TABLE;
      END;

  VAR
    ClipRect     : RECT;
    Style        : BITSET;
    LastPosition : CARDINAL;
    semafor      : Semafor;
    Path         : ARRAY [ 0 .. 64 ] OF CHAR;



  PROCEDURE Max
            (    a,
                 b : INTEGER ) : INTEGER;

  BEGIN
    IF a > b
    THEN
      RETURN a;
    ELSE
      RETURN b;
    END (* if a *);
  END Max;


  PROCEDURE Min
            (    a,
                 b : INTEGER ) : INTEGER;

  BEGIN
    IF a < b
    THEN
      RETURN a;
    ELSE
      RETURN b;
    END (* if a *);
  END Min;


  PROCEDURE StdPalette;

  CONST
    AVERAGE  = 37C;
    LAVERAGE = 17C;
    FULL     = 77C;

  VAR
    i   : CARDINAL;
    rgb : ARRAY [ 0 .. 15 ] OF RECORD
                                 r, g, b : CHAR;
                               END;

  BEGIN
    BlockClear( ADR( rgb ), SIZE( rgb ) );
    rgb[1].b := AVERAGE;
    rgb[2].g := AVERAGE;
    rgb[3].r := AVERAGE;
    rgb[4].b := AVERAGE;
    rgb[4].g := AVERAGE;
    rgb[5].b := AVERAGE;
    rgb[5].r := AVERAGE;
    (* rgb[6].g := AVERAGE; rgb[6].r := AVERAGE; *)
    rgb[6].b := CHR( 11 );
    rgb[6].g := CHR( 21 );
    rgb[6].r := CHR( 32 );
    rgb[7].b := LAVERAGE;
    rgb[7].g := LAVERAGE;
    rgb[7].r := LAVERAGE;
    rgb[8].b := AVERAGE;
    rgb[8].g := AVERAGE;
    rgb[8].r := AVERAGE;
    rgb[9].b := FULL;
    rgb[10].g := FULL;
    rgb[11].r := FULL;
    rgb[12].b := FULL;
    rgb[12].g := FULL;
    rgb[13].b := FULL;
    rgb[13].r := FULL;
    rgb[14].g := FULL;
    rgb[14].r := FULL;
    rgb[15].b := FULL;
    rgb[15].g := FULL;
    rgb[15].r := FULL;
    FOR i := 0 TO 15 DO
      OUTBYTE( 3c8h, i + 256 - 16 );
      OUTBYTE( 3c9h, ORD( rgb[i].r ) );
      OUTBYTE( 3c9h, ORD( rgb[i].g ) );
      OUTBYTE( 3c9h, ORD( rgb[i].b ) );
    END (* for i *);
  END StdPalette;


  PROCEDURE SetPaletteEntry
            (    dib   : HDIB;
                 Entry : CARDINAL;
                 r,
                 g,
                 b     : CARDINAL );

  BEGIN
    IF dib # NIL
    THEN
      WITH dib^.rgbq[Entry] DO
        rgbGreen := CHR( g );
        rgbBlue := CHR( b );
        rgbRed := CHR( r );
      END (* with dib *);
    END (* if dib *);
    OUTBYTE( 3c8h, Entry );
    OUTBYTE( 3c9h, r DIV 4 );
    OUTBYTE( 3c9h, g DIV 4 );
    OUTBYTE( 3c9h, b DIV 4 );
  END SetPaletteEntry;


  PROCEDURE SetPalette
            (    hdib : HDIB );

  VAR
    i : CARDINAL;

  BEGIN
    WITH hdib^ DO
      FOR i := 0 TO 256 - 16 DO
        OUTBYTE( 3c8h, i );
        OUTBYTE( 3c9h, ORD( rgbq[i].rgbRed ) DIV 4 );
        OUTBYTE( 3c9h, ORD( rgbq[i].rgbGreen ) DIV 4 );
        OUTBYTE( 3c9h, ORD( rgbq[i].rgbBlue ) DIV 4 );
      END (* for i *);
    END (* with hdib *);
    StdPalette;
  END SetPalette;


  PROCEDURE LoadDIB
            (    FName : ARRAY OF CHAR ) : HDIB;

  VAR
    F            : FIO.File;
    bfh          : BITMAPFILEHEADER;
    bi           : BITMAPINFO;
    dib          : HDIB;
    y            : CARDINAL;
    dlini        : CARDINAL;
    dummy        : LONGINT;
    BuforNaLinie : ARRAY [ 0 .. 799 ] OF CHAR;
    from,
    to           : XMSService.ExtMemPtr;


    PROCEDURE OpenF();

    VAR
      c : ARRAY [ 0 .. 80 ] OF CHAR;

    BEGIN
      F := FIO.Open( FName );
      IF F # 0FFFFH
      THEN
        RETURN;
      END (* if F *);
      Assign( Path, c );
      Insert( 'dib\', c, 0FFFH );
      Insert( FName, c, 0FFFH );
      F := FIO.Open( c );
    END OpenF;

  BEGIN
    OpenF;
    IF F = 0FFFFH
    THEN
      RETURN NIL;
    END (* if F *);
    IF NOT FIO.Read( F, ADR( bfh ), SIZE( bfh ) )
    THEN
      FIO.Close( F );
      RETURN NIL;
    END (* if *);
    IF ( bfh.bfType # 4d42h )
    THEN
      FIO.Close( F );
      RETURN NIL;
    END (* if *);
    IF NOT FIO.Read( F, ADR( bi ), SIZE( bi ) )
    THEN
      FIO.Close( F );
      RETURN NIL;
    END (* if *);
    IF ( bi.bmiHeader.biCompression # VAL( LONGINT, 0 ) ) OR
       ( bi.bmiHeader.biBitCount # 8 )
    THEN
      FIO.Close( F );
      RETURN NIL;
    END (* if *);
    NEW( dib );
    (* EmsPtr.SEGMENT := EMS.GetFrameSegment();*)
    WITH dib^ DO
      Width := VAL( CARDINAL, bi.bmiHeader.biWidth );
      Height := VAL( CARDINAL, bi.bmiHeader.biHeight );
      handle := XMSService.Allocate( bi.bmiHeader.biWidth *
                                     bi.bmiHeader.biHeight );
      dlini := ( Width + 3 ) DIV 4 * 4;
      FOR y := Height - 1 TO 0 BY -1 DO
        dummy := FIO.Seek( F, bfh.bfOffBits + VAL( LONGINT, dlini ) * VAL(
                           LONGINT, ORD( Height ) - 1 - y ), FIO.sBegin );
        IF NOT FIO.Read( F, ADR( BuforNaLinie ), Min( Width, 800 ) )
        THEN
          XMSService.Deallocate( handle );
          DISPOSE( dib );
          RETURN NIL;
        END (* if *);
        from.RealPtr := ADR( BuforNaLinie );
        to.ProtectedPtr := VAL( LONGINT, y ) * VAL( LONGINT, Width );
        XMSService.Copy( 0, from, handle, to, Width );
      END (* for y *);
      rgbq := bi.bmiColors;
    END (* with dib *);
    SetPalette( dib );
    FIO.Close( F );
    RETURN dib;
  END LoadDIB;


  PROCEDURE DIBWidth
            (    dib : HDIB ) : INTEGER;

  BEGIN
    IF dib # NIL
    THEN
      RETURN dib^.Width;
    ELSE
      RETURN 0;
    END (* if dib *);
  END DIBWidth;


  PROCEDURE DIBHeight
            (    dib : HDIB ) : INTEGER;

  BEGIN
    IF dib # NIL
    THEN
      RETURN dib^.Height;
    ELSE
      RETURN 0;
    END (* if dib *);
  END DIBHeight;


  PROCEDURE Swap
            ( VAR a,
                  b : INTEGER );

  VAR
    t : INTEGER;

  BEGIN
    t := a;
    a := b;
    b := t;
  END Swap;


  PROCEDURE Norm
            ( VAR r : RECT );

  BEGIN
    IF r.left > r.right
    THEN
      Swap( r.left, r.right );
    END (* if r.left *);
    IF r.top > r.bottom
    THEN
      Swap( r.top, r.bottom );
    END (* if r.top *);
  END Norm;


  PROCEDURE ShowDIB
            (    dib         : HDIB;
                 Src         : RECT;
                 Dest        : POINT;
                 UstawPalete : BOOLEAN );

  VAR
    y,
    posy,
    w,
    start,
    stop,
    aux       : INTEGER;
    ir        : RECT;
    h         : BOOLEAN;

  BEGIN
    IF dib = NIL
    THEN
      RETURN;
    END (* if dib *);
    Norm( Src );
    WITH dib^ DO
      IF Src.bottom >= Height
      THEN
        Src.bottom := Height - 1;
      END (* if Src.bottom *);
      IF Src.right >= Width
      THEN
        Src.right := Width - 1;
      END (* if Src.right *);
      w := Src.right - Src.left + 1;
      ir.left := Dest.x;
      ir.top := Dest.y;
      ir.right := ir.left + w - 1;
      ir.bottom := ir.top + Src.bottom - Src.top;
      IF NOT Intersection( ir, ir, ClipRect )
      THEN
        RETURN;
      END (* if *);
      h := HideConditionally( ir );
      FOR y := Src.top TO Src.bottom DO
        posy := Dest.y + y - Src.top;
        IF posy > ClipRect.bottom
        THEN
          IF h
          THEN
            ShowCursor;
          END (* if h *);
          RETURN;   (* bo nic wiecej nie mozna narysowac *)
        END (* if posy *);
        start := Src.left;
        stop := Src.right;
        IF posy >= ClipRect.top
        THEN
          IF Dest.x < ClipRect.left
          THEN
            IF Dest.x + w < ClipRect.left
            THEN
              HALT;   (* bo tu nigdy nie powinien wejsc *)
            END (* if Dest.x *);
            INC( start, ClipRect.left - Dest.x );
            IF Dest.x + w > ClipRect.right
            THEN
              stop := start + ClipRect.right - ClipRect.left + 1;
            END (* if Dest.x *);
          ELSIF Dest.x > ClipRect.right
          THEN
            RETURN;   (* bo nic wiecej nie mozna narysowac *)
          ELSIF Dest.x + w > ClipRect.right
          THEN
            DEC( stop, Dest.x + w - ClipRect.right );
          ELSE
          (* miesci sie w calosci *)
          END (* if Dest.x *);
          IF start <= stop
          THEN
            aux := Max( Dest.x, ClipRect.left );
            SetWindow( NIL, aux, posy, aux + stop + 1 - start, posy, handle,
                       VAL( LONGINT, y ) * VAL( LONGINT, Width ) + VAL( LONGINT
                                                                        , start
                       ) );
          END (* if start *);
        ELSE
        (* nic *)
        END (* if posy *);
      END (* for y *);
      IF h
      THEN
        ShowCursor;
      END (* if h *);
    END (* with dib *);
    IF UstawPalete
    THEN
      SetPalette( dib );
    END (* if UstawPalete *);
  END ShowDIB;


  PROCEDURE CloseDIB
            ( VAR dib : HDIB );

  BEGIN
    IF dib # NIL
    THEN
      XMSService.Deallocate( dib^.handle );
      DISPOSE( dib );
    END (* if dib *);
  END CloseDIB;


  PROCEDURE SetLineStyle
            (    b : BITSET );

  BEGIN
    Style := b;
  END SetLineStyle;


  PROCEDURE Line
            (    x1,
                 y1,
                 x2,
                 y2    : INTEGER;
                 Color : BYTE    );

  BEGIN
    LineS( x1, y1, x2, y2, Color, Style );
  END Line;


  PROCEDURE LineS
            (    x1,
                 y1,
                 x2,
                 y2    : INTEGER;
                 Color : BYTE;
                 Style : BITSET  );

  VAR
    X,
    Y,
    XStep,
    YStep,
    Direction : INTEGER;
    DeltaX,
    DeltaY    : CARDINAL;

  BEGIN
    Set( semafor );
    X := x1;
    Y := y1;
    XStep := 1;
    YStep := 1;
    IF x1 > x2
    THEN
      XStep := -1
    END (* if x1 *);
    IF y1 > y2
    THEN
      YStep := -1
    END (* if y1 *);
    DeltaX := ABS( INTEGER( x2 ) - INTEGER( x1 ) );
    DeltaY := ABS( INTEGER( y2 ) - INTEGER( y1 ) );
    IF DeltaX = 0
    THEN
      Direction := ( -1 )
    ELSE
      Direction := 0
    END (* if DeltaX *);
    WHILE NOT ( ( X = INTEGER( x2 ) ) AND ( Y = INTEGER( y2 ) ) ) DO
      IF LastPosition IN Style
      THEN
        Point( X, Y, Color );
      END (* if LastPosition *);
      LastPosition := ( LastPosition + 1 ) MOD 16;
      IF Direction < 0
      THEN
        INC( Y, YStep );
        INC( Direction, DeltaX );
      ELSE
        INC( X, XStep );
        DEC( Direction, DeltaY );
      END (* if Direction *);
    END (* while *);
    Free( semafor );
  END LineS;


  PROCEDURE Circle
            (    x,
                 y,
                 r     : INTEGER;
                 Color : BYTE    );

  VAR
    dx,
    dy,
    lx,
    ly : INTEGER;

  BEGIN
    lx := 0;
    ly := r;
    FOR dx := 1 TO r DO
      IF r < 128
      THEN
        dy := TRUNC( MathLib0.sqrt( FLOAT( r * r - dx * dx ) ) );
      ELSE
        dy := TRUNC( MathLib0.sqrt( FLOAT( r ) * FLOAT( r ) - FLOAT( dx ) *
                                    FLOAT( dx ) ) );
      END (* if r *);
      Line( x + lx, y + ly, x + dx, y + dy, Color );
      Line( x + lx, y - ly, x + dx, y - dy, Color );
      Line( x - lx, y - ly, x - dx, y - dy, Color );
      Line( x - lx, y + ly, x - dx, y + dy, Color );
      lx := dx;
      ly := dy;
    END (* for dx *);
  END Circle;


  PROCEDURE FillRect
            (    r     : RECT;
                 Color : BYTE );

  VAR
    h : BOOLEAN;

  BEGIN
    Set( semafor );
    Norm( r );
    IF Intersection( r, r, ClipRect )
    THEN
      h := HideConditionally( r );
      Graphics.FillRect( r.left, r.top, r.right, r.bottom, Color );
      IF h
      THEN
        ShowCursor;
      END (* if h *);
    END (* if Intersection *);
    Free( semafor );
  END FillRect;


  PROCEDURE Clip
            ( VAR c : RECT );

  BEGIN
    Set( semafor );
    Norm( c );
    ClipRect := c;
    IF ClipRect.left < 0
    THEN
      ClipRect.left := 0;
    END (* if ClipRect.left *);
    IF ClipRect.right >= VAL( INTEGER, MaxHor( ) )
    THEN
      ClipRect.right := MaxHor( ) - 1;
    END (* if ClipRect.right *);
    IF ClipRect.top < 0
    THEN
      ClipRect.top := 0;
    END (* if ClipRect.top *);
    IF ClipRect.bottom >= VAL( INTEGER, MaxVer( ) )
    THEN
      ClipRect.bottom := MaxVer( ) - 1;
    END (* if ClipRect.bottom *);
  END Clip;


  PROCEDURE NoClip;

  BEGIN
    ClipRect.left := 0;
    ClipRect.top := 0;
    ClipRect.right := MaxHor( ) - 1;
    ClipRect.bottom := MaxVer( ) - 1;
    Free( semafor );
  END NoClip;


  PROCEDURE GetClip
            ( VAR r : RECT );

  BEGIN
    r := ClipRect;
  END GetClip;


  PROCEDURE Point
            (    x,
                 y   : INTEGER;
                 col : BYTE    );

  VAR
    h : BOOLEAN;
    r : RECT;

  BEGIN
    Set( semafor );
    IF ( x >= ClipRect.left ) & ( x <= ClipRect.right ) & ( y >= ClipRect.top )
       & ( y <= ClipRect.bottom )
    THEN
      r.left := x;
      r.right := x;
      r.top := y;
      r.bottom := y;
      h := HideConditionally( r );
      DP( x, y, col );
      IF h
      THEN
        ShowCursor;
      END (* if h *);
    END (* if *);
    Free( semafor );
  END Point;

  VAR
    XS,
    YS : INTEGER;


  PROCEDURE MoveTo
            (    x,
                 y : INTEGER );

  BEGIN
    XS := x;
    YS := y;
  END MoveTo;


  PROCEDURE LineTo
            (    x,
                 y     : INTEGER;
                 Color : BYTE    );

  BEGIN
    Line( XS, YS, x, y, Color );
    MoveTo( x, y );
  END LineTo;


  PROCEDURE FrameRect
            (    r     : RECT;
                 Color : BYTE );

  BEGIN
    Line( r.left, r.top, r.right, r.top, Color );
    Line( r.right, r.top, r.right, r.bottom, Color );
    Line( r.right, r.bottom, r.left, r.bottom, Color );
    Line( r.left, r.bottom, r.left, r.top, Color );
  END FrameRect;


  PROCEDURE WrStr
            (    s    : ARRAY OF CHAR;
                 x,
                 y    : INTEGER;
                 fore,
                 back : BYTE          );

  VAR
    h : BOOLEAN;
    R : RECT;

  BEGIN
    R.left := x;
    R.top := y;
    R.right := R.left + VAL( INTEGER, Length( s ) ) * 8;
    R.bottom := R.top + 16;
    h := HideConditionally( R );
    _Wr16StrXY( s, x, y, fore, back );
    IF h
    THEN
      ShowCursor;
    END (* if h *);
  END WrStr;

  PROCEDURE WrStrXY
            (    s    : ARRAY OF CHAR;
                 x,
                 y    : INTEGER;
                 fore,
                 back : BYTE          );

  VAR
    h : BOOLEAN;
    R : RECT;

  BEGIN
    R.left := x;
    R.top := y;
    R.right := R.left + VAL( INTEGER, Length( s ) ) * 8;
    R.bottom := R.top + 16-7;
    h := HideConditionally( R );
    _WrStrXY( s, x, y, fore, back );
    IF h
    THEN
      ShowCursor;
    END (* if h *);
  END WrStrXY;

  PROCEDURE Wr2StrXY(  str : ARRAY OF CHAR;
                       x,y : INTEGER;
                       fore,
                       back : BYTE);
  VAR
    h : BOOLEAN;
    R : RECT;
  BEGIN
    R.left := x;
    R.top := y;
    R.right := R.left + VAL( INTEGER, Length( str ) ) * 16;
    R.bottom := R.top + (16-7)*2;
    h := HideConditionally( R );
    _Wr2StrXY( str, x, y, fore, back );
    IF h
    THEN
      ShowCursor;
    END (* if h *);
  END Wr2StrXY;

  PROCEDURE Wr2fStrXY( str : ARRAY OF CHAR;
                       x,y : INTEGER;
                       fore,
                       back : BYTE);
  VAR
    h : BOOLEAN;
    R : RECT;
  BEGIN
    R.left := x;
    R.top := y;
    R.right := R.left + VAL( INTEGER, Length( str ) ) * 16;
    R.bottom := R.top + 32;
    h := HideConditionally( R );
    _Wr2fStrXY( str, x, y, fore, back );
    IF h
    THEN
      ShowCursor;
    END (* if h *);
  END Wr2fStrXY;


  PROCEDURE GetDir();

  BEGIN
    FIO.GetDir( Path );
    IF Path[Length( Path ) - 1] # '\'
    THEN
      Insert( '\', Path, 0FFFH );
    END (* if Path *);
  END GetDir;

BEGIN
  GetDir;
  Init( semafor );
  Set( semafor );   (* bo NoClip zwalnia semafor *)
  NoClip;
  LastPosition := 0;
  SetLineStyle( { 0 .. 15 } );
  StdPalette;
END HiLevGraf.
