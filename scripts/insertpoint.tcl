namespace eval insp {

variable gx 50
variable gy 50

proc remember { x y } {
	variable gx
	variable gy
	
	set gx $x
	set gy $y
}

proc reset { } {
	
	variable gx
	variable gy
	
	lassign [ canvas_rect ] left top right bottom
	
	set gx [ expr { ($right + $left) / 2 } ]
	set gy [ expr { ($bottom + $top) / 2 } ]
}

proc canvas_rect { } {
	lassign [ mw::canvas_rect ] left top right bottom

	set left2 [ mwc::unzoom_value $left ]
	set right2 [ mwc::unzoom_value $right ]
	set top2 [ mwc::unzoom_value $top ]
	set bottom2 [ mwc::unzoom_value $bottom ]
	
	return [ list $left2 $top2 $right2 $bottom2 ]
}


proc current { } {
	variable gx
	variable gy

	lassign [ canvas_rect ] left top right bottom
	
	if { $gx <= $left || $gx >= $right ||
		$gy <= $top || $gy >= $bottom } {
		
		set x [ expr { ($right + $left) / 2 } ]
		set y [ expr { ($bottom + $top) / 2 } ]
	} else {
		set x $gx
		set y $gy
	}
	
	return [ list $x $y ]
}


}