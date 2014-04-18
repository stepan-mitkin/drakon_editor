#!/usr/bin/env bash

../drakon_gen.tcl -in ../examples/Tcl/tcl_demo.drn
../drakon_gen.tcl -in ../examples/Python/python_demo.drn
../drakon_gen.tcl -in ../examples/C/c_demo.drn
../drakon_gen.tcl -in ../examples/C++/cpp_demo.drn
../drakon_gen.tcl -in ../examples/C++/StringList.drn

gcc -Wall ../examples/C/c_demo.c -o ../tmp/c_demo
g++ -Wall ../examples/C++/cpp_demo.cpp ../examples/C++/StringList.cpp -o ../tmp/cpp_demo

../tmp/cpp_demo
../tmp/c_demo
../examples/Tcl/tcl_demo.tcl
../examples/Python/python_demo.py
