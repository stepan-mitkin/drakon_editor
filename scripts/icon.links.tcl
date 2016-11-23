namespace eval mv {

variable big 20
variable small 5

array set link_types {
	up_arrow			{ 10100 mv::make_up_arrow }
	right_arrow			{ 20100 mv::make_right_arrow }	
	down_arrow			{ 30100 mv::make_down_arrow }
	left_arrow			{ 40100 mv::make_left_arrow }

	up_white_arrow		{ 10200 mv::make_up_white_arrow }
	right_white_arrow	{ 20200 mv::make_right_white_arrow }
	down_white_arrow	{ 30200 mv::make_down_white_arrow }
	left_white_arrow	{ 40200 mv::make_left_white_arrow }

	up_paw				{ 10300 mv::make_up_paw }
	right_paw			{ 20300 mv::make_right_paw }
	down_paw			{ 30300 mv::make_down_paw }
	left_paw			{ 40300 mv::make_left_paw	}
	
	parallel			{ 50100 "" }
}

array set code_to_type {}

foreach name [ array names link_types ] {
	if {$name == "parallel"} {
		continue
	}	
	lassign $link_types($name) code make
	set code_to_type($code) [ list $name $make ]
	
	set proc_name $name.create
	
	set line1 "set code \[ get_link_code $name \]"
	if { [ string match "up*" $name ] || [ string match "down*" $name ] } {
		set line2 { return [ vertical.create_impl $item_id $diagram_id $x $y $code ] }
	} else {
		set line2 { return [ horizontal.create_impl $item_id $diagram_id $x $y $code ] }
	}
	set body "$line1\n$line2"
	
	proc $proc_name { item_id diagram_id x y } $body


	set proc_name_fit $name.fit
	set fit_body { return [ list $x $y $w $h $a $b ] }
	proc $proc_name_fit { tw th tw2 th2 x y w h a b } $fit_body
}

proc get_link_code { name } {
	variable link_types
	if { ![ info exists link_types($name) ] } {
		return 0
	}
	set record $link_types($name)
	set code [ lindex $record 0 ]
	return $code
}

proc get_link_make { name } {
	variable code_to_type
	if { ![ info exists code_to_type($name) ] } {
		return ""
	}	
	set record $code_to_type($name)
	set make [ lindex $record 1 ]
	return $make
}

proc make_custom_arrow { x y c a } {
	
	if { $a == 0 } {
		return {}
	}
	
	set make [ get_link_make $a ]
	if { $make == "" } { return {} }
	return [ $make $x $y $c ]
}


proc make_up_arrow { x y h } {
	variable big
	variable small
	
	set left [ expr { $x - $small } ]
	set top $y
	set right [ expr { $x + $small } ]
	set bottom [ expr { $y + $big } ]
	
	set coords [ list $left $bottom $right $bottom $x $top ]
	set cdbox [ list $left $top $right $bottom ]
	set prim [ make_prim head polygon $coords "" $colors::line_fg $colors::line_fg $cdbox ]
	return [ list $prim ]
}

proc make_down_arrow { x y h } {
	variable big
	variable small
	
	set left [ expr { $x - $small } ]
	set top [ expr { $y + $h - $big } ]
	set right [ expr { $x + $small } ]
	set bottom [ expr { $y + $h } ]
	
	set coords [ list $left $top $right $top $x $bottom ]
	set cdbox [ list $left $top $right $bottom ]
	set prim [ make_prim head polygon $coords "" $colors::line_fg $colors::line_fg $cdbox ]
	return [ list $prim ]
}


proc make_up_white_arrow { x y h } {
	variable big
	variable small
	
	set left [ expr { $x - $small } ]
	set top $y
	set right [ expr { $x + $small } ]
	set bottom [ expr { $y + $big } ]
	
	set coords [ list $left $bottom $right $bottom $x $top ]
	set cdbox [ list $left $top $right $bottom ]
	set prim [ make_prim head polygon $coords "" $colors::line_fg $colors::action_bg $cdbox ]
	return [ list $prim ]
}

proc make_down_white_arrow { x y h } {
	variable big
	variable small
	
	set left [ expr { $x - $small } ]
	set top [ expr { $y + $h - $big } ]
	set right [ expr { $x + $small } ]
	set bottom [ expr { $y + $h } ]
	
	set coords [ list $left $top $right $top $x $bottom ]
	set cdbox [ list $left $top $right $bottom ]
	set prim [ make_prim head polygon $coords "" $colors::line_fg $colors::action_bg $cdbox ]
	return [ list $prim ]
}


proc make_up_paw { x y h } {
	variable big
	
	set left [ expr { $x - $big / 2 } ]
	set top $y
	set right [ expr { $x + $big / 2 } ]
	set bottom [ expr { $y + $big } ]
	
	set coords_left [ list $left $top $x $bottom ]
	set coords_right [ list $right $top $x $bottom ]
	set cdbox [ list $left $top $right $bottom ]
	set priml [ make_prim head_left polygon $coords_left "" $colors::line_fg $colors::line_fg $cdbox ]
	set primr [ make_prim head_right polygon $coords_right "" $colors::line_fg $colors::line_fg $cdbox ]
	return [ list $priml $primr ]
}

proc make_down_paw { x y h } {
	variable big
	
	set left [ expr { $x - $big / 2 } ]
	set top [ expr { $y + $h - $big } ]
	set right [ expr { $x + $big / 2 } ]
	set bottom [ expr { $y + $h } ]
	
	set coords_left [ list $x $top $left $bottom ]
	set coords_right [ list $x $top $right $bottom ]
	set cdbox [ list $left $top $right $bottom ]
	set priml [ make_prim head_left polygon $coords_left "" $colors::line_fg $colors::line_fg $cdbox ]
	set primr [ make_prim head_right polygon $coords_right "" $colors::line_fg $colors::line_fg $cdbox ]
	return [ list $priml $primr ]
}

proc make_left_arrow { x y w } {
	variable big
	variable small
	
	set left $x
	set top [ expr { $y - $small } ]
	set right [ expr { $x + $big } ]
	set bottom [ expr { $y + $small } ]
	
	set coords [ list $left $y $right $top $right $bottom ]
	set cdbox [ list $left $top $right $bottom ]
	set prim [ make_prim head polygon $coords "" $colors::line_fg $colors::line_fg $cdbox ]
	return [ list $prim ]
}

proc make_left_white_arrow { x y w } {
	variable big
	variable small
	
	set left $x
	set top [ expr { $y - $small } ]
	set right [ expr { $x + $big } ]
	set bottom [ expr { $y + $small } ]
	
	set coords [ list $left $y $right $top $right $bottom ]
	set cdbox [ list $left $top $right $bottom ]
	set prim [ make_prim head polygon $coords "" $colors::line_fg $colors::action_bg $cdbox ]
	return [ list $prim ]
}

proc make_right_arrow { x y w } {
	variable big
	variable small
	
	set left [ expr { $x + $w - $big } ]
	set top [ expr { $y - $small } ]
	set right [ expr { $x + $w } ]
	set bottom [ expr { $y + $small } ]
	
	set coords [ list $left $top $right $y $left $bottom ]
	set cdbox [ list $left $top $right $bottom ]
	set prim [ make_prim head polygon $coords "" $colors::line_fg $colors::line_fg $cdbox ]
	return [ list $prim ]
}

proc make_right_white_arrow { x y w } {
	variable big
	variable small
	
	set left [ expr { $x + $w - $big } ]
	set top [ expr { $y - $small } ]
	set right [ expr { $x + $w } ]
	set bottom [ expr { $y + $small } ]
	
	set coords [ list $left $top $right $y $left $bottom ]
	set cdbox [ list $left $top $right $bottom ]
	set prim [ make_prim head polygon $coords "" $colors::line_fg $colors::action_bg $cdbox ]
	return [ list $prim ]
}

proc make_left_paw { x y w } {
	variable big
	
	set left $x
	set top [ expr { $y - $big / 2 } ]
	set right [ expr { $x + $big } ]
	set bottom [ expr { $y + $big / 2 } ]
	
	set coordsu [ list $right $y $left $top ]
	set coordsd [ list $right $y $left $bottom ]
	set cdbox [ list $left $top $right $bottom ]
	set primu [ make_prim head_up polygon $coordsu "" $colors::line_fg $colors::line_fg $cdbox ]
	set primd [ make_prim head_down polygon $coordsd "" $colors::line_fg $colors::line_fg $cdbox ]
	return [ list $primu $primd ]
}

proc make_right_paw { x y w } {
	variable big
	
	set left [ expr { $x + $w - $big } ]
	set top [ expr { $y - $big / 2 } ]
	set right [ expr { $x + $w } ]
	set bottom [ expr { $y + $big / 2 } ]
	
	set coordsu [ list $left $y $right $top ]
	set coordsd [ list $left $y $right $bottom ]
	set cdbox [ list $left $top $right $bottom ]
	set primu [ make_prim head_up polygon $coordsu "" $colors::line_fg $colors::line_fg $cdbox ]
	set primd [ make_prim head_down polygon $coordsd "" $colors::line_fg $colors::line_fg $cdbox ]
	return [ list $primu $primd ]
}

}
