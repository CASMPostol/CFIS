IMPLEMENTATION MODULE DB_utl;

IMPORT
  Str;

PROCEDURE UtnijSpacje( VAR s : ARRAY OF CHAR );
VAR
  i : CARDINAL;
BEGIN
  WHILE s[0] = ' ' DO
    Str.Delete( s, 0, 1 );
  END;
  i  := Str.Length( s );
  LOOP
    IF i = 0 THEN
      EXIT;
    END;
    DEC( i );
    IF s[i] = ' ' THEN
      s[i] := 0C;
    END;
  END;
END UtnijSpacje;

PROCEDURE CompareBezSpacji( s1, s2 : ARRAY OF CHAR ) : INTEGER;
BEGIN
  UtnijSpacje( s1 );
  UtnijSpacje( s2 );
  RETURN Str.Compare( s1, s2 );
END CompareBezSpacji;

END DB_utl.
