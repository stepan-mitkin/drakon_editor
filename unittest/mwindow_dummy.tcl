
namespace eval mwf {

proc get_dia_font { zoom } {
	return main_font
}

}

namespace eval mw {

variable current_name ""

variable canvas_width 200
variable canvas_height 100


variable current_dia ""
variable undo ""
variable redo ""
variable view_pos

### Mock-only methods

proc init_mock { } {
	variable diagram_list
	variable current_dia
	variable undo
	variable redo
	variable view_pos
	
	set mtree::current ""
	
	set diagram_list {}
	set current_dia ""
	set undo ""
	set redo ""
	set view_pos { 0 0 }
}

proc get_diagrams_mock { } {
	variable diagram_list
	return $diagram_list
}

proc get_undo_mock { } {
	variable undo
	return $undo
}

proc get_redo_mock { } {
	variable redo
	return $redo
}

proc get_scroll_mock { } {
	variable view_pos
	return $view_pos
}

### Undo / Redo ###

proc enable_undo { name } {
	variable undo
	set undo $name
}

proc disable_undo { } {
	variable undo
	set undo ""
}

proc enable_redo { name } {
	variable redo
	set redo $name
}

proc disable_redo {  } {
	variable redo
	set redo ""
}

### Used from dedit ###

proc set_status { status } {
}


proc measure_text { text } {
	set lines [ split $text "\n" ]
	set max_width 0
	foreach line $lines {
		set chars [ string length $line ]
		set width [ expr { $chars * 6 } ]
		if { $width > $max_width } {
			set max_width $width
		}
	}
	set line_count [ llength $lines ]
	if { $line_count == 0 } { set line_count 1 }
	set height [ expr { 20 * $line_count } ]
	return [ list $max_width $height ]
}


proc select_dia_kernel { diagram_id hard } {
	select_dia $diagram_id 1
	mv::fill $diagram_id
}

proc select_dia { diagram_id replay } {
	set node_id [ mwc::get_diagram_node $diagram_id ]
	mtree::select $node_id
	
	mwc::fetch_view
	mv::fill $diagram_id
}

proc unselect_dia_ex { ignored replay } {
	unselect_dia foo bar
}

proc unselect_dia { ignored replay } {
	mv::clear
	mtree::deselect
}

proc scroll { scr replay } {
	variable view_pos
	if { $replay } {
		set view_pos $scr
	}
}

proc set_diagrams { diagrams } {
	variable diagram_list
	variable current_dia
	set diagram_list [ lsort -dictionary $diagrams ]
	set current_dia ""
}

}

namespace eval mtree {

variable current ""

proc select { external_id } {
	variable current
	set current $external_id
}

proc deselect {} {
	variable current
	set current ""
}

proc add_item { parent_id type text external_id } {
}

proc rename_item { external_id new_text } {

}

proc remove_item { external_id } {
	variable current

	if { $external_id == $current } {
		set current ""
	}
}

proc get_selection { } {
	variable current
	if { $current == "" } { return {} }
	return [ list $current ]	
}

}

namespace eval ui {

variable wrong ""
variable old
variable new
variable state
variable callback

proc init_mock { } {
	variable wrong
	variable old
	variable new
	variable state
	variable callback
	
	set wrong ""
	set old ""
	set new ""
	set state ""
	set callback ""
}

proc complained_mock { } {
	variable wrong
	return $wrong
}

proc complain { message } {
	variable wrong
	set wrong $message
}

}

namespace eval insp {

proc current { } {
	set vx [ lindex $mw::view_pos 0 ]
	set vy [ lindex $mw::view_pos 1 ]
	set x [ expr { $mw::canvas_width / 2 + $vx} ]
	set y [ expr { $mw::canvas_height / 2 + $vy } ]
	return [ list $x $y ]
}

}
