MODULE PL_Znak;

FROM Graphics IMPORT
  WrStrXY, Wr16StrXY;
FROM GrafTypes IMPORT
  WHITE, RED, BLUE;
FROM Timer IMPORT
  Wait;
IMPORT
  HiLevGraf;
  
VAR
  ch : CHAR;
  i, j : CARDINAL;
BEGIN
  (* male     acelnoszx *)
  Wr16StrXY( "•Ü©à‰¢òæ´", 0,  0, WHITE, RED );
  (* duze     acelnoszx *)
  Wr16StrXY( "§è®ù„‡óΩç", 0, 20, WHITE, RED );
  FOR i := 0 TO 15 DO
    FOR j := 0 TO 15 DO
      ch := CHR( i*16+j );
      Wr16StrXY( ch, j*8, 50+i*16, WHITE, BLUE );
    END;
  END;
  Wait( 1000 );
END PL_Znak.
