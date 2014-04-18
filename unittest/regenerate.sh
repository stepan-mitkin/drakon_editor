#!/usr/bin/env bash

tclsh ../drakon_gen.tcl -in "../scripts/alt_edit.drn"
tclsh ../drakon_gen.tcl -in "../scripts/graph2.drn"
tclsh ../drakon_gen.tcl -in "../scripts/hie_engine.drn"
tclsh ../drakon_gen.tcl -in "../generators/AutoHotkey_L.drn"
tclsh ../drakon_gen.tcl -in "../generators/c.drn"
tclsh ../drakon_gen.tcl -in "../generators/cpp.drn"
tclsh ../drakon_gen.tcl -in "../generators/cs.drn"
tclsh ../drakon_gen.tcl -in "../generators/cycle_body.drn"
tclsh ../drakon_gen.tcl -in "../generators/java.drn"
tclsh ../drakon_gen.tcl -in "../generators/lua.drn"
tclsh ../drakon_gen.tcl -in "../generators/machine.drn"
tclsh ../drakon_gen.tcl -in "../generators/node_sorter.drn"
tclsh ../drakon_gen.tcl -in "../generators/nogoto.drn"
tclsh ../drakon_gen.tcl -in "../generators/python.drn"
tclsh ../drakon_gen.tcl -in "../generators/verilog.drn"
tclsh ../drakon_gen.tcl -in "../structure/struct.drn"
tclsh ../drakon_gen.tcl -in "../structure/tables.drn"
tclsh ../drakon_gen.tcl -in "../structure/tables_c.drn"
tclsh ../drakon_gen.tcl -in "../structure/tables_cs.drn"
tclsh ../drakon_gen.tcl -in "../structure/tables_tcl.drn"

tclsh ../drakon_gen.tcl -in nogoto_src.drn
tclsh ../drakon_gen.tcl -in erltest.drn
tclsh ../drakon_gen.tcl -in algo2.drn
