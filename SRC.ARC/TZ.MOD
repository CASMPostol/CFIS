MODULE TZ;

IMPORT
  DebugPMD, DOSEntry, MANAGER;
FROM Zoom IMPORT
  Init, Done, Assign, ZmiennaNiezalezna;
FROM RTSMain IMPORT
  Terminate, Status;

BEGIN
  Init;
(*  IF NOT ZmiennaNiezalezna("g:\ils\003\000_a_l.loc\predis_0.dat", FALSE) THEN*)
(*  IF NOT ZmiennaNiezalezna("g:\ils\003\000_a_l.loc\gpsr___0.dat", FALSE) THEN*)
(*  IF NOT ZmiennaNiezalezna("x:\vor\000\050.a\predis_0.dat", FALSE) THEN*)
  IF NOT ZmiennaNiezalezna("x:\vor\000\050.a\gpsa___0.dat", TRUE) THEN
    Terminate( Warning );
  END;

  Assign( 0, 0, "x:\vor\000\050.a\v_dvgpsa.dat", "Wykres 1", 100.0, FALSE );
  Assign( 1, 0, "x:\vor\000\050.a\v_agc__a.dat", "Wykres 2", 100.0, TRUE );
  Assign( 2, 0, "x:\vor\000\050.a\v_ref__a.dat", "Wykres 3", 10.0, FALSE );
  Assign( 3, 0, "x:\vor\000\050.a\v_var__a.dat", "Wykres 4", 100.0, FALSE );
  Assign( 3, 2, "x:\vor\000\050.a\v_sub__a.dat", "", 100.0, FALSE );
(*
  Assign( 0, 0, "g:\ils\003\000_a_l.loc\l_dev__a.dat", "Wykres 1", 100.0, FALSE );
  Assign( 1, 0, "g:\ils\003\000_a_l.loc\l_agcl_a.dat", "Wykres 2", 1.0, TRUE );
  Assign( 2, 0, "g:\ils\003\000_a_l.loc\l_mod__a.dat", "Wykres 3", 10.0, FALSE );
  Assign( 3, 0, "g:\ils\003\000_a_l.loc\l_agcm_a.dat", "Wykres 4", 1.0, TRUE );
*)
  LOOP
  END;
END TZ.
