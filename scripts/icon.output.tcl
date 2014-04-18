
namespace eval mv {

proc output.switch { } {
	return ""
}

proc output.create { item_id diagram_id x y } {
	return [ list insert items				\
		item_id				$item_id		\
		diagram_id		$diagram_id	\
		type					'output'		\
		text					output		\
		selected				1					\
		x						$x					\
		y						$y					\
		w						60					\
		h						30					\
		a						20					\
		b						0		 ]
}

proc output.lines { x y w h a b } {
	return {}
}

proc output.fit { tw th tw2 th2 x y w h a b } {
	if { $tw < 50 } { set tw 50 }
	set w2pri [ expr { $tw + 10 } ]
	set w2sec [ expr { $tw2 + 10 } ]
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

proc output.box { x y w h a b } {
	return [ action.box $x $y $w $h $a $b ]
}

proc output.forward_box { x y w h a } {
	set left1 [ expr { $x - $w } ]
	set top1 [ expr { $y - $h + $a } ]
	set right1 [ expr { $x + $w - 20 } ]
	set bottom1 [ expr { $y + $h } ]
	
	set rect_coords1 [ list $left1 $top1 $right1 $bottom1 ]
	return $rect_coords1
}

proc output.is_top { mx my x y w h a b } {
	set top [ expr { $y - $h } ]
	set boundary [ expr { $top + $a } ]
	if { $my > $boundary } {
		return 0
	} else {
		return 1
	}
}

proc output.icons { text text2 color x y w h a b } {
	lassign [ get_colors $color $colors::action_bg ] fg bg tc
	set left1 [ expr { $x - $w } ]
	set top1 [ expr { $y - $h + $a } ]
	set right1 [ expr { $x + $w - 20 } ]
	set bottom1 [ expr { $y + $h } ]
	
	set w1 [ expr { ($right1 - $left1)/2 } ]
	set h1 [ expr { ($bottom1 - $top1)/2 } ]
	set x1 [ expr { $left1 + $w1 } ]
	set y1 [ expr { $top1 + $h1 } ]

	set left2 [ expr { $x - $w + 10 } ]
	set top2 [ expr { $y - $h } ]
	set right2 [ expr { $x + $w } ]
	set bottom2 [ expr { $top2 + $a + 10 } ]
	set xa [ expr { $right2 - 15 } ]
	set ya [ expr { ($top2 + $bottom2) / 2 } ]
	
	set x2 $x
	set y2 [ expr { $top2 + $a / 2 } ]
	set h2 [ expr { $a / 2 } ]
	set w2 $w1

	
	set coords2 [ list $left2 $top2 $xa $top2 $right2 $ya $xa $bottom2 $left2 $bottom2 ]
	
	
	set rect_coords1 [ list $left1 $top1 $right1 $bottom1 ]
	set rect_coords [ list $left1 $top2 $right2 $bottom1 ]
	set cdbox [ add_handle_border $rect_coords ]
	set rect [ make_prim main rectangle $rect_coords1 "" $fg $bg $cdbox ]
	set top [ expr { $y - $h } ]
	set bottom [ expr { $y + $h } ]
	set text_prim [ create_text_left $x1 $y1 $w1 $h1 $text $tc ]
	set text_prim2 [ create_text_left $x2 $y2 $w2 $h2 $text2 $tc secondary ]
	set back [ make_prim back polygon $coords2 "" $fg $bg $cdbox ]
	return [ list $back $rect $text_prim $text_prim2 ]
}


proc output.handles { x y w h a b } {
	return [ action.handles $x $y $w $h $a $b ]
}

proc output.nw { dx dy x y w h a b } {
	return [ action.nw $dx $dy $x $y $w $h $a $b ]
}

proc output.n { dx dy x y w h a b } {
	return [ action.n $dx $dy $x $y $w $h $a $b ]
}

proc output.ne { dx dy x y w h a b } {
	return [ action.ne $dx $dy $x $y $w $h $a $b ]
}

proc output.e { dx dy x y w h a b } {
	return [ action.e $dx $dy $x $y $w $h $a $b ]
}

proc output.sw { dx dy x y w h a b } {
	return [ action.sw $dx $dy $x $y $w $h $a $b ]
}

proc output.s { dx dy x y w h a b } {
	return [ action.s $dx $dy $x $y $w $h $a $b ]
}

proc output.se { dx dy x y w h a b } {
	return [ action.se $dx $dy $x $y $w $h $a $b ]
}

proc output.w { dx dy x y w h a b } {
	return [ action.w $dx $dy $x $y $w $h $a $b ]
}


}

