#!/usr/bin/env tclsh8.6

package require msgcat
namespace import ::msgcat::mc

# Sources
source ../scripts/version.tcl
source ../scripts/art.tcl
source ../scripts/utils.tcl
source ../scripts/model.tcl
source ../scripts/command.tcl
source ../scripts/dedit.tcl
source ../scripts/dedit_dia.tcl
source ../scripts/mainview.tcl
source ../scripts/smart_vertex.tcl
source ../scripts/icon.action.tcl
source ../scripts/icon.vertical.tcl
source ../scripts/icon.horizontal.tcl
source ../scripts/icon.if.tcl
source ../scripts/icon.links.tcl
source ../scripts/icon.beginend.tcl
source ../scripts/search.tcl
source ../scripts/graph.tcl
source ../scripts/auto.tcl
source ../scripts/back.tcl
source ../scripts/generators.tcl
source ../scripts/alt_edit.tcl
source ../scripts/colors.tcl
source ../scripts/graph2.tcl
source ../scripts/hie_engine.tcl
source ../scripts/highlight.tcl
source ../scripts/newfor.tcl
source ../structure/tables.tcl
source ../generators/c.tcl
source ../generators/tcl.tcl
source ../generators/node_sorter.tcl
source ../generators/cpp.tcl
source ../generators/nogoto.tcl
source ../generators/java.tcl
source ../generators/cs.tcl
source ../generators/machine.tcl
source ../structure/struct.tcl


# Test utilities and mocks
source utest_utils.tcl
source mwindow_dummy.tcl

# Tests
source utils_test.tcl
source model_test.tcl
source dedit_test.tcl
source mainview_test.tcl
source search_test.tcl
source extract_auto_test.tcl
source gen_test.tcl
source alt_test.tcl
source nogoto_test.tcl
source nogoto_src.tcl
source struct_c_test.tcl
source nogoto_test2.tcl
source algo2.tcl
source graph2_test.tcl
source hie_test.tcl
source table_test.tcl
source auto_test.tcl
source highlight_test.tcl

set script_path "../"
set use_log 0

namespace eval mwf {
	proc reset {} {
	}
}

load_sqlite

if { [ llength $argv ] == 1 } {
  set test [ lindex $argv 0 ]
  testone $test
} else {
  testmain
}



puts ""
puts "success"
