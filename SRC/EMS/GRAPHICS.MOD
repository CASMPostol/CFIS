(*$R- *)
(*$S-*)
(*$O+*)
(*$T-*)
IMPLEMENTATION MODULE Graphics;
FROM SYSTEM IMPORT
  CODE,AX,BX,CX,DX,ES,DI,DS,SI, SIZE,
  SWI, SETREG, GETREG, BYTE, ADDRESS, ADR;
FROM RTSMain IMPORT
  InstallTermProc;
FROM EMS IMPORT
  GetFrameSegment, ems, Map;
IMPORT
  SYSTEM, FIO;

VAR
  FontPtr      : ADDRESS;
  EmsSeg       : CARDINAL;
CONST
    MaxX   = 800;
    MaxY   = 600;
    MaxXL  = VAL(LONGINT,MaxX);
    MaxYL  = VAL(LONGINT,MaxY);

   PROCEDURE MaxHor():CARDINAL;
   BEGIN
     RETURN MaxX;
   END MaxHor;

   PROCEDURE MaxVer():CARDINAL;
   BEGIN
     RETURN MaxY;
   END MaxVer;

   PROCEDURE Tryb(nr : CARDINAL);
   VAR
     info : ARRAY[0..127] OF CARDINAL;
     a    : ADDRESS;
     Hor, Ver	: CARDINAL;
   BEGIN
     SETREG( AX, 12H );
     SWI( 10H );	(* zeby powiadomic driver myszy o trybie graficznym *)
     a := ADR( info );
     SETREG(AX,4F02H);
     SETREG(BX,nr);
     SWI(10H);
     SETREG(AX,4F01H);
     SETREG(CX,nr );
     SETREG(ES,a.SEGMENT);
     SETREG(DI,a.OFFSET);
     SWI(10H);
     IF nr>=100H THEN
       BK64Inc := 64 DIV info[2];
       BKSizeL := VAL( LONGINT, info[2]) * 1024L;
       Hor := info[6];
       Ver := info[8];
     END;
   END Tryb;

   PROCEDURE HugeMemCpyEMS( VAR Src,
                                Dest : ADDRESS;
                                Cnt  : CARDINAL;
                                e    : ems;
                            VAR sub  : CARDINAL );
   VAR
     pass : CARDINAL;
   BEGIN
(*$R-*)
     IF (Src.SEGMENT = EmsSeg) &
        ((Src.OFFSET+Cnt) MOD 4000H < Src.OFFSET MOD 4000H )
(*$R=*)
     THEN
       pass := 4000H-Src.OFFSET MOD 4000H;
       HugeMemCpy( Src, Dest, pass );
       INC( sub );
       Map( e, sub, Src.OFFSET DIV 4000H );
       DEC( Cnt, pass );
       Src.OFFSET := (Src.OFFSET DIV 4000h) * 4000H; (* maskowanie najmlodszych bitow *)
       INC( Dest.OFFSET, pass );
(*$R-*)
     ELSIF (Dest.SEGMENT = EmsSeg) &
        ((Dest.OFFSET+Cnt) MOD 4000H < Dest.OFFSET MOD 4000H )
(*$R=*)
     THEN
       pass := 4000H-Dest.OFFSET MOD 4000H;
       HugeMemCpy( Src, Dest, pass );
       INC( sub );
       Map( e, sub, Dest.OFFSET DIV 4000H );
       DEC( Cnt, pass );
       Dest.OFFSET := (Dest.OFFSET DIV 4000h) * 4000H; (* maskowanie najmlodszych bitow *)
       INC( Src.OFFSET, pass );
     END;
     HugeMemCpy( Src, Dest, Cnt );
     INC( Src.OFFSET, Cnt );
     INC( Dest.OFFSET, Cnt );
   END HugeMemCpyEMS;

   PROCEDURE HugeMemCpy( Src, Dest : ADDRESS; Cnt : CARDINAL );
   VAR
     pass : CARDINAL;
   BEGIN
