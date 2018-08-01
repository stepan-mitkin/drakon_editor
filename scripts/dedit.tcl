


namespace eval mwc {

variable db <bad-db>
variable canvas_state <bad-canvas_state>
variable drag_last <bad-drag_last>
variable drag_item <bad-drag_item>
variable drag_handle <bad-drag_handle>
variable start_x 0
variable start_y 0
variable old_x_snap 0
variable old_y_snap 0

variable zooms { 20 40 50 60 70 75 80 85 90 95 100 105 110 120 130 140 150 160 180 200 250 300 400 500 }

# View: current diagram, scroll and zoom
variable zoom 100
variable scroll_x 0
variable scroll_y 0
variable g_current_dia ""

variable closed 0

proc get_db { } {
	variable db
	return $db
}

proc change_zoom_up { canvas_width canvas_height } {
	variable zoom
	set new_zoom [ zoomup $zoom ]
	change_zoom_to $canvas_width $canvas_height $new_zoom
}

proc change_zoom_down { canvas_width canvas_height } {
	variable zoom
	set new_zoom [ zoomdown $zoom ]
	change_zoom_to $canvas_width $canvas_height $new_zoom
}

proc find_scroll { screen old_scroll old_zoom new_zoom } {
	set model [ expr { $screen / $old_zoom * 100.0 + $old_scroll } ]
	set scroll [ expr { $model - $screen / $new_zoom * 100.0 } ]
	return $scroll
}

proc apply_zoom_to_all {} {
    variable db
    variable zoom
    $db eval {
        update diagrams
        set zoom = :zoom
    }
}

proc change_zoom_to { canvas_width canvas_height new_zoom } {
	variable zoom
	variable db
	variable scroll_x
	variable scroll_y

	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }

	set old_zoom $zoom
	set zoom $new_zoom
	set screenx [ expr { double($mw::mouse_x0) } ]
	set screeny [ expr { double($mw::mouse_y0) } ]

	set scroll_x [ find_scroll $screenx $scroll_x $old_zoom $zoom ]
	set scroll_y [ find_scroll $screeny $scroll_y $old_zoom $zoom ]

	mv::fill $diagram_id
}

proc zoom_to_fit { w h cw ch } {
	set zoomx [ expr { floor( 100.0 * $cw / $w ) } ]
	set zoomy [ expr { floor( 100.0 * $ch / $h ) } ]
	if { $zoomx < $zoomy } {
		set zoom $zoomx
	} else {
		set zoom $zoomy
	}

	if { $zoom > 100 } { set zoom 100 }
	
	return $zoom
}

proc zoom_see_all { canvas_width canvas_height } {
	variable zoom
	variable db
	variable scroll_x
	variable scroll_y

	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }
	
	lassign [ find_diagram_rect $db $diagram_id ] left top width height

	set zoom [ zoom_to_fit $width $height $canvas_width $canvas_height ]

	set scroll_x $left
	set scroll_y $top

	mv::fill $diagram_id
}

proc zoom_home {  } {
	variable db
	variable scroll_x
	variable scroll_y

	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }
	
	lassign [ find_diagram_rect $db $diagram_id ] left top width height

	set scroll_x $left
	set scroll_y $top

	mv::fill $diagram_id
}

proc go_to_branch { {foo ""} } {
	set branches [ p.get_branches ]
	if { $branches == "" } { return }
	jumpto::go_to_branch $branches
}

proc zoom_vertices { vertices } {
	return [ map -list $vertices -fun mwc::zoom_value ]
}

proc zoom_value { value } {
	variable zoom
	return [ expr { int($zoom / 100.0 * $value ) } ]
}

proc unzoom_value { value } {
	variable zoom
	return [ expr { int($value * 100.0 / $zoom) } ]
}


proc zoomup { old } {
	variable zooms
	set oldi [ expr { int($old) } ]
	set length [ llength $zooms ]
	for { set i 0 } { $i < $length } { incr i } {
		set next_i [ expr { $i + 1 } ]
		set value [ lindex $zooms $i ]
		if { $next_i == $length || $value > $oldi } {
			return $value
		}
	}
}

proc zoomdown { old } {
	variable zooms
	set oldi [ expr { int($old) } ]
	set length [ llength $zooms ]
	for { set i [ expr { $length - 1 } ] } { $i >= 0 } { incr i -1 } {
		set value [ lindex $zooms $i ]
		if { $i == 0 || $value < $oldi } {
			return $value
		}
	}
}

proc remember_old_pos { x y } {
	variable start_x
	variable start_y
	variable old_x_snap
	variable old_y_snap

	set start_x $x
	set start_y $y
	
	set old_x_snap 0
	set old_y_snap 0
}

proc snap_dx { x } {
	variable old_x_snap
	variable start_x
	
	set full_dx [ expr { $x - $start_x } ]
	set dx_snap [ snap_delta $full_dx ]
	set dx [ expr { $dx_snap - $old_x_snap } ]
	set old_x_snap $dx_snap
	return $dx
}

proc snap_dy { y } {
	variable old_y_snap
	variable start_y
	
	set full_dy [ expr { $y - $start_y } ]
	set dy_snap [ snap_delta $full_dy ]
	set dy [ expr { $dy_snap - $old_y_snap } ]
	set old_y_snap $dy_snap
	return $dy
}

proc init { dbname } {
	variable db
	set db $dbname
	state reset
	back::init
}

proc hover { cx cy shift } {
	set cx [ unzoom_value $cx ]
	set cy [ unzoom_value $cy ]	
	
	insp::remember $cx $cy
	
	set item_below [ mv::hit $cx $cy ]
	if { $item_below == "" } {
		set cursor normal 
	} elseif { $shift } {
		set cursor item
	} else {
		set drag_handle [ mv::hit_handle $item_below $cx $cy ]
		if { $drag_handle == "" } {
			set cursor item
		} else {
			set cursor handle
		}    
	}

	mw::update_cursor $cursor
}

proc delete { ignored } {
	variable db
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }
	
	if { ![ state is idle ] } { return }

	set count [ $db onecolumn { select count(*) from items
		where diagram_id = :diagram_id and selected = 1 } ]
		
	if { $count == 0 } { return }
	
	begin_transaction delete

	start_action  [ mc2 "Delete" ]

	push_delete_items $diagram_id
	
	commit_transaction delete
}

proc adjust_sizes { } {
	variable db
	
	set diagram_id [ editor_state $db current_dia ]
	if { [ is_drakon $diagram_id ] } {
		adjust_icon_sizes_current
	} else {
		mv::fill $diagram_id
	}
}

proc change_text_and_fit { old_data new_text } {
	do_change_text $old_data $new_text
	adjust_sizes
}

proc has_2_texts { type } {
	set double {
		"output" "input" "process" "shelf"
	}
	
	return [ contains $double $type ]
}

proc double_click { cx cy } {
	variable db
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }

	set cx [ unzoom_value $cx ]
	set cy [ unzoom_value $cy ]
	
	set item_id [ mv::hit $cx $cy ]
	if { $item_id == "" } { return }
	if { ![ mv::has_text $item_id ] } { return }
	
	lassign [ $db eval {
		select type, x, y, w, h, a, b
		from items
		where item_id = :item_id
	} ] type x y w h a b

	if { $type == "address" } { return }
	
	set has_2 [ has_2_texts $type ]
	if { $has_2 } {
		set secondary [ mv::$type.is_top $cx $cy $x $y $w $h $a $b ]
	} else {
		set secondary 0
	}
	
	show_change_text_dialog $item_id $secondary
}


proc request_text_change { primary } {
	variable db
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }
	
	set selected [ $db eval { select item_id
					from items where diagram_id = :diagram_id
					and selected = 1 } ]
	
	if { [ llength $selected ] != 1 } { return }
	
	set item_id [ lindex $selected 0 ]	

	if { ![ mv::has_text $item_id ] } { return }
	
	set type [ $db onecolumn {
		select type
		from items
		where item_id = :item_id
	} ]

	if { $type == "address" } { return }
	
	if { $primary } {
		show_change_text_dialog $item_id 0
	} else {
		set has_2 [ has_2_texts $type ]
		if { $has_2 } {
			show_change_text_dialog $item_id 1
		}
	}
}

proc file_description { } {
	variable db

	set old [ $db onecolumn { select description from state where row = 1 } ]
	ui::text_window [ mc2 "Edit file description" ] $old mwc::do_file_description $old
}

proc add_text_change { action rollback change_info table key field } {
	variable db
	upvar 1 $action do
	upvar 1 $rollback undo

	lassign $change_info id text
	set text [ sql_escape $text ]
	set old_text [ mod::one $db $field $table $key $id ]
	set old_text [ sql_escape $old_text ]
	
	lappend do [ list update $table $key $id $field '$text' ]
	lappend undo [ list update $table $key $id $field '$old_text' ]
}

proc adjust_icon_sizes_current { } {
	variable db
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }
	
	begin_transaction adjust_icon_sizes_current
	save_view
	start_action  [ mc2 "Adjust icon sizes for diagram" ]

	set do_gui [ wrap mwc::refill_current foo ]
	set undo_gui $do_gui

	com::push $db $do_gui {} $undo_gui {}

	adjust_icons_in_dia $diagram_id

	com::push $db $do_gui {} $undo_gui {}

	commit_transaction adjust_icon_sizes_current
}

proc adjust_icon_sizes { } {
	variable db

	begin_transaction adjust_icon_sizes
	save_view
	start_action  [ mc2 "Adjust icon sizes" ]

	set diagrams [ $db eval {
		select diagram_id from diagrams
	} ]

	set do_gui [ wrap mwc::refill_current foo ]
	set undo_gui $do_gui

	com::push $db $do_gui {} $undo_gui {}

	foreach diagram_id $diagrams {
		adjust_icons_in_dia $diagram_id
	}

	com::push $db $do_gui {} $undo_gui {}

	commit_transaction adjust_icon_sizes
}

proc adjust_icons_in_dia { diagram_id } {
	variable db
	
	set icons_to_adjust [ $db eval {
		select item_id
		from items
		where type not in ('vertical', 'horizontal', 'parallel', 'arrow', 'commentout' ) 
			and diagram_id = :diagram_id
	} ]

	set verticals [ $db eval {
		select item_id
		from items
		where type = 'vertical'
			and diagram_id = :diagram_id
	} ]
	
	array set items {}
	
	foreach item_id $icons_to_adjust {
		set coords [ fit_for_text $item_id ]
		set items($item_id) $coords
	}
	
	if { [ is_drakon $diagram_id ] } {
		set actions_on_v {}
	
		foreach item_id $icons_to_adjust {
			if { [ on_any_vertical $item_id $verticals ] } {
				lappend actions_on_v $item_id
			}
		}
	
		foreach item1 $actions_on_v {
			foreach item2 $actions_on_v {
				set type [ $db onecolumn { select type from items where item_id = :item2 } ]
				if { $type == "beginend" } { continue }
				if { $item1 != $item2 && [ on_same_vertical $item1 $item2 items ] } {
					expand_if_other_wider $item1 $item2 items
				}
			}
		}
	}
		
	foreach item_id $icons_to_adjust {
		lassign $items($item_id) old new
		push_changed_coords $item_id $old $new
	}
}

proc on_same_vertical { item1 item2 items_array } {
	upvar 1 $items_array items
	set new1 [ lindex $items($item1) 1 ]
	set new2 [ lindex $items($item2) 1 ]
	set x1 [ lindex $new1 0 ]
	set x2 [ lindex $new2 0 ]
	return [ expr { $x1 == $x2 } ]
}

proc expand_if_other_wider { this other items_array } {
	variable db
	upvar 1 $items_array items

	set old1 [ lindex $items($this) 0 ]
	set new1 [ lindex $items($this) 1 ]
	set new2 [ lindex $items($other) 1 ]
	set w1 [ lindex $new1 2 ]
	set w2 [ snap_up [ lindex $new2 2 ] ]
	if { $w2 > $w1 } {
		lassign [ $db eval {
			select type, w, h, a, b
			from items
			where item_id = :this
		} ] type w h a b
		if { $type == "beginend" } { return }
		if { $type == "if" } {
			set new1_changed [ adjust_if_exit $new1 $w2 ]
		} else {
			set new1_changed [ lreplace $new1 2 2 $w2 ]
		}
		set coords_changed [ list $old1 $new1_changed ]
		set items($this) $coords_changed
	}
}

proc adjust_if_exit { coords w2 } {
	lassign $coords x y w h a b
	set diff [ expr { $w2 - $w } ]
	set a2 [ expr { $a - $diff } ]
	if { $a2 < 20 } { set a2 20 }

	set result [ list $x $y $w2 $h $a2 $b ]

	return $result
}

