
namespace eval mv {

proc shelf.switch { } {
	return ""
}

proc shelf.create { item_id diagram_id x y } {
	return [ list insert items				\
		item_id				$item_id		\
		diagram_id		$diagram_id	\
		type					'shelf'		\
		text					shelf		\
		selected				1					\
		x						$x					\
		y						$y					\
		w						60					\
		h						30					\
		a						20					\
		b						0		 ]
}

proc shelf.lines { x y w h a b } {
	return {}
}

proc shelf.fit { tw th tw2 th2 x y w h a b } {
	if { $tw < 50 } { set tw 50 }
	set w2pri $tw
	set w2sec $tw2
	if { $w2pri > $w2sec } {
		set w2 $w2pri
	} else {
		set w2 $w2sec
	}
	if { $tw2 == 0 } {
		set a 20
	} else {
		set a [ expr { $th2 * 2 } ]
	}
	set h2 [ expr { $th + $a / 2 } ]

	return [ list $x $y $w2 $h2 $a $b ]
}

proc shelf.box { x y w h a b } {
	return [ action.box $x $y $w $h $a $b ]
}



proc shelf.is_top { mx my x y w h a b } {
	return [ output.is_top $mx $my $x $y $w $h $a $b ]
}

proc shelf.icons { text text2 color x y w h a b } {
	lassign [ get_colors $color $colors::action_bg ] fg bg tc
	set top [ expr { $y - $h } ]
	set left [ expr { $x - $w } ]
	set right [ expr { $x + $w } ]
	
	set m [ expr { $top + $a } ]

	set h1 [ expr { $h - $a / 2 } ]
	set h2 [ expr { $a / 2 } ]

	set y2 [ expr { $top + $h2 } ]
	set y1 [ expr { $m + $h1 } ]

	set coords [ make_rect $x $y $w $h ]
	set cdbox [ add_handle_border $coords ]
	
	set rect [ make_prim main rectangle $coords "" $fg $bg $cdbox ]
	set text_prim [ create_text_left $x $y1 $w $h1 $text $tc ]
	set text_prim2 [ create_text_left $x $y2 $w $h2 $text2 $tc secondary ]
	set middle [ make_line middle $left $m $right $m $fg ]

	return [ list $rect $middle $text_prim $text_prim2 ]
}


proc shelf.handles { x y w h a b } {
	return [ action.handles $x $y $w $h $a $b ]
}

proc shelf.nw { dx dy x y w h a b } {
	return [ action.nw $dx $dy $x $y $w $h $a $b ]
}

proc shelf.n { dx dy x y w h a b } {
	return [ action.n $dx $dy $x $y $w $h $a $b ]
}

proc shelf.ne { dx dy x y w h a b } {
	return [ action.ne $dx $dy $x $y $w $h $a $b ]
}

proc shelf.e { dx dy x y w h a b } {
	return [ action.e $dx $dy $x $y $w $h $a $b ]
}

proc shelf.sw { dx dy x y w h a b } {
	return [ action.sw $dx $dy $x $y $w $h $a $b ]
}

proc shelf.s { dx dy x y w h a b } {
	return [ action.s $dx $dy $x $y $w $h $a $b ]
}

proc shelf.se { dx dy x y w h a b } {
	return [ action.se $dx $dy $x $y $w $h $a $b ]
}

proc shelf.w { dx dy x y w h a b } {
	return [ action.w $dx $dy $x $y $w $h $a $b ]
}


}

