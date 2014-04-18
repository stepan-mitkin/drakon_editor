tclsh ..\..\..\drakon_gen.tcl -in globals.drn
tclsh ..\..\..\drakon_gen.tcl -in indexed.drn
tclsh ..\..\..\drakon_gen.tcl -in indexed2.drn
tclsh ..\..\..\drakon_gen.tcl -in m2m.drn
tclsh ..\..\..\drakon_gen.tcl -in ownarrow.drn
tclsh ..\..\..\drakon_gen.tcl -in ownpaw.drn
tclsh ..\..\..\drakon_gen.tcl -in peerarrow.drn
tclsh ..\..\..\drakon_gen.tcl -in peerpaw.drn
tclsh ..\..\..\drakon_gen.tcl -in simple.drn


gcc -Wall  lib.c globals.c -o globals.exe
gcc -Wall  lib.c indexed.c -o indexed.exe
gcc -Wall  lib.c indexed2.c -o indexed2.exe
gcc -Wall  lib.c ownarrow.c -o ownarrow.exe
gcc -Wall  lib.c ownpaw.c -o ownpaw.exe
gcc -Wall  lib.c peerarrow.c -o peerarrow.exe
gcc -Wall  lib.c peerpaw.c -o peerpaw.exe
gcc -Wall  lib.c simple.c -o simple.exe
gcc -Wall  lib.c m2m.c -o m2m.exe

@pause