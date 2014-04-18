namespace eval alt {

proc is_horizontal { direction } {
	if { $direction == "horizontal" || $direction == "parallel" } {
		return 1
	}
	return 0
}

proc move_along_direction { shadows direction delta } {

	
	# find the active pushers
	set good_shadows [ shadows_for_direction \
		$shadows $direction $delta ]
		
	set allied {}


	foreach shadow_id $good_shadows {
		find_allied $shadow_id $direction $delta allied
	}

	# move obstacles
	foreach shadow_id $allied {
		set myrect [ get_shadow_by_id $shadow_id ]
		set myleft [ lindex $myrect 0 ]
		set mytop [ lindex $myrect 1 ]
		set myright [ lindex $myrect 2 ]
		set mybottom [ lindex $myrect 3 ]


		set path [ sweep_rectangle $myleft $mytop $myright $mybottom \
			$delta $direction ]
		set left [ lindex $path 0 ]
		set top [ lindex $path 1 ]
		set right [ lindex $path 2 ]
		set bottom [ lindex $path 3 ]

		foreach obstacle [ get_aligned $direction ] {
			if { ![ is_marked $obstacle ] } {
				set orect [ get_shadow_by_id $obstacle ]
				set oleft [ lindex $orect 0 ]
				set otop [ lindex $orect 1 ]
				set oright [ lindex $orect 2 ]
				set obottom [ lindex $orect 3 ]				

						
				if {![ rectangles_intersect $myleft $mytop $myright $mybottom \
					$oleft $otop $oright $obottom ]} {
					if {[ rectangles_intersect $left $top $right $bottom \
						$oleft $otop $oright $obottom ]} {
						
						move_along_direction [ list $obstacle ] \
							$direction $delta					
					}            	
				}
			}
		}
	}
	
	# t-joints
	foreach shadow_id $allied {
		set myrect [ get_shadow_by_id $shadow_id ]
		set myleft [ lindex $myrect 0 ]
		set mytop [ lindex $myrect 1 ]
		set myright [ lindex $myrect 2 ]
		set mybottom [ lindex $myrect 3 ]

		foreach line [ get_orthos $direction ] {
			set orect [ get_shadow_by_id $line ]
			set oleft [ lindex $orect 0 ]
			set otop [ lindex $orect 1 ]
			set oright [ lindex $orect 2 ]
			set obottom [ lindex $orect 3 ]	

			set side [ touching_side $myleft $mytop $myright $mybottom \
				$oleft $otop $oright $obottom $direction ]
				
			if { $side == "less" } {
				move_end $line $delta $direction
			} elseif { $side == "greater" } {
				move_start $line $delta $direction
			}
		}
	}
	
	# move pushers
	foreach shadow_id $allied {
		move_shadow $shadow_id $delta $direction
	}
}


proc move_start { shadow_id delta direction } {
	# measure future size
	
	if { $delta > 0 } {
		set old_size [ get_dimension $shadow_id $direction ]
		set new_size [ expr { $old_size - $delta } ]
		set needed [ expr { 20 - $new_size } ]
		if { $needed > 0 } {
			set others {}
			# find on the other side
			set myrect [ get_shadow_by_id $shadow_id ]
			set myleft [ lindex $myrect 0 ]
			set mytop [ lindex $myrect 1 ]
			set myright [ lindex $myrect 2 ]
			set mybottom [ lindex $myrect 3 ]
				
				
			foreach other [ get_aligned $direction ] {
				if { ![ is_marked $other ] } {
					set orect [ get_shadow_by_id $other ]
					set oleft [ lindex $orect 0 ]
					set otop [ lindex $orect 1 ]
					set oright [ lindex $orect 2 ]
					set obottom [ lindex $orect 3 ]
						
					set side [ touching_side $oleft $otop $oright $obottom \
						$myleft $mytop $myright $mybottom $direction ]
					
					if { $side == "less" } {
						lappend others $other
					}
				}
			}
			
			#restore to min size
			if { [ llength $others ] == 0 } {
				move_big_side $shadow_id $delta $direction
			} else {
				foreach other $others {
					move_along_direction [ list $other ] \
						$direction $delta
				}
			}
		}
	}
	
	# move myself
	move_small_side $shadow_id $delta $direction
}


proc move_end { shadow_id delta direction } {
	# measure future size
	
	if { $delta < 0 } {
		set old_size [ get_dimension $shadow_id $direction ]
		set new_size [ expr { $old_size + $delta } ]
		set needed [ expr { $new_size - 20 } ]
		if { $needed < 0 } {
			set others {}
			# find on the other side
			set myrect [ get_shadow_by_id $shadow_id ]
			set myleft [ lindex $myrect 0 ]
			set mytop [ lindex $myrect 1 ]
			set myright [ lindex $myrect 2 ]
			set mybottom [ lindex $myrect 3 ]
				
			foreach other [ get_aligned $direction ] {
				if { ![ is_marked $other ] } {
					set orect [ get_shadow_by_id $other ]
					set oleft [ lindex $orect 0 ]
					set otop [ lindex $orect 1 ]
					set oright [ lindex $orect 2 ]
					set obottom [ lindex $orect 3 ]
						
					set side [ touching_side $oleft $otop $oright $obottom \
						$myleft $mytop $myright $mybottom $direction ]
					
					if { $side == "greater" } {
						lappend others $other
					}
				}
			}
			
			#restore to min size
			if { [ llength $others ] == 0 } {
				move_small_side $shadow_id $delta $direction
			} else {
				foreach other $others {
					move_along_direction [ list $other ] \
						$direction $delta
				}
			}
		}
	}
	
	# move myself
	move_big_side $shadow_id $delta $direction
}

proc start { hit_items mx my } {

	variable hit_shadows
	variable t_shadows

	variable aligned_x
	variable orthos_x
	variable aligned_y
	variable orthos_y
	
	set hit_shadows {}
	set aligned_x {}
	set aligned_y {}
	set orthos_x {}
	set orthos_y {}

	foreach item_id $hit_items {
		set item_shadows [ get_shadows $item_id ]
		set hit [ filter_hit $item_shadows $mx $my ]
		#item 1539
		set hit_shadows [ concat $hit_shadows $hit ]
	}
	
	foreach shadow_id [ array names t_shadows ] {
		set type [ get_shadow_type $shadow_id ]
		if { [ is_horizontal $type ] } {
			lappend aligned_y $shadow_id
			lappend orthos_x $shadow_id
		} elseif { $type == "vertical" } {
			lappend aligned_x $shadow_id
			lappend orthos_y $shadow_id
		} else {
			lappend aligned_x $shadow_id
			lappend aligned_y $shadow_id
		}
	}
}

proc get_aligned { direction } {
	variable aligned_x
	variable aligned_y
	if { [ is_horizontal $direction ] } {
		return $aligned_x
	} else {
		return $aligned_y
	}
}

proc get_orthos { direction } {
	variable orthos_x
	variable orthos_y
	
	if { [ is_horizontal $direction ] } {
		return $orthos_x
	} else {
		return $orthos_y
	}
}

}
