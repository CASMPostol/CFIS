MODULE TstINI;

FROM Ini IMPORT
  GetPrivateProfileString, WritePrivateProfileString, DeleteSection;

VAR
  s : ARRAY[0..100] OF CHAR;
BEGIN
  WritePrivateProfileString( "S1", "E1", "Ala i As", "t1.ini" );
  WritePrivateProfileString( "S1", "E 2", "Ola", "t1.ini" );
  WritePrivateProfileString( "S 2", "E1", "Ala", "t1.ini" );
  WritePrivateProfileString( "S2", "E2", "Ola", "t1.ini" );

  GetPrivateProfileString( "S2", "E2", "@", s, "t1.ini" );
  GetPrivateProfileString( "S2", "E1", "@", s, "t1.ini" );

(*  DeleteSection( "S1", "t1.ini" );*)


END TstINI.
