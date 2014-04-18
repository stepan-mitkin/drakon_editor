
namespace eval mtree {

array set images {}

variable tree
array set extids_to_items {}
array set ids_to_items {}
variable folder_icon ""
variable item_icon ""

proc p.compare_items { type1 text1 type2 text2 } {
	if { $type1 == $type2 } {
		return [ string compare $text2 $text1 ]
	} else {
		if { $type1 == "folder" } {
			return 1
		} elseif { $type2 == "folder" } {
			return -1
		} elseif { $type1 == "data" } {
			return 1
		} else {
			return -1
		}
	}
}

proc p.get_ordered_position { treeview parent type text { item_id "" } } {
	variable ids_to_items

	set i 0
	set children [ $treeview children $parent ]
	foreach child $children {
		if { $item_id == $child } { continue }
		lassign $ids_to_items($child) ctype ctext
		
		if { [ p.compare_items $type $text $ctype $ctext ] >= 0 } {
			break
		}
		incr i
	}
	return $i
}

proc p.get_icon { name } {
	variable images
	global script_path
	
	if { ![ info exists images($name) ] } {
		set file $script_path/images/$name.gif
		set images($name) [ image create photo -format GIF -file $file ]
	}
	
	return $images($name)
}


proc p.get_folder_icon { } {
	return [ p.get_icon "folder" ]
}

proc p.get_data_icon { } {
	return [ p.get_icon "structure" ]
}

proc p.get_item_icon { } {
	return [ p.get_icon "diagram" ]
}


proc map.rename { external_id new_text } {
	variable extids_to_items
	variable ids_to_items
	set item $extids_to_items($external_id)
	lassign $item type foo bar item_id
	map.remember_item $type $new_text $external_id $item_id
}

proc map.get_external_id { item_id } {
	variable ids_to_items
	set item $ids_to_items($item_id)
	return [ lindex $item 2 ]
}

proc map.get_item_id { external_id } {
	variable extids_to_items
	set item $extids_to_items($external_id)
	return [ lindex $item 3 ]
}

proc map.get_type { external_id } {
	variable extids_to_items
	set item $extids_to_items($external_id)
	return [ lindex $item 0 ]
}

proc map.remember_item { type text external_id item_id } {
	variable extids_to_items
	variable ids_to_items
	set item [ list $type $text $external_id $item_id ]
	set extids_to_items($external_id) $item
	set ids_to_items($item_id) $item
}

proc map.forget_item { external_id } {
	variable extids_to_items
	variable ids_to_items
	
	set item_id [ map.get_item_id $external_id ]
	unset extids_to_items($external_id)
	unset ids_to_items($item_id)
}

proc map.clear { } {
	clear_array mtree::extids_to_items
	clear_array mtree::ids_to_items
}

proc map.exists { external_id } {
	variable extids_to_items
	return [ info exists extids_to_items($external_id) ] 	
}

proc remove_line_break { text } {
	return [ string map {"\n" " "} $text ]
}

proc add_item { parent_id type text external_id } {
	variable tree

	if { $parent_id == 0 } {
		set parent_item ""
	} else {
		set parent_item [ map.get_item_id $parent_id ]
	}
	
	set index [ p.get_ordered_position $tree $parent_item $type $text ]
	
	set text2 [ remove_line_break $text ]
	if { $type == "folder" } {
		set image [ p.get_folder_icon ]
		set id [ $tree insert $parent_item $index -text $text2 -open yes -image $image ]
	} elseif { $type == "item" } {
		set image [ p.get_item_icon ]
		set id [ $tree insert $parent_item $index -text $text2 -image $image ]
	} elseif { $type == "data" } {
		set image [ p.get_data_icon ]
		set id [ $tree insert $parent_item $index -text $text2 -image $image ]		
	} else {
		error "Bad item type: $type"
	}
	
	map.remember_item $type $text $external_id $id
	$tree see $id
}

proc rename_item { external_id new_text } {
	variable tree
	map.rename $external_id $new_text
	set item_id [ map.get_item_id $external_id ]
	set parent [ $tree parent $item_id ]
	set type [ map.get_type $external_id ]
	
	set index [ p.get_ordered_position $tree $parent $type $new_text $item_id ]
	
	set text2 [ remove_line_break $new_text ]
	$tree item $item_id -text $text2
	$tree move $item_id $parent $index
}

proc remove_item { external_id } {
	variable tree
	if { ![ map.exists $external_id ] } { return }
	set item_id [ map.get_item_id $external_id ]
	set children [ $tree children $item_id ]
	foreach child $children {
		set child_ext_id [ map.get_external_id $child ]
		remove_item $child_ext_id
	}
	map.forget_item $external_id
	$tree delete $item_id
}

proc get_selection { } {
	variable tree
	set selection [ $tree selection ]
	set result {}
	foreach selected $selection {
		lappend result [ map.get_external_id $selected ]
	}
	return $result
}

proc p.open_to_root { item_id } {
	variable tree
	$tree item $item_id -open yes
	set parent [ $tree parent $item_id ]
	if { $parent != "" } {
		p.open_to_root $parent
	}
}

proc select { external_id } {
	variable tree
	set item_id [ map.get_item_id $external_id ]
	$tree selection set $item_id
	$tree focus $item_id
	$tree see $item_id
}

proc deselect {} {
	variable tree
	$tree selection set {}
}


proc create { name on_select } {
	variable tree
	
	map.clear
	set tree $name.treeview
	set ver $name.ver
	
	ttk::frame $name
	ttk::scrollbar $ver -command "$tree yview" -orient vertical
	ttk::treeview $tree -selectmode extended -show tree -yscrollcommand "$ver set"
	
	grid columnconfigure $name 1 -weight 1
	grid rowconfigure $name 1 -weight 1	
	grid $tree -row 1 -column 1 -sticky nswe
	grid $ver -row 1 -column 2 -sticky ns

	
	bind $tree <<TreeviewSelect>> $on_select
	bind $tree  <ButtonPress-1>  { mtree::p.on_left_click %x %y }
	return $tree
}

proc clear { } {
	variable tree
	map.clear
	clear_tree $tree ""
}

proc p.on_left_click { x y } {
	variable tree
	set hit_item [ $tree identify row $x $y ]
	if { $hit_item == "" } {
		deselect
	}
}

proc has_items { } {
	variable tree
	set root_children [ $tree children "" ]
	set count [ llength $root_children ]
	return [ expr { $count > 0 } ]
}

proc collapse { } {
	variable tree
	foreach item_id [ $tree selection ] {
		p.collapse $item_id
	}
}

proc p.collapse { item_id } {
	variable tree

	foreach child [ $tree children $item_id ] {
		p.collapse $child
	}
	
	$tree item $item_id -open no
}

}

