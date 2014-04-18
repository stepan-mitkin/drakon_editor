namespace eval mv {

proc vertical.switch { } {
	return ""
}

proc vertical.create { item_id diagram_id x y } {
	return [ vertical.create_impl $item_id $diagram_id $x $y 0 ]
}

proc vertical.create_impl { item_id diagram_id x y a} {
	return [ list insert items				\
		item_id				$item_id		\
		diagram_id		$diagram_id	\
		type					'vertical'			\
		text					""			\
		selected				1					\
		x						$x					\
		y						$y					\
		w						0					\
		h						200					\
		a						$a					\
		b						0		 ]
}

proc vertical.box { x y w h a b } {
	set left $x
	set right $x
	set top $y
	set bottom [ expr { $y + $h } ]
	return [ list $left $top $right $bottom ]
}


proc vertical.lines { x y w h a b } {

	set lines [ make_custom_arrow $x $y $h $a ]
	set coords [ list $x $y $x [ expr $y + $h ] ]
	set cdbox [ add_handle_border $coords ]
	set line [ make_prim main line $coords "" "" $colors::line_fg $cdbox ]
	set result [ linsert $lines 0 $line ]
	return $result
}

proc vertical.icons { text text2 color xx y w h a b } {
	return {}
}

proc vertical.fit { tw th tw2 th2 x y w h a b } {
	return [ list $x $y $w $h $a $b ]
}


proc vertical.handles { x y w h a b } {
	set bottom [ expr { $y + $h } ]
	
	set top			[ make_vertex top	$x $y ]
	set bottom		[ make_vertex bottom	$x $bottom ]	

	return [ list $top $bottom ]
}

proc vertical.top { dx dy x y w h a b } {
  set h2 [ expr { $h - $dy } ]
  if { $h2 < 20 } { set h2 20 }
  set y2 [ expr { $y + $h - $h2 } ]
  set x2 [ expr { $x + $dx } ]
  return [ list $x2 $y2 $w $h2 $a $b ]
}


proc vertical.bottom { dx dy x y w h a b } {
  set h2 [ expr { $h + $dy } ]
  if { $h2 < 20 } { set h2 20 }
  set x2 [ expr { $x + $dx } ]  
  return [ list $x2 $y $w $h2 $a $b ]
}

}