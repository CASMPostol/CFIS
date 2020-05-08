(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
(*# check(index=>off,
          range=>off,
          stack=>off,
          nil_ptr=>off,
          overflow=>off,
          guard=>off)
*)

IMPLEMENTATION MODULE Mouse;

  FROM SYSTEM IMPORT
    BYTE, ADDRESS, ADR, Registers, Seg, Ofs, GetFlags, SetFlags, DI;
  FROM Lib IMPORT
    Intr;

(* alignment off, in order to avoid *)
(* dummy byte after field FarCall   *)

  PROCEDURE FlagReset(VAR mouseStatus: INTEGER;
                      VAR numberOfButtons: CARDINAL);
  VAR
    r : Registers;
  BEGIN
    r.AX:=0;
    Intr(r, 33H);
    numberOfButtons := r.BX;
    mouseStatus := r.AX;
  END FlagReset;

  PROCEDURE ShowCursor;
  VAR
    r : Registers;
  BEGIN
    r.AX:=1;
    Intr(r, 33H);
  END ShowCursor;

  PROCEDURE HideCursor;
  VAR
    r : Registers;
  BEGIN
    r.AX:=2;
    Intr(r, 33H);
  END HideCursor;

  PROCEDURE GetPosBut(VAR buttonStatus: ButtonSet;
                      VAR horizontal, vertical:INTEGER);
  VAR
    r : Registers;
  BEGIN
    r.AX:=3;
    Intr(r, 33H);
    buttonStatus := ButtonSet(r.BX);
    horizontal := r.CX;
    vertical := r.DX;
  END GetPosBut;

  PROCEDURE SetCursorPos(horizontal, vertical: INTEGER);
  VAR
    r : Registers;
  BEGIN
    r.AX := 4;
    r.CX := horizontal;
    r.DX := vertical;
    Intr(r, 33H);
  END SetCursorPos;

  PROCEDURE GetButPres(button: Button;
                       VAR buttonStatus: ButtonSet;
                       VAR buttonPressCount: CARDINAL;
                       VAR horizontal, vertical: INTEGER);
  VAR
    r : Registers;
  BEGIN
    r.BX := ORD(button);
    r.AX := 5;
    Intr(r, 33H);
    buttonPressCount := r.BX;
    buttonStatus := ButtonSet(r.AX);
    horizontal := r.CX;
    vertical := r.DX;
  END GetButPres;

  PROCEDURE GetButRel(button: Button;
                      VAR buttonStatus: ButtonSet;
                      VAR buttonReleaseCount: CARDINAL;
                      VAR horizontal ,vertical: INTEGER);
  VAR
    r : Registers;
  BEGIN
    r.BX := ORD(button);
    r.AX := 6;
    Intr(r, 33H);
    buttonReleaseCount := r.BX;
    buttonStatus := ButtonSet(r.AX);
    horizontal := r.CX;
    vertical := r.DX;
  END GetButRel;

  PROCEDURE SetHorizontalLimits(minPos, maxPos: INTEGER);
  VAR
    r : Registers;
  BEGIN
    r.AX := 7;
    r.CX := minPos;
    r.DX := maxPos;
    Intr(r, 33H);
  END SetHorizontalLimits;

  PROCEDURE SetVerticalLimits(minPos, maxPos: INTEGER);
  VAR
    r : Registers;
  BEGIN
    r.AX := 8;
    r.CX := minPos;
    r.DX := maxPos;
    Intr(r, 33H);
  END SetVerticalLimits;


  PROCEDURE SetGraphicCursor(VAR cursor: GraphicCursor);
  VAR
    r   : Registers;
    a   : ADDRESS;
    x,y : INTEGER;
  BEGIN
    WITH cursor DO
      x := hotX;
      y := hotY;
      a := ADR(screenMask);
    END;
    r.DX := Ofs(a^);
    r.ES := Seg(a^);
    r.CX := y;
    r.BX := x;
    r.AX := 9;
    Intr(r, 33H);
  END SetGraphicCursor;

  PROCEDURE SetTextCursor(selectedCursor,
                          screenMaskORscanStart,
                          cursorMaskORscanStop: CARDINAL);
  VAR
    r : Registers;
  BEGIN
    r.AX := 10;
    r.BX := selectedCursor;
    r.CX := screenMaskORscanStart;
    r.DX := cursorMaskORscanStop;
    Intr(r, 33H);
  END SetTextCursor;

  PROCEDURE ReadMotionCounters(VAR horizontal,
                                   vertical:INTEGER);
  VAR
    r : Registers;
  BEGIN
    r.AX := 11;
    Intr(r, 33H);
    horizontal := r.CX;
    vertical := r.DX;
  END ReadMotionCounters;

(* reset alignment to previous state *)

  PROCEDURE SetEventHandler(mask: EventSet;
                            handler: EventHandler);
  VAR
    r : Registers;
    a : ADDRESS;
  BEGIN
    a := ADDRESS( handler );
    r.CX := WORD(mask);
    r.DX := Ofs( a^ );
    r.ES := Seg( a^ );
    r.AX := 12;
    Intr(r, 33H);
  END SetEventHandler;

  PROCEDURE LightPenOn;
  VAR
    r : Registers;
  BEGIN
    r.AX := 13;
    Intr(r, 33H);
  END LightPenOn;

  PROCEDURE LightPenOff;
  VAR
    r : Registers;
  BEGIN
    r.AX := 14;
    Intr(r, 33H);
  END LightPenOff;

  PROCEDURE SetMickeysPerPixel(horPix, verPix: CARDINAL);
  VAR
    r : Registers;
  BEGIN
    r.AX := 15;
    r.CX := horPix;
    r.DX := verPix;
    Intr(r, 33H);
  END SetMickeysPerPixel;

  PROCEDURE ConditionalOff(left, top,
                           right, bottom: INTEGER);
  VAR
    r : Registers;
  BEGIN
    r.AX := 16;
    r.CX := left;
    r.DX := top;
    r.SI := right;
    r.DI := bottom;
    Intr(r, 33H);
  END ConditionalOff;

  PROCEDURE SetSpeedThreshold(threshold: CARDINAL);
  VAR
    r : Registers;
  BEGIN
    r.AX := 19;
    r.DX := threshold;
    Intr(r, 33H);
  END SetSpeedThreshold;


  CONST
    IRET = 0CFH;

  VAR
    MouseVector[0:204]: ADDRESS;
    TerminateProc[0:88H]: PROC;
    OldTermProc: PROC;

  PROCEDURE Terminator;
  VAR
    r : Registers;
  BEGIN
    r.AX := 0;
    Intr(r, 33H);      (* reset mouse, disable user defined event handler, etc. *)
    TerminateProc := OldTermProc;
    Intr(r, 22H);
  END Terminator;

  PROCEDURE GetPos(VAR Hor, Ver : CARDINAL);
  VAR
    r : Registers;
  BEGIN
    r.AX:=3;
    Intr(r, 33H);
    Hor := r.CX;
    Ver := r.DX;
  END GetPos;

BEGIN
  DriverInstalled := (Ofs(MouseVector^) <> 0) AND
                     (Seg(MouseVector^) <> 0) AND
                     (CARDINAL(MouseVector^) MOD 256 <> IRET);
  IF DriverInstalled THEN
    OldTermProc := TerminateProc;
    TerminateProc := Terminator;
  END;
END Mouse.
