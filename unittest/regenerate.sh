#!/usr/bin/env bash

tclsh8.6 ../drakon_gen.tcl -in "../scripts/alt_edit.drn"
tclsh8.6 ../drakon_gen.tcl -in "../scripts/graph2.drn"
tclsh8.6 ../drakon_gen.tcl -in "../scripts/hie_engine.drn"
tclsh8.6 ../drakon_gen.tcl -in "../generators/AutoHotkey_L.drn"
tclsh8.6 ../drakon_gen.tcl -in "../generators/c.drn"
tclsh8.6 ../drakon_gen.tcl -in "../generators/cpp.drn"
tclsh8.6 ../drakon_gen.tcl -in "../generators/cs.drn"
tclsh8.6 ../drakon_gen.tcl -in "../generators/cycle_body.drn"
tclsh8.6 ../drakon_gen.tcl -in "../generators/java.drn"
tclsh8.6 ../drakon_gen.tcl -in "../generators/lua.drn"
tclsh8.6 ../drakon_gen.tcl -in "../generators/machine.drn"
tclsh8.6 ../drakon_gen.tcl -in "../generators/node_sorter.drn"
tclsh8.6 ../drakon_gen.tcl -in "../generators/nogoto.drn"
tclsh8.6 ../drakon_gen.tcl -in "../generators/python.drn"
tclsh8.6 ../drakon_gen.tcl -in "../generators/verilog.drn"
tclsh8.6 ../drakon_gen.tcl -in "../structure/struct.drn"
tclsh8.6 ../drakon_gen.tcl -in "../structure/tables.drn"
tclsh8.6 ../drakon_gen.tcl -in "../structure/tables_c.drn"
tclsh8.6 ../drakon_gen.tcl -in "../structure/tables_cs.drn"
tclsh8.6 ../drakon_gen.tcl -in "../structure/tables_tcl.drn"

tclsh8.6 ../drakon_gen.tcl -in nogoto_src.drn
tclsh8.6 ../drakon_gen.tcl -in erltest.drn
tclsh8.6 ../drakon_gen.tcl -in algo2.drn
