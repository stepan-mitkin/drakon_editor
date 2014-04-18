namespace eval back {

variable history
variable current

proc init {} {
	variable history
	variable current	
	set history {}
	set current -1
}

proc come_back { } {
	variable history
	variable current	
	if { $current <= 0 } { return }
	
	set next [ expr { $current - 1 } ]
	set diagram_id [ lindex $history $next ]
	if { ![ mwc::diagram_exists $diagram_id ] } {
		set history [ lrange $history $current end ]
		set current 0
		return
	}
	
	set current $next
	mwc::switch_to_dia_no_hist $diagram_id
}

proc go_forward { } {
	variable history
	variable current
	
	set history_last [ expr { [ llength $history ] - 1 } ]
	if { $current >= $history_last } { return }
	
	set next [ expr { $current + 1 } ]
	set diagram_id [ lindex $history $next ]
	if { ![ mwc::diagram_exists $diagram_id ] } {
		set history [ lrange $history 0 $current ]
		return
	}
	
	set current $next
	mwc::switch_to_dia_no_hist $diagram_id
}

proc record { diagram_id } {
	variable history
	variable current

	set history [ lrange $history 0 $current ]
	
	set already_there 0
	if { [ llength $history ] > 0 } {
		set last [ lindex $history end ]
		set already_there [ expr { $last == $diagram_id } ]
	}
	
	if { !$already_there } {
		lappend history $diagram_id
		incr current
	}
}

}
