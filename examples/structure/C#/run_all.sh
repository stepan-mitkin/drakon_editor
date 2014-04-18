rm 01-simple-cs.cs
rm 01-simple-cs.exe
rm 02-index-cs.cs
rm 02-index-cs.exe
rm 03-index2-cs.cs
rm 03-index2-cs.exe
rm 04-peer-arrow-cs.cs
rm 04-peer-arrow-cs.exe
rm 05-own-arrow-cs.cs
rm 05-own-arrow-cs.exe
rm 06-peer-paw-cs.cs
rm 06-peer-paw-cs.exe
rm 07-own-paw-cs.cs
rm 07-own-paw-cs.exe
rm 08-m2m-cs.cs
rm 08-m2m-cs.exe
rm  09-inherit-cs.cs
rm  09-inherit-cs.exe
rm 10-inherit2-cs.cs
rm 10-inherit2-cs.exe
rm 11-oop-cs.cs
rm 11-oop-cs.exe
../../../drakon_gen.tcl -in 01-simple-cs.drn
../../../drakon_gen.tcl -in 02-index-cs.drn 
../../../drakon_gen.tcl -in 03-index2-cs.drn 
../../../drakon_gen.tcl -in 04-peer-arrow-cs.drn 
../../../drakon_gen.tcl -in 05-own-arrow-cs.drn 
../../../drakon_gen.tcl -in 06-peer-paw-cs.drn 
../../../drakon_gen.tcl -in 07-own-paw-cs.drn 
../../../drakon_gen.tcl -in 08-m2m-cs.drn 
../../../drakon_gen.tcl -in 09-inherit-cs.drn 
../../../drakon_gen.tcl -in 10-inherit2-cs.drn 
../../../drakon_gen.tcl -in 11-oop-cs.drn
echo ""
echo "Build completed. Compiling..."
mcs 01-simple-cs.cs
mcs 02-index-cs.cs
mcs 03-index2-cs.cs
mcs 04-peer-arrow-cs.cs 
mcs 05-own-arrow-cs.cs 
mcs 06-peer-paw-cs.cs 
mcs 07-own-paw-cs.cs 
mcs 08-m2m-cs.cs 
mcs 09-inherit-cs.cs 
mcs 10-inherit2-cs.cs
mcs 11-oop-cs.cs
echo ""
echo "Compile completed. Running tests..."
mono 01-simple-cs.exe
mono 02-index-cs.exe
mono 03-index2-cs.exe
mono 04-peer-arrow-cs.exe
mono 05-own-arrow-cs.exe
mono 06-peer-paw-cs.exe
mono 07-own-paw-cs.exe
mono 08-m2m-cs.exe
mono 09-inherit-cs.exe
mono 10-inherit2-cs.exe
mono 11-oop-cs.exe
echo "Tests completed."