proc on_any_vertical { item_id verticals } {
	foreach vertical_id $verticals {
		if { [ item_on_vertical $item_id $vertical_id ] } {
			return 1
		}
	}
	return 0
}

proc item_on_vertical { item_id vertical_id } {
	variable db
	lassign [ $db eval { select x, y, h from items where item_id = :item_id } ] xi yi hi
	lassign [ $db eval { select x, y, h from items where item_id = :vertical_id } ] x y h
	if { $xi == $x } {
		set top [ expr { $yi - $hi } ]
		set bottom [ expr { $yi + $hi } ]
		set line_bottom [ expr { $y + $h } ]
		return [ expr { $y <= $bottom && $line_bottom >= $top } ]
	} else {
		return 0
	}
}

proc global_replace { file diagrams icons secondaries } {
	variable db

	begin_transaction global_replace
	start_action  [ mc2 "Replace all" ]
	set action {}
	set rollback {}
	
	foreach icon $icons {
		add_text_change action rollback $icon items item_id text
	}

	foreach icon $secondaries {
		add_text_change action rollback $icon items item_id text2
	}

	foreach diagram $diagrams {
		add_text_change action rollback $diagram diagrams diagram_id description
	}
	
	foreach file_descr $file {
		lassign $file_descr foo description
		set change [ list 1 $description ]
		add_text_change action rollback $change state row description
	}

	set do {}
	set current_diagram_id [ editor_state $db current_dia ]
	if { $current_diagram_id != "" } {
		lappend do [ list mw::select_dia $current_diagram_id ]
	}

	com::push $db $do $action $do $rollback

	commit_transaction global_replace
}

proc do_file_description { ignored new_text } {
	variable db
	
	set old_text [ $db onecolumn { select description from state where row = 1 } ]
	if { $old_text == $new_text } { return 1 }
	
	set new_text_esc [ sql_escape $new_text ]
	set old_text_esc [ sql_escape $old_text ]
		
	set change [ wrap update state row 1 description '$new_text_esc' ]
	set change_back [ wrap update state row 1 description '$old_text_esc' ]

	set do {}
	set undo {}
	
	begin_transaction do_file_description
	start_action  [ mc2 "Change file description" ]
	
	com::push $db $do $change $undo $change_back
	
	commit_transaction do_file_description
	state reset
	
	return 1
}

proc show_change_text_dialog { item_id secondary } {
	variable db

	if { $secondary } {
		set title [ mc2 "Change icon secondary text: item \$item_id" ]
		set old_text [ mod::one $db text2 items item_id $item_id ]
	} else {
		set title [ mc2 "Change icon text: item \$item_id" ]
		set old_text [ mod::one $db text items item_id $item_id ]
	}		
	
	set user_data [ list $item_id $old_text $secondary ]
	ui::text_window $title $old_text mwc::change_text_and_fit $user_data	
}

proc change_text { item_id } {
	show_change_text_dialog $item_id 0
}

proc change_secondary_text { item_id } {
	show_change_text_dialog $item_id 1
}


proc is_header { item_id } {
	variable db
	
	set row [ $db eval { select item_id, diagram_id, type, x, y from items where item_id = :item_id } ]
	lassign $row item_id diagram_id type x y
	if { $type != "beginend" } {
		return 0
	}
	
	set to_nw [ $db onecolumn { select count(*) from items
		where diagram_id = :diagram_id
		and item_id != :item_id
		and type = 'beginend'
		and (x < :x or y < :y ) } ]
		
	if { $to_nw == 0 } {
		return 1
	}
	
	return 0
}

proc find_header { diagram_id } {
	variable db
	$db eval { select item_id from items where diagram_id = :diagram_id and type = 'beginend' } {
		if { [ is_header $item_id ] } {
			return $item_id
		}
	}
	return ""
}

proc p.measure_text { text } {

	set text_size [ mw::measure_text $text ]
	lassign $text_size tw th
	set tw [ expr { $tw / 2 } ]
	set th [ expr { $th / 2 } ]
	set tw [ snap_up $tw ]
	set th [ snap_up $th ]
	incr tw 10
	incr th 10

	if { $text == {} } {
		set tw 0
	}

	return [ list $tw $th ]
}

proc p.fit { text text2 type oldx oldy oldw oldh olda oldb} {
	lassign [ p.measure_text $text ] tw th
	lassign [ p.measure_text $text2 ] tw2 th2
	set new_fields [ mv::$type.fit $tw $th $tw2 $th2 $oldx $oldy $oldw $oldh $olda $oldb ]
	return $new_fields
}

proc push_fit_text { item_id } {
	variable db

	set old_fields [ $db eval { select text, text2, type, x, y, w, h, a, b
		from items where item_id = :item_id } ]
	lassign $old_fields old_text old_text2 type oldx oldy oldw oldh olda oldb


	set new_fields [ p.fit $old_text $old_text2 $type $oldx $oldy $oldw $oldh $olda $oldb ]
	lassign $new_fields x y w h a b
		
	set change [ wrap update items item_id $item_id \
		x $x y $y w $w h $h a $a b $b ]
	set change_back [ wrap update items item_id $item_id \
		x $oldx y $oldy w $oldw h $oldh a $olda b $oldb ]

	com::push $db {} $change {} $change_back
}

proc push_changed_coords { item_id old new } {
	variable db
	lassign $old oldx oldy oldw oldh olda oldb
	lassign $new x y w h a b
	set change [ wrap update items item_id $item_id \
		x $x y $y w $w h $h a $a b $b ]
	set change_back [ wrap update items item_id $item_id \
		x $oldx y $oldy w $oldw h $oldh a $olda b $oldb ]

	com::push $db {} $change {} $change_back	
}

proc fit_for_text { item_id } {
	variable db

	set old_fields [ $db eval { select text, text2, type, x, y, w, h, a, b
		from items where item_id = :item_id } ]
	lassign $old_fields old_text old_text2 type oldx oldy oldw oldh olda oldb


	set new_fields [ p.fit $old_text $old_text2 $type $oldx $oldy $oldw $oldh $olda $oldb ]

	
	set old [ list $oldx $oldy $oldw $oldh $olda $oldb ]

	return [ list $old $new_fields ]		
}


proc push_change_text { item_id new_text } {
	variable db

	set old_fields [ $db eval { select text, text2, type, x, y, w, h, a, b
		from items where item_id = :item_id } ]
	lassign $old_fields old_text old_text2 type oldx oldy oldw oldh olda oldb

	set new_text_esc [ sql_escape $new_text ]
	set old_text_esc [ sql_escape $old_text ]

	set new_fields [ p.fit $new_text $old_text2 $type $oldx $oldy $oldw $oldh $olda $oldb ]
	lassign $new_fields x y w h a b
		
	set change [ wrap update items item_id $item_id text '$new_text_esc' \
		x $x y $y w $w h $h a $a b $b ]
	set change_back [ wrap update items item_id $item_id text '$old_text_esc' \
		x $oldx y $oldy w $oldw h $oldh a $olda b $oldb ]

		
	set do [ wrap mv::redraw $item_id ]
	set undo $do
	
	com::push $db $do $change $undo $change_back
}

proc push_change_secondary_text { item_id new_text2 } {
	variable db

	set old_fields [ $db eval { select text, text2, type, x, y, w, h, a, b
		from items where item_id = :item_id } ]
	lassign $old_fields old_text old_text2 type oldx oldy oldw oldh olda oldb

	set new_text_esc [ sql_escape $new_text2 ]
	set old_text_esc [ sql_escape $old_text2 ]

	set new_fields [ p.fit $old_text $new_text2 $type $oldx $oldy $oldw $oldh $olda $oldb ]
	lassign $new_fields x y w h a b
		
	set change [ wrap update items item_id $item_id text2 '$new_text_esc' \
		x $x y $y w $w h $h a $a b $b ]
	set change_back [ wrap update items item_id $item_id text2 '$old_text_esc' \
		x $oldx y $oldy w $oldw h $oldh a $olda b $oldb ]

		
	set do [ wrap mv::redraw $item_id ]
	set undo $do
	
	com::push $db $do $change $undo $change_back
}


proc change_icon_text2 { data } {
	lassign $data item_id new_text
	change_icon_text $item_id $new_text
	adjust_sizes
}

proc change_icon_text { item_id new_text } {
	variable db
	
	begin_transaction change_icon_text
	start_action  [ mc2 "Change text" ]

	push_change_text $item_id $new_text
	
	commit_transaction change_icon_text
	state reset
	return 1
}

proc change_icon_secondary_text { item_id new_text } {
	variable db
	
	begin_transaction change_icon_secondary_text
	start_action  [ mc2 "Change secondary text" ]

	push_change_secondary_text $item_id $new_text
	
	commit_transaction change_icon_secondary_text
	state reset
	return 1
}

proc do_change_text { old_data new_text } {
	variable db
	set item_id [ lindex $old_data  0 ]
	set secondary [ lindex $old_data 2 ]

	if { $secondary } {
		set action_name [ mc2 "Change secondary text" ]
	} else {	
		set action_name [ mc2 "Change text" ]
	}
	
	begin_transaction do_change_text
	
	start_action  $action_name
	
	set diagram_id [ editor_state $db current_dia ]
	if { [ is_drakon $diagram_id ] } {
		if { [ is_header $item_id ] } {

			if { $diagram_id != "" } {
				set dia_name [ string map { "'" "" } $new_text ]
				if { [ $db onecolumn { select count(*)
					from diagrams where name = :dia_name } ] == 0 } {
					push_rename_dia $diagram_id $dia_name
				}
			}
		}
	
		if { [ p.is_branch $item_id ] } {
			set addresses [ p.find_pointing_to $item_id ]
			foreach address $addresses {
				push_change_text $address $new_text
			}
		}
	}
	
	if { $secondary } {
		push_change_secondary_text $item_id $new_text
	} else {
		push_change_text $item_id $new_text
	}	
	commit_transaction do_change_text
	state reset
	return 1
}

proc p.is_branch { item_id } {
	variable db
	set type [ $db onecolumn {
		select type
		from items
		where item_id = :item_id } ]
	return [ expr { $type == "branch" } ]
}

proc p.find_pointing_to { item_id } {
	variable db
	lassign [ $db eval {
		select text, diagram_id
		from items
		where item_id = :item_id } ] text diagram_id
	return [ $db eval {
		select item_id
		from items
		where diagram_id = :diagram_id
			and text = :text
			and type = 'address' } ]
}

proc ldown { move_data ctrl shift } {
	variable db
	variable drag_last
	variable drag_item
	variable drag_handle
	
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } {
		state reset
		return
	}
	
	mv::clear_changed
	
	set cx [ lindex $move_data 2 ]
	set cy [ lindex $move_data 3 ]
	set cx [ unzoom_value $cx ]
	set cy [ unzoom_value $cy ]
	
	remember_old_pos $cx $cy
	set drag_last [ list $cx $cy ]
	set drag_item [ mv::hit $cx $cy ]
	if { $drag_item == "" } {
		if { !$ctrl } {
			mv::deselect_all
		}
		state change selecting.start
	} elseif { $shift } {
		set drag_items [ mv::hit_many $cx $cy ]
		state change alt_drag.start
		alt::start $drag_items $cx $cy
	} else {
		state change dragging.start
		set selected [ mod::one $db selected items item_id $drag_item ]
		if { $selected == 1 } {
			if { $ctrl } {
				mv::deselect $drag_item 0
			} else {
				set drag_handle [ mv::hit_handle $drag_item $cx $cy ]
				if { $drag_handle != "" } {
					state change resizing.start
					mv::prepare_line_handle $drag_item $drag_handle
				}
			}
		} else {
			if { !$ctrl } {
				mv::deselect_all
			}
			mv::select $drag_item 0
		}		 
	} 
}

proc lmove { move_data } {
	variable db
	variable drag_last
	variable drag_item
	variable drag_handle
	
	set cx [ lindex $move_data 2 ]
	set cy [ lindex $move_data 3 ]
	set cx [ unzoom_value $cx ]
	set cy [ unzoom_value $cy ]	
	set dx [ lindex $move_data 4 ]
	set dy [ lindex $move_data 5 ]
	
	set item_below [ mv::hit $cx $cy ]
	
	set dx [ snap_dx $cx ]
	set dy [ snap_dy $cy ]
	
	if { [ state is selecting ] || [ state is selecting.start ] } {
		state change selecting
		mv::selection $drag_last [ list $cx $cy ]
	} elseif { $dx != 0 || $dy != 0 } {
		if { [ state is dragging ] || [ state is dragging.start ] } {
			state change dragging
			mv::drag $dx $dy
			set cursor item
		} elseif { [ state is resizing ] || [ state is resizing.start ] } {
			state change resizing
			mv::resize $drag_item $drag_handle $dx $dy
			set cursor handle
		} elseif { [ state is alt_drag ] || [ state is alt_drag.start ] } {
			state change alt_drag
			set cursor item
			alt::mouse_move $dx $dy
		}
	}
	
	set cursor [ get_cursor ]
	mw::update_cursor $cursor	
}

