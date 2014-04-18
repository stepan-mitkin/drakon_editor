
tproc flag_on_test {} {
	equal [ flag_on 0 0 ] 0 zero-zero
	equal [ flag_on 0 1 ] 0 zero-one
	equal [ flag_on 0 2 ] 0 zero-two
	equal [ flag_on 1 1 ] 1 one-one
	equal [ flag_on 2 2 ] 1 two-two
	equal [ flag_on 5 1 ] 1 five-one
	equal [ flag_on 513 512 ] 1 513-512
	equal [ flag_on 513 1 ] 1 513-1
	equal [ flag_on 513 64 ] 0 513-64
}

proc repeat_return { } {
	repeat i 5 {
		if { $i > 3 } { return $i }
	}
}

tproc repeat_test { } {
	set result {}
	repeat i 0 {
		lappend result $i
	}
	list_equal $result { }
	
	
	set result {}
	repeat i 1 {
		lappend result $i
	}
	list_equal $result { 0 }

	set result {}
	repeat i 5 {
		lappend result $i
	}
	list_equal $result { 0 1 2 3 4 }
	
	set result {}
	repeat i 5 {
		if { $i < 2 } { continue }
		lappend result $i
	}
	list_equal $result { 2 3 4 }

	set result {}
	repeat i 5 {
		if { $i > 2 } { break }
		lappend result $i
	}
	list_equal $result { 0 1 2 }
	
	equal [ repeat_return ] 4
}

tproc zip_test { } {
	list_equal [ zip {} {} ] {}
	list_equal [ zip {a} {b} ] {a b}
	list_equal [ zip { a b c } { 1 2 3 } ] { a 1 b 2 c 3 }
	list_equal [ zip { a b c } { 1 2 3 4 } ] { a 1 b 2 c 3 "" 4 }
	list_equal [ zip { a b c d } { 1 2 3 } ] { a 1 b 2 c 3 d ""}
}

tproc wrap_test { } {
	set a [ wrap a b c ]
	set b [ wrap f ]
	
	equal [ llength $a ] 1
	equal [ llength $b ] 1
	list_equal [ lindex $a 0 ] { a b c }
	list_equal [ lindex $b 0 ] { f }
}

proc test.cool_add { left right } {
	return [ expr { $left + $right } ]
}

proc test.add_to_dict { key value } {
	upvar 3 dict1 dict
	set dict($key) $value
}

proc test.add_to_dict2 { key value } {
	upvar 3 dict1 dict
	set dict($key) "$value-2"
}

tproc invoke_test { } {
	set delegate [ list test.cool_add { 10 } ]
	equal [ invoke $delegate 20 ] 30
}

tproc invoke_all_test { } {
	set delegates {
		{ test.add_to_dict 8 }
		{ test.add_to_dict2 9 }
	}
	array set dict1 {}
	invoke_all $delegates 77
	equal $dict1(8) 77
	equal $dict1(9) 77-2
}

tproc vec2.addxy.test { } {
	set v1 { 10 20 }
	list_equal [ vec2.addxy $v1 2 3 ] { 12 23 }
}

tproc swap_test { } {
	set one "one one one"
	set two "two two two"
	swap one two
	equal $one "two two two"
	equal $two "one one one"
}


tproc rectangles_intersect_test { } {
	equal [ rectangles_intersect 0 10 100 50	200 10 300 50 ] 0
	equal [ rectangles_intersect 200 10 300 50	0 10 100 50 ] 0
	
	equal [ rectangles_intersect 0 10 100 50	200 100 300 500 ] 0
	equal [ rectangles_intersect 200 100 300 500	0 10 100 50 ] 0

	equal [ rectangles_intersect 0 10 150 50	100 10 300 50 ] 1
	equal [ rectangles_intersect 100 10 300 50	0 10 150 50 ] 1
	
	equal [ rectangles_intersect 0 10 300 50	20 10 150 50 ] 1
	
	equal [ rectangles_intersect 0 10 100 50	0 200 100 300 ] 0
	equal [ rectangles_intersect 0 200 100 300 0 10 100 50 ] 0

	equal [ rectangles_intersect 0 10 100 50	0 50 100 200 ] 1
	equal [ rectangles_intersect 0 50 100 200 0 10 100 50 ] 1
	
	equal [ rectangles_intersect 0 10 100 100	 0 50 100 90 ] 1
	
	equal [ rectangles_intersect 0 10 100 100	 50 50 60 60 ] 1
	equal [ rectangles_intersect 50 50 60 60	 0 10 100 100 ] 1
}

