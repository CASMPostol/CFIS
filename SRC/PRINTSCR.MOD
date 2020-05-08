IMPLEMENTATION MODULE PrintScreen; (*zadne przerwania nie sa tolerowane *)


FROM SYSTEM IMPORT
  ADDRESS, ADR, WORD, BYTE, SIZE, SETREG, SWI, AX, BX, CX, DX, ES,
  OUTBYTE, INBYTE;
FROM ShortCuts IMPORT
  DefineShortCut, kbCtrlF3;
FROM FIO IMPORT
  Open, Create, Close, File, Write;
FROM MANAGER IMPORT
  Assert;
FROM CommonTypes IMPORT
  Str40;
FROM StdIO IMPORT
  sprintf;
FROM Graphics IMPORT
  GetWindow;



  TYPE
    LONGCARD         =
      LONGINT;
    SHORTCARD        =
      CHAR;
    BITMAPFILEHEADER =
      RECORD
        bfType      : CARDINAL;
        bfSize      : LONGCARD;
        bfReserved1 : CARDINAL;
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
        biClrImportant  : LONGCARD;
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


  PROCEDURE OpenF() : File;
    VAR
      s : Str40;
      i : INTEGER;
      f : File;
    BEGIN
      FOR i := 0 TO 99 DO
        sprintf(s, '\\Screen%02d.bmp', i );
        f := Open(s);
        IF f = MAX(CARDINAL) THEN
          f := Create( s );
          Assert( f # MAX(CARDINAL ));
          RETURN f;
        ELSE (* juz byl *)
          Close( f );
        END;
      END;
      HALT;
    END OpenF;

  PROCEDURE SaveToDib( adres : ADDRESS );
    VAR
      file : File;
      bfh  : BITMAPFILEHEADER;
      bi   : BITMAPINFO;
      linia : ARRAY[0..800] OF CHAR;
      i, j  : INTEGER;
    BEGIN
      file := OpenF();
      WITH bfh DO
        bfType := 4d42h;
        bfSize := VAL( LONGCARD, SIZE( bfh ))+
                  VAL( LONGCARD, SIZE( bi  ))+
                  800L*600L;
        bfReserved1 := 0;
        bfReserved2 := 0;
        bfOffBits   := VAL( LONGCARD, SIZE( bi  ))+
                       VAL( LONGCARD, SIZE( bfh  ));
      END;
      Assert( Write( file, ADR( bfh ), SIZE( bfh ) ));
      WITH bi.bmiHeader DO
        biSize := VAL( LONGCARD, SIZE( bi.bmiHeader ));
        biWidth := 800L;
        biHeight := 600L;
        biPlanes := 1;
        biBitCount := 8;
        biCompression := 0L;
        biSizeImage := 0L;
        biXPelsPerMeter := 96L;
        biYPelsPerMeter := 96L;
        biClrUsed := 0L;
        biClrImportant := 0L;
      END;
      (* paleta *)
      j := 0;
      FOR i := 0 TO 255 DO
        WITH bi.bmiColors[i] DO
          OUTBYTE( 3c8h, i+1 );
          INBYTE( 3c9h, j );
          rgbRed := CHR(j * 4);
          INBYTE( 3c9h, j );
          rgbGreen := CHR(j*4);
          INBYTE( 3c9h, j );
          rgbBlue := CHR(j * 4);
          rgbReserved := 0C;
        END;
      END;
      Assert( Write( file, ADR( bi ), SIZE( bi ) ));
      FOR i := 599 TO 0 BY -1 DO
        GetWindow( ADR( linia ), 0, i, 799, i, 0, 0L );
        Assert( Write( file, ADR( linia ), 800 ));
      END;
      Close( file );
    END SaveToDib;

  PROCEDURE Init(  );
    BEGIN
      DefineShortCut( kbCtrlF3, SaveToDib, NIL );
    END Init;

BEGIN
  Init;
END PrintScreen.