proc get_cursor { } {
	if { [ state is dragging ] || [ state is dragging.start ] } {
		set cursor item
	} elseif { [ state is resizing ] || [ state is resizing.start ] } {
		set cursor handle
	} elseif { [ state is alt_drag ] || [ state is alt_drag.start ] } {
		set cursor item
	} else {
		set cursor normal
	}
	return $cursor
}


proc lup { move_data } {
	variable db
	variable drag_item
		
	begin_transaction lup
	set diagram_id [ editor_state $db current_dia ]
	
	mv::selection_hide
	
	if { [ state is selecting.start ] } {
		push_unselect_items $diagram_id
	} elseif { [ state is dragging.start ] || [ state is resizing.start ] } {
		take_selection_from_shadow $diagram_id
	} elseif { [ state is selecting ] } {		 
		take_selection_from_shadow $diagram_id
	} elseif { [ state is dragging ] } {
		take_selection_from_shadow $diagram_id
		start_action  [ mc2 "Move items" ]
		take_drag_from_shadow
		mv::fill $diagram_id
	} elseif { [ state is resizing ] } {
		take_selection_from_shadow $diagram_id
		start_action  [ mc2 "Change shape" ]
		set changed [ mv::get_changed ]
		foreach changed_item $changed {
			take_resize_from_shadow $changed_item
		}
		mv::fill $diagram_id
	} elseif { [ state is alt_drag ] } {
		start_action  [ mc2 "Move and change items" ]
		take_shapes_from_shadow [ mv::get_changed ]
		mv::fill $diagram_id
	}
	
	commit_transaction lup
	state reset
}

proc rdown { cx cy } {
	variable db
	

	
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }
	
	set cx [ unzoom_value $cx ]
	set cy [ unzoom_value $cy ]

	insp::remember $cx $cy

	set hit_item [ mv::hit $cx $cy ]
	if { $hit_item == "" } { return }
		
	set selected [ mod::one $db selected items item_id $hit_item ]
	if { !$selected } {
		begin_transaction rdown
		
		push_unselect_items $diagram_id
		push_select_item $hit_item
		
		
		commit_transaction rdown
	}
}

proc select_all { } {
	variable db
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }
	
	if { ![ state is idle ] } { return }
	
	begin_transaction select_all
	
	push_unselect_items $diagram_id
	
	$db eval { select item_id from items where diagram_id = :diagram_id } {
		push_select_item $item_id
	}
	
	commit_transaction select_all
}

proc begin_transaction { procedure } {
	variable db
	log "begin transaction: $procedure"
	$db eval { begin transaction }
	udb eval { begin transaction }	
}

proc commit_transaction { procedure } {
	variable db
	global use_log
	log "commit transaction: $procedure"
	udb eval { commit transaction }
	$db eval { commit transaction }
	if { $use_log } {
		check_integrity
	}
}


proc do_create_item { name } {
	variable db
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }
	
	if { ![ state is idle ] } { return }
	
	set constructor mv::$name.create
	
	begin_transaction do_create_item
	save_view
	
	set item_id [ mod::next_key $db items item_id ]

	set origin [ insp::current ]
	set origin [ snap_coords $origin ]
	lassign $origin x y
	
	set create_one [ $constructor $item_id $diagram_id $x $y ]
	#set text [ sql_escape [ lindex $create_one 9 ] ]
	set create_one [ lreplace $create_one 9 9 '' ]
	
	set w [ lindex $create_one 17 ]
	set h [ lindex $create_one 19 ]
	set a [ lindex $create_one 21 ]
	set b [ lindex $create_one 23 ]
	
	set new_fields [ p.fit "something" "" $name $x $y $w $h $a $b ]
	lassign $new_fields x y w h a b
	set create_one [ lreplace $create_one 17 17 $w ]
	set create_one [ lreplace $create_one 19 19 $h ]
	set create_one [ lreplace $create_one 21 21 $a ]
	set create_one [ lreplace $create_one 23 23 $b ]

	set create [ list $create_one ]
	set destroy [ wrap delete items item_id $item_id ]
	set do [ list [ list mv::insert $item_id ] [ list mv::select $item_id ] ]
	set undo [ list [ list mv::deselect $item_id ] [ list mv::delete $item_id ] ]

	add_friend_items $diagram_id $name $create_one create destroy do undo
	
	start_action  [ mc2 "Insert '\$name' icon" ]
	
	push_unselect_items $diagram_id
	com::push $db $do $create $undo $destroy
	
	commit_transaction do_create_item 
}

proc add_friend_items { diagram_id name create_one createv destroyv dov undov } {
	upvar 1 $createv create
	upvar 1 $destroyv destroy
	upvar 1 $dov do
	upvar 1 $undov undo
	
	array set fields $create_one
	set item_id $fields(item_id)
	set x $fields(x)
	set y $fields(y)
	set w $fields(w)
	set h $fields(h)
	set a $fields(a)
	set b $fields(b)
	
	set item2 $item_id
	set item3 $item_id
	
	incr item2
	incr item3 2
	
	if { $name == "if" } {
		set w2 [ expr { $w + $a } ]
		set vx [ expr { $x + $w2 } ]
		set height 150
		
		set vertical [ mv::vertical.create $item2 $diagram_id $vx $y ]
		set vertical [ lreplace $vertical 19 19 $height ]
		set vertical [ lreplace $vertical 9 9 '' ]

		append_with_item $item2 $vertical create destroy do undo
		
		set hy [ expr { $y + $height } ]
		
		set horizontal [ mv::horizontal.create $item3 $diagram_id $x $hy ]
		set horizontal [ lreplace $horizontal 17 17 $w2 ]
		set horizontal [ lreplace $horizontal 9 9 '' ]

		append_with_item $item3 $horizontal create destroy do undo
	} elseif { $name == "select" } {
		set length 300
		set height 150
		set hy [ expr { $y + $h + 20 } ]
		set cy [ expr { $hy + 40 } ]
		set x1 $x
		set x2 [ expr { $x1 + $length / 2 } ]
		set x3 [ expr { $x1 + $length } ]

	
		set itemh [ expr { $item_id + 1 } ]
		set itemc1 [ expr { $itemh + 1 } ]
		set itemc2 [ expr { $itemh + 2 } ]
		set itemc3 [ expr { $itemh + 3 } ]
		set itemv2 [ expr { $itemh + 4 } ]
		set itemv3 [ expr { $itemh + 5 } ]

		set horizontal [ mv::horizontal.create $itemh $diagram_id $x $hy ]
		set horizontal [ lreplace $horizontal 17 17 $length ]
		set horizontal [ lreplace $horizontal 9 9 '' ]

		append_with_item $itemh $horizontal create destroy do undo
		
		set vertical2 [ mv::vertical.create $itemv2 $diagram_id $x2 $hy ]
		set vertical2 [ lreplace $vertical2 19 19 $height ]
		set vertical2 [ lreplace $vertical2 9 9 '' ]
		append_with_item $itemv2 $vertical2 create destroy do undo
		
		set vertical3 [ mv::vertical.create $itemv3 $diagram_id $x3 $hy ]
		set vertical3 [ lreplace $vertical3 19 19 $height ]
		set vertical3 [ lreplace $vertical3 9 9 '' ]
		append_with_item $itemv3 $vertical3 create destroy do undo
		
		set c1 [ mv::case.create $itemc1 $diagram_id $x1 $cy ]
		set c1 [ lreplace $c1 9 9 '' ]
		append_with_item $itemc1 $c1 create destroy do undo		

		set c2 [ mv::case.create $itemc2 $diagram_id $x2 $cy ]
		set c2 [ lreplace $c2 9 9 '' ]
		append_with_item $itemc2 $c2 create destroy do undo		

		set c3 [ mv::case.create $itemc3 $diagram_id $x3 $cy ]
		set c3 [ lreplace $c3 9 9 '' ]
		append_with_item $itemc3 $c3 create destroy do undo
	} elseif { $name == "loopstart" } {
		set height 500
		set ey [ expr { $y + 70 } ]
		
		set vertical2 [ mv::loopend.create $item2 $diagram_id $x $ey ]
		set vertical2 [ lreplace $vertical2 9 9 '' ]
		append_with_item $item2 $vertical2 create destroy do undo
	}
}

proc append_with_item { item_id item_data createv destroyv dov undov } {
	upvar 1 $createv create
	upvar 1 $destroyv destroy
	upvar 1 $dov do
	upvar 1 $undov undo
	
	lappend create $item_data
	lappend destroy [ list delete items item_id $item_id ]
	lappend do [ list mv::insert $item_id ] [ list mv::select $item_id ]
	lappend undo [ list mv::deselect $item_id ] [ list mv::delete $item_id ]	
}

proc refill { diagram_id replay } {
	if { $replay } {
		fetch_view
		mv::fill $diagram_id
	}
}

proc refill_current { ignored replay } {
	fetch_view
	set diagram_id [ get_current_dia ]
	if { $diagram_id != "" } {
		fetch_view
		mv::fill $diagram_id
	}
}


proc scroll { x y } {
	variable scroll_x
	variable scroll_y

	
	set x2 [ unzoom_value $x ]
	set y2 [ unzoom_value $y ]
	set scroll_x $x2
	set scroll_y $y2

	#save_zoom
	state reset
}

proc editor_state { db key } {
	set sql "select $key from state"
	return [ $db onecolumn $sql ]
}

proc state.get_arg { action arguments } {
	if { [ llength $arguments ] == 0 } {
		error "state $action: target state required"
	}
	
	set new_state [ lindex $arguments 0 ] 
	
	set allowed { idle selecting dragging resizing selecting.start dragging.start resizing.start
		alt_drag alt_drag.start }
	if { [ lsearch -exact $allowed $new_state ] == -1 } {
		error "state $action: unknown state '$new_state'\nAvalable states: $allowed"
	}
	
	return $new_state
}

proc state { action args } {
	variable canvas_state
	
	switch $action {
		is {
			set new_state [ state.get_arg $action $args ]
			return [ expr { $new_state == $canvas_state } ]
		}
		reset { set canvas_state idle }
		change {
			set new_state [ state.get_arg $action $args ]			 
			set canvas_state $new_state
		}
		default { error "state: unsupported action '$action'" }
	}
}

proc get_scroll { } {
	return { 0 0 }
}

proc get_prim_count { } {
	variable db
	set id [ editor_state $db current_dia ]
	if { $id == "" } { return 0 }
	
	return [ $db onecolumn { select count(*) from items where diagram_id = :id } ]
}

proc get_current_dia { } {
	variable db
	if { $db == "<bad-db>" } { return "" }
	set id [ editor_state $db current_dia ]
	return $id
}

proc get_dia_name { diagram_id } {
  variable db
  if { $diagram_id == "" } { return "" }
  return [ $db onecolumn {
    select name
    from diagrams
    where diagram_id = :diagram_id } ]
}

proc get_dia_id { name } {
  variable db
  if { $name == "" } { return "" }
  return [ $db onecolumn {
    select diagram_id
    from diagrams
    where name = :name } ]
}

proc fill_tree_with_nodes { } {
	variable db
	mtree::clear
	
	$db eval {
		select node_id
		from tree_nodes
		where parent = 0
	} {
		add_tree_node $node_id
	}
}

proc add_tree_node { node_id } {
	variable db
	lassign [ $db eval {
		select type, name, diagram_id, parent
		from tree_nodes
		where node_id = :node_id } ] type name diagram_id parent
		
	if { [ is_diagram $type ] } {
		set name [ $db onecolumn { select name from diagrams where diagram_id = :diagram_id } ]
	}
	
	mtree::add_item $parent $type $name $node_id
	
	$db eval {
		select node_id child
		from tree_nodes
		where parent = :node_id
	} {
		add_tree_node $child
	}
}

proc get_diagram_parameter { diagram_id name } {
	variable db
	return [ $db onecolumn {
		select value from diagram_info
		where diagram_id = :diagram_id
		and name = :name } ]
}

