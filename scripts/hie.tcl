namespace eval hie {

variable win .hie
variable inversed 0
variable tree ""

variable roots_id ""
variable leafs_id ""
variable all_id ""

variable recursion ""

array set id_map {}

proc show_window { } {
	variable tree
	variable win
	variable recursion
	
if { [ catch {


	toplevel $win
	
	wm title $win [ mc2 "Call hierarchy" ]

	set root [ ttk::frame $win.root -padding "5 0 5 0" ]
	pack $root -expand yes -fill both
		
	
	set regen [ ttk::button $root.regen -command hie::rebuild -text [ mc2 "Regenerate" ] ]

	
	set inv [ ttk::checkbutton $root.inv -variable hie::inversed -text [ mc2 "Inversed" ] ]

	
	set tree_panel $root.tree_panel
	set tree [ create_tree $tree_panel hie::on_select ]
	pack $tree_panel -expand yes -fill both
	

	set close [ ttk::button $root.close -command hie::close -text [ mc2 "Close" ] ]
	pack $regen -side left -padx 10 -pady 10	
	pack $inv -side left -pady 10	
	pack $close -side right -padx 20 -pady 10
	
	
	if { $recursion == "" } {
		global script_path
		set file $script_path/images/recursion.gif
		set recursion [ image create photo -format GIF -file $file ]
	}

	
	} ex ] } {
		puts $ex
		puts $::errorInfo
	}
}

proc close { } {
	variable win
	destroy $win
}

proc show { } {
	variable win
	if { [ catch { raise $win } ] } {
		show_window
	}
	rebuild
}

proc clear { } {
	variable tree
	clear_array hie::id_map
	clear_tree $tree ""	
}

proc rebuild {} {
	variable tree
	variable roots_id
	variable leafs_id
	variable all_id
	variable inversed
	
	clear
	
	if { [ catch {
		hie_engine::build.graph
	} ex ] } {
		puts $ex
		puts $::errorInfo
	}
	
	if { $inversed } {
		set leafs_id [ $tree insert "" 1 -text [ mc2 "Leafs"  ] ]
		set leafs [ hie_engine::get.leafs ]		
		add_items $leafs_id $leafs 1		
	} else {
		set roots_id [ $tree insert "" 0 -text [ mc2 "Roots"  ] ]
		set roots [ hie_engine::get.roots ]	
		add_items $roots_id $roots 1		
	}

	set all_id [ $tree insert "" 2 -text [ mc2 "All"  ] ]	
	set all [ hie_engine::get.all ]
	add_items $all_id $all 1
}

proc add_items { parent ids expand } {
	variable id_map
	variable tree
	
	set children [ $tree children $parent ]
	if { $children != {} } { return }

	
	set sorted [ sort_by_name $ids ]
	foreach diagram_id $sorted {
		set id [ add_item $parent $diagram_id ] 
		if { $expand } {
			set children [ get_children $diagram_id ]
			add_items $id $children 0
		}
	}		
}

proc add_item { parent diagram_id } {
	variable id_map
	variable tree
	variable recursion
	
	set name [ hie_engine::get.name $diagram_id ]
	
	if { [ already_visited $parent $diagram_id ] } {
		set id [ $tree insert $parent end -text $name -image $recursion ] 
	} else {
		set id [ $tree insert $parent end -text $name ] 
	}
	
	set id_map($id) $diagram_id
	
	return $id
}

proc already_visited { id diagram_id } {
	variable id_map
	variable tree
	
	if { $id == "" } { return 0 }
	if { [ info exists id_map($id) ] } {
		set dia $id_map($id)
		if { $dia == $diagram_id } { return 1 }
		set parent [ $tree parent $id ]
		return [ already_visited $parent $diagram_id ]
	}
	
	return 0
}

proc get_children { diagram_id } {
	variable inversed
	if { $inversed } {
		return [ hie_engine::get.back $diagram_id ]
	} else {
		return [ hie_engine::get.called $diagram_id ]
	}
}

proc sort_by_name { ids } {
	array set name_to_id {}
	set names {}
	foreach id $ids {
		set name [ hie_engine::get.name $id ]
		set name_to_id($name) $id
		lappend names $name
	}
	
	set sorted [ lsort $names ]
	set output {}
	foreach name $sorted {
		lappend output $name_to_id($name)
	}
	return $output
}

proc expand { } {
	variable id_map
	variable tree
	variable roots_id
	variable leafs_id
	variable all_id
	
	set current [ $tree focus ]

	if { $current == {} } { return 0 }
	if { $current == $roots_id || $current == $leafs_id || $current == $all_id } { return 0 }
	set children [ $tree children $current ]
	foreach child $children {
		set diagram_id $id_map($child)
		set ids [ get_children $diagram_id ]
		add_items $child $ids 1
	}
	return 1
}

proc on_select { } {
	variable tree
	variable id_map
	
	if { ![expand] } { return }
	
	set current [ $tree focus ]
	set diagram_id $id_map($current)
	mwc::switch_to_dia $diagram_id
}

proc create_tree { name on_select } {

	set tree $name.treeview
	set ver $name.ver
	set hor $name.hor
	
	ttk::frame $name
	ttk::scrollbar $ver -command "$tree yview" -orient vertical
	ttk::scrollbar $hor -command "$tree xview" -orient horizontal
	ttk::treeview $tree -selectmode browse -show tree -yscrollcommand "$ver set" -xscrollcommand "$hor set"
	
	grid columnconfigure $name 1 -weight 1
	grid rowconfigure $name 1 -weight 1	
	grid $tree -row 1 -column 1 -sticky nswe
	grid $ver -row 1 -column 2 -sticky ns
	grid $hor -row 2 -column 1 -sticky we

	
	bind $tree <<TreeviewSelect>> $on_select
	#bind $tree  <ButtonPress-1>  { mtree::p.on_left_click %x %y }
	return $tree
}


}