tproc rectangles_on_axis_test { } {
	# not intersecting
	equal [ rectangles_on_axis 0 10 100 50	200 10 300 50 horizontal ] 0
	equal [ rectangles_on_axis 200 10 300 50	0 10 100 50 horizontal ] 0
	
	equal [ rectangles_on_axis 0 10 100 50	200 100 300 500 horizontal ] 0
	equal [ rectangles_on_axis 200 100 300 500	0 10 100 50 vertical ] 0

	equal [ rectangles_on_axis 0 10 100 50	0 200 100 300 vertical ] 0
	equal [ rectangles_on_axis 0 200 100 300 0 10 100 50 vertical ] 0
	
	# off-center
	equal [ rectangles_on_axis 0 10 100 50	0 10 100 60 horizontal ] 0
	equal [ rectangles_on_axis 0 10 100 50	0 10 110 50 vertical ] 0


	# on-center, intersecting
	equal [ rectangles_on_axis 0 10 100 50	50 20 150 40 horizontal ] 1
	equal [ rectangles_on_axis 0 10 100 50	10 20 90 60 vertical ] 1

	# on-center, touching
	equal [ rectangles_on_axis 0 10 100 50	100 20 200 40 horizontal ] 1
	equal [ rectangles_on_axis 0 10 100 50	10 50 90 100 vertical ] 1
	
}

tproc touching_side_test { } {
	# not intersecting
	equal [ touching_side 0 10 100 50	200 10 300 50 vertical ] none
	equal [ touching_side 200 10 300 50	0 10 100 50 vertical ] none
	
	equal [ touching_side 0 10 100 50	200 100 300 500 vertical ] none
	equal [ touching_side 200 100 300 500	0 10 100 50 horizontal ] none

	equal [ touching_side 0 10 100 50	0 200 100 300 horizontal ] none
	equal [ touching_side 0 200 100 300 0 10 100 50 horizontal ] none
	
	# intersecting, not sticking out parts
	equal [ touching_side 0 10 100 50	0 10 100 50 vertical ] none
	equal [ touching_side 0 10 100 50	0 10 100 50 horizontal ] none
	
	equal [ touching_side 0 10 100 50	0 20 100 40 vertical ] none
	equal [ touching_side 0 10 100 50	10 10 90 50 horizontal ] none

	# intersecting, touching
	equal [ touching_side 0 10 100 50	100 10 200 50 horizontal ] greater
	equal [ touching_side 0 10 100 50	-100 10 0 50 horizontal ] less
	
	equal [ touching_side 0 10 100 50	0 50 100 100 vertical ] greater
	equal [ touching_side 0 10 100 50	0 -10 100 10 vertical ] less
	
	# intersecting
	equal [ touching_side 0 10 100 50	70 10 200 50 horizontal ] greater
	equal [ touching_side 0 10 100 50	-100 10 10 50 horizontal ] less
	
	equal [ touching_side 0 10 100 50	0 40 100 100 vertical ] greater
	equal [ touching_side 0 10 100 50	0 -10 100 20 vertical ] less

	# subset
	equal [ touching_side 0 10 100 50	0 10 200 50 horizontal ] greater
	equal [ touching_side 0 10 100 50	-100 10 100 50 horizontal ] less
	
	equal [ touching_side 0 10 100 50	0 10 100 100 vertical ] greater
	equal [ touching_side 0 10 100 50	0 -10 100 50 vertical ] less
	
}

