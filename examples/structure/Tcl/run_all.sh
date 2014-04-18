../../../drakon_gen.tcl -in 01-simple-tcl.drn
../../../drakon_gen.tcl -in 02-index-tcl.drn
../../../drakon_gen.tcl -in 03-index2-tcl.drn
../../../drakon_gen.tcl -in 04-peer-arrow-tcl.drn
../../../drakon_gen.tcl -in 05-own-arrow-tcl.drn
../../../drakon_gen.tcl -in 06-peer-paw-tcl.drn
../../../drakon_gen.tcl -in 07-own-paw-tcl.drn
../../../drakon_gen.tcl -in 08-m2m-tcl.drn
../../../drakon_gen.tcl -in 09-inherit-tcl.drn
../../../drakon_gen.tcl -in 10-inherit2-tcl.drn
echo "Build completed. Running tests..."
tclsh 01-simple-tcl.tcl
tclsh 02-index-tcl.tcl
tclsh 03-index2-tcl.tcl
tclsh 04-peer-arrow-tcl.tcl
tclsh 05-own-arrow-tcl.tcl
tclsh 06-peer-paw-tcl.tcl
tclsh 07-own-paw-tcl.tcl
tclsh 08-m2m-tcl.tcl
tclsh 09-inherit-tcl.tcl
tclsh 10-inherit2-tcl.tcl
echo "Tests completed."