
namespace eval mv {

proc select.switch { } {
	return ""
}

proc select.create { item_id diagram_id x y } {
	return [ list insert items				\
		item_id				$item_id		\
		diagram_id		$diagram_id	\
		type					'select'		\
		text					select		\
		selected				1					\
		x						$x					\
		y						$y					\
		w						60					\
		h						20					\
		a						60					\
		b						0		 ]
}

proc select.lines { x y w h a b } {
	return {}
}

proc select.fit { tw th tw2 th2 x y w h a b } {
	set result [ action.fit $tw $th 0 0 $x $y $w $h $a $b ]
	lassign $result x2 y2 w2 h2 a2 b2
	set w2 [ expr { $w2 + $h2 / 2 } ]
	return [ list $x2 $y2 $w2 $h2 $a2 $b2 ]
}

proc select.box { x y w h a b } {
	return [ action.box $x $y $w $h $a $b ]
}


proc select.icons { text text2 color x y w h a b } {
	lassign [ get_colors $color $colors::case_bg ] fg bg tc
	set h2 [ expr { $h / 2 } ]
	set x0 [ expr { $x - $w } ]
	set x1 [ expr { $x0 + $h2 } ]
	if { $x1 > $x } { set x1 $x }
	set x3 [ expr { $x + $w } ]
	set x2 [ expr { $x3 - $h2 } ]
	if { $x2 < $x } { set x2 $x }
	set top [ expr { $y - $h } ]
	set bottom [ expr { $y + $h } ]
	set coords [ list $x0 $bottom  $x1 $top  $x3 $top  $x2 $bottom  $x0 $bottom ]
	set rect_coords [ make_rect $x $y $w $h ]
	set cdbox [ add_handle_border $rect_coords ]
	set rect [ make_prim main polygon $coords "" $fg $bg $cdbox ]
	set text_prim [ create_text $x $y $text $tc ]
	return [ list $rect $text_prim ]
}


proc select.handles { x y w h a b } {
	return [ action.handles $x $y $w $h $a $b ]
}

proc select.nw { dx dy x y w h a b } {
	return [ action.nw $dx $dy $x $y $w $h $a $b ]
}

proc select.n { dx dy x y w h a b } {
	return [ action.n $dx $dy $x $y $w $h $a $b ]
}

proc select.ne { dx dy x y w h a b } {
	return [ action.ne $dx $dy $x $y $w $h $a $b ]
}

proc select.e { dx dy x y w h a b } {
	return [ action.e $dx $dy $x $y $w $h $a $b ]
}

proc select.sw { dx dy x y w h a b } {
	return [ action.sw $dx $dy $x $y $w $h $a $b ]
}

proc select.s { dx dy x y w h a b } {
	return [ action.s $dx $dy $x $y $w $h $a $b ]
}

proc select.se { dx dy x y w h a b } {
	return [ action.se $dx $dy $x $y $w $h $a $b ]
}

proc select.w { dx dy x y w h a b } {
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

