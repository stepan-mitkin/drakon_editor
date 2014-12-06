
namespace eval mv {

variable canvas <bad-canvas-name>
variable base <bad-name>
variable border 10
variable selection_rect ""
variable changed {}

proc init { db_name canvas_name } {
	variable canvas
	variable base
	variable selection_rect
	global script_path
	
	set canvas $canvas_name
	set base $db_name
	
	catch { mb close }
	
	set init_script [ read_all_text $script_path/scripts/canvas.sql ]
	sqlite3 mb :memory:
	mb eval $init_script
	set selection_rect ""
	alt::init_db
}

proc clear { } {
	variable selection_rect
	variable canvas
	$canvas delete all
	$canvas configure -background $colors::canvas_bg
	mb eval { delete from primitives }
	mb eval { delete from item_shadows }
	mb eval { update layers set lowest = 0, topmost = 0, prim_count = 0 }
	set selection_rect ""
	alt::clear
}

proc fill { diagram_id } {
	variable canvas
	variable base
	
	clear
	
	set origin [ list $mwc::scroll_x $mwc::scroll_y ]
	set originz [ mwc::zoom_vertices $origin ]
	mw::scroll $originz 1
	
	#$canvas create text 0 0 -text "Hello from mv::fill" -justify left -anchor nw
	
	$base eval {
		select item_id, selected
		from items
		where diagram_id = :diagram_id
		order by item_id} {
		
		insert $item_id 1
		if { $selected } {
			select $item_id 1
		}
	}
}

proc render_to { surface diagram_id  } {
	variable base
	
	$base eval {
		select item_id
		from items
		where diagram_id = :diagram_id 
    and (type = 'vertical' or type = 'horizontal' or type = 'parallel' )
		order by item_id } {

		render_item $surface $item_id
	}	
	
	$base eval {
		select item_id
		from items
		where diagram_id = :diagram_id 
    and type != 'vertical' and type != 'horizontal' and type != 'parallel' 
		order by item_id } {

		render_item $surface $item_id
	}	
}

proc layer_topmost { layer } {
	set prim_id [ mod::one mb topmost layers name '$layer' ]
	if { $prim_id == 0 } {
		return 0
	}
	return [ mod::one mb ext_id primitives prim_id $prim_id ]
}

proc layer_lowest { layer } {
	set prim_id [ mod::one mb lowest layers name '$layer' ]
	if { $prim_id == 0 } {
		return 0
	}
	return [ mod::one mb ext_id primitives prim_id $prim_id ] 
}

proc zplace { prim_id layer } {
	variable canvas
	
	set item [ mod::one mb ext_id primitives prim_id '$prim_id' ]
	set topmost [ layer_topmost $layer ]
	set lowest 0
	set id [ mod::one mb ordinal layers name '$layer' ]

	
	if { $topmost == 0 } {
		set lows [ mb eval { select name from layers where ordinal < :id order by ordinal desc } ]
		foreach low $lows {
			set topmost [ layer_topmost $low ]
			if { $topmost != 0 } { break }
		}
		
		if { $topmost == 0 } {
			set highs [ mb eval { select name from layers where ordinal > :id order by ordinal } ]
			foreach high $highs {
				set lowest [	layer_lowest $high ]
				if { $lowest != 0 } { break }
			}
		}
	}
	
	
	if { $topmost != 0 } {
		$canvas raise $item $topmost
	} elseif { $lowest != 0 } {
		$canvas lower $item $lowest
	}
	
	layer_primitive $prim_id $layer
}

proc delete_prim { prim_id } {
	variable canvas
	
	set ext_id [ mod::one mb ext_id primitives prim_id $prim_id ]
	$canvas delete $ext_id
	unlayer_primitive $prim_id
	mb eval { delete from primitives where prim_id = :prim_id }
}

proc create_normal_prim { item_id layer data } {
	lassign $data role type coords text line fill rect
	set coords [ mwc::zoom_vertices $coords ]
	create_prim $item_id $layer $role $type $coords $text $rect $line $fill
}

proc update_normal_prim { item_id data } {
	lassign $data role type coords text line fill rect
	set coords [ mwc::zoom_vertices $coords ]

	update_prim $item_id $role $coords $rect
}

proc create_prim { item_id layer role type coords text rect fore fill } {
	variable canvas
  
  	set ordinal 0
	set ids [ add_to_canvas $canvas $type $coords $text $fore $fill ]
	foreach ext_id $ids {
		set prim_id [ mod::next_key mb primitives prim_id ]
		set insert [ wrap insert primitives prim_id $prim_id item_id $item_id \
			role '$role' ordinal $ordinal above 0 below 0 ext_id $ext_id type '$type' rect '$rect' ]
		mod::apply mb $insert
	
		zplace $prim_id $layer
		
		incr ordinal
	}
}

proc remove_texts { } {
	variable canvas
	
	set ids [ mb eval { 
		select prim_id
		from primitives
		where type in ('text', 'text_left')
	} ]
	
	foreach id $ids {	
		set ext_id [ mb onecolumn { 
			select ext_id
			from primitives
			where prim_id = :id 
		} ]
		
		if { $ext_id != "" } {
			$canvas delete $ext_id
		}

		mb eval { delete from primitives where prim_id = :id }
	}	
}

proc update_prim { item_id role coords rect } {
	variable canvas
	
	mb eval { select prim_id, ext_id, type from primitives
		where item_id = :item_id and role = :role } {
		
		if { $type == "text" || $type == "text_left" } {
			$canvas itemconfigure $ext_id -state hidden
		} else {		
		
			mb eval { update primitives
				set rect = :rect
				where prim_id = :prim_id }
		
		
			$canvas coords $ext_id $coords
		}
	}
}

proc add_prim_to_canvas { surface type coords text fore fill anchor } {

	if { $mwc::zoom >= 40 } {
		set font [ mwf::get_dia_font $mwc::zoom ]
		#return [ $surface create text $coords -text $text -font $font -fill $fill -anchor $anchor ]
		return [ hl::render_text $surface $coords $text $font $fill $anchor ]
	}
	return {}
}

proc add_to_canvas { surface type coords text fore fill } {
	set result {}
	set width [ expr { ceil($mwc::zoom / 130.0) } ]
	set command [ list $surface create $type $coords ]
	if { $type == "text" } {
		return [ add_prim_to_canvas $surface $type $coords $text $fore $fill "center" ]
	} elseif { $type == "text_left" } {
		return [ add_prim_to_canvas $surface $type $coords $text $fore $fill "w" ]
	} elseif { $type == "line" } {	
		lappend result [ $surface create line $coords -fill $fill -width $width ]
	} else {
		lappend result [ $surface create $type $coords -outline $fore -fill $fill -width $width ]
	}
	return $result
}

proc make_vertex_prim { item_id layer data } {
	variable border
	lassign $data role x y fill
	
	set x2 [ mwc::zoom_value $x ]
	set y2 [ mwc::zoom_value $y ]
	
	set hvertex 4
	set coords [ make_rect $x2 $y2 $hvertex $hvertex ]
	set cdcoords [ make_rect $x $y $border $border ]
	create_prim $item_id $layer $role rectangle $coords "" $cdcoords $colors::vertex_fg $fill 
}

proc update_vertex_prim { item_id data } {
	variable border
	lassign $data role x y fill
	
	set x2 [ mwc::zoom_value $x ]
	set y2 [ mwc::zoom_value $y ]
	
	set hvertex 4
	set coords [ make_rect $x2 $y2 $hvertex $hvertex ]
	set cdcoords [ make_rect $x $y $border $border ]
	update_prim $item_id $role $coords $cdcoords
}


proc select { item_id replay } {	
	mb eval { select * from item_shadows where item_id = :item_id and selected = 0 } {
		set prim_handles [ $type.handles $x $y $w $h $a $b ]
		foreach handle $prim_handles {
			make_vertex_prim $item_id handles $handle
		}
	}
	
	mb eval { update item_shadows set selected = 1 where item_id = :item_id }
}

proc deselect { item_id replay } {
	variable canvas
	
	if { [ mod::one mb selected item_shadows item_id $item_id ] != 1 } {
		return
	}
	
	set layer_id [ mod::one mb ordinal layers name 'handles' ]
	set handles [ mb eval { select prim_id from primitives 
		where item_id = :item_id and layer_id = :layer_id } ]
		
	foreach prim_id $handles {
		delete_prim $prim_id
	}
	
	mb eval { update item_shadows set selected = 0 where item_id = :item_id }
}

proc deselect_all { } {
	variable canvas
	set layer_id [ mod::one mb ordinal layers name 'handles' ]
	mb eval { select ext_id from primitives where layer_id = :layer_id } {
		$canvas delete $ext_id
	}
	mb eval {		 
		update layers set lowest = 0, topmost = 0, prim_count = 0 where ordinal = :layer_id;
		delete from primitives where layer_id = :layer_id;
		update item_shadows set selected = 0; }
}

proc selection { start end } {
	variable selection_rect
	variable canvas
	
	set x0 [ lindex $start 0 ]
	set y0 [ lindex $start 1 ]
	set x1 [ lindex $end 0 ]
	set y1 [ lindex $end 1 ]
	
	if { $x1 < $x0 } {
		swap x1 x0
	}
	
	if { $y1 < $y0 } {
		swap y1 y0
	}
	
	set cx0 [ mwc::zoom_value $x0 ]
	set cy0 [ mwc::zoom_value $y0 ]
	set cx1 [ mwc::zoom_value $x1 ]
	set cy1 [ mwc::zoom_value $y1 ]
	if { $selection_rect == "" } {
		set selection_rect [ $canvas create rectangle $cx0 $cy0 $cx1 $cy1 -outline $colors::line_fg ]
	} else {
		$canvas coords $selection_rect $cx0 $cy0 $cx1 $cy1
	}
	
	set inside [ find_items $x0 $y0 $x1 $y1 ]
	foreach item_id $inside {
		select $item_id replay
	}
}

proc shadow_selection { } {
	return [ mb eval { select item_id from item_shadows where selected = 1 } ]
}

proc selection_hide { } {
	variable selection_rect
	variable canvas
	
	$canvas delete $selection_rect
	set selection_rect ""
}

proc find_items { left top right bottom } {
	set result {}
	mb eval { select item_id, rect from primitives } {
		set item_left [ lindex $rect 0 ]
		set item_right [ lindex $rect 2 ]
		set item_top [ lindex $rect 1 ]
		set item_bottom [ lindex $rect 3 ]
		if { [ rectangles_intersect $left $top $right $bottom $item_left $item_top $item_right $item_bottom ] } {
			if { [ lsearch $result $item_id ] == -1 } {
				lappend result $item_id
			}
		}
	}
	
	return $result
}

proc redraw { item_id replay } {
	variable base
	$base eval {
		select type, x, y, w, h, a, b, text, text2
		from items
		where item_id = :item_id
	} {
		set found [ mb onecolumn { select count(*)
			from item_shadows where item_id = :item_id } ]
		if { $found == 0 } { return }
		set data [ list $x $y $w $h $a $b ]
		update_item $item_id $data 1
		set chtext [ list $item_id $text $text2 ]
		change_text $chtext $replay

		alt::delete $item_id
		alt::insert $item_id $type $x $y $w $h $a $b
	}
}

proc drag { dx dy } {
	variable canvas
	
	if { $dx == 0 && $dy == 0 } { return }
	
	mb eval {
		select item_id, x, y, a, b, w, h from item_shadows where selected = 1 } {
		# First, move the item shadow.
		set x2 [ expr { $x + $dx } ]
		set y2 [ expr { $y + $dy } ]
		set data [ list $x2 $y2 $w $h $a $b ]
		update_item $item_id $data 0
	}
}

proc clear_changed { } {
	variable changed
	set changed {}
}

proc add_changed { item_id } {
	variable changed
	if { ![ contains $changed $item_id ] } {
		lappend changed $item_id
	}
}

proc get_changed { } {
	variable changed
	return $changed
}

proc resize { item_id handle dx dy } {

	if { $dx == 0 && $dy == 0 } { return }

	set type [ mb onecolumn {
		select type from item_shadows where item_id = :item_id } ]
	
	switch $type {
		"vertical" {
			move_line_handle $dx $dy
		}

		"parallel" {
			move_line_handle $dx $dy
		}
		
		"horizontal" {
			move_line_handle $dx $dy
		}
		
		"arrow" {
			move_line_handle $dx $dy
		}
		
		"if" {
			if { $handle == "branch_handle" } {
				move_line_handle $dx $dy
			} else {
				move_normal_handle $item_id $handle $dx $dy
			}
		}
		
		default {
			move_normal_handle $item_id $handle $dx $dy
		}
	}
}

proc change_text { data replay } {
	variable canvas
	set item_id [ lindex $data 0 ]
	set text [ lindex $data 1 ]
	set text2 [ lindex $data 2 ]
	mb eval { select ext_id from primitives
		where item_id = :item_id and role = 'text' 
	} {	
		$canvas itemconfigure $ext_id -text $text
	}
	mb eval { select ext_id from primitives
		where item_id = :item_id and role = 'secondary' 
	} {	
		$canvas itemconfigure $ext_id -text $text2
	}
	
}

proc has_text { item_id } {
	set count [ mb onecolumn { select count(*) from primitives
		where item_id = :item_id and role = 'text' } ]

	return $count
}

proc update_item { item_id resized { alt 0 } } {
	set type [ mod::one mb type item_shadows item_id $item_id ]

	set b2 [ lindex $resized 5 ]
	set resized [ snap_coords $resized ]
	set x2 [ lindex $resized 0 ]
	set y2 [ lindex $resized 1 ]
	set w2 [ lindex $resized 2 ]
	set h2 [ lindex $resized 3 ]
	set a2 [ lindex $resized 4 ]
	
	mb eval { update item_shadows set
		x = :x2,
		y = :y2,
		w = :w2,
		h = :h2,
		a = :a2,
		b = :b2
		where item_id = :item_id }
	
	if { $alt } {
		alt::update $item_id $type $x2 $y2 $w2 $h2 $a2 $b2
	}
	
	set lines [ $type.lines $x2 $y2 $w2 $h2 $a2 $b2 ]
	set icons [ $type.icons foo bar {} $x2 $y2 $w2 $h2 $a2 $b2 ]
	set handles [ $type.handles $x2 $y2 $w2 $h2 $a2 $b2 ]
	
	foreach line $lines {
		update_normal_prim $item_id $line
	}
	
	foreach icon $icons {
		update_normal_prim $item_id $icon
	}
	
	foreach handle $handles {
		update_vertex_prim $item_id $handle
	}
}

proc move_to { arg replay } {
	set diagram_id [ mwc::get_current_dia ]

	set item_id [ lindex $arg 0 ]
	set x [ lindex $arg 1 ]
	set y [ lindex $arg 2 ]
	set w [ lindex $arg 3 ]
	set h [ lindex $arg 4 ]
	set a [ lindex $arg 5 ]
	set b [ lindex $arg 6 ]
		
	set resized [ list $x $y $w $h $a $b ]
	
	update_item $item_id $resized 1
}

proc hit.impl { x y selected } {
	set layer_id [ mod::one mb ordinal layers name 'handles' ]
	mb eval { select prim_id, p.item_id item_id, rect 
		from primitives p
			inner join item_shadows i on p.item_id = i.item_id
		where layer_id != :layer_id 
			and i.selected = :selected
		order by prim_id desc } {
		if { [ hit_rectangle $rect $x $y ] } {
			return $item_id
		}
	}
	
	return ""
}

proc hit { x y } {	
	set result [ hit.impl $x $y 1 ]
	if { $result != "" } {
		return $result
	}

	set result [ hit.impl $x $y 0 ]
	if { $result != "" } {
		return $result
	}

	return $result
}

proc hit_many { x y } {
	set result {}
	mb eval { select prim_id, item_id, rect 
		from primitives
	} {
		if { [ hit_rectangle $rect $x $y ] } {
			if { ![ contains $result $item_id ] } {
				lappend result $item_id
			}
		}
	}
	return $result
}

proc hit_handle { item_id x y } {
	set margin 10
	set layer_id [ mod::one mb ordinal layers name 'handles' ]
	mb eval { select role, rect from primitives where item_id = :item_id 
		and layer_id = :layer_id } {

		if { [ hit_rectangle $rect $x $y ] } {
			return $role
		}
	}
	
	return ""
}

proc insert { item_id replay } {
	variable base
	
	set item [ mod::fetch $base items item_id $item_id	type text x y w h a b selected text2 color ]
	set type [ lindex $item 0 ]
	set text [ lindex $item 1 ]
	
	set coords [ lrange $item 2 7 ]
	set b [ lindex $coords 5 ]
	set coords [ snap_coords $coords ]
	
	set x [ lindex $coords 0 ]
	set y [ lindex $coords 1 ]
	set w [ lindex $coords 2 ]
	set h [ lindex $coords 3 ]
	set a [ lindex $coords 4 ]
	set selected [ lindex $item 8 ]
	set text2 [ lindex $item 9 ]
	set color [ lindex $item 10 ]
	
	create_shadow $item_id $type $x $y $w $h $a $b 0
	alt::insert $item_id $type $x $y $w $h $a $b
	
	set lines [ $type.lines	 $x $y $w $h $a $b ]
	set icons [ $type.icons $text $text2 $color $x $y $w $h $a $b ]
	
	foreach line $lines {
		create_normal_prim $item_id lines $line
	}
	
	foreach icon $icons {
		create_normal_prim $item_id icons $icon
	}
}

proc render_item { surface item_id } {
  variable base
  $base eval { 
    select text, text2, color, x, y, w, h, a, b, type
    from items
    where item_id = :item_id } {
  
    set lines [ $type.lines	 $x $y $w $h $a $b ]
    set icons [ $type.icons $text $text2 $color $x $y $w $h $a $b ]
	
    foreach line $lines {
	lassign $line role type coords text fore fill
	add_to_canvas $surface $type $coords $text $fore $fill
    }
    
    foreach icon $icons {
	lassign $icon role type coords text fore fill
	add_to_canvas $surface $type $coords $text $fore $fill
    }
  }
}

proc delete { item_id replay } {
	set prims [ mb eval { select prim_id from primitives where item_id = :item_id } ]
	
	foreach prim $prims {
		delete_prim $prim
	}
	
	mb eval { delete from item_shadows where item_id = :item_id }
	alt::delete $item_id
}

proc create_shadow { item_id type x y w h a b selected } {
	set commands [ wrap insert item_shadows item_id $item_id type '$type' x $x y $y w $w h $h a $a b $b selected $selected]
	mod::apply mb $commands 
}

proc layer_primitive { prim_id layer } {
	set layer_row [ mod::fetch mb layers name '$layer' topmost prim_count lowest ordinal ]
	set topmost [ lindex $layer_row 0 ]
	set primcount [ lindex $layer_row 1 ]
	set lowest [ lindex $layer_row 2 ]
	set ordinal [ lindex $layer_row 3 ]
	mb eval { update primitives set layer_id = :ordinal where prim_id = :prim_id }
	
	if { $topmost != 0 } {
		mb eval { update primitives set above = :prim_id where prim_id = :topmost }
		mb eval { update primitives set below = :topmost where prim_id = :prim_id }
	} else {
		set lowest $prim_id
	}
	
	incr primcount
	mb eval { update layers 
		set topmost = :prim_id, prim_count = :primcount, lowest = :lowest
		where name = :layer }
}

proc unlayer_primitive { prim_id } {
	set prim_row [ mb eval { select above, below, layer_id from primitives where prim_id = :prim_id } ]
	set above [ lindex $prim_row 0 ]
	set below [ lindex $prim_row 1 ]
	set layer_id [ lindex $prim_row 2 ] 

	set layer_row [ mb eval { select lowest, topmost, prim_count from layers where ordinal = :layer_id } ]	
	set lowest [ lindex $layer_row 0 ]
	set topmost [ lindex $layer_row 1 ]
	set primcount [ lindex $layer_row 2 ]
	incr primcount -1
	
	if { $prim_id == $topmost } {
		mb eval { update layers set topmost = :below where ordinal = :layer_id }
	} else {
		mb eval { update primitives set below = :below where prim_id = :above }
	}
	
	if { $prim_id == $lowest } {
		mb eval { update layers set lowest = :above where ordinal = :layer_id }
	} else {
		mb eval { update primitives set above = :above where prim_id = :below }
	}
	
	mb eval { update layers set prim_count = :primcount where ordinal = :layer_id }
	mb eval { update primitives set above = 0, below = 0 where prim_id = :prim_id }
}


}

