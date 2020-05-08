MODULE tstS;

FROM StdIO IMPORT
  sprintf2;

VAR
  c : CARDINAL;
  i : INTEGER;
  s : ARRAY [0.. 100] OF CHAR;
BEGIN
  c := 1200;
  i := -2;
  sprintf2( s, "%5Y/%7X", i, c );
  sprintf2( s, "%5Z/%7X", i, c );
  i :=-20;
  sprintf2( s, "%2Y/%2X", i, c );
  sprintf2( s, "%Z/%X", i, c );
  i := -200;
  sprintf2( s, "%Y/%X", i, c );
  sprintf2( s, "%Z/%X", i, c );
  i := +200;
  sprintf2( s, "%Y/%X", i, c );
  sprintf2( s, "%Z/%X", i, c );
  i := MIN( INTEGER );
  sprintf2( s, "%Y/%X", i, c );
  sprintf2( s, "%Z/%X", i, c );
  c := MAX( CARDINAL );
  sprintf2( s, "%Y/%X", i, c );
  sprintf2( s, "%Z/%X", i, c );
  c := MAX( CARDINAL );

END tstS.
