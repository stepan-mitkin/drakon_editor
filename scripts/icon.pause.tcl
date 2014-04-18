
namespace eval mv {

proc pause.switch { } {
	return ""
}

proc pause.create { item_id diagram_id x y } {
	return [ list insert items				\
		item_id				$item_id		\
		diagram_id		$diagram_id	\
		type					'pause'		\
		text					pause		\
		selected				1					\
		x						$x					\
		y						$y					\
		w						60					\
		h						20					\
		a						60					\
		b						0		 ]
}

proc pause.lines { x y w h a b } {
	return {}
}

proc pause.fit { tw th tw2 th2 x y w h a b } {
	return [ timer.fit $tw $th 0 0 $x $y $w $h $a $b ]
}

proc pause.box { x y w h a b } {
	return [ action.box $x $y $w $h $a $b ]
}


proc pause.icons { text text2 color x y w h a b } {
	lassign [ get_colors $color $colors::action_bg ] fg bg tc
	set tw [ expr { $w - 10 } ]
	set x0 [ expr { $x - $w } ]
	set x1 [ expr { $x0 + 15 } ]
	set x3 [ expr { $x + $w } ]
	set x2 [ expr { $x3 - 15 } ]
	set top [ expr { $y - $h } ]
	set bottom [ expr { $y + $h } ]
	
	
	set trap_coords [ list $x0 $top $x3 $top $x2 $bottom $x1 $bottom ]
	set rect_coords [ make_rect $x $y $w $h ]
	set cdbox [ add_handle_border $rect_coords ]
	set trap [ make_prim main polygon $trap_coords "" $fg $bg $cdbox ]
	set text_prim [ create_text $x $y $text $tc ]
	return [ list $trap $text_prim ]
}


proc pause.handles { x y w h a b } {
	return [ action.handles $x $y $w $h $a $b ]
}

proc pause.nw { dx dy x y w h a b } {
	return [ action.nw $dx $dy $x $y $w $h $a $b ]
}

proc pause.n { dx dy x y w h a b } {
	return [ action.n $dx $dy $x $y $w $h $a $b ]
}

proc pause.ne { dx dy x y w h a b } {
	return [ action.ne $dx $dy $x $y $w $h $a $b ]
}

proc pause.e { dx dy x y w h a b } {
	return [ action.e $dx $dy $x $y $w $h $a $b ]
}

proc pause.sw { dx dy x y w h a b } {
	return [ action.sw $dx $dy $x $y $w $h $a $b ]
}

proc pause.s { dx dy x y w h a b } {
	return [ action.s $dx $dy $x $y $w $h $a $b ]
}

proc pause.se { dx dy x y w h a b } {
	return [ action.se $dx $dy $x $y $w $h $a $b ]
}

proc pause.w { dx dy x y w h a b } {
	return [ action.w $dx $dy $x $y $w $h $a $b ]
}


}

