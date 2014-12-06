#!/bin/bash

mkdir release
cd release
cp -r ../fonts .
cp -r ../scripts .
cp -r ../testdata .
cp -r ../unittest .
cp -r ../pdf4tcl07 .
cp -r ../images .
cp -r ../examples .
cp -r ../generators .
cp -r ../structure .
cp -r ../msgs .
cp -r ../docs .
rm docs/DRAKON.pdf
mkdir tmp
cp ../drakon_editor.tcl .
cp ../drakon_gen.tcl .
cp ../readme.html .
zip -r ../drakon_editor1.25_rus.zip *
cd ..
rm -rf release