tproc push_rect_test { } {
	equal [ push_rect 0 10 100 50	70 10 200 50 horizontal 100 ] 40
	equal [ push_rect 0 10 100 50	170 10 200 50 horizontal 100 ] 0
	
	equal [ push_rect 70 10 200 50  0 10 100 50	 horizontal -100 ] -40
	equal [ push_rect 170 10 200 50  0 10 100 50 horizontal -100 ] 0


	equal [ push_rect 0 10 100 50	0 30 100 100 vertical 100 ] 30
	equal [ push_rect 0 10 100 50	0 80 100 150 vertical 100 ] 0

	equal [ push_rect 0 30 100 100  0 10 100 50	 vertical -100 ] -30
	equal [ push_rect 0 30 100 100  0 10 100 20	 vertical -100 ] 0
	
	equal [ push_rect 250 150 260 190  260 80 260 370 horizontal 10 ] 10
}


tproc add_border_test { } {
	list_equal [ add_border { 10 20 100 50 } 10 ] { 0 10 110 60 }
}

tproc hit_rectangle_test { } {
	equal [ hit_rectangle { 20 10 60 30 } 0 0 ] 0
	equal [ hit_rectangle { 20 10 60 30 } 80 20 ] 0
	equal [ hit_rectangle { 20 10 60 30 } 40 40 ] 0
	equal [ hit_rectangle { 20 10 60 30 } 400 400 ] 0
	
	equal [ hit_rectangle { 20 10 60 30 } 40 20 ] 1
	equal [ hit_rectangle { 20 10 60 30 } 50 20 ] 1
	equal [ hit_rectangle { 20 10 60 30 } 20 10 ] 1
	equal [ hit_rectangle { 20 10 60 30 } 60 30 ] 1
	
	equal [ hit_rectangle { 20 10 60 30 } 80 50 ] 0
	equal [ hit_rectangle { 20 10 60 30 } 50 20 ] 1
	equal [ hit_rectangle { 50 70 120 90 } 60 80 ] 1
}

tproc move_rectangle_test { } {
	set rect { 20 10 100 60 }
	list_equal [ move_rectangle $rect 6 7 ] { 26 17 106 67 }
	list_equal [ move_rectangle $rect -6 -7 ] { 14 3 94 53 }
}

tproc make_rect_test { } {
	list_equal [ make_rect 50 20 30 10 ] { 20 10 80 30 }
}

tproc snap_test { } {
	equal [ snap 0 10 ] 0
	equal [ snap 5 10 ] 0
	equal [ snap 9 10 ] 0
	equal [ snap 10 10 ] 10
	equal [ snap 12 10 ] 10
	equal [ snap 18 10 ] 10
	equal [ snap 20 10 ] 20
	equal [ snap 22 10 ] 20
	
	equal [ snap -5 10 ] -10
	equal [ snap -9 10 ] -10
	equal [ snap -10 10 ] -10
	equal [ snap -12 10 ] -20
	equal [ snap -18 10 ] -20
	equal [ snap -20 10 ] -20
	equal [ snap -22 10 ] -30
	
	equal [ snap_up 0 ] 10
	equal [ snap_up 3 ] 10
	equal [ snap_up 8 ] 10
	equal [ snap_up 10 ] 10
	equal [ snap_up 12 ] 20
	equal [ snap_up 20 ] 20
	equal [ snap_up 22 ] 30
}

