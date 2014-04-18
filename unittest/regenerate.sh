#!/usr/bin/env bash

../drakon_gen.tcl -in ../generators/c.drn
../drakon_gen.tcl -in ../generators/cpp.drn
../drakon_gen.tcl -in ../generators/cs.drn

../drakon_gen.tcl -in ../generators/cycle_body.drn
../drakon_gen.tcl -in ../generators/java.drn
../drakon_gen.tcl -in ../generators/lua.drn


../drakon_gen.tcl -in ../generators/node_sorter.drn
../drakon_gen.tcl -in ../generators/nogoto.drn
../drakon_gen.tcl -in ../generators/python.drn
../drakon_gen.tcl -in ../generators/machine.drn


../drakon_gen.tcl -in ../scripts/alt_edit.drn
../drakon_gen.tcl -in ../scripts/graph2.drn

../drakon_gen.tcl -in ../structure/struct.drn
../drakon_gen.tcl -in ../structure/tables.drn
../drakon_gen.tcl -in ../structure/tables_tcl.drn

../drakon_gen.tcl -in nogoto_src.drn
../drakon_gen.tcl -in erltest.drn
../drakon_gen.tcl -in algo2.drn
