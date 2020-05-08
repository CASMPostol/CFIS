(* 23-06-00: MPostol - zmienilem ramke *)
IMPLEMENTATION MODULE Teo_Nadawanie;

FROM rs1 IMPORT
  pt, Init, Install, Send, TxCount;
FROM stdio IMPORT
  sprintf;
IMPORT
  Str;

PROCEDURE TSend( Azimuth, Elevation : LONGREAL; Event, Flaga : BOOLEAN );
VAR
  string : ARRAY[0..50] OF CHAR;
  e, f   : CHAR;
BEGIN
(*
  IF Azimuth < 0.0 THEN
    Azimuth := Azimuth + 360.0;
  ELSIF Azimuth >= 360.0 THEN
    Azimuth := Azimuth - 360.0;
  END;
*)
  IF TxCount() # 0 THEN
    RETURN;
  END;
  IF Elevation < 0.0 THEN
    RETURN;
  END;
  IF Event THEN
    e := 'X';
  ELSE
    e := '0';
  END;
  IF NOT Flaga THEN
    f := 'S';
  ELSE
(*    f := 'X';*)
    f := 'T';
  END;
(*
  sprintf( string,
(*         "A%05ldE%05ld%c%cS00"+15C+12C,*)
           "A%05ldE%05ld%c%c00"+15C+12C,
           LONGCARD( Azimuth * 100.0 ),
           LONGCARD( Elevation * 100.0 ),
           e, f);
*)
  sprintf( string,
(*         "A%05.0lfE%05.0lf%c%cS00"+15C+12C,*)
           "A%05.0lfE%05.0lf%c%c00"+15C+12C,
           Azimuth *100.0,
           Elevation * 100.0,
           e, f);

  Send( string, Str.Length( string) );
END TSend;

BEGIN
  Install( 1 );
  Init( 1200, 8, None, FALSE, FALSE );
END Teo_Nadawanie.