tproc intervals_touch_test { } {
	list_equal [ intervals_touch 10 20 30 40 ] {0 0 0}
	list_equal [ intervals_touch 30 40 10 20 ] {0 0 0}	
	
	list_equal [ intervals_touch 10 20 20 40 ] {1 10 40}
	list_equal [ intervals_touch 20 40 10 20 ] {1 10 40}
	
	list_equal [ intervals_touch 10 30 20 40 ] {1 10 40}	
	list_equal [ intervals_touch 20 40 10 30 ] {1 10 40}	
	
	list_equal [ intervals_touch 10 40 20 30 ] {1 10 40}	
	list_equal [ intervals_touch 20 30 10 40 ] {1 10 40}	
	
	list_equal [ intervals_touch 10 40 10 40 ] {1 10 40}	
}

tproc intervals_intersect_test { } {
	# do not touch
	equal [ intervals_intersect 10 20 30 40 ] 0
	equal [ intervals_intersect 30 40 10 20 ] 0
	
	# touch, no intersection
	equal [ intervals_intersect 10 20 20 40 ] 0
	equal [ intervals_intersect 20 40 10 20 ] 0
	
	# intersect in the middle
	equal [ intervals_intersect 10 30 20 40 ] 1
	equal [ intervals_intersect 20 40 10 30 ] 1	
	
	#starts with
	equal [ intervals_intersect 10 30 10 40 ] 1
	equal [ intervals_intersect 10 40 10 30 ] 1
	
	#ends with
	equal [ intervals_intersect 10 40 20 40 ] 1
	equal [ intervals_intersect 20 40 10 40 ] 1
	
	# inside
	equal [ intervals_intersect 10 40 20 30 ] 1
	equal [ intervals_intersect 20 30 10 40 ] 1	
}

proc mult_by_3 { value } {
	return [ expr { $value * 3 } ]
}

tproc map_test { } {
	list_equal [ map -list { 1 2 3 } -fun mult_by_3 ] { 3 6 9 }
}

proc greater_10 { number } {
	return [ expr { $number > 10 } ]
}

tproc filter_test { } {
	list_equal [ filter -list { 2 4 6 8 10 12 14 8 16 } -fun greater_10 ] { 12 14 16 }
}

tproc lfilter_test { } {
	list_equal [ lfilter {} greater_10 ] {}
	list_equal [ lfilter {100 200} greater_10 ] {100 200}
	list_equal [ lfilter {1 2} greater_10 ] {}
	list_equal [ lfilter {1 2 10 20 25} greater_10 ] { 20 25 }
}

tproc lfilter_user_test { } {
	list_equal [ lfilter_user {} greater_than 5] {}
	list_equal [ lfilter_user {100 200} greater_than 5 ] {100 200}
	list_equal [ lfilter_user {1 2} greater_than 5 ] {}
	list_equal [ lfilter_user {1 2 10 20 25} greater_than 5 ] { 10 20 25 }
}


proc greater_than { left right } {
	return [ expr { $left > $right } ]
}

tproc snap_delta_test { } {
	equal [ snap_delta 0  ] 0
	equal [ snap_delta 5  ] 0
	equal [ snap_delta 9  ] 0
	equal [ snap_delta 10  ] 10
	equal [ snap_delta 12  ] 10
	equal [ snap_delta 18  ] 10
	equal [ snap_delta 20  ] 20
	equal [ snap_delta 22  ] 20
	
	equal [ snap_delta -5  ] 0
	equal [ snap_delta -9  ] 0
	equal [ snap_delta -10  ] -10
	equal [ snap_delta -12  ] -10
	equal [ snap_delta -18  ] -10
	equal [ snap_delta -20  ] -20
	equal [ snap_delta -22  ] -20

}

tproc sql_escape_test { } {
	equal [ sql_escape "cool'foo" ] "cool''foo"
	equal [ sql_escape "cool''foo" ] "cool''''foo"
	
#	equal [ sql_unescape [ sql_escape "cool'foo" ] ] "cool'foo"
}

proc print_esc { text } {
  foreach char [ split $text "" ] {
    set code [ scan $char %c ]
    puts -nonewline [ format "\\u%04x" $code ]
  }
  puts ""
}

