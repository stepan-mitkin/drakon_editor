namespace eval cpicker {

variable colors { "#808080" "#ff0000" "#ff4400" "#ff8800" "#ffdd00" "#ffff00" "#ccff00" "#88ff00" "#00ff00" "#00ff88" "#00ffdd" "#00ffff" "#00ddff" "#00aaff" "#0055ff" "#0000ff" "#5500ff" "#aa00ff" "#ff00ff" "#ff00aa"}
variable left 0
variable bg "#ffffff"
variable fg "#000000"

variable color_grid {}

variable element background
variable color_text $bg

variable cnv ""
variable window
variable items {}

proc scan_hex { hex } {
	scan $hex "%x" output
	return $output
}

proc rgb { hex } {
	set rhex [ string range $hex 1 2 ]
	set ghex [ string range $hex 3 4 ]
	set bhex [ string range $hex 5 6 ]
	set red [ scan_hex $rhex ]
	set green [ scan_hex $ghex ]
	set blue [ scan_hex $bhex ]
	return [ list $red $green $blue ]
}

proc to_hex { r g b } {
	return [ format "#%02x%02x%02x" $r $g $b ]
}

proc inter { left right count step } {
	set dx [ expr { $right - $left } ]
	set step_size [ expr { $dx / double($count + 1) } ]
	return [ expr { int($step * $step_size + $left) } ]
}

proc interpolate { color1 color2 count step } {
	lassign [ rgb $color1 ] r1 g1 b1
	lassign [ rgb $color2 ] r2 g2 b2

	set r [ inter $r1 $r2 $count $step ]
	set g [ inter $g1 $g2 $count $step ]
	set b [ inter $b1 $b2 $count $step ]

	return [ to_hex $r $g $b ]
}

proc inter_many { colors target count step } {
	set output {}
	foreach color $colors {
		set color2 [ interpolate $color $target $count $step ]
		lappend output $color2
	}
	return $output
}

proc append_column { grid column } {
	set count [ llength $column ]
	if { $count != [ llength $grid ] } {
		error "grid height and column height are different"
	}
	set output {}
	for { set i 0 } { $i < $count } { incr i } {
		set row [ lindex $grid $i ]
		set value [ lindex $column $i ]
		set row2 [ linsert $row 0 $value ]
		lappend output $row2
	}
	
	return $output
}

proc make_grid { colors } {
	set steps 5
	set white "#ffffff"
	set black "#000000"
	
	set rows {}

	set steps_1 [ expr { $steps - 1 } ]
	for { set i $steps } { $i > 0 } { incr i -1 } {
		set row [ inter_many $colors $white $steps $i ]
		lappend rows $row
	}
	
	for { set i 0 } { $i <= $steps } { incr i } {
		set row [ inter_many $colors $black $steps $i ]
		lappend rows $row
	}
	set basic { 
		"#ffffff" "#000000" "#336699" "#ffde00" "#6599ff" 
		"#829f53" "#9CCF31" "#b22222" "#e18178" "#99cc99" 
		"#ff717e" "#1fbed6" "#ec7992" "#cdffff" "#e8d0a9" 
		"#320000" "#003200" "#000032" "#321000" "#302000"}
	lappend rows $basic
	return $rows
}



proc element_changed { } {
	variable color_text
	variable element
	variable bg
	variable fg	
	variable cnv
	
	if { $element == "background" } {
		set color_text $bg
	} else {
		set color_text $fg
	}
	
}

proc color_changed { p } {
	variable color_text
	variable element
	variable bg
	variable fg	
	variable cnv
	
	if { ![ is_color $p ] } { return  1 }

	if { $element == "background" } {
		set bg $p
	} else {
		set fg $p
	}
	draw_canvas $cnv
	return 1
}

proc find_color { canvas x y } {
	variable left
	variable color_grid
	
	set cwidth [ lindex [ $canvas configure -width ] end ]
	set cheight [ lindex [ $canvas configure -height ] end ]
	if { $x < $left } { return "" }
	set x [ expr { $x - $left } ]
	
	set rcount [ llength $color_grid ]
	set sheight [ expr { $cheight / $rcount} ]
	
	set row [ lindex $color_grid 0 ]
	set count [ llength $row ]
	set swidth [ expr { int(($cwidth - $left)/$count) } ]
	
	set row_id [ expr { $y / $sheight } ]
	set column_id [ expr { $x / $swidth } ]
	
	set color [ lindex [ lindex $color_grid $row_id ] $column_id ]

	return $color
}

proc on_click {W x y s} {
	variable color_text
	variable element
	variable bg
	variable fg	
	set color [ find_color $W $x $y ]
	if { $color == "" } { return }
	set color_text $color
	if { $element == "background" } {
		set bg $color
	} else {
		set fg $color
	}
	draw_canvas $W
}

proc draw_canvas { canvas } {
	variable color_grid
	variable left
	variable bg
	variable fg

	$canvas configure -background $colors::canvas_bg
	$canvas delete all

	set cwidth [ lindex [ $canvas configure -width ] end ]
	set cheight [ lindex [ $canvas configure -height ] end ]
	
	set cx 70
	set cy [ expr { $cheight / 2 } ]
	
	set width 100
	set height 40
	
	set x1 [ expr { $cx - $width / 2 } ]
	set y1 [ expr { $cy - $height / 2 } ]
	set x2 [ expr { $x1 + $width } ]
	set y2 [ expr { $y1 + $height } ]
	$canvas create rect $x1 $y1 $x2 $y2  -fill $bg -outline $fg
	$canvas create text $cx $cy -text [ mc2 "Don't panic" ] -justify center -fill $fg
	
	set left [ expr { $cx * 2 } ]
		
	set rcount [ llength $color_grid ]
	set sheight [ expr { $cheight / $rcount } ]
	for { set ii 0 } { $ii < $rcount } { incr ii } {
		set row [ lindex $color_grid $ii ]
		set count [ llength $row ]
		set swidth [ expr { int(($cwidth - $left)/$count) } ]
		for { set i 0 } { $i < $count } { incr i } {
			set x1 [ expr { $left + $i * ($swidth) } ]
			set x2 [ expr { $x1 + $swidth + 1 } ]
			set y1 [ expr { $ii * ($sheight) } ]
			set y2 [ expr { $y1 + $sheight + 1} ]
			set color [ lindex $row $i ]
			$canvas create rect $x1 $y1 $x2 $y2  -fill $color -outline $color
		}
	}
}

proc init { win data } {
	variable color_grid
	variable colors
	variable cnv
	
	set color_grid [ make_grid $colors ]
	
	wm title $win [ mc2 "Change colors" ]

	set root [ ttk::frame $win.root -padding 5 ]
	pack $root -fill both -expand 1

	set canvas [ canvas $root.canvas -width 500 -height 300 -relief sunken -bd 1 -highlightthickness 0 ]
	bind $canvas <ButtonPress-1> { cpicker::on_click %W %x %y %s }
	pack $canvas
	
	set cnv $canvas


	set bottom [ ttk::frame $root.bottom -padding "0 0 5 0" ]
	set ok [ ttk::button $bottom.ok -text [ mc2 "Ok" ] -command cpicker::ok ]
	set cancel [ ttk::button $bottom.cancel -text [ mc2 "Cancel" ] -command cpicker::close_win ]

	pack $bottom -fill x -expand 1 -side bottom
	pack $cancel -side right -padx 5 -pady 5
	pack $ok -side right -padx 5 -pady 5


	set config [ ttk::frame $root.config ]
	set color_edit [ ttk::entry $config.color_edit -width 10 -textvariable cpicker::color_text -validate key -validatecommand { cpicker::color_changed %P } ]
	set fore [ ttk::radiobutton $config.fore -text [ mc2 "Font and border" ] -variable cpicker::element -value foreground -command cpicker::element_changed ]
	set back [ ttk::radiobutton $config.back -text [ mc2 "Background" ] -variable cpicker::element -value background  -command cpicker::element_changed ]
	pack $config -fill x -expand 1 -side bottom
	pack $color_edit -side left  -padx 5 -pady 5
	pack $back -side left  -padx 5 -pady 5
	pack $fore -side left  -padx 5 -pady 5

	bind $win <Return> cpicker::ok
	bind $win <Escape> cpicker::close_win


	draw_canvas $canvas

}

proc ok {} {
	variable items
	variable fg
	variable bg
	mwc::change_color $items $fg $bg
	close_win
}

proc close_win {} {
	variable window
	destroy $window
}

proc show { item_list } {
	variable items
	variable window
	variable bg
	variable fg
	set window .cpicker
	set items $item_list
	
	set old_color [ mwc::get_items_color $item_list ]
	if { $old_color != "" } {
		set bg [ dict get $old_color bg ]
		set fg [ dict get $old_color fg ]
	} else {
		set bg "#ffffff"
		set fg "#000000"
	}	
	element_changed
	ui::modal_window $window cpicker::init foo
}

}