(*$R-*)
     IF Src.OFFSET+Cnt < Src.OFFSET THEN (* przewinelo sie *)
(*$R=*)
       pass := CARDINAL(-INTEGER(Src.OFFSET));
       SETREG( DS, Src.SEGMENT );
       SETREG( ES, Dest.SEGMENT );
       SETREG( SI, Src.OFFSET );
       SETREG( DI, Dest.OFFSET );
       SETREG( CX, pass );
       CODE(0FCH,0F3H,0A4H); (* cld rep movsb *)
       DEC( Cnt, pass );
       SetBank( bank+BK64Inc );
       Src.OFFSET := 0;
       INC(Dest.OFFSET, pass);
(*$R-*)
     ELSIF Dest.OFFSET+Cnt < Dest.OFFSET THEN (* przewinelo sie *)
(*$R=*)
       pass := CARDINAL(-INTEGER(Dest.OFFSET));
       SETREG( DS, Src.SEGMENT );
       SETREG( ES, Dest.SEGMENT );
       SETREG( SI, Src.OFFSET );
       SETREG( DI, Dest.OFFSET );
       SETREG( CX, pass );
       CODE(0FCH,0F3H,0A4H); (* cld rep movsb *)
       DEC( Cnt, pass );
       SetBank( bank+BK64Inc );
       Dest.OFFSET := 0;
       INC(Src.OFFSET, pass);
     END;
     SETREG( DS, Src.SEGMENT );
     SETREG( ES, Dest.SEGMENT );
     SETREG( SI, Src.OFFSET );
     SETREG( DI, Dest.OFFSET );
     SETREG( CX, Cnt );
     CODE(0FCH,0F3H,0A4H); (* cld rep movsb *)
   END HugeMemCpy;


  MODULE InternalMonitor[0];

  FROM SYSTEM IMPORT CODE,AX,BX,CX,DX,ES,DI,DS,SI, SIZE,
                   SWI, SETREG, GETREG, BYTE, ADDRESS, ADR;
  IMPORT
    FontPtr, HugeMemCpy, MaxX, MaxY, MaxXL, MaxYL, FntTable, ems,
    HugeMemCpyEMS, EmsSeg, Map;

  EXPORT  WrStrXY, SetBank, GetBank, bank, GetWindow, InvertW, SetWindow,
          FillRect,DP, BKSizeL, BK64Inc, Wr2StrXY, Wr16StrXY,
          Wr2fStrXY;

TYPE
    Long2Card = RECORD CASE BOOLEAN OF FALSE:
                 L     : LONGINT;    | TRUE :
                 lo,hi : CARDINAL;
                END END;

CONST
     WindowSEG = 0A000H;
