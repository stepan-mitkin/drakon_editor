#!/usr/bin/tclsh

package require Tk

proc unpack { list args } {
	set i 0
	foreach arg $args {
		set varname v$i
		upvar $arg $varname
		set $varname [ lindex $list $i ]
		incr i
	}
}

source tree.tcl

set  script_path .
set last 1111
array set items_map {}

proc get_type { id } {
	global items_map
	set item $items_map($id)
	return [ lindex $item 0 ]
}

proc get_parent { id } {
	global items_map
	set item $items_map($id)
	return [ lindex $item 1 ]	
}

proc remember { id type parent } {
	puts $id
	global items_map
	set item [ list $type $parent ]
	set items_map($id) $item
}

proc forget { id } {
	global items_map
	unset items_map($id)	
}

proc get_current { } {
	set selection [ mtree::get_selection ]
	if { [ llength $selection ] == 0 } { return 0 }
	return [ lindex $selection 0 ]
}

proc add_item { } {
	add_item_kernel "item"
}

proc add_item_kernel { item_type } {
	global name
	global last
	global items_map
	incr last
	set current [ get_current ]
	if { $current == 0 } {
		set parent 0
	} else {
		set type [ get_type $current ]
		if { $type == "folder" } {
			set parent $current
		} else {
			set parent [ get_parent $current ]
		}
	}
	remember $last $item_type $parent
	mtree::add_item $parent $item_type $name $last
}

proc add_folder { } {
	add_item_kernel "folder"
}

proc delete { } {
	foreach id [ mtree::get_selection ] {
		forget $id
		mtree::remove_item $id
	}
}

proc select { } {
	global id
	if { $id != "" } {
		mtree::select [ string trim $id ]
	}
}

proc deselect { } {
	mtree::deselect
}

proc clear { } {
	mtree::clear
}

proc rename {} {
	global name
	set selection [ mtree::get_selection ]
	set first [ lindex $selection 0 ]
	if { $first == "" } { return }
	mtree::rename_item $first $name
}

proc selection_changed { } {
	global ids
	set ids [ mtree::get_selection ]
}

set name ""
set ids ""
set id ""



wm title . "TreeView test"

ttk::frame .root -padding "0 0 0 0"
ttk::entry .root.name -textvariable name
ttk::button .root.item -text "Add item" -command add_item
ttk::button .root.folder -text "Add folder" -command add_folder
ttk::button .root.rename -text "Rename" -command rename
ttk::button .root.delete -text "Delete" -command delete
ttk::entry .root.id -textvariable id
ttk::button .root.select -text "Select" -command select
ttk::button .root.deselect -text "Deselect" -command deselect
ttk::button .root.clear -text "Clear" -command clear
ttk::entry .root.ids -textvariable ids
set tree [ mtree::create .root.tree selection_changed ]


pack .root -fill both -expand yes
pack .root.name -padx 10 -pady 10 -fill x
pack .root.item -padx 10 -pady 10
pack .root.folder -padx 10 -pady 10
pack .root.rename
pack .root.delete -padx 10 -pady 10 -fill x
pack .root.id -padx 10 -pady 10 -fill x
pack .root.select -padx 10 -pady 10
pack .root.deselect -padx 10 -pady 10
pack .root.clear -padx 10 -pady 10
pack .root.ids -padx 10 -pady 10 -fill x
pack .root.tree  -fill both -expand yes