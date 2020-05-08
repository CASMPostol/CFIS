(*.F- *)
(**********************************************************************
|  Title   : Obsluga danych archiwalnych GS
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE PI_ArchDate;

  IMPORT
    G_results;

  FROM Files IMPORT
    ChangeDir, GoHomeDir;

  FROM EventsMng IMPORT
    LoadDistEvents, Events;

  FROM CommonData IMPORT
    (* VAR *) SciezkaOpisuPomiaru;

  PROCEDURE LoadData
            ( VAR dataOk : okTab );
  VAR
    pomiar : BOOLEAN;

  BEGIN
    IF NOT ChangeDir(SciezkaOpisuPomiaru)
    THEN
      FOR pomiar := FALSE TO TRUE DO
        dataOk[pomiar] := FALSE;
      END (* for pomiar *);
      RETURN;
    END (* if *);
    dataOk[FALSE] := G_results.GetAnRes() AND LoadDistEvents(
                     Events[FALSE], FALSE);
    dataOk[TRUE] := FALSE;
  END LoadData;

END PI_ArchDate.
