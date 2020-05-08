MODULE TB; (* test butonow *)


  FROM MANAGER IMPORT
    Condition, WAITC, Notify, InitC;
  FROM Buttons IMPORT
    Button, CreateButton, DisposeButton;
  FROM GrafTypes IMPORT
    RECT, AssignRect, MoveRect;
  FROM NumberConversion IMPORT
    CardToString;
  FROM ShortCuts IMPORT
    kbAlt1;


CONST
  L_B = 5;

VAR
  Bts : ARRAY[0..L_B-1] OF Button;
  Redrawed : Condition;
  i : CARDINAL;
  str : ARRAY [0..100] OF CHAR;
  R   : RECT;



  PROCEDURE Redraw(  );
    BEGIN
      Notify( Redrawed );
    END Redraw;

BEGIN
  InitC( Redrawed );
  LOOP
    AssignRect( R, 350, 10, 450, 40 );
    FOR i := 0 TO L_B-1 DO
      CardToString( i, str, 1 );
      Bts[i] := CreateButton( R, str, 1, kbAlt1+i, Redraw );
      MoveRect( R, 0, 50 );
    END;
    WAITC( Redrawed );
    FOR i := 0 TO L_B-1 DO
      DisposeButton( Bts[i] );
    END;
  END;
END TB.
