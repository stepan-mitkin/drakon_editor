
namespace eval jumpto {

array set diagrams {}

variable name_edit ""
variable name ""
variable window <bad-window>
variable visible {}
variable callback ""

proc init { win data } {
	variable name_edit
	variable callback
	
	set title [ dict get $data title ]
	set callback [ dict get $data callback ]
	
	wm title $win $title
	
	set root [ ttk::frame $win.root -padding "5 0 5 0" ]

	set name_edit [ ttk::entry $root.name -textvariable jumpto::name -width 40 -validate key -validatecommand { jumpto::name_changed %P } ]
	set listbox [ mw::create_listbox $root.list jumpto::visible ]	
	set butt_panel [ ttk::frame $root.buttons ]
	set ok [ ttk::button $butt_panel.ok -command jumpto::ok -text [ mc2 "Ok" ] ]
	set cancel [ ttk::button $butt_panel.cancel -command jumpto::close -text [ mc2 "Cancel" ] ]

	pack $root -expand yes -fill both
	
	pack $root.name -fill x -padx 5 -pady 10
	pack $root.list -fill both -expand yes
	pack $butt_panel -fill x

	pack $cancel -padx 10 -pady 10 -side right	
	pack $ok -padx 10 -pady 10 -side right

	

	bind $win <Return> jumpto::ok
	bind $win <Escape> jumpto::close
	bind $root.name <KeyPress-Down> [ list jumpto::moved_to_list $listbox ]
	bind $listbox <<ListboxSelect>> { jumpto::selected %W }
	bind $listbox <Double-ButtonPress-1> jumpto::ok	

	focus $root.name
}

proc name_changed { new } {
	variable visible
	
	if { $new == "" } {
		set visible [ get_all ]
	} else {
		set visible [ get_matching $new ]
	}

	return 1
}

proc moved_to_list { listbox } {
	variable visible
	focus $listbox
	if { [ llength $visible ] > 0 } {
		mw::select_listbox_item $listbox 0
		selected $listbox
	}
}

proc selected { listbox } {
	variable name
	variable visible
	
	set current [ $listbox curselection ]
	if { $current == "" } { return }
	
	set name [ lindex $visible $current ]
}

proc go_to_branch { branches } {
	set title [ mc2 "Go to branch" ]
	set action jumpto::goto_branch_callback
	
	goto_dialog_impl $branches $title $action
}

proc goto_branch_callback { branch_name } {
	variable name
	variable diagrams
	if { $branch_name == "" } {
		return [ mc2 "Branch '\$name' not found." ]
	}
	
	set item_id $diagrams($branch_name)
	
	mwc::switch_to_item $item_id
	return ""
}


proc goto_dialog { dia_names_to_ids } {
	set title [ mc2 "Go to diagram" ]
	set action jumpto::goto_diagram_callback
	
	goto_dialog_impl $dia_names_to_ids $title $action
}

proc goto_diagram_callback { diagram_name } {
	variable name
	if { $diagram_name == "" } {
		return [ mc2 "Diagram '\$name' not found." ]
	}
	
	set diagram_id [ mwc::get_dia_id $diagram_name ]
	mwc::switch_to_dia $diagram_id
	return ""
}


proc goto_dialog_impl { dia_names_to_ids title action } {
	variable diagrams
	variable window
	variable name
	variable visible
	variable name_edit
	
	array unset diagrams
	array set diagrams $dia_names_to_ids
	
	set data [ list title $title callback $action ]

	set window .jump_to
	set name ""
	set visible [ get_all ]
	
	ui::modal_window $window jumpto::init $data
	focus $name_edit
}

proc get_all { } {
	variable diagrams
	return [ lsort -dictionary [ array names diagrams ] ]
}

proc get_matching { substring } {
	set needle [ string tolower $substring ]
	set all [ get_all ]
	set result {}
	
	foreach name $all {
		set current [ string tolower $name ]
		if { [ string first $needle $current ] != -1  } {
			lappend result $name
		}
	}
	
	return $result
}

proc find_equal { name } {
	variable diagrams
	foreach diagram_name [ array names diagrams ] {
		if { [ string equal -nocase $name $diagram_name ] } {
			return $diagram_name
		}
	}
	return ""
}

proc close { } {
	variable window
	destroy $window
}



proc ok { } {
	variable window
	variable name
	variable callback
	set diagram_name [ find_equal $name ]
	
	set error_message [ $callback $diagram_name ]
	if { $error_message != "" } {
		tk_messageBox -message $error_message -type ok -parent $window
		return	
	}
	
	set diagram_id [ mwc::get_dia_id $diagram_name ]
	mwc::switch_to_dia $diagram_id
	
	destroy $window
}


}
