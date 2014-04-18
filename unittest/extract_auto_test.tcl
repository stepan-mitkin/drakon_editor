
proc print_errors { diagram_name diagram_id } {
	puts \n\n
	puts $diagram_name
	gdb eval { select * from errors } row {
		parray row
		puts ""
	}
	puts \n\n
}

proc check_auto_errors { diagram_name count } {
	set diagram_id [ ddd onecolumn { 
		select diagram_id from diagrams where name = :diagram_name } ]
	
	if { $diagram_id == "" } {
		error "Diagram $diagram_name not found"
	}
	graph::verify_one ddd $diagram_id
	if { 0 } {
		print_errors $diagram_name $diagram_id
		printlinks $diagram_id 
	}
	equal [ gdb onecolumn { select count(*) from errors } ] $count

	return $diagram_id
}

proc find_icon { diagram_id text } {
	gdb eval {
		select vertex_id
		from vertices v inner join items it 
			on it.item_id = v.item_id
		where it.text = :text
			and it.diagram_id = :diagram_id
	} {
		return $vertex_id
	}
	error "Icon with text $text not found on diagram $diagram_id"
}

proc check_icon_text { vertex_id text } {
	set actual [ gdb onecolumn {
		select it.text
		from vertices v inner join items it
			on v.item_id = it.item_id
		where vertex_id = :vertex_id } ]
		
	equal $actual $text
}

tproc extract_auto_test { } {
	sqlite3 ddd ../testdata/extract_auto.drn
	
	check_auto_errors bad_end 2
#	check_auto_errors bad_parameters 1
	check_auto_errors bad_parameters2 2
	check_auto_errors begin_end_middle 1
	check_auto_errors disconnected_icon 4
	check_auto_errors left_from_beginend 2
	check_auto_errors many_ends 1
	check_auto_errors no_ends 1
	check_auto_errors no_starts 1
	check_auto_errors right_from_end 2

	check_auto_errors branches_start_only 1
	check_auto_errors branches_no_text 1
	check_auto_errors branches_no_text_address 1
	check_auto_errors branches_non_unique 1
	check_auto_errors branches_dangling 1
	check_auto_errors branches_sil_one_branch 1

	check_auto_errors vertical_only 4
	check_auto_errors up_down_exist 3
	
	check_auto_errors many_starts_primitive 1

	check_auto_errors end_in_loop 1
	check_auto_errors unexpected_loopend 1
	check_auto_errors select_vertical_expected 1
	check_auto_errors cross_in_select 1
	check_auto_errors cross_in_select2 1


	check_auto_errors t1_in_select 2
	check_auto_errors t2_in_select 1
	check_auto_errors join_in_select 1
	check_auto_errors no_case 1
	check_auto_errors case_expected 1
	check_auto_errors if_in_case 1
	check_auto_errors icon_after_select 1
	check_auto_errors tjoint_after_select 2
	check_auto_errors tjoint_after_select_left 1
	check_auto_errors tjoint_before_case 1
	
	check_auto_errors bare_horizontal 1
	check_auto_errors arrow_expected 2
	
	check_auto_errors double_if 1
	check_auto_errors if_arrow_ends_badly 1
	check_auto_errors if_bad_vertical 1
	check_auto_errors if_bad_vertical2 1

	
	check_auto_errors if_icon_on_up 1
	
	check_auto_errors broken 1
	check_auto_errors broken2 1
	
	check_auto_errors loop_right 1
	
	check_auto_errors action_instead_of_start 1
	check_auto_errors action_instead_of_branch 1
	check_auto_errors empty_skewer 1
	
	check_auto_errors wrong_start 1
	check_auto_errors wrong_start2 1
	check_auto_errors no_arrow 1	
	
	check_auto_errors twins 1 
	
	check_auto_errors crossing 1
	check_auto_errors crossing2 1
	check_auto_errors crossing3 1
	
	check_auto_errors wrong_turn 2
	check_auto_errors wrong_turn2 1
	check_auto_errors two_arrows 1
	check_auto_errors icon_on_arrow 1
	check_auto_errors wrong_start3 1
	check_auto_errors icon_below_branch 1
	check_auto_errors joint_below_branch 2
	check_auto_errors arrow_from_right 2	

	check_auto_errors bad_horiz_joining 1
	check_auto_errors bad_horiz_joining2 1
	ddd close
}

proc loadcheck { name } {
	set diagram_id [ ddd onecolumn { select diagram_id from diagrams where name = :name } ]
	graph::verify_one ddd $diagram_id
	check_integrity $diagram_id
	return $diagram_id
}

proc deadend { vertex_id } {
	equal [ gdb onecolumn { select count(*) from links where src = :vertex_id } ] 0
}

proc flink { vertex_id ordinal } {
	upvar 1 $vertex_id v
	set dst [ gdb onecolumn { select dst from links where src = :v and ordinal = :ordinal } ]
	if { $dst == "" } {
		error "Link not found: src=$v, ordinal=$ordinal"
	}

	set v $dst
}

proc printlinks { diagram_id } {
	gdb eval {
		select src, ordinal, dst, direction
		from links
		order by src, ordinal
	} {
		set text [ gdb eval { select text, parent from vertices where vertex_id = :src } ]
		set text2 [ gdb eval { select text, parent from vertices where vertex_id = :dst } ]
		
		puts "$src:$text $ordinal-> $dst:$text2 $direction"
	}
}

