MODULE IniTst;


FROM Ini IMPORT
  WritePrivateProfileString, GetPrivateProfileString;

FROM Terminal IMPORT
  ReadString, WriteString, WriteLn, Read;

IMPORT RTSMain;     

VAR 
   Section,Entry,What,FN,Def : ARRAY [0..40] OF CHAR;
   
   PROCEDURE Czytanie;
   VAR
      res : ARRAY [0..40] OF CHAR;
   BEGIN
     WriteLn;WriteString("Jaka sekcja : "); ReadString(Section);
     WriteLn;WriteString("Jakie miejsce : "); ReadString(Entry);
     GetPrivateProfileString( Section,Entry,Def,res,FN);
     WriteLn;WriteString("WYNIK  >>> ");WriteString(res);
   END Czytanie;
   
   PROCEDURE Pisanie;
   VAR
      txt : ARRAY [0..40] OF CHAR;
   BEGIN
     WriteLn;WriteString("Jaka sekcja : "); ReadString(Section);
     WriteLn;WriteString("Jakie miejsce : "); ReadString(Entry);
     WriteLn;WriteString("Jaki napis : "); ReadString(txt);
     WritePrivateProfileString( Section,Entry,txt,FN);
   END Pisanie;
   
   VAR
     ch : CHAR;
BEGIN
  FN := "0000000.ini";
  Section := "Sekcja";
  Entry := "Entry";
  What := "What";
  Def  := "Nie ma takiego";
  WriteLn;
  WriteString(" (P)isanie i (C)zytanie z plikow ini : ");
  WriteString(FN);WriteLn;WriteLn;
  LOOP
    WriteLn;
    WriteString("(P)isanie i (C)zytanie");
    WriteLn;
    Read(ch);
    CASE CAP(ch) OF
      "C" : Czytanie;
    | "P" : Pisanie;
    | 33C : RTSMain.Terminate( RTSMain.Stopped );
    END;    
  END;
  RTSMain.Terminate( RTSMain.Stopped );
END IniTst.
