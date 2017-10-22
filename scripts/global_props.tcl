namespace eval gprops {

variable yes_entry
variable no_entry
variable end_entry
variable scheme_combo
variable language_combo
variable element_combo
variable color_entry
variable cnvs
variable colors

variable window ""
variable restart_required 0

variable element_list {
	"Icon background"
	"Line"
	"If icon"
	"Switch icon"
	"Loop icon"
	"Comment primary"
	"Comment secondary"
	"Background"
	"Text"
	"Code: identifier"
	"Code: string"
	"Code: keyword"
	"Code: number"
	"Code: comment"
	"Code: operator"
}

variable scheme_list {
	Parrot
	Strict
	Black
	Night
	"Colored night"
}

variable language_list {
	"English"
	"Russian"
}

variable strict {
	background 	"#C3E7EF"
	line 			"#000000"
	text 			"#000000"
	action	 	"#ffffff"
	if 			"#ffffff"
	switch	 	"#ffffff"
	loop			"#ffffff"
	comment		"#ffffa0"
	comment_s		"#38BAC8"
	syntax_identifier "#000000"
	syntax_string "#d00000"
	syntax_keyword "#0000cB"
	syntax_number "#d00000"
	syntax_comment "#228B22"
	syntax_operator "#a000a0"
}

variable parrot {
	background 	"#C3E7EF"
	line 			"#000000"
	text 			"#000000"
	action	 	"#ffffff"
	if 			"#ffffd8"
	switch	 	"#ffe8e8"
	loop			"#e8ffe8"
	comment		"#ffff00"
	comment_s		"#909090"
	syntax_identifier "#000000"
	syntax_string "#d00000"
	syntax_keyword "#0000cB"
	syntax_number "#d00000"
	syntax_comment "#228B22"
	syntax_operator "#a000a0"
}

variable black {
	background 	"#000000"
	line 			"#707070"
	text 			"#ffffff"
	action	 	"#000000"
	if 			"#000000"
	switch	 	"#000000"
	loop			"#000000"
	comment		"#303030"
	comment_s		"#303030"
	syntax_identifier "#c0c0c0"
	syntax_string "#909090"
	syntax_keyword "#b0b0b0"
	syntax_number "#ffffff"
	syntax_comment "#505050"
	syntax_operator "#ffffff"  
}

variable night {
	background 	"#000040"
	line 			"#7070c0"
	text 			"#ffffaa"
	action	 	"#000000"
	if 			"#000000"
	switch	 	"#000000"
	loop			"#000000"
	comment		"#0000a0"
	comment_s		"#0000a0"
	syntax_identifier "#BCD5FF"
	syntax_string "#6882aF"
	syntax_keyword "#70A5FF"
	syntax_number "#ffffff"
	syntax_comment "#808080"
	syntax_operator "#ffffff"  
}

variable colored_night {
	background 	"#000040"
	line 			"#7070c0"
	text 			"#ffffaa"
	action	 	"#000000"
	if 			"#202000"
	switch	 	"#250000"
	loop			"#002500"
	comment		"#0000a0"
	comment_s		"#0000a0"
	syntax_identifier "#FBF9C0"
	syntax_string "#dC8623"
	syntax_keyword "#ABFFCF"
	syntax_number "#ffffff"
	syntax_comment "#808080"
	syntax_operator "#6CCC88"
}

#	syntax_identifier "#EBD9C0"
#	syntax_string "#CC8623"
#	syntax_keyword "#6CCC88"
#	syntax_number "#ffffff"
#	syntax_comment "#808080"
#	syntax_operator "#ABEBCF"

array set colors $parrot

proc color { name } {
  variable colors
  return $colors($name)
}

proc color_safe { color_dict name } {
	array set colors $color_dict
	if { [ info exists colors($name) ] } {
		return $colors($name)
	} else {
		return [ color $name ]
	}
}

proc load_from_settings {} {
	set colors_dict [ app_settings::get_prop drakon_editor colors ]
	
	set colors::canvas_bg [ color_safe $colors_dict background ]
	set colors::if_bg [ color_safe $colors_dict if ]
	set colors::for_bg [ color_safe $colors_dict loop ]
	set colors::case_bg [ color_safe $colors_dict switch ]
	set colors::action_bg [ color_safe $colors_dict action ]
	set colors::text_fg [ color_safe $colors_dict text ]
	set colors::line_fg [ color_safe $colors_dict line ]
	set colors::comment_bg [ color_safe $colors_dict comment_s ]
	set colors::comment_fg [ color_safe $colors_dict comment ]

	set colors::syntax_identifier [ color_safe $colors_dict syntax_identifier ]
	set colors::syntax_string [ color_safe $colors_dict syntax_string ]
	set colors::syntax_keyword [ color_safe $colors_dict syntax_keyword ]
	set colors::syntax_number [ color_safe $colors_dict syntax_number ]
	set colors::syntax_comment [ color_safe $colors_dict syntax_comment ]
	set colors::syntax_operator [ color_safe $colors_dict syntax_operator ]
}

proc save_to_settings {} {
	variable colors
	set colors_dict [ array get colors ]
	app_settings::set_prop drakon_editor colors $colors_dict
}

proc color_set { name value } {
  variable colors
  set colors($name) $value
}

proc reset {} {
	variable element_combo
	variable scheme_combo
	variable color_entry
	
	set element_combo ""
	set scheme_combo ""
	set color_entry ""
}

proc element_changed {} {
	variable element_combo
	variable color_entry
	
	set color_text ""

	switch $element_combo {
		"Icon background" { set color_text [ color action ] }
		"Line" { set color_text [ color line ] }
		"If icon" { set color_text [ color if ] }
		"Switch icon" { set color_text [ color switch ] }
		"Loop icon" { set color_text [ color loop ] }
		"Comment primary" { set color_text [ color comment ] }
		"Comment secondary" { set color_text [ color comment_s ] }
		"Background"	{ set color_text [ color background ] }
		"Text"	{ set color_text [ color text ] }		
		"Code: identifier" { set color_text [ color syntax_identifier ] }
		"Code: string" { set color_text [ color syntax_string ] }
		"Code: keyword" { set color_text [ color syntax_keyword ] }
		"Code: number" { set color_text [ color syntax_number ] }
		"Code: comment" { set color_text [ color syntax_comment ] }
		"Code: operator" { set color_text [ color syntax_operator ] }		
	}
	set color_entry $color_text
}



proc color_changed { color } {
	variable element_combo
	
	if { $element_combo == "" } { return 1 }
	
	if { ![ is_color $color ] } { 
		return 1 
	}

	switch $element_combo {
		"Icon background" { color_set action $color }
		"Line" { color_set line $color }
		"If icon" { color_set if $color }
		"Switch icon" { color_set switch $color }
		"Loop icon" { color_set loop $color }
		"Comment primary" { color_set comment $color }
		"Comment secondary" { color_set comment_s $color }
		"Background"	{ color_set background $color }
		"Text"	{ color_set text $color }
		"Code: identifier" { color_set syntax_identifier $color }
		"Code: string" { color_set syntax_string $color }
		"Code: keyword" { color_set syntax_keyword $color }
		"Code: number" { color_set syntax_number $color }
		"Code: comment" { color_set syntax_comment $color }
		"Code: operator" { color_set syntax_operator $color }		
	}
	
	draw_sample_picture
	return 1
	
}

proc on_language { } {
	variable yes_entry
	variable no_entry
	variable end_entry
	variable language_combo
	
	if {$language_combo == "English"} {
		set yes_entry "Yes"
		set no_entry "No"
		set end_entry "End"
	} else {
		set yes_entry "Да"
		set no_entry "Нет"
		set end_entry "Конец"		
	}
}

proc init { win data } {
	variable element_list
	variable scheme_list
	variable language_list
	variable cnvs
	
	reset
	load_colors

	wm title $win [ mc2 "Global settings" ]
	
	set root [ ttk::frame $win.root -padding "5 5 5 5" ]

	set language_frame [ ttk::frame $root.language_frame ]
	set language_label [ ttk::label $language_frame.lang_label -text "Language:" -width 30 ]
	set language_entry [ ttk::combobox $language_frame.lang_combo -values [lsort $language_list ] -state readonly -textvariable gprops::language_combo ]

	set yes_frame [ ttk::frame $root.yes_frame ]
	set yes_label [ ttk::label $yes_frame.lang_label -text [ mc2 "Label for \\\"Yes\\\" exit:" ] -width 30 ]
	set yes_entry [ ttk::entry $yes_frame.yes_entry -textvariable gprops::yes_entry -width 20 ]	

	set no_frame [ ttk::frame $root.no_frame ]
	set no_label [ ttk::label $no_frame.lang_label -text [ mc2 "Label for \\\"No\\\" exit:" ] -width 30 ]
	set no_entry [ ttk::entry $no_frame.no_entry -textvariable gprops::no_entry -width 20 ]	

	set end_frame [ ttk::frame $root.end_frame ]
	set end_label [ ttk::label $end_frame.lang_label -text [ mc2 "Text for \\\"End\\\" icon:" ] -width 30 ]
	set end_entry [ ttk::entry $end_frame.end_entry -textvariable gprops::end_entry -width 20 ]	


	set scheme_frame [ ttk::frame $root.scheme_frame ]
	set scheme_label [ ttk::label $scheme_frame.lang_label -text [ mc2 "Theme:" ] -width 30 ]
	set scheme_combo [ ttk::combobox $scheme_frame.color_combo -values [lsort $scheme_list ] -state readonly -textvariable gprops::scheme_combo ]

	bind $scheme_combo <<ComboboxSelected>> { gprops::theme_changed }

	set element_frame [ ttk::frame $root.element_frame ]
	set element_label [ ttk::label $element_frame.lang_label -text [ mc2 "Element:" ] -width 30 ]
	set element_combo [ ttk::combobox $element_frame.color_combo -values [lsort $element_list] -state readonly -textvariable gprops::element_combo ]

	bind $element_combo <<ComboboxSelected>> { gprops::element_changed }

	set color_frame [ ttk::frame $root.color_frame ]
	set color_label [ ttk::label $color_frame.lang_label -text [ mc2 "Color:" ] -width 30 ]
	set color_entry [ ttk::entry $color_frame.color_entry -textvariable gprops::color_entry -width 20 -validate key -validatecommand { gprops::color_changed %P } ]	



	set lower [ ttk::frame $root.lower -padding "0 20 0 0" ]
	set ok [ ttk::button $lower.ok -command gprops::ok -text [ mc2 "Ok" ] ]
	set cancel [ ttk::button $lower.cancel -command gprops::close -text [ mc2 "Cancel" ] ]

	pack $root -expand yes -fill both

	pack $language_frame -fill x
	pack $yes_frame -fill x
	pack $no_frame -fill x
	pack $end_frame -fill x
	pack $scheme_frame -fill x
	pack $element_frame -fill x
	pack $color_frame -fill x
	
	set canvas [ canvas $root.cns -relief sunken -background [color background]  -width 300 -height 220 ]
	set cnvs $canvas
	draw_sample_picture
	pack $canvas -pady 10
	
	pack $lower -fill x -side bottom

	pack $language_label -side left
	pack $language_entry -side left -padx 10
	
	pack $yes_label -side left
	pack $yes_entry -side left -padx 10

	pack $no_label -side left
	pack $no_entry -side left -padx 10

	pack $end_label -side left
	pack $end_entry -side left -padx 10

	pack $scheme_label -side left
	pack $scheme_combo -side left -padx 10

	pack $element_label -side left
	pack $element_combo -side left -padx 10

	pack $color_label -side left
	pack $color_entry -side left -padx 10
	
	
	
	pack $cancel -padx 10 -pady 10 -side right	
	pack $ok -padx 10 -pady 10 -side right

	

	bind $win <Return> gprops::ok
	bind $win <Escape> gprops::close
	bind $language_entry <<ComboboxSelected>> gprops::on_language

	focus $yes_entry
}


proc show_dialog { } {
	variable window
	variable yes_entry
	variable no_entry
	variable end_entry
	variable language_combo
	
	set window .gprops
	
	set yes_entry [ texts::get "yes" ]
	set no_entry [ texts::get "no" ]
	set end_entry [ texts::get "end" ]
	set language_combo [ texts::get "language" ]

	ui::modal_window $window gprops::init foo
}

proc ok { } {
	variable window
	
	variable yes_entry
	variable no_entry
	variable end_entry
	variable language_combo
	
	texts::put "yes" $yes_entry
	texts::put "no" $no_entry
	texts::put "end" $end_entry
	
	set old_language [ texts::get "language" ]
	set restart_required 0
	if {$old_language != $language_combo} {
		set restart_required 1
	}
	
	
	texts::put "language" $language_combo
	
	app_settings::set_prop drakon_editor "yes" $yes_entry
	app_settings::set_prop drakon_editor "no" $no_entry
	app_settings::set_prop drakon_editor "end" $end_entry
	app_settings::set_prop drakon_editor "language" $language_combo
	
	save_colors
	
	destroy $window
	
	if {$restart_required} {
		set message [ mc2 "Please restart the application" ]
		tk_messageBox -parent . -message $message -type ok
	}
}

proc close { } {
	variable window
	destroy $window
}

proc load_colors {} {
	color_set background $colors::canvas_bg 
	color_set if $colors::if_bg 
	color_set loop $colors::for_bg
	color_set switch $colors::case_bg 
	color_set action $colors::action_bg 
	color_set text $colors::text_fg 
	color_set line $colors::line_fg 
	color_set comment_s $colors::comment_bg
	color_set comment $colors::comment_fg
	color_set syntax_identifier $colors::syntax_identifier
	color_set syntax_string  $colors::syntax_string
	color_set syntax_keyword  $colors::syntax_keyword
	color_set syntax_number $colors::syntax_number
	color_set syntax_comment  $colors::syntax_comment
	color_set syntax_operator  $colors::syntax_operator	
}

proc save_colors {} {
	
	set colors::canvas_bg [ color background ]
	set colors::if_bg [ color if ]
	set colors::for_bg [ color loop]
	set colors::case_bg [ color switch ]
	set colors::action_bg [ color action ]
	set colors::text_fg [ color text ]
	set colors::line_fg [ color line ]
	set colors::comment_bg [ color comment_s ]
	set colors::comment_fg [ color comment ]
	
	set colors::syntax_identifier [ color syntax_identifier ]
	set colors::syntax_string  [ color syntax_string ]
	set colors::syntax_keyword  [ color syntax_keyword ]
	set colors::syntax_number [ color syntax_number ]
	set colors::syntax_comment  [ color syntax_comment ]
	set colors::syntax_operator  [ color syntax_operator ]
		
	save_to_settings
	
	mwc::refill_current 1 1
}

proc draw_sample_picture {} {
	variable cnvs
	set canvas $cnvs
	
	$canvas delete all
	
	$canvas configure -background [color background]

	$canvas create line 60 10 60 210 -fill [color line]
	$canvas create rectangle 10 20 110 40 -fill [color action] -outline [color line] 
	$canvas create rectangle 15 25 25 35 -fill [color action] -outline [color text] 
	$canvas create rectangle 35 25 45 35 -fill [color action] -outline [color text] 

	$canvas create rectangle 55 25 65 35 -fill [color action] -outline [color text] 

	$canvas create polygon 10 60 20 50 100 50 110 60 100 70 20 70 10 60 -fill [color if] -outline [color line]
	$canvas create polygon 10 100 10 90 20 80 100 80 110 90 110 100 10 100 -fill [color loop] -outline [color line]
	$canvas create rectangle 10 110 110 130 -fill [color action] -outline [color line] 
	$canvas create polygon 10 140 110 140 110 150 100 160 20 160 10 150 10 140 -fill [color loop] -outline [color line]
	$canvas create line 110 60 130 60 -fill [color line]
	$canvas create line 130 60 130 170 -fill [color line]
	$canvas create line 130 170 60 170 -fill [color line]
	$canvas create polygon 20 180 110 180 100 200 10 200 20 180 -fill [color switch] -outline [color line]
	$canvas create polygon 180 80 280 80 280 160 180 160 180 120 150 110 180 110 180 80 -fill [color comment] -outline [color line]
}

proc theme_changed {} {
	variable element_combo
	variable color_entry
	variable scheme_combo
	variable colors
	
	variable parrot
	variable strict
	variable black
	variable white
	variable night
	variable colored_night
	variable glamour
	variable is
	
	if { $scheme_combo == "" } { return }
	set color_entry ""
	set element_combo ""
	
	switch $scheme_combo {
		Parrot { array set colors $parrot }
		Strict { array set colors $strict }
		Black { array set colors $black }
		White { array set colors $white }
		Night { array set colors $night }
		"Colored night" { array set colors $colored_night }
	}
	
	draw_sample_picture
}

}

