masm RTSCorou /ML/DRTSmainM2;
if errorlevel 1 goto errmasm
masm RTSDevic /ML /DRTSmainM2;
if errorlevel 1 goto errmasm
masm RTSInter /ML /DRTSmainM2;
if errorlevel 1 goto errmasm
masm RTSIntpr /ML /DRTSmainM2;
if errorlevel 1 goto errmasm
masm RTSLangu /ML /DRTSmainM2;
if errorlevel 1 goto errmasm
masm RTSMain /ML /DRTSmainM2;
if errorlevel 1 goto errmasm
masm RTSPrior /ML /DRTSmainM2;
if errorlevel 1 goto errmasm
masm RTSRealE /ML /DRTSmainM2;
if errorlevel 1 goto errmasm
masm RTSError /ML /DRTSmainM2;
if errorlevel 1 goto errmasm
masm RTS87 /ML /DRTSmainM2;
if errorlevel 1 goto errmasm
masm RTSM87 /ML /DRTSmainM2;
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
lib MCRTS +RTSINTER +RTSERROR +RTSINTPR +RTSMAIN +RTSM87 +RTS87 +RTSPRIOR +RTSLANGU +RTSCOROU +RTSREALE +RTSDEVIC +RTSMONEX;
if errorlevel 1 goto errlib
echo off
echo library MCRTS.LIB created for linking C modules with M2 main program
del *.obj
goto end
:errlib
echo off
echo **** error when creating library
:end
