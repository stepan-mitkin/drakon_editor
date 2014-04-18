#!/usr/bin/tclsh

# A stub to test mwindow.tcl

package require Tk


source utils.tcl
source mwindow.tcl
source inputbox.tcl

namespace eval mwc {

proc hover { args } {
	puts hover:$args
}

proc ldown { args } {
	puts ldown:$args
}

proc lmove { args } {
	puts lmove:$args
}

proc lup { args } {
	puts lup:$args
}

proc rclick { args } {
	puts rclick:$args
}


proc action { } {
	puts action
}

proc beginend { } {
	puts beginend
}

proc if { } {
	puts if
}

proc select { } {
	puts select
}

proc case { } {
	puts case
}

proc branch { } {
	puts branch
}

proc address { } {
	puts address
}

proc vertical { } {
	puts vertical
}

proc horizontal { } {
	puts horizontal
}

proc arrow { } {
	puts arrow
}

proc parameters { } {
	puts parameters
}

proc commentin { } {
	puts commentin
}

proc commentout { } {
	puts commentout
}

proc new_dia { } {
	puts new_dia
}

proc undo { } {
	puts undo
}

proc redo { } {
	puts redo
}

proc delete_dia { } {
	puts "delete_dia: [ mw::get_current_dia ]"
}


proc do_rename_dia { old new } {
	puts "renaming dia '$old' to '$new'"
}

proc rename_dia { } {
	set old [ mw::get_current_dia ]
	inputbox "Rename diagram" $old mwc::do_rename_dia $old
}

proc current_dia_changed {} {
	set current [ mw::get_current_dia ]
	puts "Current dia changed: $current"
}

proc dia_properties { } {
	puts "dia properties"
}

proc create_file { } {
	puts create_file
}

proc open_file { } {
	puts open_file
}


proc save_as { } {
	puts save_as
}


}


mw::create_ui

set dias {}

for { set i 0 } { $i < 30 } { incr i } {
	lappend dias "MegaDiagram No. $i"
}

mw::set_dia_list $dias
mw::set_current_dia "MegaDiagram No. 3"