proc p.print_some_u { } {
  set fp [ open "in.txt" rb ]
  fconfigure $fp -encoding utf-8
  set text [ read $fp ]
  close $fp
  print_esc $text
}

tproc char_set_test { } {

  set texts { "one" "two" "three" "\u042D\u0442\u043E-\u042D\u0442\u043E" }
  
  set chars [ make_char_set $texts ]
  list_equal $chars { 45 101 104 110 111 114 116 119 1069 1086 1090 }
}

tproc unpack_test { } {
	set list1 { 20 30 40 50 }
	unpack $list1 x y w z
	equal $x 20
	equal $y 30
	equal $w 40
	equal $z 50
}


tproc line_hit_box_test { } {
	equal [ line_hit_box {10 20 50 40} {0 0} {100 0} ] 0
	equal [ line_hit_box {10 20 50 40} {0 100} {100 100} ] 0
	equal [ line_hit_box {10 20 50 40} {0 0} {0 100} ] 0
	equal [ line_hit_box {10 20 50 40} {100 0} {100 100} ] 0
	
	equal [ line_hit_box {10 20 50 40} {0 30} {100 30} ] 1
	equal [ line_hit_box {10 20 50 40} {30 0} {30 100} ] 1
	
	equal [ line_hit_box {10 20 50 40} {0 30} {10 30} ] 1
	equal [ line_hit_box {10 20 50 40} {50 30} {100 30} ] 1
	equal [ line_hit_box {10 20 50 40} {30 0} {30 20} ] 1
	equal [ line_hit_box {10 20 50 40} {30 40} {30 200} ] 1
	
	equal [ line_hit_box {10 20 50 40} {10 0} {10 20} ] 1
	equal [ line_hit_box {10 20 50 40} {0 20} {10 20} ] 1
	
	equal [ line_hit_box {10 20 50 40} {50 0} {50 20} ] 1
	equal [ line_hit_box {10 20 50 40} {50 20} {500 20} ] 1
	
	equal [ line_hit_box {10 20 50 40} {50 40} {60 40} ] 1
	equal [ line_hit_box {10 20 50 40} {50 40} {50 50} ] 1	
	
	equal [ line_hit_box {10 20 50 40} {0 40} {10 40} ] 1
	equal [ line_hit_box {10 20 50 40} {10 40} {10 50} ] 1
	
	equal [ line_hit_box {10 20 50 40} {10 30} {50 30} ] 1
	equal [ line_hit_box {10 20 50 40} {40 20} {40 40} ] 1
}


tproc box_cut_line_vertical_test { } {
	list_equal [ box_cut_line_vertical {10 20 50 40} {30 0} {30 50} ] {{2 {30 0} {30 20}}  {1 {30 40} {30 50}}}
	list_equal [ box_cut_line_vertical {10 20 50 40} {30 0} {30 20} ] {{2 {30 0} {30 20}}}
	list_equal [ box_cut_line_vertical {10 20 50 40} {30 40} {30 50} ] {{1 {30 40} {30 50}}}
	list_equal [ box_cut_line_vertical {10 20 50 40} {30 20} {30 50} ] {{1 {30 40} {30 50}}}
	list_equal [ box_cut_line_vertical {10 20 50 40} {30 0} {30 40} ] {{2 {30 0} {30 20}}}	
	equal [ box_cut_line_vertical {10 20 50 40} {30 20} {30 40} ] ""
}

tproc box_cut_line_horizontal_test { } {
	list_equal [ box_cut_line_horizontal {10 20 50 40} {0 30} {60 30} ] {{2 {0 30} {10 30}} {1 {50 30} {60 30}}}
	list_equal [ box_cut_line_horizontal {10 20 50 40} {0 30} {10 30} ] {{2 {0 30} {10 30}}}
	list_equal [ box_cut_line_horizontal {10 20 50 40} {0 30} {50 30} ] {{2 {0 30} {10 30}}}
	list_equal [ box_cut_line_horizontal {10 20 50 40} {50 30} {60 30} ] {{1 {50 30} {60 30}}}
	list_equal [ box_cut_line_horizontal {10 20 50 40} {10 30} {60 30} ] {{1 {50 30} {60 30}}}
	equal [ box_cut_line_horizontal {10 20 50 40} {10 30} {50 30} ] ""
}

