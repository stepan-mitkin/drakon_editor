namespace eval graph {

variable end_text_rus "\u43A\u43E\u43D\u435\u446"

proc p.do_extract_auto { diagram_id } {
	p.denormalize_vertices $diagram_id
	set starts [ p.find_starts $diagram_id ]
	if { [ p.errors $diagram_id ] } { return }
	
	p.create_branches $diagram_id
	p.check_reachable $diagram_id
	if { [ p.errors $diagram_id ] } { return }
	
	p.degrade_silouette_check $diagram_id $starts
	if { [ p.errors $diagram_id ] } { return }	
	
	p.check_icons_on_verticals $diagram_id $starts
	if { [ p.errors $diagram_id ] } { return }
	

	p.trace $diagram_id $starts
	if { [ p.errors $diagram_id ] } { return }

	p.loops $diagram_id

	p.check_loops $diagram_id
	if { [ p.errors $diagram_id ] } { return }

	p.check_infinite $diagram_id
	if { [ p.errors $diagram_id ] } { return }

	p.check_cases $diagram_id
	if { [ p.errors $diagram_id ] } { return }

	p.skip_joints $diagram_id
}

proc p.degrade_silouette_check { diagram_id starts } {
	set branch_count [ gdb onecolumn {
		select count(*)
		from branches
		where diagram_id = :diagram_id } ]
	
	if { $branch_count < [ llength $starts ] } {
		p.error $diagram_id {} [ mc2 "Too many 'begin' icons." ]
		return
	}

	if { $branch_count == 1 } {
		set headers [ gdb onecolumn {
			select count(*)
			from vertices
			where diagram_id = :diagram_id
				and type = 'branch' } ]
		if { $headers != 0 } {
			p.error $diagram_id { } [ mc2 "A silouette must have more than one branch." ]
			return
		}
	}
}

proc p.trace { diagram_id starts } {
	set branch_count [ gdb onecolumn {
		select count(*)
		from branches
		where diagram_id = :diagram_id } ]
	
	gdb eval {
		update vertices
		set marked = 0
		where diagram_id = :diagram_id }

	set first [ lindex $starts 0 ]
	
	if { $branch_count == 1 } {
		p.start_primitive $diagram_id $first
	} else {
		if { ![ p.check_main_arrow $diagram_id ] } { return }
		p.start_silouette $diagram_id
	}
}

proc p.check_main_arrow { diagram_id } {
	set count [ gdb onecolumn {
		select count(*)
		from edges
		where diagram_id = :diagram_id
			and vertical = 0
			and head = 'right arrow' } ]
	if { $count == 1 } {
		return 1
	} else {
		p.error $diagram_id {} [ mc2 "A silouette must have exactly one arrow at the right side." ]
		return 0
	}
}

proc p.get_params { start_vertex } {
	set edge [ gdb onecolumn {
		select right from vertices where vertex_id = :start_vertex } ]
	return [ gdb onecolumn {
		select vertex2 from edges where edge_id = :edge } ]
}

proc p.connect_branch_to_start { diagram_id branch_no start_vertex } {
	set params [ p.get_params $start_vertex ]
	gdb eval {
		update branches
		set start_icon = :start_vertex, params_icon = :params
		where diagram_id = :diagram_id
			and ordinal = :branch_no }
}

proc p.set_branch_first_icon { diagram_id branch_no first_icon } {
	gdb eval {
		update branches
		set first_icon = :first_icon
		where diagram_id = :diagram_id
			and ordinal = :branch_no }	
}

proc p.start_primitive { diagram_id first } {
	set vertex_info [ p.get_info $first]
	lassign $vertex_info type text up left right down
	
	p.connect_branch_to_start $diagram_id 1 $first
	p.set_branch_first_icon $diagram_id 1 $down
	
	s.down $first $down 1 1 0
}

proc p.is_marked { vertex_id } {
	set marked [ gdb onecolumn {
		select marked
		from vertices
		where vertex_id = :vertex_id } ]

	return $marked
}

proc p.mark { vertex_id } {
	gdb eval {
		update vertices
		set marked = 1
		where vertex_id = :vertex_id }
}

proc p.check_and_mark { vertex_id } {
	set marked [ gdb onecolumn {
		select marked
		from vertices
		where vertex_id = :vertex_id } ]
	
	if { $marked } { return 0 }
	
	gdb eval {
		update vertices
		set marked = 1
		where vertex_id = :vertex_id }
	
	return 1
}

proc p.check_skewer_marked { vertex_id } {
	set marked [ gdb onecolumn {
		select marked
		from vertices
		where vertex_id = :vertex_id } ]
	
	if { !$marked } { return 0 }
	set edge_id [ gdb onecolumn {
		select left from vertices where vertex_id = :vertex_id } ]
	if { $edge_id == "" } {
		error [ mc2 "Left is empty." ]
	}
	p.unexpected_edge $edge_id
	return 1
}

proc p.link { from ordinal to direction } {
	if { $from == "" } {
		error [ mc2 "p.link: from is empty" ]
	}
	set dst [ gdb onecolumn { select dst from links where src = :from and ordinal = :ordinal } ]
	if { $dst != "" } {
		if { $to != $dst } {
			error [ mc2 "Link not unique: \$from, \$ordinal -> old: \$dst new: \$to." ]
		}
	} else {
		gdb eval {
			insert into links (src, ordinal, dst, direction)
			values (:from, :ordinal, :to, :direction)
		}
	}
}

proc p.unlink { src } {
	gdb eval {
		delete from links
		where src = :src }
}

proc p.unlink_one { src ordinal } {
	gdb eval {
		delete from links
		where src = :src and ordinal = :ordinal }
}


proc p.relink { src old_ordinal ordinal direction } {
	set count [ gdb onecolumn { 
		select count(*) 
		from links 
		where src = :src and ordinal = :old_ordinal } ]
	if { $count == 0 } {
		error [ mc2 "Link not found: \$src \$old_ordinal" ]
	}
	gdb eval {
		update links
		set ordinal = :ordinal, direction = :direction
		where src = :src and ordinal = :old_ordinal }
}

proc p.get_links { vertex_id } {
	return [ gdb eval {
		select dst
		from links
		where src = :vertex_id
		order by ordinal } ]
}


proc p.get_info { vertex_id } {
	gdb eval {
		select type, text, up, left, right, down, diagram_id, item_id
		from vertices
		where vertex_id = :vertex_id
	} {
		set upv ""
		set leftv ""
		set rightv ""
		set downv ""
		
		if { $up != "" } {
			set upv [ gdb onecolumn { select vertex1 from edges where edge_id = :up  } ]
		}
		if { $left != "" } {
			set leftv [ gdb onecolumn { select vertex1 from edges where edge_id = :left  } ]
		}
		if { $right != "" } {
			set rightv [ gdb onecolumn { select vertex2 from edges where edge_id = :right  } ]
		}
		if { $down != "" } {
			set downv [ gdb onecolumn { select vertex2 from edges where edge_id = :down  } ]
		}
		return [ list $type $text $upv $leftv $rightv $downv $diagram_id $item_id ]
	}
}

proc s.down { src vertex_id is_primitive is_skewer loop_depth } {
	p.link $src 1 $vertex_id "down"
	if { ![ p.check_and_mark $vertex_id ] } { return }


	lassign [ p.get_info $vertex_id ] type text up left right down
	switch $type {
		"action" {
			s.down $vertex_id $down $is_primitive $is_skewer $loop_depth
		}
		"shelf" {
			s.down $vertex_id $down $is_primitive $is_skewer $loop_depth
		}
		"if" {
			s.down $vertex_id $down $is_primitive $is_skewer $loop_depth
			s.right $vertex_id $right $is_primitive 1 2
		}
		"loopstart" {
			set nested [ expr { $loop_depth + 1 } ]
			s.down $vertex_id $down $is_primitive $is_skewer $nested
		}
		"loopend" {
			if { $loop_depth == 0 } {
				p.unexpected_vertex $vertex_id
				return
			}

			set outer [ expr { $loop_depth - 1 } ]
			s.down $vertex_id $down $is_primitive $is_skewer $outer
		}
		"select" {
			s.select_joint $vertex_id $down $is_primitive $is_skewer $loop_depth
		}
		"address" {
			if { $is_primitive || $loop_depth != 0 } {
				p.unexpected_vertex $vertex_id
				return
			}
			p.address $vertex_id
		}
		"beginend" {
			if { ![ p.is_end $text ] || $loop_depth != 0 } {
				p.unexpected_vertex $vertex_id
				return
			}
		}
		"" {
			if { [ p.is_cross $vertex_id ] } { return }
			if { $is_skewer || $loop_depth != 0 } {
				if { $left != "" } {
					set edge [ gdb onecolumn { select left from
						vertices where vertex_id = :vertex_id } ]
					p.unexpected_edge $edge
					return
				}
				if { $down == "" } {
					set edge [ gdb onecolumn { select right from
						vertices where vertex_id = :vertex_id } ]
					p.unexpected_edge $edge
					return
				}
			}
			if { $down != "" } {
				set right_edge [ gdb onecolumn { select right from vertices where vertex_id = :vertex_id } ]
				
				if { $right_edge != "" } {
					set head [ gdb onecolumn { select head from edges where edge_id = :right_edge } ]
					if { $head != "left arrow" } {
						p.check_right_goes_up $vertex_id
					}
				}
				s.down $vertex_id $down $is_primitive $is_skewer $loop_depth
			} elseif { $left != "" } {
				s.left $vertex_id $left $is_primitive
			} elseif { $right != "" } {
				s.right $vertex_id $right $is_primitive 0 1
			}
		}
		default {
			p.unexpected_vertex $vertex_id
		}
	}	
}

proc s.select_joint { select vertex_id is_primitive is_skewer loop_depth } {
	if { [ p.is_cross $vertex_id ] } { return }
	lassign [ p.get_info $vertex_id ] type text up left right down diagram_id
	if { $type != "" } {
		p.unexpected_vertex $vertex_id
		return
	}
	set item_id [ gdb onecolumn { select item_id from vertices where vertex_id = :select } ]
	if { $left != "" || $right == "" || $down == "" } {
		p.error $diagram_id [ list $item_id ] [ mc2 "A right t-joint expected after the 'select' icon." ]
		return
	}
	s.case 1 $select $down $is_primitive $is_skewer $loop_depth
	set current $right
	set i 2
	while { $current != "" } {
		lassign [ p.get_info $current ] type text up left right down diagram_id
		if { $type != "" } {
			p.unexpected_vertex $current
			return
		}
		if { [ p.is_cross $current ] } { return }
		if { $up != "" || $down == "" } {
			p.error $diagram_id [ list $item_id ] [ mc2 "Expected a line with a 'case' icon." ]
			return
		}
		s.case $i $select $down $is_primitive 0 0
		incr i
		set current $right
	}
}

proc s.case { ordinal select vertex_id is_primitive is_skewer loop_depth } {
	if { $ordinal == 1 } {
		set direction "down"
	} else {
		set direction "step"
	}
	p.link $select $ordinal $vertex_id $direction
	lassign [ p.get_info $vertex_id ] type text up left right down diagram_id item_id
	if { $type == "" } {
		set edge [ gdb onecolumn { select up from vertices where vertex_id = :vertex_id } ]
		set items [ gdb onecolumn { select items from edges where edge_id = :edge } ]
		p.error $diagram_id $items [ mc2 "A 'case' icon expected." ]
		return
	}

	if { $type != "case" } {
		p.unexpected_vertex $vertex_id
		return
	}

	s.down $vertex_id $down $is_primitive $is_skewer $loop_depth
}

proc s.left { src vertex_id is_primitive } {
	p.link $src 1 $vertex_id "left"
	if { [ p.is_marked $vertex_id ] } { return }
	if { [ p.is_cross $vertex_id ] } { return }


	lassign [ p.get_info $vertex_id ] type text up left right down
	if { $type != "" } {
		p.unexpected_vertex $vertex_id
		return
	}
	set dedge [ gdb onecolumn { select down from vertices where vertex_id = :vertex_id } ]
	if { $left != "" && $down != "" && $up == "" } {
		p.unexpected_edge $dedge
		return
	}
	set redge [ gdb onecolumn { select right from vertices where vertex_id = :vertex_id } ]
	if { $left == "" } {
		if { $up == "" || $down == "" } {
			lassign [ gdb eval { select items, diagram_id from edges where edge_id = :redge } ] items diagram_id
			p.error $diagram_id $items [ mc2 "Wrong turn." ]
			return
		}
	} else {
		p.mark $vertex_id
		s.left $vertex_id $left $is_primitive
	}
}

proc s.up { src vertex_id is_primitive } {
	p.link $src 1 $vertex_id "up"
	if { [ p.is_cross $vertex_id ] } { return }
	if { ![ p.check_and_mark $vertex_id ] } { return }
	lassign [ p.get_info $vertex_id ] type text up left right down
	if { $type != "" } {
		p.unexpected_vertex $vertex_id
		return
	}

	if  { $left == "" || $up != "" || $right != "" } {
		set dedge [ gdb onecolumn { select down from vertices where vertex_id = :vertex_id } ]
		lassign [ gdb eval { select items, diagram_id from edges where edge_id = :dedge } ] items diagram_id
		p.error $diagram_id $items [ mc2 "The line should turn left at the top." ]
		return
	}

	s.arrow $vertex_id $left
}

proc s.arrow { src vertex_id } {
	if { [ p.is_cross $vertex_id ] } { return }
	p.link $src 1 $vertex_id "arrow"

	lassign [ p.get_info $vertex_id ] type text up left right down
	if { $type != "" } {
		p.unexpected_vertex $vertex_id
		return
	}

	set redge [ gdb onecolumn { select right from vertices where vertex_id = :vertex_id } ]
	lassign [ gdb eval { select items, diagram_id, head from edges where edge_id = :redge } ] items diagram_id head
	
	if { $head != "left arrow" } {
		p.error $diagram_id $items [ mc2 "Arrow expected." ]
		return
	}

	if  { $left != "" || $up == "" || $down == "" } {
		p.error $diagram_id $items [ mc2 "Arrow points to a wrong place." ]
		return
	}
}

proc s.right { src vertex_id is_primitive down_allowed ordinal } {
	p.link $src $ordinal $vertex_id "right"
	if { [ p.is_cross $vertex_id ] } { return }
	if { [ p.is_marked $vertex_id ] } { return }




	lassign [ p.get_info $vertex_id ] type text up left right down
	set dedge [ gdb onecolumn { select down from vertices where vertex_id = :vertex_id } ]
	if { $right != "" && $down != "" } {
		p.unexpected_edge $dedge
		return
	}

	set uedge [ gdb onecolumn { select up from vertices where vertex_id = :vertex_id } ]
	if { $right != "" && $up != "" } {
		p.unexpected_edge $uedge
		return
	}


	if { $right == "" } {
		if { $up != "" && $down != "" } { return }
		p.mark $vertex_id
		if { $down != "" } {
			if { !$down_allowed } {
				p.unexpected_edge $dedge
				return
			}
			s.down $vertex_id $down $is_primitive 0 0
		} else {
			s.up $vertex_id $up $is_primitive
		}
	} else {
		p.mark $vertex_id
		s.right $vertex_id $right $is_primitive $down_allowed 1
	}
}

proc p.address { vertex_id } {
	set downe [ gdb onecolumn { select down from vertices where vertex_id = :vertex_id } ]
	set down_edge [ gdb eval {
		select vertex2, items
		from edges
		where edge_id = :downe } ]
	lassign $down_edge down_vertex items
	p.check_bottom_right_ok $down_vertex $items
	p.check_bottom_arrow_ok $down_vertex
}

proc p.check_bottom_right_ok { vertex_id items } {
	set current $vertex_id
	while { $current != "" } {
		set vinfo [ p.get_info $current ]
		lassign $vinfo type text up left right down diagram_id item_id

		if { $type != "" } {
			p.unexpected_vertex $current
			return
		}
		
		if { $left == "" } {
			p.error $diagram_id $items [ mc2 "A left-leading line expected here." ]
			return
		}
		
		if { $down != "" } {
			set bad_edge [ gdb onecolumn {
				select down from vertices where vertex_id = :current } ]
			p.unexpected_edge $bad_edge
			return
		}
		
		set current $right
	}
}

proc p.check_bottom_arrow_ok { down_vertex } {
	set current $down_vertex
	while { $current != "" } {
		set vinfo [ p.get_info $current ]
		lassign $vinfo type text up left right down diagram_id item_id
		if { $type != "" } {
			p.unexpected_vertex $current
			return
		}
		set edge_id [ gdb onecolumn { select right from vertices where vertex_id = :current } ]
		set items [ gdb onecolumn { select items from edges where edge_id = :edge_id } ]
		
		if { $up == "" } {
			p.error $diagram_id $items [ mc2 "Error near this line." ]
			return
		}
		
		if { $down != "" } {
			p.error $diagram_id $items [ mc2 "Error near this line." ]
			return			
		}
		
		if { $left == "" } {
			set uinfo [ p.get_info $up ]
			lassign $uinfo utype utext uup uleft uright
			if { $utype != "" } {
				p.unexpected_vertex $up
				return
			}
			
			if { $uleft != "" } {
				p.unexpected_edge [ gdb onecolumn { select left from vertices where vertex_id = :up } ]
				return
			}
			if { $uup != "" } {
				p.unexpected_edge [ gdb onecolumn { select up from vertices where vertex_id = :up } ]
				return
			}
			
			set arrow_edge_id [ gdb onecolumn { select right from vertices where vertex_id = :up } ]
			gdb eval { 
				select head, items from edges where edge_id = :arrow_edge_id
			} {
				if { $head != "right arrow" } {
					p.error $diagram_id $items [ mc2 "Arrow expected here." ]
				}
			}
			return
		}
		
		set current $left
	}
}


proc p.is_cross { vertex_id } {
	gdb eval {
		select up, left, right, down, diagram_id
		from vertices
		where vertex_id = :vertex_id
	} {
		if { $up != "" && $left != "" && $right != "" && $down != "" } {
			set items [ gdb onecolumn { select items from edges where edge_id = :left } ]
			p.error $diagram_id $items [ mc2 "Line crossings are not allowed." ]
			return 1
		}
	}
	return 0
}


proc p.is_valid_arrow_end { vertex_id } {
	gdb eval {
		select up, left, right, down, type
		from vertices
		where vertex_id = :vertex_id
	} {
		if { $up != "" && $left == "" && $down != "" && $type == "" } { return 1 }
	}
	return 0
}



proc p.check_right_goes_up { vertex_id } {
	set rightmost [ p.find_rightmost $vertex_id ]
	lassign [ gdb eval { select down, diagram_id from vertices where vertex_id = :rightmost } ] down diagram_id
	if { $down != "" } {
		set items [ p.get_left_edge_items $rightmost ]
		p.error $diagram_id $items [ mc2 "The line should go up at the right." ]
		return 0
	}
	return 1
}

proc p.check_right_not_bare_down { vertex_id } {
	set rightmost [ p.find_rightmost $vertex_id ]
	lassign [ gdb onecolumn { select down, up, diagram_id from vertices where vertex_id = :rightmost } ] down up diagram_id
	if { $down != "" && $up == "" } {
		set items [ p.get_left_edge_items $rightmost ]
		p.error $diagram_id $items [ mc2 "The line should not go down at the right." ]
		return 0
	}
	return 1
}


proc p.find_rightmost { vertex_id } {
	set current $vertex_id
	while { 1 } {
		set right [ gdb onecolumn { select right 
			from vertices where vertex_id = :current } ]
		if { $right == "" } {
			return $current
		}
		set current [ gdb onecolumn {
			select vertex2 from edges where edge_id = :right } ]
	}
}

proc p.get_left_edge_items { vertex_id } {
	return [ gdb onecolumn {
		select items
		from edges e inner join vertices v
			on e.edge_id = v.left
		where vertex_id = :vertex_id } ]
}



proc p.start_silouette { diagram_id } {
	gdb eval {
		select ordinal, header_icon
		from branches
		where diagram_id = :diagram_id
		order by diagram_id
	} {

		p.try_connect_branch_to_start $diagram_id $ordinal $header_icon
		set branch [ p.get_info $header_icon ]
		lassign $branch type text up left right down foo item_id
		p.set_branch_first_icon $diagram_id $ordinal $down
		s.down $header_icon $down 0 1 0
	}
}

proc p.try_connect_branch_to_start { diagram_id ordinal header_icon } {
	set branch [ p.get_info $header_icon ]
	lassign $branch type text up left right down foo item_id
	
	if { $up == "" } {
		p.error $diagram_id [ list $item_id ] [ mc2 "A going up line expected here." ]
		return
	}
	
	set node [ p.get_info $up ]
	lassign $node ntype ntext nup nleft nright ndown foo nitem

	p.trace_to_arrow $up $item_id
	
	if { $nup == "" } {
		return
	}

	set start_info [ p.get_info $nup ]
	lassign $start_info stype stext
	if { $stype == "beginend" } {
		p.connect_branch_to_start $diagram_id $ordinal $nup	
	}
}

proc p.trace_to_arrow { header_node item_id } {
	set current $header_node
	while { 1 } {
		set node [ p.get_info $current ]

		
		lassign $node type text up left right down diagram_id item
		
		if { $type != "" } {
			p.unexpected_vertex $current
			return
		}
		
		if { $left == "" } {
			p.error $diagram_id {} [ mc2 "Arrow expected at the top of the diagram." ]
			return
		}
		
		set left_edge [ gdb eval { 
			select head, edge_id, items
			from edges e inner join vertices v
				on v.left = e.edge_id
			where vertex_id = :current } ]
		lassign $left_edge head edge_id items
		
		if { $head == "left arrow" } {
			p.error $diagram_id $items [ mc2 "Left arrow not expected." ]
			return
		}
		
		if { $head == "right arrow" } {
			break
		}
		
		set current $left
	}
	
	set current $header_node
	while { $current != "" } {

		set node [ p.get_info $current ]
		lassign $node type text up left right down diagram_id item
		
		if { $type != "" } {
			p.unexpected_vertex $current
			return
		}
		
		if { $up != "" } {
			gdb eval {
				select item_id, type, down downe
				from vertices
				where vertex_id = :up
			} {
				if { $type == "" } {
					p.unexpected_edge $downe
					return
				}
				if { $type != "beginend" || $down == "" } {
					p.unexpected_vertex $up
					return
				}
			}
		}
		
		if { $down != "" } {
			gdb eval {
				select item_id, type, up upe
				from vertices
				where vertex_id = :down
			} {
				if { $type == "" } {
					p.unexpected_edge $upe
					return
				}
				if { $type != "branch" } {
					p.unexpected_vertex $down
				}
			}
		}
		
		set current $right
	}
}
		
proc p.denormalize_vertices { diagram_id } {
	gdb eval {
		select vertex_id, item_id
		from vertices
		where diagram_id = :diagram_id 
			and item_id is not null
	} {	
		set icon [ gdb eval {
			select type, text
			from items
			where item_id = :item_id } ]
			
		lassign $icon type text
		
		gdb eval {
			update vertices
			set type = :type, text = :text
			where vertex_id = :vertex_id
		}
	}
}

proc p.unexpected_edge { edge_id } {
	gdb eval {
		select items, diagram_id, vertex1, vertex2
		from edges
		where edge_id = :edge_id
	} {
		set message [ mc2 "Line not expected here." ]
	
		p.error $diagram_id $items $message
	}
}

proc p.unexpected_vertex { vertex_id } {
	gdb eval {
		select item_id, diagram_id, type
		from vertices
		where vertex_id = :vertex_id
	} {
		if { $type == "timer" || $type == "pause" } {
			set message [ mc2 "Elements of type '\$type' are not supported by the verifier yet." ]
		} else {
			set message [ mc2 "Icon '\$type' not expected here." ]
		}
		p.error $diagram_id [ list $item_id ] $message
	}
}



proc p.is_end { text } {
	variable end_text_rus
	set lowered [ string tolower $text ]

	return [ expr { $lowered == "end" || $lowered == $end_text_rus || $text == [texts::get end] } ]
}

proc p.find_starts { diagram_id } {
	variable end_text_rus
	set ends_count 0
	set starts {}
	gdb eval {
		select vertex_id, type, text, up, left, right, down, item_id
		from vertices
		where diagram_id = :diagram_id
			and type = 'beginend'
		order by x
	} {
		if { $left != "" } {
			p.unexpected_edge $left
		} elseif { $down == "" && $right != "" } {
			p.unexpected_edge $right
		} elseif { $down != "" && $up != "" } {
			p.unexpected_edge $up
		} elseif { $down == "" && $up == "" } {
			p.error $diagram_id [ list $item_id ] [ mc2 "Disconnected icon." ]
		}
		
		if { $down == "" } {
			if { [ p.is_end $text ] } {
				incr ends_count
			} else {
				set end [texts::get end]
				p.error $diagram_id $item_id [ mc2 "'End' icon should have the text '\$end'" ]
			}
		} else {
			lappend starts $vertex_id
		}
	}
	
	if { $ends_count != 1 } {
		p.error $diagram_id {} [ mc2 "The diagram must have exactly one end." ]
	}
	if { [ llength $starts ] == 0 } {
		p.error $diagram_id {} [ mc2 "The diagram must have one or more starts." ]
	}
	return $starts
}


proc p.check_parameters { begin_vertex } {
	set right_edge [ gdb onecolumn {
		select right
		from vertices
		where vertex_id = :begin_vertex } ]
	if { $right_edge == "" } { return "" }
	set param_vertex [ gdb onecolumn {
		select vertex2
		from edges
		where edge_id = :right_edge } ]
	
	gdb eval {
		select up, right, down, diagram_id, item_id, type
		from vertices
		where vertex_id = :param_vertex
	} {
		if { $up != "" || $right != "" || $down != "" } {
			p.error $diagram_id [ list $item_id ] [ mc2 "Unexpected lines around the parameters icon." ]
		}
		if { $type != "action" } {
			p.error $diagram_id [ list $item_id ] [ mc2 "Only action icon can serve as a parameters icon." ]
		}
	}
	return $param_vertex
}

proc p.create_branches { diagram_id } {
	set headers [ gdb eval {
		select vertex_id
		from vertices
		where type = 'branch'
			and diagram_id = :diagram_id } ]
	
	set footers [ gdb eval {
		select vertex_id
		from vertices
		where type = 'address'
			and diagram_id = :diagram_id } ]
	
	if { [ llength $headers  ] != 0 && [ llength $footers ] == 0 } {
		p.error $diagram_id {} [ mc2 "Missing one or more address icons." ]
		return
	}
	
	array set names_to_headers { }
	
	foreach header $headers {
		gdb eval {
			select text, item_id
			from vertices
			where vertex_id = :header
		} {
			set text [ string trim $text ]	
			if { $text == "" } {
				p.error $diagram_id [ list $item_id ] [ mc2 "No text in the branch header." ]
				return
			}
			if { [ info exists names_to_headers($text) ] } {
				p.error $diagram_id [ list $item_id ] [ mc2 "Branch name \$text is not unique." ]
				return
			}
			set names_to_headers($text) $header
		}
	}
	
	foreach footer $footers {
		gdb eval {
			select text, item_id
			from vertices
			where vertex_id = :footer
		} {
			set text [ string trim $text ]	
			if { $text == "" } {
				p.error $diagram_id [ list $item_id ] [ mc2 "No text in the address header." ]
				return
			}
			if { ![ info exists names_to_headers($text) ] } {
				p.error $diagram_id [ list $item_id ] [ mc2 "Branch name \$text is not found." ]
				return
			}
			set header $names_to_headers($text)
			p.link $footer 1 $header "branch"
		}
	}
	
	if { [ llength $headers ] == 0 } {
		p.create_primitive_branch $diagram_id
		return 1
	} else {
		foreach header $headers {
			p.create_branch_from_header $diagram_id $header	
		}
		return [ llength $headers ]
	}
}

proc is_weak_machine { diagram_id } {
	if { ![ mwc::is_drakon $diagram_id ] } { return 0 }
	
	set starts [ p.find_starts $diagram_id ]
	set start [ lindex $starts 0 ]
	set params_icon [ p.get_params $start ]
	if { $params_icon == "" } { return 0 }

	set text [ gen::p.vertex_text gdb $params_icon ]
	set trimmed [ string trim $text ]
	
	if { $trimmed == "state machine" } {
		return 1
	}
	
	return 0
}


proc is_machine { diagram_id } {

	if { ![ mwc::is_drakon $diagram_id ] } { return 0 }

	set name [ gdb onecolumn { 
		select name
		from diagrams
		where diagram_id = :diagram_id } ]
		
	set name [ string tolower $name ]
	if { $name == "state machine" } { return 1 }
	if { [ string match "sm *" $name ] } { return 1 }
	
	set starts [ p.find_starts $diagram_id ]
	set start [ lindex $starts 0 ]
	set params_icon [ p.get_params $start ]
	if { $params_icon == "" } { return 0 }

	set text [ gen::p.vertex_text gdb $params_icon ]
	set trimmed [ string trim $text ]

	if { [ string match "state machine*" $trimmed ] } {
		return 1
	}

	return 0
}

proc p.check_reachable { diagram_id } {
	set headers [ gdb eval {
		select header_icon
		from branches
		where diagram_id = :diagram_id
		order by ordinal } ]

	set is_machine [ is_machine $diagram_id ]

	set length [ llength $headers ]
	set last [ expr { $length - 1 } ]
	for { set i 1 } { $i < $length } { incr i } {
		if { !($is_machine && $i == $last) } {
			set header [ lindex $headers $i ]
			if { ![ p.is_reachable $header ] } {
				set item_id [ gdb onecolumn { select item_id from vertices where vertex_id = :header } ]
				p.error $diagram_id $item_id [ mc2 "This branch is unreachable." ]
			}
		}
	}
}

proc p.is_reachable { vertex_id } {
	set count [ gdb onecolumn {
		select count(*)
		from links
		where dst = :vertex_id } ]
	return [ expr { $count > 0 } ]
}

proc p.create_primitive_branch { diagram_id } {
	gdb eval {
		insert into branches (diagram_id, ordinal)
		values (:diagram_id, 1)
	}
}

proc p.create_branch_from_header { diagram_id header } {
	set ordinal [ gdb onecolumn {
		select max(ordinal)
		from branches
		where diagram_id = :diagram_id } ]
	if { $ordinal == "" } { set ordinal 0 }
	incr ordinal
	gdb eval {
		insert into branches (diagram_id, ordinal, header_icon)
		values (:diagram_id, :ordinal, :header)
	}
}

proc p.parameters_icons { starts } {
	set result {}
	foreach start $starts {
		set params_vertex [ p.check_parameters $start ]
		if { $params_vertex != "" } {
			lappend result $params_vertex
		}
	}
	return $result
}

proc p.check_icons_on_verticals { diagram_id  starts } {
	set params [ p.parameters_icons $starts ]
	
	gdb eval {
		select vertex_id, up, left, right, down, type, item_id
		from vertices
		where diagram_id = :diagram_id
			and type in ('action', 'if', 'branch', 'case', 'insertion', 'loopend', 'loopstart', 'select', 'address')
	} {
		if { [ contains $params $vertex_id ] } { continue }
		if { $left != "" } {
			p.unexpected_edge $left
		}
		if { $type != "if" && $right != "" } {
			p.unexpected_edge $right
		}
		if { $up == "" || $down == "" } {
			p.error $diagram_id [ list $item_id ] [ mc2 "This icon should be placed on a vertical line." ]
		}
	}
}

proc p.loops { diagram_id } {
	gdb eval {
		update vertices
		set parent = 0, marked = 0
		where diagram_id = :diagram_id }
	set branches [ gdb eval {
		select header_icon
		from branches
		where diagram_id = :diagram_id } ]
	if { [ llength $branches ] == 1 } {
		gdb eval {
			select start_icon
			from branches
			where diagram_id = :diagram_id
		} {
			p.scan_loops $start_icon 0
		}
	} else {
		foreach header $branches {
			p.scan_loops $header 0
		}
	}
}

proc p.get_below { vertex_id } {
	return [ gdb onecolumn {
		select vertex2
		from edges e inner join vertices v
			on v.down = e.edge_id
		where vertex_id = :vertex_id } ]
}

proc p.scan_loops { vertex_id parent } {
	set current $vertex_id
	while { $current != "" } {
		if { ![ p.check_and_mark $current ] } { return }
		set below [ p.get_below $current ]

		gdb eval { update vertices set parent = :parent where vertex_id = :current }
		lassign [ gdb eval { select type, text from vertices where vertex_id = :current } ] type text

		switch $type {
			"loopstart" {
				lassign [ p.scan_loops $below $current ] last after_loop
				p.relink $current 1 2 "step"
				p.unlink $last
				p.link $current 1 $after_loop "down"

				set below $after_loop
			}
			"loopend" {
				set after_loop [ gdb onecolumn { select dst from links where src = :current } ]
				return [ list $current $after_loop ]
			}
			"if" {
				set if_start [ p.get_if_start $current ]
				if { $if_start != "" } {
					p.scan_loops $if_start $parent
				}
			}
			"select" {
				set select_starts [ p.get_select_starts $current ]
				foreach sel_start $select_starts {
					p.scan_loops $sel_start $parent
				}
			}
			"beginend" {
				if { [ p.is_end $text ] } {
					return ""
				}
			}
			"address" {
				return ""
			}
			default {
			}
		}
		set current $below
	}
	return ""
}

proc p.get_select_starts { vertex_id } {
	return [ gdb eval {
		select dst
		from links
		where src = :vertex_id
			and ordinal > 1 } ]
}

proc p.get_if_start { vertex_id } {
	set current $vertex_id
	while { 1 } {
		lassign [ p.get_info $current ] type text up left right down
		if { $right == "" } {
			if { $up != "" } { return "" }
			return $current
		} else {
			set current $right
		}
	}
}

proc p.check_loops { diagram_id } {
	gdb eval {
		select first_icon
		from branches
		where diagram_id = :diagram_id
	} {
		p.check_loop_entries $first_icon 0
	}
}

proc p.is_vertical_tjoint { vertex_id } {
	gdb eval {
		select up, left, right, down
		from vertices
		where vertex_id = :vertex_id
	} {
		if { $up == "" || $down == "" } { return 0 }
		if { $left == "" && $right == "" } { return 0 }
		return 1
	}
	error [ mc2 "Vertex \$vertex_id not found" ]
}

proc p.is_same_or_parent { vertex_id parent } {
	if { $parent == 0 } { return 1 }
	set current $vertex_id
	while { $current != 0 } {
		if { $current == $parent } { return 1 }	
		set current [ gdb onecolumn { select parent from vertices where vertex_id = :current } ]
	}
	return 0
}

proc p.parent { vertex_id } {
	return [ gdb onecolumn {
		select parent
		from vertices
		where vertex_id = :vertex_id } ]
}

proc p.check_loop_entries { vertex_id src_parent } {

	gdb eval {
		select dst, ordinal, direction
		from links
		where src = :vertex_id
			and direction != 'branch'
	} {
		set dst_parent [ p.parent $dst ]

		if { $direction == "arrow" || 
			($direction == "left" ) && [ p.is_vertical_tjoint $dst ] } {

			if { ![ p.is_same_or_parent $src_parent $dst_parent ] } {
				lassign [ gdb eval { select left, right from vertices where vertex_id = :dst } ] left right
				if { $direction == "left" || $direction == "arrow" } {
					p.unexpected_edge $right
				} elseif { $direction == "right" } {
					p.unexpected_edge $left
				}
				return
			}			
		} else {
			set type [ gdb onecolumn { select type from vertices where vertex_id = :vertex_id } ]
			if { $type == "loopstart" && $ordinal == 2 } {
				set parent $dst
			} elseif { ($type == "if" || $type == "select") && $ordinal > 1 } {
				set parent [ p.parent $vertex_id ]
			} else {
				set parent $src_parent
			}
			p.check_loop_entries $dst $parent
		}
	}
}

proc p.check_infinite { diagram_id } {
	if { [ is_machine $diagram_id ] } { return }
	set headers [ gdb eval {
		select vertex_id
		from vertices
		where diagram_id = :diagram_id and type = 'branch' } ]
	if { [ llength $headers ] == 1 } {
		return
	}
	gdb eval {
		update vertices
		set marked = 0
		where diagram_id = :diagram_id }
	array set map {}
	foreach header $headers {
		set exits [ p.find_exits $header ]
		set map($header) $exits
	}

	if { [ llength $headers ] > 1 } {
		set last [ p.find_last_branch map ]
		foreach header $headers {
			if { ![ p.can_reach $header $last map ] } {
				set item_id [ gdb onecolumn {
					select item_id from vertices where vertex_id = :header } ]
				p.error $diagram_id [ list $item_id ] [ mc2 "An infinite loop detected." ]
			}
		}
	}
	#p.print_map map
}

proc p.can_reach { from to map } {
	set visited {}
	upvar 1 $map graph
	return [ p.find_node $from $to graph $visited ]
}

proc p.find_last_branch { map } {
	upvar 1 $map graph
	foreach src [ array names graph ] {
		if { $graph($src) == "" } { return $src }
	}
	error [ mc2 "Last branch not found" ]
}

proc p.find_node { from to map visited } {
	upvar 1 $map graph
	if { $from == $to } { return 1 }
	if { [ contains $visited $from ] } { return 0 }
	lappend visited $from
	set next_nodes $graph($from)
	foreach next $next_nodes {
		if { [ p.find_node $next $to graph $visited ] } { return 1 }
	}
	return 0
}

proc p.print_vertex { vertex_id } {
	gdb eval {
		select text
		from vertices
		where vertex_id = :vertex_id
	} {
		return "$vertex_id:$text"
	}
}

proc p.print_map { map } {
	upvar 1 $map graph
	foreach src [ array names graph ] {
		puts [ p.print_vertex $src ]
		foreach dst $graph($src) {
			puts "   [ p.print_vertex $dst ]"
		}
	}
}

proc p.find_exits { vertex_id } {
	if { ![ p.check_and_mark $vertex_id ] } { return "" }
	set type [ gdb onecolumn { select type from vertices where vertex_id = :vertex_id } ]
	set result {}
	gdb eval {
		select dst, direction
		from links
		where src = :vertex_id
	} {
		if { $direction == "branch" } {
			lappend result $dst
		} else {
			set exit [ p.find_exits $dst ]
			if { $exit != "" } {
				set result [ concat $result $exit ]
			}
		}
	}
	return $result
}

proc p.get_items_for_dst { src ordinal } {
	set item_id [ gdb onecolumn {
		select item_id
		from vertices v inner join links l 
			on l.dst = v.vertex_id
		where l.src = :src and ordinal = :ordinal + 1 } ]
	return [ list $item_id ]
}

proc p.check_cases { diagram_id } {
	gdb eval {
		select vertex_id
		from vertices
		where diagram_id = :diagram_id
			and type = 'select'
	} {
		set cases [ gdb eval {
			select text 
			from links l inner join vertices v
				on l.dst = v.vertex_id
			where src = :vertex_id order by ordinal } ]
		set case_texts {}
		set last_case [ expr [ llength $cases ] - 1 ]
		for { set i 0 } { $i <= $last_case } { incr i } {
			set text [ lindex $cases $i ]
			set items [ p.get_items_for_dst $vertex_id $i ]			
			if { $i == 0 && $text == "" } {
				p.error $diagram_id $items [ mc2 "First case icon cannot be empty." ]
			} elseif { $i == 0 && [string compare -nocase $text "Else"] == 0 } {
				p.error $diagram_id $items [ mc2 "First case icon cannot be Else." ]
			} elseif { $i != $last_case && $text == "" } {
				p.error $diagram_id $items [ mc2 "The empty case icon should be the last one." ]
			} elseif { $i != $last_case && [string compare -nocase $text "Else"] == 0 } {
				p.error $diagram_id $items [ mc2 "The Else case icon should be the last one." ]
			}
			
			if { $text != "" } {
				if { [ contains $case_texts $text ] } {
					p.error $diagram_id $items [ mc2 "\$text is not a unique case branch." ]
				}
				lappend case_texts $text
			}
		}
	}
}

proc p.skip_joints { diagram_id } {
	gdb eval {
		update vertices
		set marked = 0
		where diagram_id = :diagram_id }
	set branches [ gdb eval { 
		select ordinal
		from branches
		where diagram_id = :diagram_id } ]
	
	if { [ llength $branches ] == 1 } {
		set first_branch [ lindex $branches 0 ]
		set start [ gdb onecolumn { select start_icon from branches 
			where ordinal = :first_branch and diagram_id = :diagram_id } ]
		p.skip_jointsv $start
	} else {
		foreach branch $branches {
			set header [ gdb onecolumn { select header_icon from branches 
				where ordinal = :branch  and diagram_id = :diagram_id } ]
			p.skip_jointsv $header
		}
	}
}

proc p.get_first_non_joint { vertex_id } {
	set current $vertex_id
	while { [ gdb onecolumn { select type from vertices where vertex_id = :current } ] == "" } {
		set current [ gdb onecolumn { select dst from links where src = :current } ]
	}
	return $current
}

proc p.skip_jointsv { vertex_id } {
	if { ![ p.check_and_mark $vertex_id ] } { return }
	set count [ gdb onecolumn { select count(*) from links where src = :vertex_id } ]
	repeat i $count {
		set ordinal [ expr { $i + 1 } ]
		set dst [ gdb onecolumn { select dst from links where src = :vertex_id and ordinal = :ordinal } ]
		set type [ gdb onecolumn { select type from vertices where vertex_id = :dst } ]
		if { $type == "" } {
			set icon [ p.get_first_non_joint $dst ]
			p.unlink_one $vertex_id $ordinal
			p.link $vertex_id $ordinal $icon "short"
			p.skip_jointsv $icon
			
		} else {
			p.skip_jointsv $dst
		}
	}
}

}

