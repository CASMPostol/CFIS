
MODULE Menutst;

  IMPORT
    DebugPMD;

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
    w,
    i     : CARDINAL;
    first,
    last  : CARDINAL;
    str   : ARRAY [ 0 .. 6 ] OF CHAR;
    ACC   : ARRAY [ 0 .. 0 ] OF CARDINAL;
    mstr  : ARRAY [ 0 .. 6 ] OF ARRAY [ 0 .. 400 ] OF CHAR;

BEGIN
  mstr[0] := "aaaa0|bbb0";
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
  w := 10;
  cmd := 1;
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
          ELSE
        ELSE   (* ch="P" THEN w dol *)
          IF i = 7
          THEN
            EXIT
          ELSIF ShowMenu( 10 * i + 2, 3, mstr[i], ACC, cmd, w )
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
END Menutst.
