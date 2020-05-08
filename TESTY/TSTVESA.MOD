MODULE VESA;
FROM SYSTEM IMPORT Registers;
IMPORT Lib, IO;

TYPE
    set8 = SET OF [0..7];
VAR
   r   : Registers;
   nfo : RECORD
            present : SET OF [0..15];
            WindA, WindB : set8;
            SZB , SZW : CARDINAL;
            BegA , BegB : CARDINAL;
            SWP    : PROC;
            unusf2 : ARRAY [0..250] OF CHAR;
          END;

   PROCEDURE Nfo(nr : CARDINAL);
   VAR   r   : Registers;

     PROCEDURE WAttr( at : set8;start : CARDINAL);
     BEGIN
       IF NOT (0 IN at) THEN
         IO.WrStr(" nie ma");
       ELSE
         IF 1 IN at THEN
           IO.WrStr(" do pisania");
         ELSE
           IO.WrStr(" nie do pisania");
         END;
         IF 2 IN at THEN
           IO.WrStr(" do czytania");
         ELSE
           IO.WrStr(" nie do czytania");
         END;
         IO.WrStr("   start ");
         IO.WrHex(start,0);
         IO.WrStr("H");
       END;
       IO.WrLn;
     END WAttr;

   VAR   ch : CHAR;
   BEGIN
     r.AX := 4F01H;
     r.CX := nr;
     r.ES := Seg(nfo);
     r.DI := Ofs(nfo);
     Lib.Intr(r,10H);
     WITH nfo DO
       IF 0 IN present THEN
         IO.WrStr("Tryb dostepny"); IO.WrLn;
         IO.WrStr("Rozmiar banku"); IO.WrCard(SZB,3); IO.WrStr(" KB");IO.WrLn;
         IO.WrStr("Rozmiar okna "); IO.WrCard(SZW,3); IO.WrStr(" KB");IO.WrLn;
         IO.WrStr("OKNO A : ");
         WAttr(WindA,BegA);
         IO.WrStr("OKNO B : ");
         WAttr(WindB,BegB);
       ELSE
         IO.WrStr("Tryb niedostepny");
       END;
     END;
     ch := IO.RdKey();
   END Nfo;

   PROCEDURE Bank(nr : CARDINAL);
   VAR   r   : Registers;
   BEGIN
     r.AX := 4F05H;
     r.BX := 0;
     r.DX := nr;
     Lib.Intr(r,10H);
   END Bank;

   PROCEDURE Tryb(nr : CARDINAL);
   VAR   r   : Registers;
   BEGIN
     r.AX := 4F02H;
     r.BX := nr;
     Lib.Intr(r,10H);
   END Tryb;

VAR
    i : CARDINAL;
    b : SHORTCARD;
    ch : CHAR;
    mem [0A000H:0] : ARRAY [0..0FFF0H] OF BYTE;
CONST
    MDE = 103H;
BEGIN
  Nfo(MDE);
  Tryb(MDE);
  FOR b:=0 TO 116 DO
    Bank(ORD(b));
    FOR i:=0 TO 1000H DO
(*
     IF ODD(ORD(b)) THEN
       mem[i] := 1;
     ELSE
       mem[i] := 3;
      END
*)
      mem[i] := b+1;
    END;
  END;
  ch := IO.RdKey();
  Tryb(3);
END VESA.
