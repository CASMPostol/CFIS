masm RTSCorou /ML /DTRTS;
if errorlevel 1 goto errmasm
masm RTSDevic /ML /DTRTS;
if errorlevel 1 goto errmasm
masm RTSInter /ML /DTRTS;
if errorlevel 1 goto errmasm
masm RTSMonEx /ML /DTRTS;
if errorlevel 1 goto errmasm
masm RTSIntpr /ML /DTRTS;
if errorlevel 1 goto errmasm
masm RTSLangu /ML /DTRTS;
if errorlevel 1 goto errmasm
masm RTSMain /ML /DTRTS;
if errorlevel 1 goto errmasm
masm RTSPrior /ML /DTRTS;
if errorlevel 1 goto errmasm
masm RTSRealE /ML /DTRTS;
if errorlevel 1 goto errmasm
masm RTSError /ML /DTRTS /DP8086, RTSER86;
if errorlevel 1 goto errmasm
masm RTSError /ML /DTRTS /DP286, RTSER286;
if errorlevel 1 goto errmasm
echo off
echo *** 
echo *** Rename/copy RTSER86.OBJ or RTSER286.OBJ to RTSERROR.OBJ,
echo *** depending on the processor in your target system
echo *** (see RTSERRor.ASM source file for more information).
echo *** 
copy rtser86.obj rtserror.obj
echo *** Note that the 80x87 support modules RTS87.ASM and RTSM87.ASM
echo *** have not been assembled (must be adapted to target hardware).
rem not done: masm RTS87 /ML /DTRTS;
rem not done: if errorlevel 1 goto errmasm
rem not done: masm RTSM87 /ML /DTRTS;
rem not done: if errorlevel 1 goto errmasm
echo *** 
echo *** The resulting TRTS object files are only usable if
echo *** you have adapted RTSINTCO.INC to your target system!
echo *** 
echo assembling of TRTS modules completed successfully
goto end
:errmasm
echo off
echo **** error when assembling
goto end
:end


del m2rts.lib
lib M2RTS +RTSINTER +RTSERROR +RTSINTPR +RTSMAIN +RTSPRIOR +RTSLANGU +RTSCOROU +RTSREALE +RTSDEVIC +RTSMONEX;
