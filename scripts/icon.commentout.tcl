
namespace eval mv {

proc commentout.switch { } {
	return [ mc2 "Flip horizontally" ]
}

proc commentout.create { item_id diagram_id x y } {
	return [ list insert items				\
		item_id				$item_id		\
		diagram_id		$diagram_id	\
		type					'commentout'			\
		text					comment-out			\
		selected				1					\
		x						$x					\
		y						$y					\
		w						60					\
		h						100					\
		a						60					\
		b						0		 ]
}

proc commentout.fit { tw th tw2 th2 x y w h a b } {
	return [ action.fit $tw $th 0 0 $x $y $w $h $a $b ]
}


proc commentout.lines { x y w h a b } {
	if { $b == 1 } {
		set left [ expr { $x + $w } ]
		set right [ expr { $left + $a } ]
	} else {
		set right [ expr { $x - $w } ]	
		set left [ expr { $right - $a } ]
	}
	set coords [ list $left $y $right $y ]
	set cdbox [ add_handle_border $coords ]	
	set line [ make_prim branch line $coords "" "" $colors::line_fg $cdbox ]
	return [ list $line ]
}

proc commentout.box { x y w h a b } {
	if { $b == 0 } {
		set left [ expr { $x - $w - $a } ]
		set right [ expr { $x + $w } ]
	} else {
		set left [ expr { $x - $w } ]
		set right [ expr { $x + $w + $a } ]
	}
	set top [ expr { $y - $h } ]	
	set bottom [ expr { $y + $h } ]
	
	return [ list $left $top $right $bottom ]

}

proc commentout.icons { text text2 color x y w h a b } {
	lassign [ get_colors $color $colors::comment_fg ] fg bg tc
	set radius 12
	set number 8
	
	set left [ expr { $x - $w} ]
	set right [ expr { $x + $w } ]
	set top [ expr { $y - $h } ]
	set bottom [ expr { $y + $h } ]
	set hh [ expr { $radius * 2 } ]
	set tt [ expr { $bottom - $hh } ]
	set width [ expr { $right - $left } ]
	
	set x1 [ expr { $left + $radius } ]
	set x2 [ expr { $right - $radius } ]
	set y1 [ expr { $top + $radius } ]
	set y2 [ expr { $bottom - $radius } ]
	
	set nw [ arc_nw $left $top $hh $number ]
	set ne [ arc_ne $left $top $width $hh $number ]
	set se [ arc_se $left $tt $width $hh $number ]	
	set sw [ arc_sw $left $tt $hh $number ]

	
	set arrow_bott [ expr { $y + 10 } ]
	
	if { $b == 0 } {
		set arrow_left [ expr { $left - $a } ]	
		set coords [ concat $nw [ list $x1 $top ] $ne [ list $right $y1 ] $se [ list $x2 $bottom ] $sw [ list $left  $y2 ] \
			[ list $left $arrow_bott  $arrow_left $y $left $y ] ]
	} else {
		set arrow_right [ expr { $right + $a } ]	
		set coords [ concat $nw [ list $x1 $top ] $ne [ list $right $y1 ] \
			[ list $right $y $arrow_right $y $right $arrow_bott ] \
			$se [ list $x2 $bottom ] $sw [ list $left  $y2 ] ]
			

	}
	
	set rect_coords [ make_rect $x $y $w $h ]
	set cdbox [ add_handle_border $rect_coords ]
	
	set rect [ make_prim main polygon $coords "" $fg $bg $cdbox ]
	set text_prim [ create_text $x $y $text $tc ]
	
	return [ list $rect $text_prim ]
}


proc commentout.handles { x y w h a b } {
	set result [ action.handles $x $y $w $h $a $b ]
	if { $b == 0 } {
		set side [ expr { $x - $w - $a } ]
	} else {
		set side [ expr { $x + $w + $a } ]
	}
	set branch_handle [ make_vertex branch_handle $side $y ]
	lappend result $branch_handle
	return $result
}

proc commentout.branch_handle { dx dy x y w h a b } {
	if { $b == 0 } {
		set a2 [ expr $a - $dx ]
	} else {
		set a2 [ expr $a + $dx ]
	}
	
	if { $a2 < 20 } { set a2 20 }
	return [ list $x $y $w $h $a2 $b ]
}

proc commentout.nw { dx dy x y w h a b } {
	return [ action.nw $dx $dy $x $y $w $h $a $b ]
}

proc commentout.n { dx dy x y w h a b } {
	return [ action.n $dx $dy $x $y $w $h $a $b ]
}

proc commentout.ne { dx dy x y w h a b } {
	return [ action.ne $dx $dy $x $y $w $h $a $b ]
}

proc commentout.e { dx dy x y w h a b } {
	return [ action.e $dx $dy $x $y $w $h $a $b ]
}

proc commentout.sw { dx dy x y w h a b } {
	return [ action.sw $dx $dy $x $y $w $h $a $b ]
}

proc commentout.s { dx dy x y w h a b } {
	return [ action.s $dx $dy $x $y $w $h $a $b ]
}

proc commentout.se { dx dy x y w h a b } {
	return [ action.se $dx $dy $x $y $w $h $a $b ]
}

proc commentout.w { dx dy x y w h a b } {
	return [ action.w $dx $dy $x $y $w $h $a $b ]
}


}
