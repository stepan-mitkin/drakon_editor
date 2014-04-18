
namespace eval ui {

variable ib_userinput ""
variable ib_window ""
variable ib_callback ""
variable ib_olduserdata ""
variable ib_textbox

proc foreground_win { w } {
 #  wm withdraw $w
 #  wm deiconify $w
   update
   focus -force $w
}

proc get_window_start {  } {

	set rect [ get_window_rect . ]
	lassign $rect left top
	
	set my_left [ expr { $left + 200 } ]
	set my_top [ expr { $top + 100 } ]
	
	return "+$my_left+$my_top"
}

proc center_window_resize { window width height } {

	catch { tkwait visibility $window }
	set crect [ get_window_rect $window ]
	lassign $crect cleft ctop cwidth cheight
	
	set rect [ get_window_rect . ]
	lassign $rect left top
	
	set my_left [ expr { $left + 200 } ]
	set my_top [ expr { $top + 100 } ]
		
	set geom [ make_geometry $my_left $my_top $width $height ]
	wm geometry $window $geom
}



proc modal_window { window init data { parent "" } } {
	# create window
	toplevel $window

	# set the window origin near the main window top-left corner
	set origin [ get_window_start ]
	wm geometry $window $origin
		
	# run the callback that fills the window with widgets
	$init $window $data

	# make this window a child of the main window
	wm transient $window .
	
	# wait until it is visible...
	catch { tkwait visibility $window }
	
	# now make it modal
	catch { grab $window }
	
	# raise the window up
   	update
   	focus -force $window
}

proc make_geometry { left top width height } {
	return [ join [ list $width x $height + $left + $top ] "" ]
}

proc get_window_rect { window } {
	set left 0
	set top 0
	set geom [wm geometry $window]
	scan $geom "%dx%d+%d+%d" width height left top
	return [ list $left $top $width $height ]
}

proc init_inputbox { window data } {

	variable ib_userinput
	variable ib_window
	variable ib_callback
	variable ib_olduserdata
	variable ib_textbox
	
	set ib_window $window
	set title [ lindex $data 0 ]
	set ib_userinput [ lindex $data 1 ]
	set ib_callback [ lindex $data 2 ]
	set ib_olduserdata [ lindex $data 3 ]
	
	wm title $window $title
	
	ttk::frame $window.root
	
	grid $window.root -column 0 -row 0 -sticky nwse
	grid columnconfigure $window 0 -weight 1
	grid rowconfigure $window 0 -weight 1	
	
	set ib_textbox [ ttk::entry $window.root.entry -textvariable ui::ib_userinput ]
	ttk::button $window.root.ok -text [ mc2 "Ok" ] -command ui::ib_ok
	
	ttk::button $window.root.cancel -text [ mc2 "Cancel" ] -command ui::ib_close
	
	grid columnconfigure $window.root 2 -weight 1 -minsize 50
	
	grid $window.root.entry -row 1 -column 1 -sticky we -columnspan 3 -padx 5 -pady 5
	grid $window.root.ok -row 2 -column 1 -padx 10 -pady 10
	grid $window.root.cancel -row 2 -column 3 -padx 10 -pady 10
	
	bind $window <Return> ui::ib_ok
	bind $window <Escape> ui::ib_close
	
	bind_entry_win_copypaste $window.root.entry
	
	focus $window.root.entry
}

proc input_box { title old callback data } {
	variable ib_textbox
	modal_window .input init_inputbox [ list $title $old $callback $data ] .
	focus $ib_textbox
}

proc ib_close { } {
	variable ib_window
	destroy $ib_window
}

proc ib_ok { } {
	variable ib_userinput
	variable ib_callback
	variable ib_olduserdata
	set new_value [ string trim $ib_userinput ]
	if { $new_value == "" } return
	set error [ $ib_callback $ib_olduserdata $new_value ]
	if { $error != "" } {
	    tk_messageBox -message $error -parent .input
	    return
	}
	ib_close
}

proc wait_for_main { } {
	catch { tkwait visibility . }
}

proc complain { message { parent .input } } {
	tk_messageBox -type ok -message $message -parent $parent
}

proc is_mac { } {
	global tcl_platform
	if { $tcl_platform(os) == "Darwin" } {
		return 1
	}
	return 0
}

proc is_windows { } {
	global tcl_platform
	if { $tcl_platform(platform) == "windows" } {
		return 1
	}
	return 0
}

}
