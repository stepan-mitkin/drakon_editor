
namespace eval mv {

proc timer.switch { } {
	return ""
}

proc timer.create { item_id diagram_id x y } {
	return [ list insert items				\
		item_id				$item_id		\
		diagram_id		$diagram_id	\
		type					'timer'		\
		text					timer		\
		selected				1					\
		x						$x					\
		y						$y					\
		w						60					\
		h						20					\
		a						60					\
		b						0		 ]
}

proc timer.lines { x y w h a b } {
	return {}
}

proc timer.fit { tw th tw2 th2 x y w h a b } {
	incr tw 20
	return [ action.fit $tw $th 0 0 $x $y $w $h $a $b ]
}

proc timer.box { x y w h a b } {
	return [ action.box $x $y $w $h $a $b ]
}


proc timer.icons { text text2 color x y w h a b } {
	lassign [ get_colors $color $colors::action_bg ] fg bg tc
	set tw [ expr { $w - 10 } ]
	set x0 [ expr { $x - $w } ]
	set x1 [ expr { $x0 + 15 } ]
	set x3 [ expr { $x + $w } ]
	set x2 [ expr { $x3 - 15 } ]
	set top [ expr { $y - $h } ]
	set bottom [ expr { $y + $h } ]
	
	set x1m [ expr { $x1 + 5 } ]
	set x0m [ expr { $x0 + 5 } ]
	set x2m [ expr { $x2 - 5 } ]
	set x3m [ expr { $x3 - 5 } ]
	
	set trap_coords [ list $x0 $top $x3 $top $x2 $bottom $x1 $bottom ]
	set rect_coords [ make_rect $x $y $w $h ]
	set cdbox [ add_handle_border $rect_coords ]
	set trap [ make_prim main polygon $trap_coords "" $fg $bg $cdbox ]
	set left [ make_line left $x0m $top $x1m $bottom $fg ]
	set right [ make_line right $x3m $top $x2m $bottom $fg ]
	set text_prim [ create_text $x $y $text $tc ]
	return [ list $trap $left $right $text_prim ]
}


proc timer.handles { x y w h a b } {
	return [ action.handles $x $y $w $h $a $b ]
}

proc timer.nw { dx dy x y w h a b } {
	return [ action.nw $dx $dy $x $y $w $h $a $b ]
}

proc timer.n { dx dy x y w h a b } {
	return [ action.n $dx $dy $x $y $w $h $a $b ]
}

proc timer.ne { dx dy x y w h a b } {
	return [ action.ne $dx $dy $x $y $w $h $a $b ]
}

proc timer.e { dx dy x y w h a b } {
	return [ action.e $dx $dy $x $y $w $h $a $b ]
}

proc timer.sw { dx dy x y w h a b } {
	return [ action.sw $dx $dy $x $y $w $h $a $b ]
}

proc timer.s { dx dy x y w h a b } {
	return [ action.s $dx $dy $x $y $w $h $a $b ]
}

proc timer.se { dx dy x y w h a b } {
	return [ action.se $dx $dy $x $y $w $h $a $b ]
}

proc timer.w { dx dy x y w h a b } {
	return [ action.w $dx $dy $x $y $w $h $a $b ]
}


}

