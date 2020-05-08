@ECHO OFF
m2c K:D_result.def/noa/B K:D_Files.def/noa/B K:D_Odb.def/noa/B K:D_DisRes.def/noa/B I:V_result.def/noa/B
if exist *.lst goto error

m2c I:V_Files.def/noa/B K:D_Count.def/noa/B K:D_Slupek.def/noa/B I:V_Count.def/noa/B
if exist *.lst goto error

m2c J:CommonTy.MOD/noa J:CommonDa.MOD/noa J:SpecConv.MOD/noa J:WorseBec.MOD/noa J:FlagAnal.MOD/noa J:Czas.MOD/noa
if exist *.lst goto error

m2c J:AltInter.MOD/noa J:DGHInter.MOD/noa J:NAVInter.MOD/noa J:DGH_util.MOD/noa J:FIltr1St.MOD/noa J:GPSRead.MOD/noa
if exist *.lst goto error

m2c J:GeoArith.MOD/noa J:Theodoli.MOD/noa J:ScannerI.MOD/noa J:Files.MOD/noa K:D_result.MOD/noa K:D_Odb.MOD/noa
if exist *.lst goto error

m2c K:D_Files.MOD/noa J:DisResUt.MOD/noa K:D_DisRes.MOD/noa J:Marks.MOD/noa J:DataColl.MOD/noa J:EventsMn.MOD/noa
if exist *.lst goto error

m2c J:PiszEven.MOD/noa I:VORO_avr.MOD/noa I:V_result.MOD/noa I:V_DisRes.MOD/noa I:PI_Anali.MOD/noa I:PI_ArchD.MOD/noa
if exist *.lst goto error

m2c J:Print.MOD/noa J:PrintCnt.MOD/noa K:DMEPrint.MOD/noa I:V_Odb.MOD/noa I:V_Files.MOD/noa I:VORPrint.MOD/noa
if exist *.lst goto error

m2c J:Mapa.MOD/noa I:V_Databa.MOD/noa I:V_Oblot.MOD/noa I:PI_Glown.MOD/noa K:D_Count.MOD/noa K:D_Slupek.MOD/noa
if exist *.lst goto error

m2c K:D_DAcqui.MOD/noa I:V_Slupek.MOD/noa I:PI_ScrUt.MOD/noa J:Wykres.MOD/noa J:Screen.MOD/noa J:Pomiar.MOD/noa
if exist *.lst goto error

m2c J:CocpDsp.MOD/noa I:V_CP_Con.MOD/noa I:VORR_Ave.MOD/noa I:V_Count.MOD/noa I:V_DAcqui.MOD/noa I:PI_Pomia.MOD/noa
if exist *.lst goto error

m2c I:PI_Qchec.MOD/noa J:PrintScr.MOD/noa pV.MOD/noa
if exist *.lst goto error

ECHO TRWA LINKOWANIE i BEDZIE TRWAC JESZCZE CHWILE
m2l/SA/v/b pV >lastlink.TXT
IF NOT EXIST pV.EXE GOTO ERROR
GOTO end

@ECHO ! NIC NOWEGO - WSZYSTKO JUZ ZROBIONE  !
GOTO END

:SKIPLINK
PAUSE ZLA WERSJA BIBLIOTEKI

:error
ECHO !!!   ERRORS   !!!
PAUSE !! ERRORS !!
GOTO FINAL

:END
ECHO JESZCZE JEDEN PELEN SUKCES

:FINAL