proc set_diagram_parameter { diagram_id name value } {
	variable db
	set count [ $db onecolumn { select count(*) from diagram_info
		where diagram_id = :diagram_id
		and name = :name } ]
	if { $count == 0 } {
		$db eval { insert into diagram_info (diagram_id, name, value)
			values (:diagram_id, :name, :value) }
	} else {
		$db eval { update diagram_info set value = :value
			where diagram_id = :diagram_id
			and name = :name }
	}
}


proc get_diagrams { } {
	variable db
	return [ $db eval { select name from diagrams order by name } ]
}

proc update_undo { } {
	variable db
	set current [ com::get_current_undo ]
	mw::disable_undo
	mw::disable_redo
	
	if { $current == "" } { return }
	
	set max [ $db onecolumn { select max(step_id) from undo_steps } ]
	if { $current > 0 } {
		set name [ mod::one $db name undo_steps step_id $current ]
		mw::enable_undo $name
	}
	
	set next [ expr { $current + 1 } ]
	if { $next <= $max } {
		set name [ mod::one $db name undo_steps step_id $next ]
		mw::enable_redo $name 
	}
}

proc build_new_diagram { id name sil parent_node node_id } {
	variable db
	variable zoom
	
	set result {}
	lappend result [ list insert diagrams diagram_id $id name '$name' origin "'0 0'" zoom $zoom ]
	lappend result [ list insert tree_nodes node_id $node_id parent $parent_node type 'item' diagram_id $id ]
	
	if { $sil == "sm" } {
	  set result [ build_new_sm $id $name $result ]
	} elseif { $sil == "silhouette" } {
	  set result [ build_new_sil $id $name $result ]
	} else {
	  set item_id [ mod::next_key $db items item_id ]
	  lappend result [ list insert items item_id $item_id diagram_id $id type 'beginend' text '$name' selected 0 x 170 y 60 w 100 h 20 a 60 b 0 ]
	  incr item_id
	  lappend result [ list insert items item_id $item_id diagram_id $id type 'beginend' text '[texts::get end]' selected 0 x 170 y 390 w 60 h 20 a 60 b 0 ]
	  incr item_id
	  lappend result [ list insert items item_id $item_id diagram_id $id type 'vertical' selected 0 x 170 y 80 w 0 h 290 a 0 b 0 ]
	  incr item_id
	  lappend result [ list insert items item_id $item_id diagram_id $id type 'horizontal' selected 0 x 170 y 60 w 200 h 0 a 0 b 0 ]
	  incr item_id
	  lappend result [ list insert items item_id $item_id diagram_id $id type 'action' selected 0 x 370 y 60 w 60 h 30 a 0 b 0 ]	  
	  
	}
	return $result
}

proc build_new_data_diagram { id name sil parent_node node_id } {
	variable db
	
	set result {}
	lappend result [ list insert diagrams diagram_id $id name '$name' origin "'0 0'" zoom 100 ]
	lappend result [ list insert tree_nodes node_id $node_id parent $parent_node type 'data' diagram_id $id ]
	set item_id [ mod::next_key $db items item_id ]
	lappend result [ list insert items item_id $item_id diagram_id $id type 'action' text '' selected 0 x 170 y 60 w 100 h 20 a 60 b 0 ]
	return $result
}

proc build_new_sm { id name result } {
	variable db

	set item_id [ mod::next_key $db items item_id ]
	lappend result [ list insert items item_id $item_id diagram_id $id type 'beginend' text '$name' selected 0 x 110 y 60 w 80 h 20 a 60 b 0 ]
	incr item_id

	set items {{139 beginend End {} {} 1 1110 310 50 20 60 0} {140 vertical {} {} {} 1 -20 150 0 510 0 0} \
		 {141 vertical {} {} {} 1 380 190 0 470 0 0} {142 vertical {} {} {} 1 1110 190 0 110 0 0} {143 horizontal {} {} {} 1 -20 190 1130 0 0 0} \
		 {144 arrow {} {} {} 1 -120 190 100 470 1070 1} {145 branch State1 {} {} 1 -20 240 60 30 60 0} {146 address State1 {} {} 1 -20 610 60 30 60 0} \
		 {148 branch Exit {} {} 1 1110 240 50 30 60 0} {150 horizontal {} {} {} 1 -20 130 170 0 0 0} {151 action "state machine\n\nmsg" {} {} 1 170 130 70 40 0 0} \
		 {152 select receive {} {} 1 -20 320 60 20 60 0} {153 horizontal {} {} {} 1 -20 360 190 0 0 0} {154 case signal1 {} {} 1 -20 400 60 20 60 0} \
		 {155 case signal2 {} {} 1 170 400 50 20 60 0} {156 vertical {} {} {} 1 170 360 0 300 0 0} {157 address State1 {} {} 1 170 610 50 30 60 0} \
		 {158 branch State2 {} {} 1 380 240 60 30 60 0} {159 address State2 {} {} 1 380 610 60 30 60 0} {160 select receive {} {} 1 380 320 60 20 60 0} \
		 {161 horizontal {} {} {} 1 380 360 190 0 0 0} {162 case signal1 {} {} 1 380 400 60 20 60 0} {163 case signal2 {} {} 1 570 400 50 20 60 0} \
		 {164 vertical {} {} {} 1 570 360 0 300 0 0} {165 address State2 {} {} 1 570 610 50 30 60 0} {166 vertical {} {} {} 1 760 190 0 470 0 0} \
		 {167 branch State3 {} {} 1 760 240 60 30 60 0} {168 address State3 {} {} 1 760 610 60 30 60 0} {169 select receive {} {} 1 760 320 60 20 60 0} \
		 {170 horizontal {} {} {} 1 760 360 190 0 0 0} {171 case signal1 {} {} 1 760 400 60 20 60 0} {172 case signal2 {} {} 1 950 400 50 20 60 0} \
		 {173 vertical {} {} {} 1 950 360 0 300 0 0} {174 address State3 {} {} 1 950 610 50 30 60 0}} 


	foreach item $items {
		lassign $item _ type text _ _ _ x y w h a b
		incr x 130
		incr y -70
		lappend result [ list insert items item_id $item_id diagram_id $id type '$type' text "'$text'" selected 0 x $x y $y w $w h $h a $a b $b ]
		incr item_id
	}
	
	return $result
}

proc build_new_sil { id name result } {
  variable db
  
  set item_id [ mod::next_key $db items item_id ]
  lappend result [ list insert items item_id $item_id diagram_id $id type 'beginend' text '$name' selected 0 x 170 y 60 w 100 h 20 a 60 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'beginend' text "'[texts::get end]'" selected 0 x 660 y 510 w 60 h 20 a 60 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'vertical' text "''" selected 0 x 170 y 80 w 0 h 520 a 0 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'vertical' text "''" selected 0 x 420 y 120 w 0 h 480 a 0 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'vertical' text "''" selected 0 x 660 y 120 w 0 h 380 a 0 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'horizontal' text "''" selected 0 x 170 y 120 w 490 h 0 a 0 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'arrow' text "''" selected 0 x 20 y 120 w 150 h 480 a 400 b 1 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'branch' text "'branch 1'" selected 0 x 170 y 170 w 50 h 30 a 60 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'address' text "'branch 2'" selected 0 x 170 y 550 w 50 h 30 a 60 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'branch' text "'branch 2'" selected 0 x 420 y 170 w 50 h 30 a 60 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'branch' text "'branch 3'" selected 0 x 660 y 170 w 50 h 30 a 60 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'address' text "'branch 3'" selected 0 x 420 y 550 w 50 h 30 a 60 b 0 ]
  
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'horizontal' selected 0 x 170 y 60 w 200 h 0 a 0 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'action' selected 0 x 370 y 60 w 60 h 30 a 0 b 0 ]	  
  
  
  return $result
}


proc build_backup_item { item_id } {
	variable db
	$db eval {
		select
			item_id, diagram_id, type, text, text2, color, selected, x, y, w, h, a, b
		from items
		where item_id = :item_id
	} {
		set text [ sql_escape $text ]
		set text2 [ sql_escape $text2 ]
		set color [ sql_escape $color ]
		set insert_item [ list insert items \
			item_id				$item_id		\
			diagram_id		$diagram_id \
			type					'$type'			\
			text					'$text'			\
			text2					'$text2'			\
			color					'$color'    \
			selected				$selected		\
			x						$x					\
			y						$y					\
			w						$w				\
			h						$h					\
			a						$a					\
			b						$b					]
			
		return $insert_item
	}
}

proc build_backup_folder { node_id } {
	variable db
	$db eval {
		select parent, name
		from tree_nodes
		where node_id = :node_id
	} {
		return [ wrap insert tree_nodes node_id $node_id type 'folder' name '$name' parent $parent ]
	}
	error [ mc2 "Folder not found: \$node_id" ]
}

proc build_backup_diagram { id type } {
	variable db
	set fields [ mod::fetch $db diagrams diagram_id $id diagram_id name origin description zoom ]
	lassign $fields id name origin description zoom
	if { $zoom == "" } { set zoom 100 }
	set name [ sql_escape $name ]
	set description [ sql_escape $description ]
	
	set insert_diagram [ list insert diagrams diagram_id $id name '$name' origin '$origin' description '$description' zoom $zoom ]
	
	lassign [ mod::fetch $db tree_nodes diagram_id $id node_id parent ] node_id parent
	
	set insert_node [ list insert tree_nodes node_id $node_id parent $parent type '$type' diagram_id $id ]
	
	set result [ list $insert_diagram $insert_node ]
	
	$db eval { 
		select item_id
		from items
		where diagram_id = :id
	} {
		set insert_item [ build_backup_item $item_id ]
		lappend result $insert_item
	}
	
	$db eval {
		select name, value from diagram_info
		where diagram_id = :id
	} {
		set insert_info [ list insert diagram_info diagram_id $id name '$name' value '[ sql_escape $value ]' ]
		lappend result $insert_info
	} 
	
	return $result
}

proc build_delete_folder { node_id } {
	return [ wrap delete tree_nodes node_id $node_id ]
}

proc build_delete_diagram { id } {
	variable db
	
	set delete_node [ list delete tree_nodes diagram_id $id ]
	set delete_dia [ list delete diagrams diagram_id $id ]
	set delete_dia_info [ list delete diagram_info diagram_id $id ]
	set delete_items [ list delete items diagram_id $id ]
	set result [ list $delete_node $delete_dia $delete_dia_info $delete_items ]
 	
	return $result
}

proc check_diagram_name { name } {
	variable db
	if { [ string trim $name ] == "" } {
		return [ mc2 "Diagram name should not be empty" ]
	}
	if { [ string trim $name ] != $name } {
		return [ mc2 "Diagram name should not have trailing and leading spaces" ]
	}
	if { [ string first "'" $name ] != -1 } {
		return [ mc2 "Diagram name cannot contain single quotes" ]
	}		
	
	if { [ mod::exists $db diagrams name '$name' ] } {
		return [ mc2 "Diagram with name '\$name' already exists." ]
	}
	return ""
}

proc check_folder_name { name } {
	variable db
	if { [ string trim $name ] == "" } {
		return "Folder name should not be empty"
	}
	if { [ string trim $name ] != $name } {
		return "Folder name should not have trailing and leading spaces"
	}
	if { [ string first "'" $name ] != -1 } {
		return "Folder name cannot contain single quotes"
	}		
	return ""
}


proc get_parent_node { sibling } {
	variable db
	set selection [ mtree::get_selection ]
	if { [ llength $selection ] == 0 } {
		return 0
	}
	
	set selected [ lindex $selection 0 ]
	lassign [ $db eval {
		select type, parent from tree_nodes where node_id = :selected } ] type parent
	if { [ is_diagram $type ] || $sibling } {
		set parent_node $parent
	} else {
		set parent_node $selected
	}
	return $parent_node
}

proc is_drakon { diagram_id } {
	set type [ get_diagram_type $diagram_id ]
	if { $type == "" || $type == "item" } {
		return 1
	} else {
		return 0
	}
}

proc get_diagram_type { diagram_id } {
	variable db
	set type [ $db onecolumn {
		select type
		from tree_nodes
		where diagram_id = :diagram_id
	} ]
	return $type
}

proc do_create_folder { parent_node new } {
	variable db
	set message [ check_folder_name $new ]
	if { $message != "" } {
		return $message
	}

	begin_transaction do_create_folder
	start_action  [ mc2 "Create folder" ] dont_save
	
	set node_id [ mod::next_key $db tree_nodes node_id ]
	
	set old_current [ editor_state $db current_dia ]
	
	push_unselect $old_current
	
	set do_data [ wrap insert tree_nodes node_id $node_id type 'folder' name '$new' parent $parent_node ]
	set undo_data [ wrap delete tree_nodes node_id $node_id ]
	
	set do_gui [ wrap mwc::create_dia_node $node_id ]
	set undo_gui [ wrap mwc::delete_dia_node $node_id ]
	
	com::push $db $do_gui $do_data $undo_gui $undo_data
	
	commit_transaction do_create_folder
	state reset
	return ""
}


