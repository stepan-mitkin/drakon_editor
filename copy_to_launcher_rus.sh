#!/bin/bash

rm -rf DRAKONEditor/tcl
mkdir DRAKONEditor/tcl
cd DRAKONEditor/tcl

cp -r ../../fonts .
cp -r ../../scripts .
cp -r ../../pdf4tcl07 .
cp -r ../../images .
cp -r ../../generators .
cp -r ../../structure .
cp -r ../../msgs .
cp ../../drakon_editor.tcl .

cd ../..