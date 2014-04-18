
namespace eval mv {

proc address.switch { } {
	return [ mc2 "Add/remove cycle mark" ]
}

proc address.create { item_id diagram_id x y } {
	return [ list insert items				\
		item_id				$item_id		\
		diagram_id		$diagram_id	\
		type					'address'		\
		text					address		\
		selected				1					\
		x						$x					\
		y						$y					\
		w						60					\
		h						20					\
		a						60					\
		b						0		 ]
}

proc address.lines { x y w h a b } {
	return {}
}


proc address.fit { tw th tw2 th2 x y w h a b } {
	set result [ action.fit $tw $th 0 0 $x $y $w $h $a $b ]
	lassign $result x2 y2 w2 h2 a2 b2
	incr h2 10
	return [ list $x2 $y2 $w2 $h2 $a2 $b2 ]
}

proc address.box { x y w h a b } {
	set left [ expr { $x - $w } ]
	set top [ expr { $y - $h } ]
	set right [ expr { $x + $w } ]
	set bottom [ expr { $y + 1.5 * $h } ]
	
	return [ list $left $top $right $bottom ]
}


proc address.icons { text text2 color x y w h a b } {
	lassign [ get_colors $color $colors::action_bg ] fg bg tc
	set h2 [ expr { $h / 1.5 } ]
	set middle [ expr { $y - $h + $h2 } ]
	set left [ expr { $x - $w } ]
	set right [ expr { $x + $w } ]
	set top [ expr { $y - $h } ]
	set bottom [ expr { $y + $h } ]
	set coords [ list $left $middle  $x $top  $right $middle  $right $bottom $left $bottom  $left $middle ]
	set rect_coords [ make_rect $x $y $w $h ]
	set cdbox [ add_handle_border $rect_coords ]
	set rect [ make_prim main polygon $coords "" $fg $bg $cdbox ]
	set ty [ expr { $bottom - ( $bottom - $middle ) / 2 } ]
	set text_prim [ create_text $x $ty $text $tc ]
	if { $b == 0 } {
		return [ list $rect $text_prim ]
	} else {
		set m2 [ expr { $top + ($middle - $top) / 2.0 } ]
		set x1 [ expr { $x - $w / 2.0 } ]
		set x2 [ expr { $x + $w / 2.0 } ]
		set tri [ make_prim mark polygon [ list $x1 $m2 $x $top $x2 $m2 $x1 $m2 ] "" $fg $fg $cdbox ]
		return [ list $rect $tri $text_prim ]
	}
}


proc address.handles { x y w h a b } {
	return [ action.handles $x $y $w $h $a $b ]
}

proc address.nw { dx dy x y w h a b } {
	return [ action.nw $dx $dy $x $y $w $h $a $b ]
}

proc address.n { dx dy x y w h a b } {
	return [ action.n $dx $dy $x $y $w $h $a $b ]
}

proc address.ne { dx dy x y w h a b } {
	return [ action.ne $dx $dy $x $y $w $h $a $b ]
}

proc address.e { dx dy x y w h a b } {
	return [ action.e $dx $dy $x $y $w $h $a $b ]
}

proc address.sw { dx dy x y w h a b } {
	return [ action.sw $dx $dy $x $y $w $h $a $b ]
}

proc address.s { dx dy x y w h a b } {
	return [ action.s $dx $dy $x $y $w $h $a $b ]
}

proc address.se { dx dy x y w h a b } {
	return [ action.se $dx $dy $x $y $w $h $a $b ]
}

proc address.w { dx dy x y w h a b } {
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