proc do_create_dia { new sil parent_node dialect } {
	variable db
	set message [ check_diagram_name $new ]
	if { $message != "" } {
		return $message
	}
	
	begin_transaction do_create_dia
	
	start_action  [ mc2 "Create diagram" ] dont_save
	
	set id [ mod::next_key $db diagrams diagram_id ]
	set node_id [ mod::next_key $db tree_nodes node_id ]
	
	set old_current [ editor_state $db current_dia ]
	
	push_unselect $old_current

	if { $dialect == "drakon" } {
		set insert [ build_new_diagram $id $new $sil $parent_node $node_id ]
	} else {
		set insert [ build_new_data_diagram $id $new $sil $parent_node $node_id ]
	}
	
	set delete [ build_delete_diagram $id ]
	
	set create_do [ wrap mwc::create_dia_node $node_id ]	
	set create_undo [ wrap mwc::delete_dia_node $node_id ]
	
	com::push $db $create_do $insert $create_undo $delete
	
	push_select $id
	
	commit_transaction do_create_dia
	state reset
	
	return ""
}

proc take_selection_from_shadow { diagram_id } {
	variable db
	set new_selection [ mv::shadow_selection ]
	set old_selection [ $db eval { select item_id from items where diagram_id = :diagram_id and selected = 1 } ]
	set select {}
	set deselect { }
	set do { }
	set undo { }
	foreach old_selected $old_selection {
		lappend do [ list mv::deselect $old_selected ]
		lappend select [ list update items item_id $old_selected selected 0 ]
	}
	foreach new_selected $new_selection {
		lappend do [ list mv::select $new_selected ]
		lappend select [ list update items item_id $new_selected selected 1 ]
		lappend undo [ list mv::deselect $new_selected ]
		lappend deselect [ list update items item_id $new_selected selected 0 ]
	}
	foreach old_selected $old_selection {
		lappend undo [ list mv::select $old_selected ]
		lappend deselect [ list update items item_id $old_selected selected 1 ]
	}
	com::push $db $do $select $undo $deselect
}

proc take_drag_from_shadow { } {
	set selected [ mv::shadow_selection ]
	take_shapes_from_shadow $selected
}

proc take_resize_from_shadow { item_id } {
	set items [ list $item_id ]
	take_shapes_from_shadow $items
}

proc take_shapes_from_shadow { items } {
	variable db
	set drag {}
	set put_back {}
	set do {}
	set undo {}
	
	foreach item_id $items {	
		mb eval { select x, y, w, h, a, b from item_shadows where item_id = :item_id } {
			lappend drag [ list update items item_id $item_id x $x y $y w $w h $h a $a b $b ]
			set arg [ list $item_id $x $y $w $h $a $b ]
			lappend do [ list mv::move_to $arg ]
		}
		
		$db eval { select x, y, w, h, a, b from items where item_id = :item_id } {
			lappend put_back [ list update items item_id $item_id x $x y $y w $w h $h a $a b $b ]
			set arg [ list $item_id $x $y $w $h $a $b ]
			lappend undo [ list mv::move_to $arg ]
		}
	}
	if { [ llength $items ] > 0 } {
		com::push $db $do $drag $undo $put_back
	}
}

proc push_delete_items { diagram_id } {
	variable db
	
	set delete {}
	set undelete {}
	set do {}
	set undo {}

	
	$db eval { select item_id
					from items where diagram_id = :diagram_id
					and selected = 1 } {
		set insert_item [ build_backup_item $item_id ]
		set delete_item [ list delete items item_id $item_id ]
		set insert_cnv [ list mv::insert $item_id ]
		set delete_cnv [ list mv::delete $item_id ]

		
		lappend delete $delete_item
		lappend undelete $insert_item
		lappend do [ list mv::deselect $item_id ]
		lappend do $delete_cnv
		lappend undo $insert_cnv
		lappend undo [ list mv::select $item_id ]
	}
	
	if { [ llength $do ] > 0 } {
		com::push $db $do $delete $undo $undelete
	}	
}

proc push_unselect_items { diagram_id } {
	variable db
	
	set unselect {}
	set select {}

	set unselect_do {}
	set unselect_undo {}
	
	set counter 0
	
	$db eval { select item_id from items where diagram_id = :diagram_id and selected = 1 } {
		lappend unselect [ list update items item_id $item_id selected 0 ]
		lappend select [ list update items item_id $item_id selected 1 ]
		lappend unselect_do [ list mv::deselect $item_id ]
		lappend unselect_undo [ list mv::select $item_id ]
		incr counter
	}
	
	if { $counter > 0 } {
		com::push $db $unselect_do $unselect $unselect_undo $select
	}
}

proc push_select_item { item_id } {
	variable db
	
	set select [ wrap update items item_id $item_id selected 1 ]
	set deselect [ wrap update items item_id $item_id selected 0 ]
	set do [ wrap mv::select $item_id ]
	set undo [ wrap mv::deselect $item_id ]
	com::push $db $do $select $undo $deselect
}


proc fetch_zoom {  } {
	variable db
	variable zoom
	variable scroll_x
	variable scroll_y
	set diagram_id [ editor_state $db current_dia ]	
	if { $diagram_id == "" } { return }
	$db eval { select zoom z, origin from diagrams
		where diagram_id = :diagram_id } {

		if { $z == "" || int($z) == 0 } {
			set zoom 100
		} else {
			set zoom [ expr { int($z) } ]
		}
		lassign $origin scroll_x scroll_y
	}
}

proc save_zoom { } {
	variable db
	variable zoom
	variable scroll_x
	variable scroll_y
	set diagram_id [ editor_state $db current_dia ]	
	if { $diagram_id == "" } { return }
	set origin [ list $scroll_x $scroll_y ]
	$db eval { 
    update diagrams
    set zoom = :zoom, origin = :origin
		where diagram_id = :diagram_id }
}

proc fetch_view { } {
  variable g_current_dia
	variable db

	set g_current_dia [ editor_state $db current_dia ]	
	fetch_zoom
}

proc save_view { } {
  variable db
  variable g_current_dia
  $db eval {
    update state
    set current_dia = :g_current_dia }
    
  save_zoom
}

proc clear_g_current_dia { foo bar } {
	variable g_current_dia
	set g_current_dia ""
}

proc push_unselect { diagram_id } {
	variable db
	set clean_old [ wrap update state row 1 current_dia '' ]
	set unselect_do { { mw::unselect_dia_ex 1 } { mwc::clear_g_current_dia foo } }
	
	set restore_old {}
	set unselect_undo {}
	
	if { $diagram_id != "" } {
		lappend restore_old [ list update state row 1 current_dia $diagram_id ]	
		lappend unselect_undo [ list mw::select_dia $diagram_id ]
	}
	
	com::push $db $unselect_do $clean_old $unselect_undo $restore_old 
}

proc push_select { diagram_id } {

	variable db
	set set_new [ wrap update state row 1 current_dia $diagram_id ]
	set clean_new [ wrap update state row 1 current_dia '' ]

	set select_do {}
	lappend select_do [ list  mw::select_dia $diagram_id ]
		
	set select_undo [ wrap mw::unselect_dia_ex 1 ]
	com::push $db $select_do $set_new $select_undo $clean_new
}

proc new_dia_here { } {
	set parent_node [ get_parent_node 0 ]
	mwd::create_diagram_dialog mwc::do_create_dia $parent_node
}

proc new_dia { } {
	set parent_node [ get_parent_node 1 ]
	mwd::create_diagram_dialog mwc::do_create_dia $parent_node
}


proc undo { } {
	variable db
	begin_transaction undo
	com::undo $db
	commit_transaction undo
	state reset
	refill_all 0 0
}

proc redo { } {
	variable db
	begin_transaction redo
	com::redo $db
	commit_transaction redo
	state reset
	refill_all 0 0 
}

proc get_node_info { node_id } {
	variable db
	return [ $db eval {
		select parent, type, name, diagram_id
		from tree_nodes
		where node_id = :node_id } ]
}

proc sort_selection { selection } {
	variable db
	set result {}
	
	$db eval {
		select node_id
		from tree_nodes
		where parent = 0
	} {
		set selected_in_subtree [ traverse_subtree $node_id $selection 0 ]
		set result [ concat $result $selected_in_subtree ]
	}
	
	return $result
}

proc traverse_subtree { node_id selection parent_selected } {
	variable db
	set result {}
	
	if { $parent_selected || [ contains $selection $node_id ] } {
		lappend result $node_id
		set parent_selected 1
	}
	
	$db eval {
		select node_id child
		from tree_nodes
		where parent = :node_id
	} {
		set in_child [ traverse_subtree $child $selection $parent_selected ]
		set result [ concat $result $in_child ]
	}
	
	return $result
}

proc get_diagram_node { diagram_id } {
	variable db
	return [ $db onecolumn {
		select node_id
		from tree_nodes
		where diagram_id = :diagram_id } ]
}

proc delete_tree_items { } {
	take_from_tree 1 0
}

proc do_delete_tree_items { sorted } {
	variable db
	
	
	begin_transaction delete_dia
	start_action  [ mc2 "Delete diagram" ] dont_save	
	
	set old_current [ editor_state $db current_dia ]
	push_unselect $old_current	
	
	set delete_data {}
	set delete_gui {}
	set undelete_data {}
	set undelete_gui {}
	
	foreach node_id $sorted {
		lassign [ get_node_info $node_id ] parent type name diagram_id
		if { $type == "folder" } {
			set undo_data [ build_backup_folder $node_id ]	
		} else {
			set undo_data [ build_backup_diagram $diagram_id $type ]
		}
		lappend undelete_gui [ list mwc::create_dia_node $node_id ]
		set undelete_data [ concat $undelete_data $undo_data ]
	}
	
	set last [ expr { [ llength $sorted ] - 1 } ]
	for { set i $last } { $i >= 0 } { incr i -1 } {
		set node_id [ lindex $sorted $i ]
		lassign [ get_node_info $node_id ] parent type name diagram_id
		if { $type == "folder" } {
			set do_data [ build_delete_folder $node_id ]		
		} else {
			set do_data [ build_delete_diagram $diagram_id ]
		}
		lappend delete_gui [ list mwc::delete_dia_node $node_id ]
		set delete_data [ concat $delete_data $do_data ]
	}
		
	com::push $db $delete_gui $delete_data $undelete_gui $undelete_data

	commit_transaction delete_dia
	state reset
}

proc push_rename_dia { id new } {
	variable db
	
	set node_id [ get_diagram_node $id ]
	
	set old [ mod::one $db name diagrams diagram_id $id ]
	set rename [ wrap update diagrams diagram_id $id name '$new' ]
	set undo [ wrap update diagrams diagram_id $id name '$old' ]
	
	set rename_do [ wrap mwc::rename_dia_node $node_id ]
	set rename_undo [ wrap mwc::rename_dia_node $node_id ]
	com::push $db $rename_do $rename $rename_undo $undo
}

proc change_dia_name_only { id new } {
	variable db
	
	set old [ mod::one $db name diagrams diagram_id $id ]
	if { $old == $new } { return 0 }
	set message [ check_diagram_name $new ]
	if { $message != "" } {
		return 0
	}
	
	
	begin_transaction change_dia_name_only
	start_action  [ mc2 "Rename diagram" ]
	
	push_rename_dia $id $new

	commit_transaction change_dia_name_only
	state reset
	return 1
}

proc do_rename_folder { node_id new } {
	variable db
	set message [ check_folder_name $new ]
	if { $message != "" } {
		return $message
	}
	set old [ $db onecolumn {
		select name from tree_nodes where node_id = :node_id } ]
	if { $old == $new } { return "" }

	begin_transaction do_rename_folder
	start_action  [ mc2 "Rename folder" ]
	
	set do_data [ wrap update tree_nodes node_id $node_id name '$new' ]
	set undo_data [ wrap update tree_nodes node_id $node_id name '$old' ]
	set do_gui [ wrap mwc::rename_dia_node $node_id ]
	set undo_gui $do_gui
	
	com::push $db $do_gui $do_data $undo_gui $undo_data
	
	commit_transaction do_rename_folder
	state reset
	return ""
}

