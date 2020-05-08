(*.F- *)
(**********************************************************************
|  Title   : Obsluga danych archiwalnych
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
    V_results, D_results;

  FROM Files IMPORT
    ChangeDir;

  FROM EventsMng IMPORT
    LoadDistEvents, Events;

  FROM CommonData IMPORT
    SciezkaOpisuPomiaru;


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
    dataOk[FALSE] := V_results.GetAnRes(V_results.anRes) AND LoadDistEvents(
                     Events[FALSE], FALSE);
    dataOk[TRUE] := D_results.GetAnRes(D_results.anRes) AND LoadDistEvents(
                    Events[TRUE], TRUE);
  END LoadData;

END PI_ArchDate.
