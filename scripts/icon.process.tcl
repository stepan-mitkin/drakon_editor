
namespace eval mv {

proc process.switch { } {
	return ""
}

proc process.create { item_id diagram_id x y } {
	return [ list insert items				\
		item_id				$item_id		\
		diagram_id		$diagram_id	\
		type					'process'		\
		text					process		\
		selected				1					\
		x						$x					\
		y						$y					\
		w						60					\
		h						30					\
		a						20					\
		b						0		 ]
}

proc process.lines { x y w h a b } {
	return {}
}

proc process.fit { tw th tw2 th2 x y w h a b } {
	return [ output.fit $tw $th $tw2 $th2 $x $y $w $h $a $b ]
}

proc process.box { x y w h a b } {
	return [ action.box $x $y $w $h $a $b ]
}



proc process.is_top { mx my x y w h a b } {
	return [ output.is_top $mx $my $x $y $w $h $a $b ]
}

proc process.icons { text text2 color x y w h a b } {
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

	
	set coords2 [ list $left2 $top2 $right2 $top2 $right2 $bottom2 $left2 $bottom2 ]
	
	
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


proc process.handles { x y w h a b } {
	return [ action.handles $x $y $w $h $a $b ]
}

proc process.nw { dx dy x y w h a b } {
	return [ action.nw $dx $dy $x $y $w $h $a $b ]
}

proc process.n { dx dy x y w h a b } {
	return [ action.n $dx $dy $x $y $w $h $a $b ]
}

proc process.ne { dx dy x y w h a b } {
	return [ action.ne $dx $dy $x $y $w $h $a $b ]
}

proc process.e { dx dy x y w h a b } {
	return [ action.e $dx $dy $x $y $w $h $a $b ]
}

proc process.sw { dx dy x y w h a b } {
	return [ action.sw $dx $dy $x $y $w $h $a $b ]
}

proc process.s { dx dy x y w h a b } {
	return [ action.s $dx $dy $x $y $w $h $a $b ]
}

proc process.se { dx dy x y w h a b } {
	return [ action.se $dx $dy $x $y $w $h $a $b ]
}

proc process.w { dx dy x y w h a b } {
	return [ action.w $dx $dy $x $y $w $h $a $b ]
}


}