proc do_rename_dia { node_id new } {
	variable db
	set old [ $db onecolumn {
		select name from tree_nodes where node_id = :node_id } ]	
	if { $old == $new } { return "" }
	set message [ check_diagram_name $new ]
	if { $message != "" } {
		return $message
	}
	
	begin_transaction do_rename_dia
	start_action  [ mc2 "Rename diagram" ]
	
	set id [ mod::one $db diagram_id tree_nodes node_id $node_id ]
	push_rename_dia $id $new
	
	if { [ is_drakon $id ] } {
		set header [ find_header $id ]
		if { $header != "" } {
			push_change_text $header $new
		}
	}
	
	mv::fill $id
	
	commit_transaction do_rename_dia
	state reset
	return ""
}

proc do_dia_properties { old new } {
	variable db
	
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return "" }
	
	return [ do_dia_properties_kernel $diagram_id $new ]
}

proc do_dia_properties_kernel { diagram_id new } {
	variable db
	
	set old [ mod::one $db description diagrams diagram_id $diagram_id ]
	if { $old == $new } { return "" }
	
	
	begin_transaction do_dia_properties_kernel
	start_action  [ mc2 "Change diagram description" ]
	
	set old_e [ sql_escape $old ]
	set new_e [ sql_escape $new ]
	
	set change [ wrap update diagrams diagram_id $diagram_id description '$new_e' ]
	set revert [ wrap update diagrams diagram_id $diagram_id description '$old_e' ]
	set do [ wrap mw::update_description foo ]
	set undo [ wrap mw::update_description foo ]
	
	com::push $db $do $change $undo $revert
	
	commit_transaction do_dia_properties_kernel
	state reset

	return ""
}

proc rename_dia { } {
	variable db
	
	set selection [ mtree::get_selection ]
	if { [ llength $selection ] != 1 } { return }
	
	set node_id [ lindex $selection 0 ]
	lassign [ get_node_info $node_id ] parent type foo diagram_id
	
	set old [ get_node_text $node_id ]
	if { $type == "folder" } {
		ui::input_box [ mc2 "Rename folder" ] $old mwc::do_rename_folder $node_id 
	} else {
		ui::input_box [ mc2 "Rename diagram" ] $old mwc::do_rename_dia $node_id 
	}
}

proc goto_item { } {
	variable db
	ui::input_box [ mc2 "Go to item" ] "" mwc::do_goto_item foo
}

proc do_goto_item { foo item } {
	variable db
	set trimmed [ string trim $item ]
	if { $trimmed == "" } {
		return [ mc2 "Please enter an item id." ]
	}

	if { ![ string is integer $trimmed ] } {
		return [ mc2 "Item id should be a whole number." ]
	}

	set count [ $db onecolumn {
		select count(*) from items where item_id = :trimmed } ]
	if { $count != 1 } {
		return [ mc2 "Item \$trimmed not found" ]
	}
	switch_to_item $trimmed
	return ""
}

proc new_folder_here { } {

	set parent_node [ get_parent_node 0 ]
	ui::input_box [ mc2 "Create folder" ] "" mwc::do_create_folder $parent_node
}

proc new_folder { } {
	set parent_node [ get_parent_node 1 ]
	ui::input_box [ mc2 "Create folder" ] "" mwc::do_create_folder $parent_node
}


proc get_items_to_copy { diagram_id selected_only } {
	variable db
	
	set result {}
	$db eval { 
		select item_id, type, text, text2, color, selected, x, y, w, h, a, b
		from items
		where diagram_id = :diagram_id
	} {
		if { $selected || !$selected_only } {			
			lappend result [ list $item_id $type $text $text2 $color $selected $x $y $w $h $a $b ]
		}
	}
	return $result
}

proc copy { ignored } {
	variable db
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return 0 }

	set items_data [ get_items_to_copy $diagram_id 1 ]
	if { [ llength $items_data ] != 0 } {
		mw::put_items_to_clipboard $items_data
		return 1
	}
	return 0
}

proc cut { ignored } {
	if { [ copy foo ] } {
		delete foo
	}
}

proc get_sorted_nodes { } {
	set selection [ mtree::get_selection ]
	if { [ llength $selection ] == 0 } { return {} }
	set sorted [ sort_selection $selection ]
	return $sorted
}

proc get_diagram_name_from_node { node_id } {
	variable db
	set diagram_id [ $db onecolumn {
		select diagram_id
		from tree_nodes
		where node_id = :node_id
	} ]
	
	set name [ $db onecolumn { select name from diagrams where diagram_id = :diagram_id } ]
	
	return [ string trim $name ]
}

proc copy_dia_names { } {
	set sorted [ get_sorted_nodes ]
	if { [ llength $sorted ] == 0 } { return }
	set lines {}
	foreach node_id $sorted {
		set name [ get_diagram_name_from_node $node_id ]
		lappend lines $name
	}
	set content [ join $lines "\n" ]
	mw::put_text_to_clipboard $content
}

proc take_from_tree { delete copy } {
	set sorted [ get_sorted_nodes ]
	if { [ llength $sorted ] == 0 } { return }
	
	if { $copy } {
		do_copy_tree $sorted
	}
	
	if { $delete } {	
		do_delete_tree_items $sorted
	}
}

proc copy_tree { } {
	take_from_tree 0 1
}

proc cut_tree { } {
	take_from_tree 1 1
}

proc get_node_to_copy { node_id } {
	variable db
	$db eval {
		select parent, type, name, diagram_id
		from tree_nodes
		where node_id = :node_id
	} {
		return [ list $node_id $parent $type $name $diagram_id ]
	}
}

proc get_diagram_properties { diagram_id } {
	variable db 
	set result {}
	$db eval {
		select name, value
		from diagram_info
		where diagram_id = :diagram_id
	} {
		lappend result $name $value
	}
	return $result
}

proc get_diagram_to_copy { diagram_id } {
	variable db
	set items_data [ get_items_to_copy $diagram_id 0 ]
	set properties [ get_diagram_properties $diagram_id ]
	$db eval {
		select name, origin, description, zoom
		from diagrams
		where diagram_id = :diagram_id
	} {
		return [ list $diagram_id $name $origin $description $zoom $items_data $properties ]
	}
}

proc do_copy_tree { sorted } {
	set nodes {}
	set diagrams {}
	
	foreach node_id $sorted {
		lappend nodes [ get_node_to_copy $node_id ]
		
		lassign [ get_node_info $node_id ] parent type name diagram_id
		if { [ is_diagram $type ] } {
			lappend diagrams [ get_diagram_to_copy $diagram_id ]
		}
	}
	
	set content [ list $diagrams $nodes ]
	mw::put_nodes_to_clipboard $content
}

proc make_diagram_ids { diagrams } {
	variable db
	set diagram_id [ mod::next_key $db diagrams diagram_id ]
	
	set result {}
	foreach diagram $diagrams {
		set old_diagram_id [ lindex $diagram 0 ]
		lappend result $old_diagram_id $diagram_id
		incr diagram_id
	}
	
	return $result
}

proc name_not_unique { name result } {
	variable db
	if { [ contains $result $name ] } { return 1 }
	if { [ $db onecolumn {
		select count(*) from diagrams where name = :name } ] > 0 } {
		return 1
	}
	return 0
}

proc make_diagram_names { diagrams } {
	variable db
	
	set result {}
	foreach diagram $diagrams {
		set old_diagram_name [ lindex $diagram 1 ]
		set name $old_diagram_name
		set i 2
		while { [ name_not_unique $name $result ] } {
			set name "$old_diagram_name-$i"
			incr i
		}
		
		lappend result $old_diagram_name $name
	}
	
	return $result	
}

proc make_node_ids { nodes } {
	variable db
	set node_id [ mod::next_key $db tree_nodes node_id ]
	
	set result {}
	foreach node $nodes {
		set old_node_id [ lindex $node 0 ]
		lappend result $old_node_id $node_id
		incr node_id
	}
	
	return $result	
}

proc make_item_ids { items first_item_id } {
	set item_id $first_item_id
	set result {}
	foreach item $items {
		set old_item_id [ lindex $item 0 ]
		lappend result $old_item_id $item_id
		incr item_id
	}
	return $result
}

proc make_item_ids_tree { diagrams } {
	variable db
	set item_id [ mod::next_key $db items item_id ]

	set result {}
	foreach diagram $diagrams {
		set items [ lindex $diagram 5 ]
		set ids [ make_item_ids $items $item_id ]
		set item_id [ expr { $item_id + [ llength $ids ] / 2 } ]
		set result [ concat $result $ids ]
	}
	
	return $result
}

proc make_paste_diagram_actions { diagram diagram_ids diagram_names item_ids } {
	array set ids $diagram_ids
	array set names $diagram_names
	array set it_ids $item_ids
	
	set do_data {}
	
	lassign $diagram old_diagram_id old_name origin description zoom items_data properties
	set name $names($old_name)
	set diagram_id $ids($old_diagram_id)
	set description [ sql_escape $description ]
	
	lappend do_data [ list insert diagrams diagram_id $diagram_id name '$name' origin '$origin' \
		description '$description' zoom $zoom ]
	
	
	lassign [ make_paste_items_actions $diagram_id $items_data $item_ids 0 0 ] \
		items_do_gui items_do_data items_undo_gui items_undo_data

	set do_data [ concat $do_data $items_do_data ]
	
	set prop_count [ expr { [ llength $properties ] / 2 } ]
	repeat i $prop_count {
		set key_index [ expr { $i * 2 } ]
		set value_index [ expr { $key_index + 1 } ]
		set pname [ lindex $properties $key_index ]
		set pvalue [ lindex $properties $value_index ]
		lappend do_data [ list insert diagram_info diagram_id $diagram_id name '$pname' value '$pvalue' ]
	}
	
	set undo_data [ list \
		[ list delete diagram_info diagram_id $diagram_id ] \
		[ list delete items diagram_id $diagram_id ] \
		[ list delete diagrams diagram_id $diagram_id ] ]
		
	return [ list $do_data $undo_data ]
}

proc make_paste_node_actions { node node_ids diagram_ids parent } {

	array set dias $diagram_ids
	array set ids $node_ids
	
	lassign $node old_node_id old_parent type name diagram_id
	
	if { $diagram_id != "" } {
		set diagram_id $dias($diagram_id)
	}
	
	set node_id $ids($old_node_id)
	
	if { [ info exists ids($old_parent) ] } {
		set parent_id $ids($old_parent)
	} else {
		set parent_id $parent
	}
	
	if { $diagram_id == "" } {
		set diagram_id null
	}
	set do_data [ list insert tree_nodes node_id $node_id parent $parent_id type '$type' name '$name' \
		diagram_id $diagram_id ]
	set undo_data [ list delete tree_nodes node_id $node_id ]
	
	set do_gui [ list mwc::create_dia_node $node_id ]
	set undo_gui [ list mwc::delete_dia_node $node_id ]
	return [ list $do_gui $do_data $undo_gui $undo_data ]
}

proc paste_tree_here { } {
	paste_tree_kernel 0
}

proc paste_tree { } {
	paste_tree_kernel 1
}

proc paste_tree_kernel { sibling } {
	variable db
	
	lassign [ mw::take_nodes_from_clipboard ] diagrams nodes
	
	set diagram_ids [ make_diagram_ids $diagrams ]
	set diagram_names [ make_diagram_names $diagrams ]
	set node_ids [ make_node_ids $nodes ]
	
	set item_ids [ make_item_ids_tree $diagrams ]

	set parent [ get_parent_node $sibling ]

	set diagram_actions {}
	set node_actions {}
	
	foreach diagram $diagrams {
		set actions [ make_paste_diagram_actions $diagram $diagram_ids $diagram_names $item_ids ]
		lassign $actions paste delete
		lappend diagram_actions $actions
	}
	
	foreach node $nodes {
		lappend node_actions [ make_paste_node_actions $node $node_ids $diagram_ids $parent ]
	}
	
	set do_data {}
	set undo_data {}
	set do_gui {}
	set undo_gui {}
	
	foreach actions $diagram_actions {
		lassign $actions paste delete
		set do_data [ concat $do_data $paste ]
	}
	
	foreach actions $node_actions {
		lassign $actions do paste undo delete
		lappend do_data $paste
		lappend do_gui $do
	}
	
	set last [ expr { [ llength $node_actions ] - 1 } ]
	for { set i $last } { $i >= 0 } { incr i -1 } {
		lassign [ lindex $node_actions $i ] do paste undo delete
		lappend undo_data $delete
		lappend undo_gui $undo
	}

	foreach actions $diagram_actions {
		lassign $actions paste delete
		set undo_data [ concat $undo_data $delete ]		
	}
	
	lappend undo_gui [ list mw::unselect_dia_ex 1 ]

	
	begin_transaction paste_tree
	
	start_action  [ mc2 "Paste nodes" ]
	
	set diagram_id [ editor_state $db current_dia ]
	push_unselect $diagram_id
		
	com::push $db $do_gui $do_data $undo_gui $undo_data
	
	set pasting_one_diagram [ expr { [ llength $diagrams ] == 1 && [ llength $nodes ] == 1 } ]
	if { $pasting_one_diagram } {
		set new_diagram_id [ lindex $diagram_ids 1 ]
		push_select $new_diagram_id
	}
	
	commit_transaction paste_tree
	state reset	
}


