masm RTSCorou /ML/DRTSmainC;
if errorlevel 1 goto errmasm
masm RTSDevic /ML /DRTSmainC;
if errorlevel 1 goto errmasm
masm RTSInter /ML /DRTSmainC;
if errorlevel 1 goto errmasm
masm RTSIntpr /ML /DRTSmainC;
if errorlevel 1 goto errmasm
masm RTSLangu /ML /DRTSmainC;
if errorlevel 1 goto errmasm
masm RTSMain /ML /DRTSmainC /DTRTM;
if errorlevel 1 goto errmasm
masm RTSPrior /ML /DRTSmainC;
if errorlevel 1 goto errmasm
masm RTSRealE /ML /DRTSmainC;
if errorlevel 1 goto errmasm
masm RTSError /ML /DRTSmainC;
if errorlevel 1 goto errmasm
masm RTS87 /ML /DRTSmainC;
if errorlevel 1 goto errmasm
masm RTSM87 /ML /DRTSmainC;
if errorlevel 1 goto errmasm
masm RTSMonEx/ML;
if errorlevel 1 goto errmasm
echo off
echo assembling of RTS modules completed successfully
goto lib
:errmasm
echo off
echo **** error when assembling
goto end
:lib
del Crts.lib
lib CMRTS +RTSINTER +RTSERROR +RTSINTPR +RTSMAIN +RTSM87 +RTS87 +RTSPRIOR +RTSLANGU +RTSCOROU +RTSREALE +RTSDEVIC +RTSMONEX;
if errorlevel 1 goto errlib
echo off
echo library CMRTS.LIB created for linking Modula-2 modules with C main program
del *.obj
goto end
:errlib
echo off
echo **** error when creating library
:end
