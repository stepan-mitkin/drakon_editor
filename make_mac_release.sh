#!/bin/bash

mkdir release
cd release
cp -r ../DRAKONEditor/build/Release/DRAKONEditor.app .
cp -r ../examples .
cp ../readme_mac.html readme.html
zip -r ../drakon_editor1.26_mac.zip *
cd ..
rm -rf release