tproc intersect_lines_updown_test { } {
	# to the left
	list_equal [ intersect_lines_updown {20 50} {70 50} {10 10} {10 90} ] {none bad bad}
	
	# to the right
	list_equal [ intersect_lines_updown {20 50} {70 50} {100 10} {100 90} ] {none bad bad}
	
	# higher
	list_equal [ intersect_lines_updown {20 50} {70 50} {40 -50} {40 10} ] {none bad bad}
	
	# lower
	list_equal [ intersect_lines_updown {20 50} {70 50} {40 60} {40 100} ] {none bad bad}
	
	# crossing
	list_equal [ intersect_lines_updown {20 50} {70 50} {40 0} {40 100} ] {crossing_ud 40 50}
	
	# up
	list_equal [ intersect_lines_updown {20 50} {70 50} {40 0} {40 50} ] {up 40 50}
	
	# down
	list_equal [ intersect_lines_updown {20 50} {70 50} {40 50} {40 100} ] {down 40 50}
}

tproc intersect_lines_leftright_test { } {
	# to the left
	list_equal [ intersect_lines_leftright {50 20} {50 70} {10 40} {40 40} ] {none bad bad}
	
	# to the right
	list_equal [ intersect_lines_leftright {50 20} {50 70} {60 40} {100 40} ] {none bad bad}
	
	# higher
	list_equal [ intersect_lines_leftright {50 20} {50 70} {0 10} {100 10} ] {none bad bad}
	
	# lower
	list_equal [ intersect_lines_leftright {50 20} {50 70} {0 80} {100 80} ] {none bad bad}
	
	# crossing
	list_equal [ intersect_lines_leftright {50 20} {50 70} {10 40} {100 40} ] {crossing_lr 50 40}
	
	# left
	list_equal [ intersect_lines_leftright {50 20} {50 70} {10 40} {50 40} ] {left 50 40}
	
	# right
	list_equal [ intersect_lines_leftright {50 20} {50 70} {50 40} {100 40} ] {right 50 40}
}


tproc contains_test { } {
	equal [ contains { 10 20 30 40 } 10 ] 1
	equal [ contains { 10 20 30 40 } 50 ] 0
	equal [ contains { "one" "two" "three" } "two" ] 1
	equal [ contains { "one" "two" "three" } "four" ] 0
	equal [ contains {} "four" ] 0
}

tproc remove_test { } {
	equal [ remove {} 20 ] {}
	equal [ remove {10 20 30} 20 ] {10 30}
	equal [ remove {10 20 30} 30 ] {10 20}
	equal [ remove {10 20 30} 40 ] {10 20 30}
}

tproc init_cap_test { } {
	equal [ init_cap privet ] Privet
	equal [ init_cap Privet ] Privet
	equal [ init_cap "" ] ""
	equal [ init_cap PRIVET ] Privet
	equal [ init_cap pRiVeT ] Privet
}

tproc replace_extension_test { } {
	equal [ replace_extension "/foo/bar/moo.drn" "cpp" ] "/foo/bar/moo.cpp"
	equal [ replace_extension "/foo/bar/moo" "cpp" ] "/foo/bar/moo.cpp"	
}

tproc generate_structure_test { } {
	generate_structure person333 { name surname year }
	set obj [ create_person333 ivan petrov 1982 ]
	equal [ get_person333_name $obj ] ivan
	equal [ get_person333_surname $obj ] petrov
	equal [ get_person333_year $obj ] 1982
	set obj2 [ set_person333_name $obj peter ]
	equal [ get_person333_name $obj2 ] peter
	set obj3 [ set_person333_year $obj2 1980 ]
	equal [ get_person333_year $obj3 ] 1980
}