VAR
   bank      : CARDINAL;(* numer aktualnego banku *)
   bankstart : LONGINT; (* adres fizycznej pamieci dla poczatku banku *)
   BKSizeL   : LONGINT; (* rozmiar banku *)
   BK64Inc   : CARDINAL;(* przyrost numeru banku do zmiany bankstart o 64K *)
   SCRMEM [0A000H:0] : ARRAY [0..0H] OF BYTE;

   PROCEDURE SetBank(nr : CARDINAL);
   BEGIN
     IF (bank#nr) THEN
       SETREG(AX,4F05H);
       SETREG(BX,0);  (* bank 0 *)
       SETREG(DX,nr);
       SWI(10H);
       SETREG(AX,4F05H);
       SETREG(BX,1);  (* bank 1 dla ET4000 *)
       SETREG(DX,nr);
       SWI(10H);
       bank := nr;
       bankstart := VAL(LONGINT,nr)*BKSizeL;
     END;
   END SetBank;

   PROCEDURE GetBank():CARDINAL;
   BEGIN
     RETURN bank;
   END GetBank;


   PROCEDURE DP(x,y : CARDINAL;color:BYTE);
   VAR
       pt,diff : Long2Card;
   BEGIN
     IF (x<MaxX) AND (y<MaxY) THEN
       pt.L := VAL(LONGINT,y)*MaxXL+VAL(LONGINT,x);
       diff.L:= pt.L - bankstart;
       IF (diff.hi#0) THEN
       (* trzeba zmienic bank *)
         SetBank(VAL(CARDINAL,pt.L DIV BKSizeL));
         diff.L:= pt.L - bankstart;
       END;
(*$T-*)
       SCRMEM [diff.lo] := color;
(*$T=*)
     END;
   END DP;

   PROCEDURE FillRect(xl,yt,xr,yb: CARDINAL; color : BYTE);
   VAR
       pt, diff : Long2Card;
       p,x,y,x1 : CARDINAL;
   BEGIN
     IF (xl>=MaxX) THEN xl := MaxX-1 END;
     IF (xr>=MaxX) THEN xr := MaxX-1 END;
     IF (yt>=MaxY) THEN yt := MaxY-1 END;
     IF (yb>=MaxY) THEN yb := MaxY-1 END;
     IF (xl>xr) OR (yt>yb) THEN
       RETURN
     END;
     x := xr-xl+1;
     FOR y:=yt TO yb DO
       pt.L   := VAL(LONGINT,y)*MaxXL+VAL(LONGINT,xl);
       diff.L:= pt.L - bankstart;
       IF diff.hi#0 THEN (* ponad 64k *)
       (* trzeba zmienic bank i przeliczyc diff *)
         SetBank(VAL(CARDINAL,pt.L DIV BKSizeL));
         diff.L:= pt.L - bankstart;
       END;
(*$R-*)
       IF diff.lo+x-1 < diff.lo THEN (* przewinelo sie = trzeba na 2 x *)
(*$R=*)
         p := CARDINAL(-INTEGER(diff.lo));
         SETREG( ES, WindowSEG );
         SETREG( DI, diff.lo );
         SETREG( CX, p );
         SETREG(AX,color);
         CODE(0FCH,0F3H,0AAH); (* cld rep stosb *)
         x1 := x - p;
         SetBank( bank+BK64Inc );
         diff.lo := 0;
       ELSE
         x1 := x;
       END;
       SETREG( ES, WindowSEG );
       SETREG( DI, diff.lo );
       SETREG( CX, x1 );
       SETREG(AX,color);
       CODE(0FCH,0F3H,0AAH); (* cld rep stosb *)
     END;
   END FillRect;




   PROCEDURE GetWindow( WindowPtr : ADDRESS;
                        xl,
                        yt,
                        xr,
                        yb        : CARDINAL;
                        emsH      : ems;
                        Podstr    : CARDINAL );
   VAR
       pt,diff : Long2Card;
       x,y : CARDINAL;
       Src: ADDRESS;
   BEGIN
     IF (xl>=MaxX) THEN xl := MaxX-1 END;
     IF (xr>=MaxX) THEN xr := MaxX-1 END;
     IF (yt>=MaxY) THEN yt := MaxY-1 END;
     IF (yb>=MaxY) THEN yb := MaxY-1 END;
     IF (xl>xr) OR (yt>yb) THEN
       RETURN
     END;
     Src.SEGMENT := WindowSEG;
     x := xr-xl+1;
     IF (WindowPtr.SEGMENT = EmsSeg) THEN
       Map( emsH, Podstr, WindowPtr.OFFSET DIV 4000H );
     END;
     FOR y:=yt TO yb DO
       pt.L := VAL(LONGINT,y)*MaxXL+VAL(LONGINT,xl);
       diff.L:= pt.L - bankstart;
       IF (diff.hi#0) THEN
       (* trzeba zmienic bank *)
         SetBank(VAL(CARDINAL,pt.L DIV BKSizeL));
         diff.L:= pt.L - bankstart;
       END;
       Src.OFFSET := diff.lo;
       HugeMemCpyEMS( Src, WindowPtr, x, emsH, Podstr );
     END;
   END GetWindow;

   PROCEDURE InvertW( xl,yt,xr,yb : CARDINAL );
   VAR
       pt,diff : Long2Card;
       x,y,x1,p : CARDINAL;
   BEGIN
     IF (xl>=MaxX) THEN xl := MaxX-1 END;
     IF (xr>=MaxX) THEN xr := MaxX-1 END;
     IF (yt>=MaxY) THEN yt := MaxY-1 END;
     IF (yb>=MaxY) THEN yb := MaxY-1 END;
     IF (xl>xr) OR (yt>yb) THEN
       RETURN
     END;
     x := xr-xl+1;
     FOR y:=yt TO yb DO
       pt.L := VAL(LONGINT,y)*MaxXL+VAL(LONGINT,xl);
       diff.L:= pt.L - bankstart;
       IF (diff.hi#0) THEN
       (* trzeba zmienic bank *)
         SetBank(VAL(CARDINAL,pt.L DIV BKSizeL));
         diff.L:= pt.L - bankstart;
       END;
(*$R-*)
       IF diff.lo+x-1 < diff.lo THEN (* przewinelo sie *)
(*$R=*)
         p := CARDINAL(-INTEGER(diff.lo));
         SETREG( ES, WindowSEG );
         SETREG( DI, diff.lo );
         SETREG( CX, p );
         SETREG(AX,0FH);                  (* -------------------------    *)
         CODE(26H,30H,5, 47H, 0E2H,0FAH); (* xor es:[di],al; inc di, loop *)
         x1 := x-p;
         SetBank( bank+BK64Inc );
         diff.lo := 0;
       ELSE
         x1 := x;
       END;
       SETREG( ES, WindowSEG );
       SETREG( DI, diff.lo );
       SETREG( CX, x1 );
       SETREG(AX,0FH);                  (* -------------------------    *)
       CODE(26H,30H,5, 47H, 0E2H,0FAH); (* xor es:[di],al; inc di, loop *)
     END;
   END InvertW;

   PROCEDURE SetWindow( WindowPtr : ADDRESS;
                        xl,
                        yt,
                        xr,
                        yb        : CARDINAL;
                        emsH      : ems;
                        Podstr    : CARDINAL );
   VAR
       pt,diff : Long2Card;
       x,y : CARDINAL;
       Dest : ADDRESS;
   BEGIN
     IF (xl>=MaxX) THEN xl := MaxX-1 END;
     IF (xr>=MaxX) THEN xr := MaxX-1 END;
     IF (yt>=MaxY) THEN yt := MaxY-1 END;
     IF (yb>=MaxY) THEN yb := MaxY-1 END;
     IF (xl>xr) OR (yt>yb) THEN
       RETURN
     END;
     x := xr-xl+1;
     Dest.SEGMENT := WindowSEG;
     IF (WindowPtr.SEGMENT = EmsSeg) THEN
       Map( emsH, Podstr, WindowPtr.OFFSET DIV 4000H );
     END;
     FOR y:=yt TO yb DO
       pt.L := VAL(LONGINT,y)*MaxXL+VAL(LONGINT,xl);
       diff.L:= pt.L - bankstart;
       IF (diff.hi#0) THEN
       (* trzeba zmienic bank *)
         SetBank(VAL(CARDINAL,pt.L DIV BKSizeL));
         diff.L:= pt.L - bankstart;
       END;
       Dest.OFFSET := diff.lo;
       HugeMemCpyEMS( WindowPtr, Dest, x, emsH, Podstr );
     END;
   END SetWindow;

   PROCEDURE WrStrXY(str : ARRAY OF CHAR;
                     x,y : CARDINAL;
                     color, TextBackColor : BYTE);
     TYPE
        TypeFacePtr = POINTER TO ARRAY [0..15] OF SET OF [0..7];
     VAR
   	idx,ix,iy : CARDINAL;
   	TF  : RECORD CASE BOOLEAN OF
   	          TRUE : A : ADDRESS;
   	      |  FALSE : F : TypeFacePtr;
   	      END; END;

   BEGIN
     idx := 0;
     WHILE (idx<=HIGH(str)) AND (str[idx]#0C) DO
       TF.A := GetFontPtr( str[idx] );
       INC(TF.A.OFFSET,+2);                 (* +2 *)
       FOR iy:=0 TO 9 DO	            (* -5 *)
         FOR ix:=0 TO 7 DO
           IF 7-ix IN TF.F^[iy] THEN
             DP(x+ix,y+iy,color);
           ELSIF color#TextBackColor THEN
             DP(x+ix,y+iy,TextBackColor);
           END;
         END;
       END;
       INC(x,8);
       INC(idx);
     END;
   END WrStrXY;

   PROCEDURE GetFontPtr( c : CHAR ):ADDRESS;
   VAR
     TF : ADDRESS;
   BEGIN
     CASE c OF
       '�' : RETURN ADR( FntTable[0] );
     | '�' : RETURN ADR( FntTable[1] );
     | '�' : RETURN ADR( FntTable[2] );
     | '�' : RETURN ADR( FntTable[3] );
     | '�' : RETURN ADR( FntTable[4] );
     | '�' : RETURN ADR( FntTable[5] );
     | '�' : RETURN ADR( FntTable[6] );
     | '�' : RETURN ADR( FntTable[7] );
     | '�' : RETURN ADR( FntTable[8] );
     | '�' : RETURN ADR( FntTable[9] );
     | '�' : RETURN ADR( FntTable[10] );
     | '�' : RETURN ADR( FntTable[11] );
     | '�' : RETURN ADR( FntTable[12] );
     | '�' : RETURN ADR( FntTable[13] );
     | '�' : RETURN ADR( FntTable[14] );
     | '�' : RETURN ADR( FntTable[15] );
     | '�' : RETURN ADR( FntTable[16] );
     | '�' : RETURN ADR( FntTable[17] );
     ELSE
       TF:=FontPtr;
       INC(TF.OFFSET,ORD(c)*16);
       RETURN TF;
     END;
   END GetFontPtr;

   PROCEDURE Wr16StrXY(str : ARRAY OF CHAR;
                     x,y : CARDINAL;
                     color, TextBackColor : BYTE);
     TYPE
        TypeFacePtr = POINTER TO ARRAY [0..15] OF SET OF [0..7];
     VAR
   	idx,ix,iy : CARDINAL;
   	TF  : RECORD CASE BOOLEAN OF
   	          TRUE : A : ADDRESS;
   	      |  FALSE : F : TypeFacePtr;
   	      END; END;

   BEGIN
     idx := 0;
     WHILE (idx<=HIGH(str)) AND (str[idx]#0C) DO
       TF.A:=GetFontPtr(str[idx]);
       FOR iy:=0 TO 15 DO
         FOR ix:=0 TO 7 DO
           IF 7-ix IN TF.F^[iy] THEN
             DP(x+ix,y+iy,color);
           ELSIF color#TextBackColor THEN
             DP(x+ix,y+iy,TextBackColor);
           END;
         END;
       END;
       INC(x,8);
       INC(idx);
     END;
   END Wr16StrXY;

   PROCEDURE Wr2StrXY(str : ARRAY OF CHAR;
                     x,y : CARDINAL;
                     color, TextBackColor : BYTE);
     TYPE
        TypeFacePtr = POINTER TO ARRAY [0..15] OF SET OF [0..7];
     VAR
   	idx,ix,iy,x2,y2 : CARDINAL;
   	TF  : RECORD CASE BOOLEAN OF
   	          TRUE : A : ADDRESS;
   	      |  FALSE : F : TypeFacePtr;
   	      END; END;

   BEGIN
     idx := 0;
     WHILE (idx<=HIGH(str)) AND (str[idx]#0C) DO
       TF.A:=GetFontPtr(str[idx]);
       INC(TF.A.OFFSET,                +2); (* +2 *)
       FOR iy:=0 TO 9 DO	            (* -5 *)
         FOR ix:=0 TO 7 DO
           x2:=x+ix*2;
           y2:=y+iy*2;
           IF 7-ix IN TF.F^[iy] THEN
             DP(x2,y2,color);
             DP(x2+1,y2,color);
             INC(y2);
             DP(x2,y2,color);
             DP(x2+1,y2,color);
           ELSIF color#TextBackColor THEN
             DP(x2,y2,TextBackColor);
             DP(x2+1,y2,TextBackColor);
             INC(y2);
             DP(x2,y2,TextBackColor);
             DP(x2+1,y2,TextBackColor);
           END;
         END;
       END;
       INC(x,14);
       INC(idx);
     END;
   END Wr2StrXY;

   PROCEDURE Wr2fStrXY(str : ARRAY OF CHAR;
                       x,y : CARDINAL;
                       color, TextBackColor : BYTE);
     TYPE
        TypeFacePtr = POINTER TO ARRAY [0..15] OF SET OF [0..7];
     VAR
   	idx,ix,iy,x2,y2 : CARDINAL;
   	TF  : RECORD CASE BOOLEAN OF
   	          TRUE : A : ADDRESS;
   	      |  FALSE : F : TypeFacePtr;
   	      END; END;

   BEGIN
     idx := 0;
     WHILE (idx<=HIGH(str)) AND (str[idx]#0C) DO
       TF.A:=GetFontPtr(str[idx]);
       FOR iy:=0 TO 15 DO
         FOR ix:=0 TO 7 DO
           x2:=x+ix*2;
           y2:=y+iy*2;
           IF 7-ix IN TF.F^[iy] THEN
             DP(x2,y2,color);
             DP(x2+1,y2,color);
             INC(y2);
             DP(x2,y2,color);
             DP(x2+1,y2,color);
           ELSIF color#TextBackColor THEN
             DP(x2,y2,TextBackColor);
             DP(x2+1,y2,TextBackColor);
             INC(y2);
             DP(x2,y2,TextBackColor);
             DP(x2+1,y2,TextBackColor);
           END;
         END;
       END;
       INC(x,14);
       INC(idx);
     END;
   END Wr2fStrXY;

 END InternalMonitor;

   PROCEDURE Terminator;
   BEGIN
     SETREG(AX,3);
     SWI( 10H );
   END Terminator;

  PROCEDURE FindROMFontAddr() : ADDRESS;
  VAR
     seg,off : CARDINAL;
     FontPtr : ADDRESS;
  BEGIN
    CODE(0B8H,30H,11H); (* MOV AX,1130H return char font info *)
    CODE(0B7H,06H);     (* MOV BH, 6    for font 8x16 *)
    CODE(1EH,55H);      (* PUSH DS and BP *)
    CODE(0CDH,10H);     (* INT 10H        *)
    CODE(89H,0E8H);     (* MOV AX, BP     save offset in AX *)
    CODE(5DH,1FH);      (* PUSH DS and BP *)
    GETREG(AX,off);
    GETREG(ES,seg);
    FontPtr.SEGMENT := seg;
    FontPtr.OFFSET := off;
    RETURN FontPtr;
  END FindROMFontAddr;

VAR
  FntTable : ARRAY[0..17] OF ARRAY[0..15] OF CHAR;

  PROCEDURE LoadPLFonts;
  VAR
    F : FIO.File;
  BEGIN
    F := FIO.Open( 'znaki.pl' );
    IF FIO.Read( F, ADR( FntTable ), SIZE( FntTable )) THEN
    END;
    FIO.Close( F );
  END LoadPLFonts;

BEGIN
  InstallTermProc( Terminator );
  Tryb(103H);
  FontPtr := FindROMFontAddr();
  EmsSeg := GetFrameSegment();
  SetBank(0);
  LoadPLFonts;
END Graphics.