tproc extract_auto_test2 { } {
	sqlite3 ddd ../testdata/extract_auto2.drn
	check_auto_errors exit_down 0
	check_auto_errors exit_up 0

	check_auto_errors entry_from_above 1
	check_auto_errors entry_from_above2 1
	check_auto_errors entry_from_above2_good 0
	check_auto_errors entry_from_below 1
	check_auto_errors entry_from_below2 1
	check_auto_errors entry_from_below2_good 0
	check_auto_errors from_sibling_above 1
	check_auto_errors from_sibling_below 1

	set diagram_id [ check_auto_errors if_from_above_good 0 ]
	set if1 [ find_icon $diagram_id if1 ]
	
	set v $if1
	flink v 1	
	check_icon_text $v End

	set v $if1
	flink v 2
	check_icon_text $v if2

	flink v 1
	check_icon_text $v loopstart
	set loop $v
	
	flink v 2
	check_icon_text $v ""
	deadend $v
	
	set v $loop
	flink v 1
	check_icon_text $v End
	
	check_auto_errors if_from_above 1
	check_auto_errors if_from_below 1
	check_auto_errors two_starts 1
	check_auto_errors two_problems 2

	ddd close
}


tproc branch_trouble { } {
	sqlite3 ddd ../testdata/branch_trouble.drn
	check_auto_errors unreachable 1
	check_auto_errors infinite_loop 2

	check_auto_errors only_empty 1
	check_auto_errors empty_in_wrong_place 1
	check_auto_errors repeating_case 1
	ddd close
}

proc check_example { filename } {
	sqlite3 ddd $filename
	graph::verify_all ddd
	equal [ gdb onecolumn { select count(*) from errors } ] 0
	ddd close	
}

proc name_to_v { name } {
	set vertex_id [ gdb onecolumn {
		select vertex_id
		from vertices
		where text = :name } ]
	if { $vertex_id == "" } {
		error "Icon '$name' not founnd."
	}
	return $vertex_id
}

proc has_name { vertex_id name } {
	set actual_name [ gdb onecolumn {
		select text
		from vertices
		where vertex_id = :vertex_id } ]
	if { $actual_name != $name } {
		error "No icon with text '$name' and vertex_id $vertex_id"
	}
}

proc onelink { src dst } {
	#puts "$src $dst"
	set vertex_id [ name_to_v $src ]
	set actual_dst [ gdb eval {
		select dst
		from links
		where src = :vertex_id } ]
	equal [ llength $actual_dst ] 1
	has_name [ lindex $actual_dst 0 ] $dst
}

proc checklink { src ordinal dst } {
	#puts "$src $ordinal $dst"
	set vertex_id [ name_to_v $src ]
	set actual_dst [ gdb onecolumn {
		select dst
		from links
		where src = :vertex_id and ordinal = :ordinal } ]
	if { $actual_dst == "" } {
		error "Link $src, $ordinal not found"
	}
	has_name [ lindex $actual_dst 0 ] $dst
}

proc branch_start { name } {
	set addresses [ gdb eval {
		select vertex_id
		from vertices
		where text = :name
			and type = 'address' } ]
	if { [ llength $addresses ] == 0 } {
		error "Addresses '$name' not found."
	}
	set dst ""
	foreach address $addresses {
		set dsts [ gdb eval {
			select dst
			from links
			where src = :address 
				and direction = 'branch' } ]
		equal [ llength $dsts ] 1
		set dst [ lindex $dsts 0 ]
		set actual_name [ gdb onecolumn {
			select text
			from vertices
			where vertex_id = :dst } ]
		equal $actual_name $name
	}
	if { $dst == "" } {
		error "Bad branch link for $name."
	}
	return $dst
}

tproc auto_test { } {
	sqlite3 ddd ../testdata/skip.drn
	check_auto_errors primitive1 0
	
	onelink primitive1 loopstart
	checklink loopstart 1 select
	checklink loopstart 2 if
	checklink if 1 if2
	checklink if 2 loopstart
	checklink if2 1 ""
	checklink if2 2 action2
	onelink action2 End
	checklink select 1 case
	checklink select 2 case2
	checklink select 3 case3
	onelink case action
	onelink case2 End
	onelink case3 action2


	check_auto_errors silouette1 0

	onelink branch1 loopstart
	checklink loopstart 1 select
	checklink loopstart 2 if1
	checklink if1 1 ""
	checklink if1 2 loopstart

	checklink select 1 case
	checklink select 2 case4
	checklink select 3 case2
	checklink select 4 case3

	onelink case action
	onelink action branch2
	onelink case4 branch2
	onelink case2 loopstart
	onelink case3 action2
	onelink action2 loopstart

	set v [ branch_start branch2 ]
	flink v 1
	check_icon_text $v loopstart5
	
	checklink loopstart5 1 End
	checklink loopstart5 2 if3
	checklink if3 1 select2
	checklink if3 2 action5
	checklink select2 1 case5
	checklink select2 2 case6
	checklink select2 3 case7
	checklink select2 4 case8
	
	onelink case5 action3
	onelink action3 ""
	onelink case6 End
	onelink case7 End
	onelink case8 action4
	onelink action4 End
	onelink action5 End

	check_auto_errors complex_logic 0

	onelink complex_logic A
	checklink A 1 B
	checklink A 2 D

	checklink B 1 C
	checklink B 2 D
	
	checklink C 1 Say_YES
	checklink C 2 D

	checklink D 1 E
	checklink D 2 Say_NO

	checklink E 1 F
	checklink E 2 Say_NO

	checklink F 1 Say_YES
	checklink F 2 Say_NO

	onelink Say_YES End
	onelink Say_NO End

	ddd close

	check_example ../examples/01.Insertion.drn
	check_example ../examples/02.Silhouette.drn
	check_example "../examples/03.The skewer.drn"
	check_example ../examples/04.Joinings.drn
	check_example ../examples/05.Loops.drn
	check_example ../examples/06.Logic.drn
}