tproc put_value_test { } {
	set map {}
	put_value map 10 ten
	put_value map 20 twenty
	put_value map 30 thirty
	
	equal [ get_value $map 10 ] ten
	equal [ get_value $map 20 ] twenty
	equal [ get_value $map 30 ] thirty
	equal [ find_key $map 40 ] -1
	
	put_value map 20 TWENTY2
	equal [ get_value $map 20 ] TWENTY2
	list_equal $map {10 ten 20 TWENTY2 30 thirty}
	
}

tproc have_intersection_test { } {
	equal [ have_intersection {} {} ] 0
	equal [ have_intersection {1} {1} ] 1
	equal [ have_intersection {1} {0} ] 0
	equal [ have_intersection {1 2} {1 2} ] 1
	equal [ have_intersection {1 3} {1 2} ] 1
	equal [ have_intersection {3 1 4} {1 2 5} ] 1
}

tproc is_variable_test { } {
	equal [ is_variable {} ] 1
	equal [ is_variable { } ] 1
	equal [ is_variable " foo208_ " ] 1
	equal [ is_variable "x2" ] 1
	equal [ is_variable {$x2} ] 1
	equal [ is_variable "foo\(bar\)" ] 0
	equal [ is_variable "m-n" ] 0
	equal [ is_variable "m n" ] 0
}

tproc add_range_test { } {

	set left {}
	set right {}
	add_range left $right
	equal $left {}
	
	set left {}
	set right {a b}
	add_range left $right
	equal $left {a b}
	
	set left {1 2}
	set right {a b}
	add_range left $right
	equal $left {1 2 a b}
}

tproc append_not_empty_test { } {
	
	set list {}
	append_not_empty list {}
	equal $list {}
	
	append_not_empty list {a}
	equal $list {a}
	
	set list {a b c}
	append_not_empty list {}
	equal $list {a b c}
	
	set list {a b c}
	append_not_empty list {d e}
	equal $list {a b c {d e}}
}

tproc subtract_test { } {
	equal [ subtract {} {} ] {}
	equal [ subtract a {} ] a
	equal [ subtract {a b} {} ] {a b}
	equal [ subtract {} {a b} ] {}
	equal [ subtract {a b} {d c} ] {a b}
	equal [ subtract {a b} {b c} ] a
	equal [ subtract {a b c d} {a d} ] {b c}
	equal [ subtract {a b c d} {a b c d} ] {}
}

tproc dict_get_safe_test { } {
	set ar1 {}
	set ar2 {a 10 b 20}
	
	equal [ dict_get_safe $ar1 foo moo ] moo
	equal [ dict_get_safe $ar2 foo moo ] moo
	equal [ dict_get_safe $ar2 b moo ] 20
}

namespace eval megatest {

proc test_art { } {
	art::create megatest person name
	set_person_name 10 "jon"
	set_person_name 20 "henrik"
	equal [ lsort -integer [ person_name_keys ] ] {10 20}
	equal [get_person_name 10] "jon"
	equal [get_person_name 20] "henrik"
	remove_person_name 10
	equal [ person_name_keys ] 20
	equal [get_person_name 10] ""
	equal [get_person_name 20] "henrik"

	art::create_table megatest diagram {name description}

	equal [ diagram_name_keys ] {}
	set id1 [ diagram_next_id ]
	insert_diagram $id1 "jiafei" "vud boss"
	set id2 [ diagram_next_id ]
	insert_diagram $id2 "alan" ""
	equal $id1 1
	equal $id2 2
	equal [ fetch_diagram $id1 ] {id 1 name jiafei description {vud boss}}
	equal [ fetch_diagram $id2 ] {id 2 name alan description {}} 

	print_diagram
}

}

tproc art_test { } {
	megatest::test_art
	megatest::test_art
}

