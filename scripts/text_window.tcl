
namespace eval ui {

variable tw_window ""
variable tw_callback ""
variable tw_olduserdata ""
variable tw_text <bad-tw_text>
variable tw_state {}

proc tw_remember { } {
}

proc tw_restore { } {
}

proc create_tabs { n } {
  set result {}
  repeat i $n {
    set tab [ expr { $i * 4 + 1 } ]
    lappend result $tab
  }
  return $result
}

proc create_textbox { name  } {
	# Background frame
	frame $name -borderwidth 1 -relief sunken
	
	set text_path [ join [ list $name text ] "." ]
	set vscroll_path [ join [ list $name vscroll ] "." ]

	
	# Scrollbar.
	ttk::scrollbar $vscroll_path -command "$text_path yview" -orient vertical
	
	# Listbox.
	text $text_path -yscrollcommand "$vscroll_path set" -undo 1 -bd 0 -highlightthickness 0 -font main_font -wrap word 

	# Put the text and its scrollbar together.
	#pack $vscroll_path $text_path -expand yes -fill both -side right
	

	grid columnconfigure $name 1 -weight 1
	grid rowconfigure $name 1 -weight 1	
	grid $text_path -row 1 -column 1 -sticky nswe
	grid $vscroll_path -row 1 -column 2 -sticky ns

	return $text_path
}

proc noop { } { }

proc tw_init { window data } {

	variable tw_window
	variable tw_callback
	variable tw_olduserdata
	variable tw_text
	
	set tw_window $window
	set title [ lindex $data 0 ]
	set userinput [ lindex $data 1 ]
	set tw_callback [ lindex $data 2 ]
	set tw_olduserdata [ lindex $data 3 ]
	
	wm title $window $title
	
	ttk::frame $window.root
	
	grid $window.root -column 0 -row 0 -sticky nwse
	grid columnconfigure $window 0 -weight 1
	grid rowconfigure $window 0 -weight 1	
	
	set tw_text [ create_textbox $window.root.entry ]
	$tw_text insert 1.0 $userinput
	ttk::button $window.root.ok -text [ mc2 "Ok" ] -command ui::tw_ok
	if { [ ui::is_mac ] } {
		set hint [ mc2 "Command-Enter to save and close" ]
	} else {
		set hint [ mc2 "Control-Enter to save and close" ]
	}
	ttk::label $window.root.hint -text $hint
	ttk::button $window.root.cancel -text [ mc2 "Cancel" ] -command ui::tw_close
	
	grid columnconfigure $window.root 2 -weight 1 -minsize 50
	grid rowconfigure $window.root 1 -weight 1 -minsize 50
	
	grid $window.root.entry -row 1 -column 1 -sticky nwse -columnspan 3 -padx 5 -pady 5
	grid $window.root.ok -row 2 -column 1 -padx 10 -pady 10
	grid $window.root.hint -row 2 -column 2 -sticky w
	grid $window.root.cancel -row 2 -column 3 -padx 10 -pady 10
	
	mw::bind_shortcut $window ui::shortcut_handler
	
	if { [ is_mac ] } {
		bind $tw_text <Command-Return> { ui::tw_ok; break }
		bind $tw_text <Command-KeyPress> { ui::command_key  %W %K %N %k }
	} else {
		bind $tw_text <Control-Return> { ui::tw_ok; break }
	}
	
	bind_win_copypaste $tw_text
		
	bind $tw_text <ButtonRelease-2> { ui::noop; break }
	bind $tw_text <ButtonRelease-3> { ui::noop; break }
	
	bind $window <Escape> ui::tw_close
}

proc bind_win_copypaste { window } {
	if { [ is_mac ] } {
		bind $window <Command-KeyPress> { ui::win_command_key  %W %K %N %k }
	} else {
		bind $window <Control-KeyPress> { ui::win_command_key  %W %K %N %k }
	}
}

proc bind_entry_win_copypaste { window } {
	if { [ is_mac ] } {
		bind $window <Command-KeyPress> { ui::win_entry_command_key  %W %K %N %k }	
	} else {
		bind $window <Control-KeyPress> { ui::win_entry_command_key  %W %K %N %k }
	}		
}


proc win_command_key { window k n code } {
	variable tw_window
	switch $k {
		c {}
		C {}
		x {}
		X {}
		v {}
		V {}
		default {
			array set codes [ key_codes ]
			if { $code == $codes(x) } {
				tk_textCut $window
			} elseif { $code == $codes(c) } {
				tk_textCopy $window
			} elseif { $code == $codes(v) } {
				tk_textPaste $window
			} elseif { $code == $codes(a) } {
				$window tag add sel 1.0 end			
			}
		}		
	}

}

proc win_entry_command_key { window k n code } {
	variable tw_window
	switch $k {
		c {}
		C {}
		x {}
		X {}
		v {}
		V {}
		default {
			array set codes [ key_codes ]
			if { $code == $codes(x) } {
				entry_cut $window
			} elseif { $code == $codes(c) } {
				entry_copy $window
			} elseif { $code == $codes(v) } {
				entry_paste $window
			} elseif { $code == $codes(a) } {
				entry_all $window
			}			
		}		
	}

}

proc get_clipboard_text { } {
	if {[catch {clipboard get} contents]} {
		return ""
	}
	return $contents
}

proc set_clipboard_text { text } {
	clipboard clear
	clipboard append -type STRING -format UTF8_STRING -- $text
}

proc entry_all { window } {
	$window selection range 0 end
}

proc entry_cut { window } {
	if { ![ $window selection present ] } { return }
	set selected [ entry_get_selected_text $window ]
	set_clipboard_text $selected
	$window delete sel.first sel.last
}

proc entry_get_selected_text { window } {
	set begin [ $window index sel.first ]
	set end [ $window index sel.last ]
	incr end -1
	set all_text [ $window get ]
	set selected [ string range $all_text $begin $end ]
	return $selected
}

proc entry_copy { window } {
	if { ![ $window selection present ] } { return }
	set selected [ entry_get_selected_text $window ]
	set_clipboard_text $selected
}

proc entry_paste { window } {
	set text [ get_clipboard_text ]
	if { $text == "" } { return }
	if { [ $window selection present ] } {
		$window delete sel.first sel.last
	}
	$window insert insert $text
}


proc command_key { window k n code } {

	switch $k {
		Up {
			$window mark set insert 1.0
		}
		Down {
			$window mark set insert end
		}
		Left {
			$window mark set insert {insert linestart +1c}
		}
		Right {
			$window mark set insert {insert lineend -1c}
		}
	}
}

proc shortcut_handler { window code key } {
	variable tw_text
	array set codes [ ui::key_codes ]
	set selection [ $tw_text tag ranges sel ]
	set sel_start [ lindex $selection 0 ]
	set sel_end [ lindex $selection 1 ]
	if { $code == $codes(a) } {
		if { $selection != "" } {
			$tw_text tag remove sel $sel_start $sel_end
		}
		$tw_text tag add sel 1.0 end end
		focus $tw_text
	}
}

proc text_window { title old callback data } {
	variable tw_text
	modal_window .twindow tw_init [ list $title $old $callback $data ] .
	focus $tw_text
}

proc tw_close { } {
	variable tw_window
	destroy $tw_window
	set tw_window <bad-text-window>
}

proc tw_ok { } {
	variable tw_window
	variable tw_callback
	variable tw_olduserdata
	variable tw_text
	
	set new_value [ $tw_text get -- 1.0 end ]
	set new_wo_trail [ string trimright $new_value ]
	$tw_callback $tw_olduserdata $new_wo_trail
	tw_close
}

}
