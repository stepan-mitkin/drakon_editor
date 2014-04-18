namespace eval mv {

proc parallel.switch { } {
	return ""
}

proc parallel.create { item_id diagram_id x y } {
	return [ list insert items				\
		item_id					$item_id		\
		diagram_id				$diagram_id	\
		type					'parallel'			\
		text					""			\
		selected				1					\
		x						$x					\
		y						$y					\
		w						60					\
		h						0					\
		a						0					\
		b						0		 ]
}

proc parallel.fit { tw th tw2 th2 x y w h a b } {
	return [ list $x $y $w $h $a $b ]
}

proc parallel.box { x y w h a b } {
	set left $x
	set top $y
	set right [ expr { $x + $w } ]
	set bottom $y
	
	return [ list $left $top $right $bottom ]
}


proc parallel.lines { x y w h a b } {
	set left $x
	set right [ expr { $x + $w } ]
	set y2 [ expr { $y + 5 } ]
	set coords [ list $left $y $right $y ]
	set coords2 [ list $left $y2 $right $y2 ]
	set cdbox [ add_handle_border $coords ]
	set line [ make_prim main line $coords "" "" $colors::line_fg $cdbox ]
	set line2 [ make_prim secondary line $coords2 "" "" $colors::line_fg $cdbox ]
	return [ list $line $line2 ]
}

proc parallel.icons { text text2 color xx y w h a b } {
	return {}
}


proc parallel.handles { x y w h a b } {
	set left_coord $x
	set right_coord [ expr { $x + $w } ]
	
	set left			[ make_vertex left	$left_coord $y ]
	set right			[ make_vertex right $right_coord $y ] 

	return [ list $left $right ]
}

proc parallel.left { dx dy x y w h a b } {
	set w2 [ expr { $w - $dx } ]
	if { $w2 < 20 } { set w2 20 }
	set x2 [ expr { $x + $w - $w2 } ]
	set y2 [ expr { $y + $dy } ]
	return [ list $x2 $y2 $w2 $h $a $b ]
}


proc parallel.right { dx dy x y w h a b } {
	set w2 [ expr { $w + $dx } ]
	if { $w2 < 20 } { set w2 20 }
	set y2 [ expr { $y + $dy } ]
	return [ list $x $y2 $w2 $h $a $b ]
}

}