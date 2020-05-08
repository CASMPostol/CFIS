(*.F- *)
(**********************************************************************
|  Title   : Modul obsluguje obliczanie warosci minimalnych, 
|            maksymalnych i srednich
|  Author  : MPostol
|  System  : LOGITECH MODULA-2/86 
|  History :
|    Rel.3.0. utworzony
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE MMA_Cout;

  FROM SYSTEM IMPORT
    WORD;

  FROM CommonTypes IMPORT
    (* TYPE *) SigNilVal,  
    (* PROCEDURE *) InitSignalDsc;
      
  FROM MathLib0 IMPORT
    entier, real;

  FROM WorseBecause IMPORT
    WorseBLess, WorseBGreater;

    PROCEDURE Init_MMA_SignalDsc
              ( VAR cont    : MMA_SignalDsc;
                    posNilV : WORD    );

    BEGIN
      WITH cont DO
        avr := SigNilVal;
        InitSignalDsc(min, posNilV);
        InitSignalDsc(max, posNilV);
      END (* with AVcont *);
    END Init_MMA_SignalDsc;

    PROCEDURE Count_MMA_SignalDsc
              ( VAR res     : MMA_SignalDsc;
                    cont    : AvrDscr );

    BEGIN
      WITH res DO
        WITH cont DO
          IF num > 10
          THEN
            avr := entier( sum / FLOAT( num ) );
          ELSE
            avr := SigNilVal;
          END (* if num *);
        END (* with AVcont *);
        min := cont.min;
        max := cont.max;
      END (*  *);
    END Count_MMA_SignalDsc;

    PROCEDURE Init_AvrDscr
              ( VAR AVcont  : AvrDscr;
                    posNilV : WORD    );

    BEGIN
      WITH AVcont DO
        num := 0;
        sum := 0.0;
        InitSignalDsc(min, posNilV);
        InitSignalDsc(max, posNilV);
      END (* with AVcont *);
    END Init_AvrDscr;

    PROCEDURE MinMaxAvr
              (     dv       : INTEGER;
                    pos      : WORD;
                VAR dvAVcont : AvrDscr );

    BEGIN
      IF dv <> SigNilVal
      THEN
        WITH dvAVcont DO
          INC( num );
          sum := sum + real( dv );
          WorseBLess( min, dv, pos );
          WorseBGreater( max, dv, pos );
        END (* with dvAVcont *);
      END (* if dv *);
    END MinMaxAvr;

END MMA_Cout.
