:: Get the path to this script
set SCRIPTPATH=%~dp0

:: Build useful file and folder names
set SKETCH=%SCRIPTPATH%\south_norway
set OUT=%SCRIPTPATH%\out
set GEN=%SCRIPTPATH%\..\..\drakon_gen.tcl

:: Generate Processing.org .pde files from DRAKON .drn files
tclsh %GEN% -in "%SCRIPTPATH%\south_norway\Sky.drn"
tclsh %GEN% -in "%SCRIPTPATH%\south_norway\Displacement.drn"

:: Compile and run
processing-java --sketch=%SKETCH% --output=%OUT% --force --run
@pause