proc get_left_top { items_data } {
	set min_x ""
	set min_y ""
	foreach item_data $items_data {
		lassign $item_data foo type text text2 color selected x y w h a b	
		
		if { $type == "horizontal" || $type == "parallel" || $type == "arrow" } {
			set left $x
		} else {
			set left [ expr { $x - $w } ]
		}
		
		if { $type == "vertical" || $type == "arrow" } {
			set top $y
		} else {
			set top [ expr { $y - $h } ]
		}
		
		if { $min_x == "" || $min_x > $left } {
			set min_x $left
		}
		
		if { $min_y == "" || $min_y > $top } {
			set min_y $top
		}
	}
	return [ list $min_x $min_y ]
}

proc calculate_shift { left_top } {
	lassign [ insp::current ] mx my
	set left [ lindex $left_top 0 ]
	set top [ lindex $left_top 1 ]
	set dx [ snap_delta [ expr { $mx - $left - 20 } ] ]
	set dy [ snap_delta [ expr { $my - $top - 20 } ] ]
	return [ list $dx $dy ]
}

proc swap_item { item_id } {
	variable db
	
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }
	
	begin_transaction swap_item
	start_action  [ mc2 "Change item" ]

	set before [ mod::one $db b items item_id $item_id ]
	set after [ expr { !$before } ]

	
	set swap [ wrap update items item_id $item_id b $after ]
	set revert [ wrap update items item_id $item_id b $before ]
	
	set do [ list \
		[ list mv::delete $item_id ] \
		[ list mv::insert $item_id ] \
		[ list mv::select $item_id ] ]
		
	com::push $db $do $swap $do $revert 
	commit_transaction swap_item
	
	state reset		
}

proc make_paste_items_actions { diagram_id items_data item_ids dx dy } {
	set paste {}
	set delete {}
	set do {}
	set undo {}
	
	array set ids $item_ids

	
	foreach item_data $items_data {
		lassign $item_data old_item_id type text text2 color selected x y w h a b
		set text [ sql_escape $text ]
		set text2 [ sql_escape $text2 ]
		set color [ sql_escape $color ]
		
		set x [ expr { $x + $dx } ]
		set y [ expr { $y + $dy } ]
		
		set item_id $ids($old_item_id)
		
		lappend paste [ list insert items \
			item_id $item_id \
			diagram_id $diagram_id \
			type '$type' \
			text '$text' \
			text2 '$text2' \
			color '$color' \
			selected $selected \
			x $x \
			y $y \
			w $w \
			h $h \
			a $a \
			b $b ]
			
		lappend delete [ list delete items item_id $item_id ]
		lappend do [ list mv::insert $item_id ]
		if { $selected } {
			lappend do [ list mv::select $item_id ]
		}
		lappend undo [ list mv::delete $item_id ]
	}
	
	return [ list $do $paste $undo $delete ]
}

proc paste { ignored } {
	variable db
	
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }

	set items_data [ mw::take_items_from_clipboard ]
	if { [ llength $items_data ] == 0 } { return }
	
	set left_top [ get_left_top $items_data ]
	set shift [ calculate_shift $left_top ]
	set dx [ lindex $shift 0 ]
	set dy [ lindex $shift 1 ]
	
	set dx [ snap_up $dx ]
	set dy [ snap_up $dy ]

	set item_id [ mod::next_key $db items item_id ]

	set item_ids [ make_item_ids $items_data $item_id ]
	
	lassign [ make_paste_items_actions $diagram_id $items_data $item_ids $dx $dy ] do paste undo delete
	
	begin_transaction paste
	
	start_action  [ mc2 "Paste items" ]
	push_unselect_items $diagram_id
		
	com::push $db $do $paste $undo $delete 
	
	commit_transaction paste
	state reset	
}

proc get_context_inserts {} {
	set result {}
	set more {}
	
	set diagram_id [ get_current_dia ]
	if { [ is_drakon $diagram_id ] } {
		lappend result [ list command  action [ mc2 "Action" ] ]
		lappend result [ list command  if [ mc2 "If" ] ]
		lappend result [ list command  vertical [ mc2 "Vertical line" ] ]
		lappend result [ list command  horizontal [ mc2 "Horizontal line" ] ]
		lappend result [ list command  select [ mc2 "Select" ] ]
		lappend result [ list command  case [ mc2 "Case" ] ]
		lappend result { separator }
		lappend result [ list command  loopstart [ mc2 "Loop" ] ]	
		lappend result [ list command  arrow [ mc2 "Arrow" ] ]
		lappend result { separator }
		lappend result [ list command  beginend [ mc2 "Begin/End" ] ]
		lappend result [ list command  branch [ mc2 "Branch header" ] ]
		lappend result [ list command  address [ mc2 "Branch footer" ] ]
		lappend result { separator }
		lappend result [ list command  commentin [ mc2 "Inline comment" ] ]
		lappend result [ list command  commentout [ mc2 "Standalone comment" ] ]
	

	
		lappend more [ list command  insertion [ mc2 "Insertion" ] ]
		lappend more [ list command  shelf [ mc2 "Shelf" ] ]
		lappend more { separator }
		lappend more [ list command  output [ mc2 "Output" ] ]
		lappend more [ list command  input [ mc2 "Input" ] ]	
		lappend more { separator }
		lappend more [ list command  parallel [ mc2 "Parallel" ] ]
		lappend more [ list command  process [ mc2 "Process" ] ]	
		lappend more [ list command  pause [ mc2 "Pause" ] ]
		lappend more [ list command  timer [ mc2 "Timer" ] ]
	} else {
		lappend result [ list command  action [ mc2 "Entity" ] ]
		lappend result [ list command  shelf [ mc2 "Entity with fields" ] ]
		lappend result [ list command  beginend [ mc2 "Attribute" ] ]		
		lappend result { separator }
		lappend result [ list command  vertical [ mc2 "Vertical line" ] ]
		lappend result [ list command  horizontal [ mc2 "Horizontal line" ] ]
		lappend result { separator }
		lappend result [ list command  up_paw [ mc2 "One-to-many \(\\\"many\\\" at the top\)" ] ]				
		lappend result [ list command  down_paw [ mc2 "One-to-many \(\\\"many\\\" at the bottom\)" ] ]
		lappend result [ list command  left_paw [ mc2 "One-to-many \(\\\"many\\\" on the left\)" ] ]
		lappend result [ list command  right_paw [ mc2 "One-to-many \(\\\"many\\\" on the right\)" ] ]
		lappend result { separator }
		lappend result [ list command  up_arrow [ mc2 "Directed link up" ] ]
		lappend result [ list command  left_arrow [ mc2 "Directed link to the left" ] ]
		lappend result [ list command  right_arrow [ mc2 "Directed link to the right" ] ]
		lappend result [ list command  down_arrow [ mc2 "Directed link down" ] ]
		
		lappend result { separator }
		lappend result [ list command  commentin [ mc2 "Inline comment" ] ]
		lappend result [ list command  commentout [ mc2 "Standalone comment" ] ]



		lappend more [ list command  up_white_arrow [ mc2 "Inheritance link up" ] ]
		lappend more [ list command  left_white_arrow [ mc2 "Inheritance link to the left" ] ]
		lappend more [ list command  right_white_arrow [ mc2 "Inheritance link to the right" ] ]
		lappend more [ list command  down_white_arrow [ mc2 "Inheritance link down" ] ]
	}
	
	return [ list $result $more ]
}

proc is_url { text } {
	return [ regexp \[a-z\]+://.+ $text ]
}

proc extract_urls { text } {
	set parts [ split $text " \t\n" ]
	set output {}
	foreach item $parts {
		if { [ is_url $item ] } {
			lappend output $item
		}
	}
	return $output
}

proc get_links { cx cy } {
	variable db
	
	set cx [ unzoom_value $cx ]
	set cy [ unzoom_value $cy ]
	
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return {} }
	
	set hit_item [ mv::hit $cx $cy ]
	if { $hit_item != "" } {

		set text [ $db onecolumn {
			select text
			from items
			where item_id = :hit_item } ]
		
		set links [ extract_urls $text ]
		return $links
	} else {
		return {}
	}
}

proc get_context_commands { cx cy } {
	variable db
	set cx [ unzoom_value $cx ]
	set cy [ unzoom_value $cy ]
	
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return {} }
	
	set selected [ $db eval { select item_id from items 
		where selected = 1 and diagram_id = :diagram_id } ]
		
	if { [ llength $selected ] == 0 } {
		set copy_state disabled
	} else {
		set copy_state normal
	}
	
	if { [ mw::can_paste_items ] } {
		set paste_state normal
	} else {
		set paste_state disabled
	}
	
	set commands [ list \
		[ list command [ mc2 "Copy" ] $copy_state mwc::copy {} ] \
		[ list command [ mc2 "Cut" ] $copy_state mwc::cut {} ] \
		[ list command [ mc2 "Paste" ] $paste_state mwc::paste { } ] \
		[ list separator ] \
		[ list command [ mc2 "Delete" ] $copy_state mwc::delete { } ]	\
		[ list separator ] ]

	set hit_item [ mv::hit $cx $cy ]
	if { $hit_item != "" } {
		$db eval { select type, selected from items where item_id = :hit_item } {
			if { $selected } {
				if { [ mv::has_text $hit_item ] } {
					if { $type != "address" } {
						if { [ has_2_texts $type ] } {
							lappend commands [ list command [ mc2 "Edit upper text..." ] normal mwc::change_secondary_text $hit_item ]
						}
						lappend commands [ list command [ mc2 "Edit text..." ] normal mwc::change_text $hit_item ]
					}
					set referenced [ find_referenced_diagrams $hit_item $diagram_id ]
					foreach dia $referenced {
						lassign $dia ref_id ref_name
						if { $ref_id != $diagram_id } {
							lappend commands [ list command [ mc2 "Go to '\$ref_name'" ] normal mwc::switch_to_dia $ref_id ]
						}
					}
				}
				set switch_command [ mv::$type.switch ]
				if { $switch_command != "" } {
					lappend commands [ list command $switch_command normal mwc::swap_item $hit_item ]
				}
				if { [ p.is_address $hit_item ] } {
					set branches [ p.get_branches_except $hit_item ]
					foreach branch $branches {
						set original $branch
						set branch [new_line_to_space $branch ]
						lappend commands [ list command [ mc2 "Point to '\$branch'" ] normal mwc::change_icon_text2 \
							[ list $hit_item $original ] ]
					}
				}
			}
		}
	}
	
	set all_branches [ p.get_branches ]
	if { $all_branches != "" } {
		lappend commands [ list command [ mc2 "Go to branch..." ] normal mwc::go_to_branch {} ]
	}
	
	set wcolors [ get_colorful_items ]
	if { $wcolors != {} } {	
		lappend commands [ list separator ]
		lappend commands [ list command [ mc2 "Change colors..." ] normal cpicker::show $wcolors ]
		lappend commands [ list command [ mc2 "Clear colors" ] normal mwc::clear_color $wcolors ]
	}
	
	return $commands
}



proc new_line_to_space { text } {
	return [ string map {"\n" " "} $text ]
}

proc p.is_address { hit_item } {
	variable db
	set type [ mod::one $db type items item_id $hit_item ]
	return [ expr { $type == "address" } ]
}

proc p.get_branches_except { hit_item } {
	variable db
	set text [ mod::one $db text items item_id $hit_item ]
	set diagram_id [ mod::one $db diagram_id items item_id $hit_item ]	
	return [ $db eval {
		select text
		from items
		where diagram_id = :diagram_id
			and text != :text
			and type = 'branch' 
		order by x } ]
}

proc p.get_branches {  } {
	variable db
	
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return "" }
	
	return [ $db eval {
		select text, item_id
		from items
		where diagram_id = :diagram_id
			and type = 'branch' 
		order by x } ]
}


