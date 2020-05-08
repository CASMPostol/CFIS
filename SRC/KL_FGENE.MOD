(*.F- *)
(**********************************************************************
|  Title   : Functions generator 
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86 
|  History :
|    06-06-96: created
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE Kl_FGenerators;

  PROCEDURE LookupM
            (     X        : REAL;
              VAR pnkt_kal : ARRAY OF REAL;
              VAR st       : ARRAY OF REAL;
              VAR ok       : BOOLEAN       ) : REAL;

  VAR
    idx     : CARDINAL;
    a       : REAL;
    rosnaca : BOOLEAN;

  BEGIN (* LookupM *)
    (* Assert(HIGH(st) = HIGH(pnkt_kal) *)
    ok := TRUE;
    rosnaca := st[0] <= st[HIGH( st )];
    idx := 0;
    IF rosnaca AND ( X >= st[0] ) AND ( X <= st[HIGH( st )] ) OR
       ( NOT rosnaca ) AND ( X <= st[0] ) AND ( X >= st[HIGH( st )] )
    THEN
      LOOP
        INC( idx );
        IF rosnaca AND ( st[idx] >= X ) OR ( NOT rosnaca ) AND ( st[idx] <= X )
        THEN
          EXIT;
        END (* if *);
      END (* loop *);
    ELSIF ( rosnaca AND ( X < st[0] ) ) OR ( NOT rosnaca AND ( X > st[0] ) )
    THEN
      ok := FALSE;
      RETURN pnkt_kal[0];
    ELSE
      ok := FALSE;
      RETURN pnkt_kal[HIGH( st )];
    END (* if rosnaca *);
    IF st[idx - 1] = st[idx]
    THEN
      RETURN st[idx]
    END (* if st *);
    a := ( pnkt_kal[idx] - pnkt_kal[idx - 1] ) / ( st[idx] - st[idx - 1] );
    RETURN ( X - st[idx] ) * a + pnkt_kal[idx];
  END LookupM;

END Kl_FGenerators.
