namespace eval mv {

variable handles {}
variable verticals {}
variable horizontals {}
variable arrows {}
variable others {}
	
proc move_normal_handle { item_id handle dx dy } { 

	mb eval { select type, x, y, w, h, a, b from item_shadows
		where item_id = :item_id
	} {	
		set resized [ $type.$handle $dx $dy $x $y $w $h $a $b ]
		update_item $item_id $resized
		add_changed $item_id
	}
}

proc get_handle_coords { item_id handle_name } {
	mb eval {
		select type, x, y, w, h, a, b from item_shadows where item_id = :item_id
	} {
		set handles [ $type.handles $x $y $w $h $a $b ]
		foreach handle $handles {
			lassign $handle role vx vy foo
			if { $role == $handle_name } {
				return [ list $vx $vy ]
			}
		}
	}
	error [ mc2 "handle not found. item_id = \$item_id, handle_name = \$handle_name" ]
}

proc find_handle_at_position { hx hy type x y w h a b } {
	set handles [ $type.handles $x $y $w $h $a $b ]
	foreach h2 $handles {
		lassign $h2 role vx vy foo
		if { $vx == $hx && $vy == $hy } {
			return $h2
		}
	}
	return ""
}


proc prepare_line_handle { item_id handle } {
	variable handles
	variable verticals
	variable horizontals
	variable arrows
	variable others

	set handles {}
	set verticals {}
	set horizontals {}
	set arrows {}
	set others {}
	
	lassign [ get_handle_coords $item_id $handle ] hx hy
	
	mb eval { select item_id, type, x, y, w, h, a, b from item_shadows
		where type in ('vertical', 'horizontal', 'parallel', 'if', 'arrow')
	} {
		set item_info [ list $item_id $type $x $y $w $h $a $b ]
		set taken 1
		set h2 [ find_handle_at_position $hx $hy $type $x $y $w $h $a $b ]
		if { $h2 != "" } {
			lassign $h2 h2role h2x h2y foo
		}
		if { $h2 == "" || ($type == "if" && $h2role != "branch_handle") } {
			switch $type {
				"vertical" {
					if { [ point_on_vertical $hx $hy $x $y $w $h ] } {
						lappend verticals $item_id
					} else {
						set taken 0
					}
				}
				"horizontal" {
					if { [ point_on_horizontal $hx $hy $x $y $w $h ] } {
						lappend horizontals $item_id
					} else {
						set taken 0
					}
				}
				"parallel" {
					if { [ point_on_horizontal $hx $hy $x $y $w $h ] } {
						lappend horizontals $item_id
					} else {
						set taken 0
					}
				}				
				"arrow" {
					if { [ point_on_lower_arrow $hx $hy $x $y $w $h $a $b ] } {
						lappend arrows $item_id
					} else {
						set taken 0
					}
				}
				default {
					set taken 0
				}
			}
		} else {
			lappend handles [ list $item_id $h2role ]
		}
		
		if { !$taken } {
			lappend others $item_id
		}
	}
}

proc move_line_handle { dx dy } {
	variable handles
	variable verticals
	variable horizontals
	variable arrows
	variable others
	
	foreach hinfo $handles {
		lassign $hinfo item_id handle
		lassign [ get_handle_coords $item_id $handle ] hx hy
		mb eval {
			select type, x, y, w, h, a, b
			from item_shadows
			where item_id = :item_id
		} {
		
			move_normal_handle $item_id $handle $dx $dy
			switch $type {
				"vertical" {
					move_vertical_line_nei $others $x $y $w $h $dx
				}
				
				"horizontal" {
					move_horizontal_line_nei $others $x $y $w $h $dy
				}

				"parallel" {
					move_horizontal_line_nei $others $x $y $w $h $dy
				}
				
				"arrow" {
					if { $handle == "sw" || $handle == "se" } {
						move_arrow_nei $others $x $y $w $h $a $b $dy
					}
				}
				
				default {
				}
			}
		}
	}
	
	foreach item_id $arrows {
		move_arrow $others $item_id $dy
	}
	
	foreach item_id $verticals {
		move_vertical_line $others $item_id $dx
	}
	
	foreach item_id $horizontals {
		move_horizontal_line $others $item_id $dy
	}
	
}

proc move_horizontal_line { others item_id dy } {
	mb eval {
		select type, x, y, w, h, a, b
		from item_shadows
		where item_id = :item_id 
	} {	
		set resized [ horizontal.left 0 $dy $x $y $w $h $a $b ]
		update_item $item_id $resized
		add_changed $item_id
		
		move_horizontal_line_nei $others $x $y $w $h $dy
	}
}


proc move_vertical_line { others item_id dx } {
	mb eval {
		select type, x, y, w, h, a, b
		from item_shadows
		where item_id = :item_id 
	} {
	
		set resized [ vertical.top $dx 0 $x $y $w $h $a $b ]
		update_item $item_id $resized
		add_changed $item_id
		
		move_vertical_line_nei $others $x $y $w $h $dx
	}	
}


proc move_arrow { others item_id dy } {
	mb eval {
		select type, x, y, w, h, a, b
		from item_shadows
		where item_id = :item_id 
	} {	
		set resized [ arrow.sw 0 $dy $x $y $w $h $a $b ]
		update_item $item_id $resized
		add_changed $item_id
		
		set h2 [ lindex $resized 3 ]
		set dy [ expr { $h2 - $h } ]
		
		move_arrow_nei $others $x $y $w $h $a $b $dy
	}
}

proc move_arrow_nei { others x y w h a b dy } {
	
	set bottom [ expr { $y + $h } ]
	if { $b == 0 } {
		set x [ expr { $x - $a } ]
	}
	set y $bottom
	set w $a
	set h 0	
	
	move_horizontal_line_nei $others $x $y $w $h $dy	
}

proc move_vertical_line_nei { others x y w h dx } {

	foreach item_id $others {
		mb eval {
			select type, x x2, y y2, w w2, h h2, a a2, b b2
			from item_shadows
			where item_id = :item_id 
		} {	
			set handle ""
			set bottom [ expr { $y + $h } ]
			set y2in [ expr { $y2 >= $y && $y2 <= $bottom } ]
			if { [ alt::is_horizontal $type ] } {
				if { $y2in } {
					if { $x == $x2 } {
						set handle "left"
					} elseif { $x == $x2 + $w2 } {
						set handle "right"
					}
				}
			} elseif { $type == "if" } {
				if { $y2in } {
					if { $x == $x2 + $w2 + $a2 } {
						set handle "branch_handle"
					}
				}
			} elseif { $type == "arrow" } {
				set bott2 [ expr { $y2 + $h2 } ]
				set bott2in [ expr { $bott2 >= $y && $bott2 <= $bottom } ]
				if { $bott2in && $b2 == 1 && $x == $x2 + $a2 } {
					set handle "se"
				} elseif { $y2in && $b2 == 0 && $x == $x2 - $w2 } {
					set handle "nw"
				}
			}
			
			if { $handle != "" } {
				move_normal_handle $item_id $handle $dx 0
			}
		}
	}
	
	move_icons_on_skewer $x $y $h $dx
}

proc move_icons_on_skewer { lx  ly  lh  dx } {
	set bottom [ expr { $ly + $lh } ]
	mb eval {
		select item_id, type, x, y, w, h, a, b
		from item_shadows
		where type not in ('vertical', 'horizontal', 'parallel', 'arrow')
	} {
		if { [ on_skewer $x $y $w $h $lx $ly $bottom ] } {
			set x2 [ expr { $x + $dx } ]
			set a2 $a
			if { $type == "if" } {
				set a2 [ expr { $a - $dx } ]
				if { $a2 < 20 } { set a2 20 }
			}
			set resized [ list $x2 $y $w $h $a2 $b ]
			update_item $item_id $resized
			add_changed $item_id			
		}
	}
}

proc on_skewer { x  y  w  h  lx ly bottom } {
	if { $x != $lx } { return 0 }
	set top2 [ expr { $y - $h } ]
	set bottom2 [ expr { $y + $h } ]
	return [ expr { $top2 <= $bottom && $bottom2 >= $ly } ]
}

proc move_horizontal_line_nei { others x y w h dy } {

	foreach item_id $others {
		mb eval {
			select type, x x2, y y2, w w2, h h2, a a2, b b2
			from item_shadows
			where item_id = :item_id 
		} {	

			set handle ""
			set right [ expr { $x + $w } ]
			set x2in [ expr { $x2 >= $x && $x2 <= $right } ]
			if { $type == "vertical" } {
				if { $x2in } {
					if { $y == $y2 } {
						set handle "top"
					} elseif { $y == $y2 + $h2 } {
						set handle "bottom"
					}
				}
			}
			
			if { $handle != "" } {
				move_normal_handle $item_id $handle 0 $dy
			}
		}
	}
}



proc point_on_vertical { hx hy x y w h } {
	if { $hx != $x } { return 0 }
	if { $hy < $y } { return 0 }
	set bottom [ expr { $y + $h } ]
	if { $hy > $bottom } { return 0 }
	return 1
}

proc point_on_horizontal { hx hy x y w h } {
	if { $hy != $y } { return 0 }
	if { $hx < $x } { return 0 }
	set right [ expr { $x + $w } ]
	if { $hx > $right } { return 0 }
	return 1
}

proc point_on_lower_arrow { hx hy x y w h a b } {
	set bottom [ expr { $y + $h } ]
	if { $hy != $bottom } { return 0 }
	if { $b == 0 } {
		# left arrow
		set left [ expr { $x - $a } ]
		set right $x
	} else {
		# right arrow
		set left $x
		set right [ expr { $x + $a } ]
	}
	
	return [ expr { $hx > $left && $hx < $right } ]
}

}
