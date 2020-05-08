(*.F- *)
(**********************************************************************
|  Title   : Print utiliy functions
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86 
|  History :
|    Rel. 3.02 created
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE PrintUtl;

  FROM CommonTypes IMPORT
    SignalDsc, NadajnikT, RodzajLotu, Reprezentacja, SigNilVal;

  FROM Print IMPORT
    WrPrnLn;

  FROM StdIO IMPORT
    sprintf;

  FROM Strings IMPORT
    ConstAssign, Length;

  FROM SYSTEM IMPORT
    WORD;
  
PROCEDURE Wr_NagTab10
          (     Nagl : ARRAY OF CHAR;
                Kol1 : ARRAY OF CHAR;
                Kol2 : ARRAY OF CHAR): BOOLEAN;
TYPE
  T_States = (St_Nagl, St_Kol1, St_Kol2);

VAR
  str    : ARRAY[0..80] OF CHAR;
  tabIdx : CARDINAL;
  parIdx : CARDINAL;
  state  : T_States;
  parLngt: CARDINAL;
  
BEGIN
  ConstAssign(NagTab10, str);
  tabIdx  := 1;
  parIdx  := 0;
  state   := MIN(T_States);
  parLngt := Length(Nagl);
  LOOP 
    CASE state OF
      St_Nagl:
      IF str[tabIdx] <> ' ' THEN
        INC(tabIdx, 2);
        parIdx  := 0;
        parLngt := Length( Kol1 );
        state   := St_Kol1;
      ELSIF parIdx < parLngt THEN
        str[ tabIdx ] := Nagl[ parIdx ];
        INC( tabIdx );
        INC( parIdx );
      ELSE
        INC(tabIdx);
      END (* if *);
        
    | St_Kol1:
      IF str[tabIdx] <> ' ' THEN
        INC(tabIdx, 2);
        parIdx  := 0;
        parLngt := Length( Kol2 );
        state   := St_Kol2;
      ELSIF parIdx < parLngt THEN
        str[tabIdx] := Kol1[parIdx];
        INC(tabIdx);
        INC(parIdx);
      ELSE
        INC(tabIdx);
      END (* if *);

    | St_Kol2:
      IF str[tabIdx] <> ' ' THEN
        EXIT;
      ELSIF parIdx < parLngt THEN
        str[tabIdx] := Kol2[parIdx];
        INC(tabIdx);
        INC(parIdx);
      ELSE
        EXIT;
      END (* if *);
    END (* case *);
  END (* loop *);
  RETURN WrPrnLn( 0, str);
END Wr_NagTab10;

 PROCEDURE PiszSignalDsc
            (     nag         : ARRAY OF CHAR;
                  Val_goA     : SignalDsc;
                  Val_goB     : SignalDsc;
                  lot         : RodzajLotu;
                  repWartosci : Reprezentacja): BOOLEAN;
  VAR
    CONV_STR : ARRAY [ 0..7 ] OF CHAR;
    kol1     : KolStr;
    kol2     : KolStr;

  BEGIN
    CONV_STR := "%?/%?";
    CASE lot OF
      Promien   : CONV_STR[4] := 'x'
    | Orbita    : CONV_STR[4] := 'z';
    | Orbita360 : 
        WITH Val_goA DO
          IF INTEGER(pos) <> SigNilVal THEN
            IF INTEGER(pos) < 0   THEN
              pos := WORD((INTEGER(pos) DIV 10) + 3600);
            ELSE
              pos := WORD((INTEGER(pos) DIV 10));
            END (* IF *);
          END (* IF *);
        END (* WITH *);
        WITH Val_goB DO
          IF INTEGER(pos) <> SigNilVal THEN
            IF INTEGER(pos) < 0   THEN
              pos := WORD((INTEGER(pos) DIV 10) + 3600);
            ELSE
              pos := WORD((INTEGER(pos) DIV 10));
            END (* IF *);
          END (* IF *);
        END (* WITH *);
        CONV_STR[4] := 'y';
    END (* CASE *);
    CASE repWartosci OF
      Wart_X1       : CONV_STR[1] := 'd';
    | Wart_X10      : CONV_STR[1] := 'y';
    | Wart_X100     : CONV_STR[1] := 'z';
    | Wart_X500     : 
      CONV_STR[1] := 'x';
      WITH Val_goA  DO
        IF val = SigNilVal THEN
          val := -1;
        END (* IF *);
      END (* WITH *);
      WITH Val_goB  DO
        IF val = SigNilVal THEN
          val := -1;
        END (* IF *);
      END (* WITH *);
    END (* CASE *);
    sprintf(kol1, CONV_STR, Val_goA);
    sprintf(kol2, CONV_STR, Val_goB);
    RETURN Wr_NagTab10(nag, kol1, kol2);
  END PiszSignalDsc;

BEGIN
  StartN[nA]      := 32;
  StartN[nB]      := 48;
END PrintUtl.