proc change_current_dia { old_id new_id hard record } {
	variable db
	
	if { $new_id == $old_id } { return }

	begin_transaction change_current_dia
	save_view
	
	if { $old_id != "" } {
		mw::unselect_dia "" 0
	}
	
	$db eval {
    update state 
    set current_dia = :new_id }
  
	fetch_view
	
	if { $new_id != "" } {
		mw::select_dia_kernel $new_id $hard
		if { $record } {
			back::record $new_id
		}
	}
	
	commit_transaction change_current_dia
	state reset
}

proc get_selected_from_tree { } {
	variable db
	set selection [ mtree::get_selection ]
	if { [ llength $selection ] != 1 } { return "" }
	set selected_node [ lindex $selection 0 ]
	lassign [ $db eval {
		select type, diagram_id from tree_nodes where node_id = :selected_node } ] type diagram_id
	if { $type == "folder" } {
		return ""
	} elseif { [ is_diagram $type ] } {
		if { $diagram_id == "" } {
			error "Empty diagram id for node $selected_node"
		}
		return $diagram_id
	} else {
		error "Bad node type: $type (selected_node=$selected_node, diagram_id=$diagram_id, selection=$selection)"
	}
}

proc current_dia_changed {} {
	variable db

	
	
	set old_id [ editor_state $db current_dia ]
	set new_id [ get_selected_from_tree ]
	

	if { $new_id == "" && $old_id == "" } { return }
	
	change_current_dia $old_id $new_id 1 1
}



proc switch_to_dia { diagram_id } {
	variable db
	
	if { $diagram_id == "" } { return }
	set old_id [ editor_state $db current_dia ]
	change_current_dia $old_id $diagram_id 0 1
}

proc switch_to_dia_no_hist { diagram_id } {
	variable db
	set old_id [ editor_state $db current_dia ]
	change_current_dia $old_id $diagram_id 0 0
}

proc diagram_exists { diagram_id } {
	variable db
	set count [ $db onecolumn { 
		select count(*) from diagrams where diagram_id = :diagram_id
	} ]
	return [ expr { $count > 0 } ]
}

proc center_on { item_id } {
	variable db
	variable scroll_x
	variable scroll_y
	
	set width [ unzoom_value $mw::canvas_width ]
	set height [ unzoom_value $mw::canvas_height ]
	$db eval {
		select x, y
		from items
		where item_id = :item_id
	} {
		set width2 [ expr { $width / 2 } ]
		set height2 [ expr { $height / 2 } ]
		set scroll_x [ expr { $x - $width2 } ]
		set scroll_y [ expr { $y - $height2 } ]
		set cscroll_x [ zoom_value $scroll_x ]
		set cscroll_y [ zoom_value $scroll_y ]
		set cscroll [ list $cscroll_x $cscroll_y ]
		mw::scroll $cscroll 1
	}
}

proc switch_to_item { item_id } {
	variable db
	set new_diagram_id [ mod::one $db diagram_id items item_id $item_id ]


	switch_to_dia $new_diagram_id
	
	begin_transaction switch_to_item

	push_unselect_items $new_diagram_id
	push_select_item $item_id
	center_on $item_id

	save_view
	commit_transaction switch_to_item
	state reset	
}

proc get_dia_description { } {
	variable db
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return "" }
	return [ mod::one $db description diagrams diagram_id $diagram_id ]
}

proc has_selection { } {
	variable db
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return 0 }
	
	set count [ $db onecolumn { select count(*) from items where diagram_id = :diagram_id
		and selected = 1 } ]
	
	if { $count == 0 } { return 0 }
	return 1
}

proc dia_properties { } {
	variable db
	set id [ editor_state $db current_dia ]
	if { $id == "" } { return }

	set descr_name [ $db eval { select description, name from diagrams where diagram_id = :id } ]
	lassign $descr_name old dia_name

	ui::text_window [ mc2 "\$dia_name: Edit diagram description" ] $old mwc::do_dia_properties $old
}



proc create_file { } {
	variable db
	hl::reset
	log create_file
	set filename [ ds::requestspath main .drn ]
	if { $filename != "" } {
		mod::close $db
		if { ![ ds::createfile $filename ] } { 
			ds::complain_file $filename
			exit
		}
	}
}

proc open_file { } {
	variable db
	hl::reset	
	set filename [ ds::requestopath main ]
	if { $filename != "" } {
		mod::close $db
		if { ![ ds::openfile $filename ] } { 
			ds::complain_file $filename
			exit
		}
	}
}

proc save_as { } {
	set filename [ ds::requestspath main .drn ]
	if { $filename != "" } {
		if { ![ ds::saveasfile $filename ] } { 
			ds::complain_file $filename
			exit
		}
	}
}

proc prime_view { diagram_id sx sy zoom_level } {
  variable zoom
  variable scroll_x
  variable scroll_y
  variable g_current_dia

  
}

proc set_view { view } {
  variable db
  variable zoom
  variable scroll_x
  variable scroll_y
  variable g_current_dia

  set old_zoom $zoom
  set old_dia $g_current_dia
  
  lassign $view g_current_dia scroll_x scroll_y zoom
  $db eval { update state set current_dia = :g_current_dia }
  
  if { $g_current_dia != "" } {
    set origin [ list $scroll_x $scroll_y ]
    $db eval {
      update diagrams
      set zoom = :zoom, origin = :origin
      where diagram_id = :g_current_dia }
  }

  if { $g_current_dia != $old_dia || $zoom != $old_zoom } {
    if { $g_current_dia != "" } {
      mw::unselect_dia "" 1
      mw::select_dia $g_current_dia 1
    }
  } else {
    set cx [ zoom_value $scroll_x ]
    set cy [ zoom_value $scroll_y ]
    mw::scroll [ list $cx $cy ] 1
  }  
}

proc start_action { name { save_camera save } } {
  variable zoom
  variable scroll_x
  variable scroll_y
  variable g_current_dia

  
  
  if { $save_camera == "dont_save" } {
    set delegates {}
  } elseif { $save_camera == "save" } {
    save_view
    set view [ list $g_current_dia $scroll_x $scroll_y $zoom ]
    set delegates [ wrap mwc::set_view $view ]
  } else {
    error "Wrong value of 'save_camera': $save_camera"
  }
  
  com::start_action $name $delegates
}


proc check_integrity { } {
	variable db
	set errors {}
	$db eval {
		select node_id, parent
		from tree_nodes
		where parent != 0
	} {
		set found [ $db onecolumn {
			select count(*) from tree_nodes where node_id = :parent } ]
		if { $found == 0 } {
			lappend errors "Node $node_id [ get_node_text $node_id ] has a dangling parent id: $parent."
		}
	}
	
	if { [ llength $errors ] != 0 } {
		error $errors
	}
}

proc goto {} {
	variable db
	set diagrams {}
	
	$db eval {
		select diagram_id, name
		from diagrams
	} {
		lappend diagrams $name $diagram_id
	}
	
	jumpto::goto_dialog $diagrams
}


proc find_referenced_diagrams { item_id current_diagram_id} {
	variable db
	set diagram_name [$db onecolumn {
			select name
			from diagrams
			where diagram_id = :current_diagram_id
	}]
	
	set text [ $db onecolumn {
		select text
		from items
		where item_id = :item_id } ]	
	
	set parts [ split $diagram_name "."]
	if { [llength $parts] == 2 } {
		lassign $parts task name
		set part1 [find_referenced_diagrams_normal $text]
		set part2 [find_referenced_diagrams_utopist $text $task ]
		return [concat $part1 $part2]
	} else {
		return [find_referenced_diagrams_normal $text]
	}
}

proc find_referenced_diagrams_utopist { text ctask } {
	variable db
	set result {}
	$db eval {
		select diagram_id, name
		from diagrams
		order by name
	} {
		set parts [ split $name "."]
		if { [llength $parts] == 2} {
			lassign $parts otask oname
			if {$ctask == $otask} {		
				if { [ string first $oname $text ] != -1 } {
					lappend result [ list $diagram_id $name ]
				}
			}
		}
	}
	return [lrange $result 0 7 ]
}


proc find_referenced_diagrams_normal { text } {
	variable db
	set result {}
	$db eval {
		select diagram_id, name
		from diagrams
		order by name
	} {
		if { [ string first $name $text ] != -1 } {
			lappend result [ list $diagram_id $name ]
		}
	}
	return [lrange $result 0 7 ]
}


proc property_keys { } {
	return { language canvas_font canvas_font_size pdf_font pdf_font_size }
}

proc get_file_properties { } {
	variable db
	
	set name [ $db onecolumn {
		SELECT name FROM sqlite_master WHERE type='table' AND name='info'
	} ]
	
	if { $name == "" } {
		return {}
	}
	
	set result {}
	set keys [ property_keys ]
	$db eval {
		select key, value
		from info
	} {
		if { [ contains $keys $key ] } {
			lappend result $key $value
		}
	}
	return $result
}

proc set_file_properties { props } {
	variable db
	array set properties $props
	set keys [ property_keys ]

	set do {}
	set undo {}

	# deletes
	foreach key $keys {
		set value [ $db onecolumn { select value from info where key = :key } ]
		set value [ sql_escape $value ]
		if { $value != "" && ![ info exists properties($key) ] } {
			lappend do [ list delete info key '$key' ]
			lappend undo [ list insert info key '$key' value '$value' ]
		}
	}

	foreach key [ array names properties ] {
		set old_value [ $db onecolumn { select value from info where key = :key } ]
		set new_value [ sql_escape $properties($key) ]
		if { $old_value == "" } {
			# insert
			lappend do [ list insert info key '$key' value '$new_value' ]
			lappend undo [ list delete info key '$key' ]
		} else {
			# update
			set old_value [ sql_escape $old_value ]
			lappend do [ list update info key '$key' value '$new_value' ]
			lappend undo [ list update info key '$key' value '$old_value' ]
		}
	}
	
	begin_transaction set_file_properties
	start_action  [ mc2 "Change file properties" ]
	
	set action [ wrap mwc::refill_all foo ]
	com::push $db $action $do $action $undo
	
	commit_transaction set_file_properties
	state reset
	
	return 1
}

proc refill_all { foo replay } {
	mwf::reset
	refill_current foo 1
}

proc find_diagram_rect { db diagram_id } {
	set left 1000000
	set right -1000000
	set top 1000000
	set bottom -1000000
	
	set empty 1
	
	$db eval {
		select x, y, w, h, a, b, type
		from items
		where diagram_id = :diagram_id
	} {
		set box mv::$type.box
		lassign [ $box $x $y $w $h $a $b ] bleft btop bright bbottom
		if { $bleft < $left } { set left $bleft }
		if { $bright > $right } { set right $bright }
		if { $btop < $top } { set top $btop }
		if { $bbottom > $bottom } { set bottom $bbottom }
		set empty 0
	}
	if { $empty } {
		return { 0 0 200 200 }
	} else {
		set left [ expr { int($left) } ]
		set right [ expr { int($right) } ]
		set top [ expr { int($top) } ]
		set bottom [ expr { int($bottom) } ]
		
		incr left -10
		incr right 10
		incr top -10
		incr bottom 10
	
		set width [ expr { $right - $left } ]
		if { $width < 200 } { set width 200 }
		set height [ expr { $bottom - $top } ]
		if { $height < 200 } { set height 200 }
	
		return [ list $left $top $width $height ]
	}
}

proc get_colorful_items { } {
	variable db	
	
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return {} }
	
	set items [ $db eval {
		select item_id
		from items
		where diagram_id = :diagram_id
		and selected = 1
		and type not in ('vertical', 'horizontal', 'parallel')
	} ]
	
	return $items
}


proc change_color_impl { items name new_color } {

	variable db
	
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }
	
	begin_transaction change_color
	start_action $name



	set changes {}
	set changes_back {}
	set present {}
	foreach item_id $items {
		set old_color [ mod::one $db color items item_id $item_id ]
		set old_color [ sql_escape $old_color ]
		
		lappend changes [ list update items item_id $item_id color '$new_color' ]
		lappend changes_back [ list update items item_id $item_id color '$old_color' ]
		lappend present [ list mv::delete $item_id ]
		lappend present [ list mv::insert $item_id ]
		lappend present [ list mv::select $item_id ]
	}

		
	com::push $db $present $changes $present $changes_back
	
	commit_transaction change_color
	
	state reset
}

proc change_color { items fg bg } {
	set new_color [ list fg $fg bg $bg ]
	change_color_impl $items [ mc2 "Change colors" ] $new_color
}


proc clear_color { items } {
	set new_color {}
	change_color_impl $items [ mc2 "Clear colors" ] $new_color
}

proc get_items_color { items } {
	variable db
	foreach item_id $items {
		set color [ mod::one $db color items item_id $item_id ]
		if { $color != "" } { return $color }
	}
	return ""
}

}
