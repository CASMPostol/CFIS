
MODULE Viewer;

  IMPORT
    DebugPMD;

  FROM HiLevGraf IMPORT
  LoadDIB, CloseDIB, ShowDIB, DIBWidth, DIBHeight, RECT, POINT, HDIB, Point,
  Line;
  
  FROM GMenu IMPORT
    ShowMenu;

  FROM SYSTEM IMPORT
    GETREG, SETREG, ADDRESS, CODE, AX, BX, ES, BP, WORD;

  FROM NumberConversion IMPORT
    NumToString;

  FROM Terminal IMPORT
    Read;

  FROM Graphics IMPORT
    InvertW, WrStrXY;

  FROM RTSMain IMPORT
    Terminate, Status;

  VAR
    ok    : BOOLEAN;
    ch    : CHAR;
    x,
    y,
    cmd,
    menuWith,
    i     : CARDINAL;
    first,
    last  : CARDINAL;
    str   : ARRAY [ 0 .. 6 ] OF CHAR;
    ACC   : ARRAY [ 0 .. 0 ] OF CARDINAL;
    mstr  : ARRAY [ 0 .. 6 ] OF ARRAY [ 0 .. 400 ] OF CHAR;
    picture1 : HDIB;
    picture2 : HDIB;
  r : RECT;
  p : POINT;
  c : CHAR;
    
    PROCEDURE ShowPDMenu;
    VAR
      i: CARDINAL;
    BEGIN
  FOR i := 0 TO 7 DO
    IF i = 7
    THEN
      WrStrXY( "KONIEC", ( 10 * i + 1 ) * 8, 16, 11 );
    ELSE
      WrStrXY( "MENU", ( 10 * i + 2 ) * 8, 16, 11 );
      ch := CHR( i + 31H );
      WrStrXY( ch, ( 10 * i + 6 ) * 8, 16, 11 );
    END (* if i *);
  END (* for i *);
      
    END ShowPDMenu;
    
BEGIN
  picture1 := LoadDIB( 'pl_cas.bmp' );
  r.left := 0;
  r.top := 0;
  r.right := DIBWidth(picture1  );
  r.bottom := DIBHeight( picture1 );
  p.x := x;
  p.y := x;
  ShowDIB( picture, r, p );
  mstr[0] := "StronaTytul|VORPomiar";
  mstr[1] :=
  "aTya1|bTyb1|ckjccc1(c1111|c2222|c3333|c4444(ddddd|eeeee|fffff))|kkgggg";
  mstr[2] :=
  "aaaa2|bbbb2|cccccc2(c1111|c2222|c3333|c4444(ddddd|eeeee|fffff))|kkgggg";
  mstr[3] :=
  "aaaa3|Tybb3|ccKJcc3(c1111|c2222|c3333|c4444(ddddd|eeeee|fffff))|gggggg";
  mstr[4] := "akya0|kkyy";
  mstr[5] := "aaaa0|bbb0";
  mstr[6] := "aaaa0|bbb0";
  x := 10;
  y := 5;
  ch := '?';
  menuWith := 10;
  cmd := 1;
  i := 0;
  InvertW( 80 * i, 15, ( 7 + 10 * i ) * 8, 15 + 17 );
  LOOP
    Read( ch );
    IF ( ch = 0C ) OR ( ch = 36C )
    THEN
      IF ch = 0C
      THEN
        Read( ch );
      END (* if ch *);
      IF ( ch = "K" ) OR ( ch = "M" ) OR ( ch = "H" ) OR ( ch = "P" ) OR
         ( ch = 36C )
      THEN
        IF ( ch = "K" ) OR ( ch = "M" )
        THEN
          InvertW( 80 * i, 15, ( 7 + 10 * i ) * 8, 15 + 17 );
          IF ch = "K"
          THEN   (* w lewo *)
            IF i = 0
            THEN
              i := 7;
            ELSE
              DEC( i );
            END (* if i *);
          ELSE   (* ch="M" THEN w prawo *)
            INC( i );
            IF i > 7
            THEN
              i := 0;
            END (* if i *);
          END (* if ch *);
          InvertW( 80 * i, 15, ( 7 + 10 * i ) * 8, 15 + 17 );
        ELSIF ch = "H"
        THEN   (* w gore *)
          ;
        ELSE   (* ch="P" THEN w dol *)
          IF i = 7
          THEN
            EXIT
          ELSIF ShowMenu( 10 * i + 2, 3, mstr[i], ACC, cmd, menuWith )
          THEN
          (* GoToXY(30,20); WriteString("W menu nr: "); Write(CHR(i+31H));
             WriteString(" opcja "); NumToString(cmd,8,str,4);
             WriteString(str); last := 2; FOR first:=0 TO 60000 DO FOR last:=0
             TO 20 DO END; END; GoToXY(30,20); FOR first:=0 TO 40 DO Write('
             '); END; *)
          END (* if i *);
        END (* if *);
      END (* if *);
    END (* if *);
  END (* loop *);
  Terminate( Stopped );
END Viewer.
