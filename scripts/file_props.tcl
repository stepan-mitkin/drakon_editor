namespace eval fprops {

variable error_message ""

variable window
variable language ""
variable none "<none>"
variable next_action ""

variable canvas_font ""
variable canvas_default 1
variable cf_combo ""
variable cf_size_entry ""
variable cf_size 14

variable pdf_font ""
variable pdf_default 1
variable pdf_combo ""
variable pf_size_entry ""
variable pdf_size 19

proc get_pdf_fonts { } {
	global script_path

	set pdf_fonts_full [ lsort -dictionary [ glob -nocomplain "$script_path/fonts/*.ttf" ] ]
	set pdf_fonts {}
	foreach font $pdf_fonts_full {
		lappend pdf_fonts [ file tail $font ]
	}

	return $pdf_fonts
}

proc init { win data } {
	variable language
	variable none
	variable cf_combo
	variable pdf_combo
	variable cf_size_entry
	variable error_message
	variable pf_size_entry
	

	set fonts [ lsort -dictionary [ font families ] ]
	set pdf_fonts [ get_pdf_fonts ]
	
	set error_message ""

	set languages [ array names gen::generators ] 
	if { $language != $none && ![ contains $languages $language ] } {
		lappend languages $language
	}
	set languages [ lsort -dictionary $languages ]
	set lang_list [ linsert $languages 0 $none ]


	wm title $win [ mc2 "File properties" ]
	
	set root [ ttk::frame $win.root -padding "5 5 5 5" ]

	set upper [ ttk::frame $root.upper ]
	set lang_label [ ttk::label $upper.lang_label -text [ mc2 "Language:" ] ]
	set lang_combo [ ttk::combobox $upper.lang_combo -values $lang_list -state readonly -textvariable fprops::language ]

	set cff [ ttk::frame $root.canvas_font_frame -padding "5 5 5 5" -borderwidth 1 -relief ridge ]
	
	set cf_label [ ttk::label $cff.cf_label -text [ mc2 "Canvas font" ] ]
	set cf_default [ ttk::checkbutton $cff.cf_default -text [ mc2 "Use default font" ] \
		-variable fprops::canvas_default -command fprops::update_controls ] 
	set cf_combo [ ttk::combobox $cff.cf_combo -values $fonts -state readonly \
		-textvariable fprops::canvas_font  ]
		
	set cf_size_frame [ ttk::frame $cff.cf_size_frame ]
	set cf_size_label [ ttk::label $cf_size_frame.cf_size_label -text [ mc2 "Size" ] ]
	set cf_size_entry [ ttk::entry $cf_size_frame.cf_size_entry -textvariable fprops::cf_size -width 3 ]


	set pff [ ttk::frame $root.pdf_font_frame -padding "5 5 5 5" -borderwidth 1 -relief ridge ]
	
	set pf_label [ ttk::label $pff.pf_label -text [ mc2 "PDF font" ] ]
	set pf_default [ ttk::checkbutton $pff.pf_default -text [ mc2 "Use default font" ] \
		-variable fprops::pdf_default -command fprops::update_controls ] 
	set pdf_combo [ ttk::combobox $pff.pf_combo -values $pdf_fonts -state readonly \
		-textvariable fprops::pdf_font  ]

	set pf_size_frame [ ttk::frame $pff.cf_size_frame ]
	set pf_size_label [ ttk::label $pf_size_frame.pf_size_label -text [ mc2 "Size" ] ]
	set pf_size_entry [ ttk::entry $pf_size_frame.pf_size_entry -textvariable fprops::pdf_size -width 3 ]
	
	set error_label [ ttk::label $root.error_label -textvariable fprops::error_message ]
	
	set lower [ ttk::frame $root.lower -padding "0 20 0 0" ]
	set ok [ ttk::button $lower.ok -command fprops::ok -text [ mc2 "Ok" ] ]
	set cancel [ ttk::button $lower.cancel -command fprops::close -text [ mc2 "Cancel" ] ]

	pack $root -expand yes -fill both
	
	pack $upper -fill x
	pack $cff -fill x -padx 3 -pady 3
	pack $pff -fill x -padx 3 -pady 3
	pack $lower -fill x -side bottom
	
	pack $error_label
	
	pack $lang_label -side left
	pack $lang_combo -side left -padx 10

	pack $cf_size_label -side left
	pack $cf_size_entry -side left -padx 10

	pack $pf_size_label -side left
	pack $pf_size_entry -side left -padx 10


	pack $pf_label -side top -anchor w
	pack $pf_default -side top -anchor w
	pack $pdf_combo -side top -anchor w -fill x
	pack $pf_size_frame -side top -fill x
	
	pack $cf_label -side top -anchor w
	pack $cf_default -side top -anchor w
	pack $cf_combo -side top -anchor w -fill x
	pack $cf_size_frame -side top -fill x
	
	pack $cancel -padx 10 -pady 10 -side right	
	pack $ok -padx 10 -pady 10 -side right

	

	bind $win <Return> fprops::ok
	bind $win <Escape> fprops::close
	
	update_controls

	focus $lang_combo
}

proc cf_combo_changed { } {
	variable canvas_default
	update_controls
}

proc update_controls { } {
	variable canvas_default
	variable cf_combo
	variable pdf_combo
	variable cf_size_entry
	variable pf_size_entry
	variable pdf_default
	
	if { $canvas_default } {
		$cf_combo configure -state disabled
		$cf_size_entry configure -state disabled
	} else {
		$cf_combo configure -state readonly
		$cf_size_entry configure -state normal
	}
	
	if { $pdf_default } {
		$pdf_combo configure -state disabled
		$pf_size_entry configure -state disabled
	} else {
		$pdf_combo configure -state readonly
		$pf_size_entry configure -state normal
	}
	
}

proc show_dialog { { next "" } } {
	variable window
	variable language
	variable none
	variable next_action
	set window .fprops
	set next_action $next

	set props [ mwc::get_file_properties ]
	array set properties $props
	
	if { [ info exists properties(language) ] } {
		set language $properties(language)
	} else {
		set language $none
	}
	
	load_fonts $props

	ui::modal_window $window fprops::init foo
}

proc load_fonts { props } {
	variable canvas_default
	variable canvas_font
	variable cf_size
	variable pdf_default
	variable pdf_font
	variable pdf_size


	array set properties $props
	
	if { [ info exists properties(canvas_font) ] &&
			[ info exists properties(canvas_font_size) ] } {
		set canvas_default 0
		set canvas_font $properties(canvas_font)
		set cf_size $properties(canvas_font_size)
	} else {
		set canvas_default 1
		set canvas_font ""
		set cf_size 14
	}
	
	if { [ info exists properties(pdf_font) ]  &&
			[ info exists properties(pdf_font_size) ] } {
		set pdf_default 0
		set pdf_font $properties(pdf_font)
		set pdf_size $properties(pdf_font_size)
	} else {
		set pdf_default 1
		set pdf_font ""
		set pdf_size 13
	}

}

proc try_get_font_size { variable control } {
	if { [ string trim $variable ] == "" || ![ string is integer $variable ] } {
		focus $control
		return 0
	}
	
	set size [ expr { int($variable) } ]
	if { $size < 3 || $size > 150 } {
		focus $control
		return 0
	}

	return $size
}

proc try_get_fonts { props } {
	variable canvas_default
	variable canvas_font
	variable cf_size
	variable cf_combo
	variable cf_size_entry
	variable pdf_default
	variable pdf_font
	variable pdf_combo
	variable pf_size_entry
	variable pdf_size	

	if { !$canvas_default } {	
		if { $canvas_font == "" } {
			focus $cf_combo
			return [ list $props [ mc2 "Choose a canvas font" ] ]
		}
	
		set size [ try_get_font_size $cf_size $cf_size_entry ]
		if { $size == 0 } {
			focus $cf_size_entry
			return [ list $props [ mc2 "Enter a correct canvas font size" ] ]
		}
		
		lappend props canvas_font $canvas_font
		lappend props canvas_font_size $size
	}
	
	if { !$pdf_default } {
		if { $pdf_font == "" } {
			focus $pdf_combo
			return [ list $props [ mc2 "Choose a PDF font" ] ]
		}

		set size [ try_get_font_size $pdf_size $pf_size_entry ]
		if { $size == 0 } {
			focus $pf_size_entry		
			return [ list $props [ mc2 "Enter a correct PDF font size" ] ]
		}
		
		lappend props pdf_font $pdf_font
		lappend props pdf_font_size $size
	}
	
	return [ list $props "" ]
}

proc ok { } {
	variable language
	variable none
	variable window
	variable next_action
	variable error_message
	
	hl::reset
	
	if { $language == $none } {
		set props {}
	} else {
		set props [ list language $language ]
	}
	
	lassign [ try_get_fonts $props ] props error_message
	
	if { $error_message != "" } {
	
		return
	}

	mwc::set_file_properties $props
	
	destroy $window
	
	if { $next_action != "" } {
		$next_action
	}
}

proc close { } {
	variable window
	destroy $window
}


}

