
namespace eval recent {

array set diagrams {}


variable name ""
variable window <bad-window>
variable files {}

proc init { win data } {

	wm title $win [ mc2 "Recently open files" ]
	
	set root [ ttk::frame $win.root -padding "5 0 5 0" ]

	set listbox [ mw::create_listbox $root.list recent::files ]	
	$listbox configure -width 80
	
	mw::make_alternate_lines $listbox
	
	set butt_panel [ ttk::frame $root.buttons ]
	set ok [ ttk::button $butt_panel.ok -command recent::ok -text Open ]
	set cancel [ ttk::button $butt_panel.cancel -command recent::close -text Cancel ]

	pack $root -expand yes -fill both
	
	pack $root.list -fill both -expand yes
	pack $butt_panel -fill x

	pack $cancel -padx 10 -pady 10 -side right	
	pack $ok -padx 10 -pady 10 -side right

	

	bind $win <Return> recent::ok
	bind $win <Escape> recent::close
	bind $listbox <<ListboxSelect>> { recent::selected %W }
	bind $listbox <Double-ButtonPress-1> recent::ok	

	focus $listbox
}



proc selected { listbox } {
	variable name
	variable files
	
	set current [ $listbox curselection ]
	if { $current == "" } { return }
	
	set name [ lindex $files $current ]
}

proc recent_files_dialog { } {
	variable window
	variable name
	variable files
	
	set window .recent
	set name ""
	set all_files [ app_settings::get_recent_files drakon_editor ]
	set files [ lrange $all_files 1 end ]
	
	ui::modal_window $window recent::init foo
}


proc close { } {
	variable window
	destroy $window
}

proc ok { } {

	variable window
	variable name
	
	
	if { $name != "" } {
		mod::close [ mwc::get_db ]
		if { ![ ds::openfile $name ] } { 
			tk_messageBox -message [ mc2 "Error opening file: \$name" ] -parent $window
			exit 1
		}	
	}
	
	destroy $window
}


}
