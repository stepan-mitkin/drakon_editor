
namespace eval mv {

proc commentin.switch { } {
	return ""
}

proc commentin.create { item_id diagram_id x y } {
	return [ list insert items				\
		item_id				$item_id		\
		diagram_id		$diagram_id	\
		type					'commentin'	\
		text					comment-in	\
		selected				1					\
		x						$x					\
		y						$y					\
		w						60					\
		h						20					\
		a						60					\
		b						0		 ]
}

proc commentin.lines { x y w h a b } {
	return {}
}

proc commentin.fit { tw th tw2 th2 x y w h a b } {
	set tmp [ action.fit $tw $th 0 0 $x $y $w $h $a $b ]
	lassign $tmp x2 y2 w2 h2 a2 b2
	incr w2 8
	return [ list $x2 $y2 $w2 $h2 $a2 $b2 ]
}


proc commentin.icons { text text2 color x y w h a b } {
	lassign [ get_colors $color $colors::action_bg ] fg bg tc
	set radius 12
	set number 8
	set margin [ expr { $radius / 2 } ]
	
	set left [ expr { $x - $w + $margin } ]
	set right [ expr { $x + $w - $margin } ]
	set top [ expr { $y - $h + $margin } ]
	set bottom [ expr { $y + $h - $margin } ]
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

	set coords [ concat $nw [ list $x1 $top ] $ne [ list $right $y1 ] $se [ list $x2 $bottom ] $sw [ list $left  $y2 ] ]
	
	set rect1_coords [ make_rect $x $y $w $h ]
	set cdbox [ add_handle_border $rect1_coords ]
	set rect1 [ make_prim main rectangle $rect1_coords "" $fg $colors::comment_bg $cdbox ]
	set screen [ make_prim screen polygon $coords "" $fg $bg $cdbox ]
	
	set text_prim [ create_text_left $x $y $w $h $text $tc ]
	return [ list $rect1 $screen $text_prim ]
}

proc commentin.box { x y w h a b } {
	return [ action.box $x $y $w $h $a $b ]
}

proc commentin.handles { x y w h a b } {
	return [ action.handles $x $y $w $h $a $b ]
}

proc commentin.nw { dx dy x y w h a b } {
	return [ action.nw $dx $dy $x $y $w $h $a $b ]
}

proc commentin.n { dx dy x y w h a b } {
	return [ action.n $dx $dy $x $y $w $h $a $b ]
}

proc commentin.ne { dx dy x y w h a b } {
	return [ action.ne $dx $dy $x $y $w $h $a $b ]
}

proc commentin.e { dx dy x y w h a b } {
	return [ action.e $dx $dy $x $y $w $h $a $b ]
}

proc commentin.sw { dx dy x y w h a b } {
	return [ action.sw $dx $dy $x $y $w $h $a $b ]
}

proc commentin.s { dx dy x y w h a b } {
	return [ action.s $dx $dy $x $y $w $h $a $b ]
}

proc commentin.se { dx dy x y w h a b } {
	return [ action.se $dx $dy $x $y $w $h $a $b ]
}

proc commentin.w { dx dy x y w h a b } {
	return [ action.w $dx $dy $x $y $w $h $a $b ]
}




proc divide_arc { radius number } {
	global pi
	set result { 0 }
	set small_angle [ expr $pi / 2.0 / $number ]
	for { set i 1 } { $i < $number } { incr i } {
		set angle [ expr $small_angle * $i ]
		set x [ expr (1.0 - cos($angle)) * $radius ]
		lappend result $x
	}
	lappend result $radius
	return $result
}

proc arc_nw { left top height number } {
	set radius [ expr $height / 2.0 ]
	set subdivs [ divide_arc $radius $number ]
	set result {}
	
	for { set i 0 } { $i < $number } { incr i } {
		set x0 [ lindex $subdivs $i ]
		set yi [ expr $number - $i ]
		set y0 [ lindex $subdivs $yi ]
		set x [ expr $x0 + $left ]
		set y [ expr $y0 + $top ]
		lappend result $x $y
	}
	return $result
}

proc arc_ne { left top width height number } {
	set radius [ expr $height / 2.0 ]
	set subdivs [ divide_arc $radius $number ]
	set result {}
	set right [ expr $left + $width ]
	
	for { set i 0 } { $i < $number } { incr i } {
		set xi [ expr $number - $i ]
		set x0 [ lindex $subdivs $xi ]
		set y0 [ lindex $subdivs $i ]
		set x [ expr $right - $x0 ]
		set y [ expr $y0 + $top ]
		lappend result $x $y
	}
	return $result
}


proc arc_se { left top width height number } {
	set radius [ expr $height / 2.0 ]
	set subdivs [ divide_arc $radius $number ]
	set result {}
	set right [ expr $left + $width ]
	
	for { set i 0 } { $i < $number } { incr i } {
		set x0 [ lindex $subdivs $i ]
		set yi [ expr $number - $i ]
		set y0 [ lindex $subdivs $yi ]
		set x [ expr $right - $x0 ]
		set y [ expr $top + $height - $y0 ]
		lappend result $x $y
	}
	return $result
}


proc arc_sw { left top height number } {
	set radius [ expr $height / 2.0 ]
	set subdivs [ divide_arc $radius $number ]
	set result {}
	
	for { set i 0 } { $i < $number } { incr i } {
		set xi [ expr $number - $i ]
		set x0 [ lindex $subdivs $xi ]
		set y0 [ lindex $subdivs $i ]
		set x [ expr $x0 + $left ]
		set y [ expr $top + $height - $y0 ]
		lappend result $x $y
	}
	return $result
}


proc rounded_outline { left top width height number } {
	set nw [ arc_nw $left $top $height $number ]
	set ne [ arc_ne $left $top $width $height $number ]
	set se [ arc_se $left $top $width $height $number ]	
	set sw [ arc_sw $left $top $height $number ]
	
	set x0 $left
	set x1 [ expr $left + $height / 2.0 ]
	set x2 [ expr $left + $width - $height / 2.0 ]
	set x3 [ expr $left + $width ]
	set bottom [ expr $top + $height ]
	
	set extent [ expr $height / 5.0 ]
	
	set leto [ list $x1 $top ]

	
	
	set ribo [ list $x2 $bottom ]
	
	set result [ concat $nw $leto   $ne $se   $ribo  $sw ]
}

proc segments_from_height { h } {
	if { $h <= 30 } { return 6 }
	if { $h <= 60 } { return 12 }
	return 16
}

proc rounded_outline_adpt { x y w h } {
	set width [ expr { $w * 2 } ]
	set height [ expr { $h * 2 } ]
	set left [ expr { $x - $w } ]
	set top [ expr { $y - $h } ]
	set number [ segments_from_height $h ]
	set coords [ rounded_outline $left $top $width $height $number ]
	return $coords
}

}

