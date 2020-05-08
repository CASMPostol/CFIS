masm RTSCorou /ML/DM2Only;
if errorlevel 1 goto errmasm
masm RTSDevic /ML /DM2Only;
if errorlevel 1 goto errmasm
masm RTSInter /ML /DM2Only;
if errorlevel 1 goto errmasm
masm RTSIntpr /ML /DM2Only;
if errorlevel 1 goto errmasm
masm RTSLangu /ML /DM2Only;
if errorlevel 1 goto errmasm
masm RTSMain /ML /DM2Only /DTRTM;
if errorlevel 1 goto errmasm
masm RTSPrior /ML /DM2Only;
if errorlevel 1 goto errmasm
masm RTSRealE /ML /DM2Only;
if errorlevel 1 goto errmasm
masm RTSError /ML /DM2Only;
if errorlevel 1 goto errmasm
masm RTS87 /ML /DM2Only;
if errorlevel 1 goto errmasm
masm RTSM87 /ML /DM2Only;
if errorlevel 1 goto errmasm
masm RTSMonEx/ML;
if errorlevel 1 goto errmasm
echo off
echo assembling of RTS modules completed successfully
goto lib
:errmasm
@echo off
echo **** error when assembling
goto end
:lib
del m2rts.lib
lib M2RTS +RTSINTER +RTSERROR +RTSINTPR +RTSMAIN +RTSM87 +RTS87 +RTSPRIOR +RTSLANGU +RTSCOROU +RTSREALE +RTSDEVIC +RTSMONEX;
if errorlevel 1 goto errlib
if NOT exist m2rts.lib goto  errlib
@echo off
echo library M2RTS.LIB created for linking pure Modula-2 programs
copy m2rts.lib ..\m2rts.lib
goto end
:errlib
echo off
echo **** error when creating library
:end
