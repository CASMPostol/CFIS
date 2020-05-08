MODULE GLT;

FROM GList IMPORT
  TworzListe, UsunListe, DodajDoListy, Wybor, Idx2Str, HLIST;
FROM RTSMain IMPORT
  Terminate, Status;
FROM Terminal IMPORT
  Read;
FROM GrafTypes IMPORT
  RECT, WHITE, BLUE;
FROM Graphics IMPORT
   Wr16StrXY;

VAR
  h : HLIST;
  r : RECT;
  idx : CARDINAL;
  s   : ARRAY[0..99] OF CHAR;
BEGIN
  r.left := 100;
  r.right := 400;
  r.top := 100;
  r.bottom := 200;
  h := TworzListe( r );
  DodajDoListy( h, "qerhgterh0" );
  DodajDoListy( h, "qerhgterh1" );
  DodajDoListy( h, "qerhgterh2" );
  DodajDoListy( h, "qerhgterh3" );
  DodajDoListy( h, "qerhgterh4" );
  DodajDoListy( h, "qerhgterh5" );
  DodajDoListy( h, "qerhgterh6" );
  DodajDoListy( h, "qerhgterh7" );
  DodajDoListy( h, "qerhgterh8" );
  DodajDoListy( h, "qerhgterh9" );
  DodajDoListy( h, "qerhgterhA" );
  DodajDoListy( h, "qerhgterhB" );
  DodajDoListy( h, "qerhgterhC" );
  DodajDoListy( h, "qerhgterhD" );
  DodajDoListy( h, "qerhgterhE" );
  LOOP
    idx := Wybor( h );
    Idx2Str( h, idx, s );
    Wr16StrXY( s, 0, 0, WHITE, BLUE );
    Read( s[0] );
  END;
  UsunListe( h );
  Terminate( Stopped );
END GLT.
