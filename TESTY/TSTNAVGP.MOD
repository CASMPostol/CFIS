(*.F- *)
(**********************************************************************
|  Title   : Test of access to NAV generator by BPIB Interface
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

MODULE TstNAVGPIB;

  FROM NAVGPIB IMPORT
    (* TYPE *) CommandSimple, CommandRealPar, GPIB_Result, 
    (* VAR *) lastGPIBError, 
    (* PROCEDURE *) DoSimpleComm, DoCommandRealPar, VOR_Default, 
    LOC_Default, GS_Default, MKR_Default; 

VAR
  ok: BOOLEAN;
  
BEGIN
  ok := VOR_Default();
  ok := LOC_Default();
  ok := GS_Default();
  ok := MKR_Default();
END TstNAVGPIB.
