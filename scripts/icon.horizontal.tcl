namespace eval mv {

proc horizontal.switch { } {
	return ""
}

proc horizontal.create_impl { item_id diagram_id x y a } {
	return [ list insert items				\
		item_id				$item_id		\
		diagram_id		$diagram_id	\
		type					'horizontal'			\
		text					""			\
		selected				1					\
		x						$x					\
		y						$y					\
		w						60					\
		h						0					\
		a						$a					\
		b						0		 ]
}

proc horizontal.create { item_id diagram_id x y } {
	return [ horizontal.create_impl $item_id $diagram_id $x $y 0 ]
}

proc horizontal.fit { tw th tw2 th2 x y w h a b } {
	return [ list $x $y $w $h $a $b ]
}

proc horizontal.box { x y w h a b } {
	set left $x
	set top $y
	set right [ expr { $x + $w } ]
	set bottom $y
	
	return [ list $left $top $right $bottom ]
}


proc horizontal.lines { x y w h a b } {
	set lines [ make_custom_arrow $x $y $w $a ]
	
	set left $x
	set right [ expr { $x + $w } ]
	set coords [ list $left $y $right $y ]
	set cdbox [ add_handle_border $coords ]
	set line [ make_prim main line $coords "" "" $colors::line_fg $cdbox ]
	
	set result [ linsert $lines 0 $line ]
	return $result
}


proc horizontal.icons { text text2 color xx y w h a b } {
	return {}
}


proc horizontal.handles { x y w h a b } {
	set left_coord $x
	set right_coord [ expr { $x + $w } ]
	
	set left			[ make_vertex left	$left_coord $y ]
	set right			[ make_vertex right $right_coord $y ] 

	return [ list $left $right ]
}

proc horizontal.left { dx dy x y w h a b } {
	set w2 [ expr { $w - $dx } ]
	if { $w2 < 20 } { set w2 20 }
	set x2 [ expr { $x + $w - $w2 } ]
	set y2 [ expr { $y + $dy } ]
	return [ list $x2 $y2 $w2 $h $a $b ]
}


proc horizontal.right { dx dy x y w h a b } {
	set w2 [ expr { $w + $dx } ]
	if { $w2 < 20 } { set w2 20 }
	set y2 [ expr { $y + $dy } ]
	return [ list $x $y2 $w2 $h $a $b ]
}

}