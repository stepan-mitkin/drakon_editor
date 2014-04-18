namespace eval mwf {

array set dia_fonts {}
variable size100 ""
variable long_string "this is a very-very long string. this is here to emulate a crazy item on diagram."

variable font_family ""
variable font_size ""
variable size100 ""

proc reset {} {
	variable font_family
	variable font_size
	variable size100
	variable dia_fonts
	
	foreach font_name [ array names dia_fonts ] {
		forget_font $font_name
	}
	
	set font_family ""
	set font_size ""
	set size100 ""
}

proc get_font_size { } {
	variable font_size
	return $font_size
}

proc get_font { } {
	variable font_family
	return $font_family
}

proc get_family_size { } {
	variable font_family
	variable font_size

	array set props [ mwc::get_file_properties ]
	
	if { ![ info exists props(canvas_font_size) ] } { return 0 }
	if { ![ info exists props(canvas_font) ] } { return 0 }
	
	set size $props(canvas_font_size)
	if { [ string trim $size ] == "" } { return 0 }
	if { ![ string is integer $size ] } { return 0 }
	
	set font_size [ expr { int($size) } ]
	set font_family $props(canvas_font)
	
	if { $font_size < 3 } { return 0 }
	
	if { ![ contains [ font families ] $font_family ] } { return 0 }
	
	return 1
}

proc init_100 { } {
	variable long_string
	variable size100
	variable font_family
	variable font_size
	
	if { $size100 == "" } {
		if { ![ get_family_size ] } {
			set font_family [ mw::get_default_family ]
			set font_size [ mw::get_default_font_size ]
		}
		set font_name [ build_font_name 100 ]
		font create $font_name -family $font_family -size $font_size
		remember_font $font_name
		set size100 [ font measure $font_name $long_string ]
	}
}

proc font_exists { font_name } {
	variable dia_fonts
	return [ info exists dia_fonts($font_name) ]
}

proc remember_font { font_name } {
	variable dia_fonts
	set dia_fonts($font_name) $font_name
}

proc forget_font { font_name } {
	variable dia_fonts
	font delete $font_name
	unset dia_fonts($font_name)
}

proc build_font_name { zoom } {
	return "dia-$zoom"
}


proc get_dia_font { zoom } {
	variable font_family
	variable font_size

	init_100
	
	set size [ expr { int( $font_size * $zoom / 100.0 ) } ]
	set font_name [ build_font_name $zoom ]
	
	if { ![font_exists $font_name] } {
		find_font_that_fits $font_family $size $font_name $zoom
		remember_font $font_name
	}
	return $font_name	
}

proc find_font_that_fits { family size font_name zoom } {
	variable size100
	variable long_string
	set max_length [ expr { int( $zoom / 100.0 * $size100 ) } ]
	while { 1 } {
		font create $font_name -family $family -size $size
		set length [ font measure $font_name $long_string ]
		if { $length <= $max_length } {
			return
		}
		font delete $font_name
		incr size -1
	}
}

}
