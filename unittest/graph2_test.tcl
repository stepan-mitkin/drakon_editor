tproc merge.simple_test { } {

	# coincide
	equal [ graph2::merge.simple {300 80 100 200 0} {400 80 100 200 0} ] {300 80 100 200 0}
	
	# next is longer
	equal [ graph2::merge.simple {300 80 100 200 0} {400 80 150 300 0} ] {300 80 100 300 0}
	
	# current is longer
	equal [ graph2::merge.simple {300 80 100 300 0} {400 80 150 200 0} ] {300 80 100 300 0}
	
	equal [ graph2::success.status ] 1
}

tproc line.arrow_test { } {

	graph2::stor.clear

	
	# down
	equal [ graph2::line.arrow {300 80 100 300 0} {301 80 150 200 30100} ] {{301 80 100 200 30100} {300 80 200 300 0}}
	equal [ graph2::line.arrow {300 80 100 300 0} {301 80 150 400 30100} ] {{} {301 80 100 400 30100}}
	
	# up
	equal [ graph2::line.arrow {300 80 100 300 0} {301 80 200 400 10100} ] {{300 80 100 200 0} {301 80 200 400 10100}}
	equal [ graph2::line.arrow {300 80 100 300 0} {301 80 200 250 10100} ] {{300 80 100 200 0} {301 80 200 300 10100}}
	
	equal [ graph2::line.arrow {300 80 100 300 0} {301 80 100 400 10100} ] {{} {301 80 100 400 10100}}
	equal [ graph2::line.arrow {300 80 100 300 0} {301 80 100 250 10100} ] {{} {301 80 100 300 10100}}
	
	equal [ graph2::success.status ] 1
}

tproc arrow.line_test { } {

	graph2::stor.clear
	
	# down
	equal [ graph2::arrow.line {301 80 100 400 30100} {300 80 100 300 0} ] {{} {301 80 100 400 30100}}
	equal [ graph2::arrow.line {301 80 100 300 30100} {300 80 200 400 0} ] {{301 80 100 300 30100} {300 80 300 400 0}}
	
	# up
	equal [ graph2::arrow.line {301 80 100 400 10100} {300 80 200 300 0} ] {{} {301 80 100 400 10100}}
	equal [ graph2::arrow.line {301 80 100 300 10100} {300 80 200 400 0} ] {{} {301 80 100 400 10100}}	
	
	equal [ graph2::success.status ] 1
}

tproc merge.segments_test { } {
	graph2::stor.clear

	# no intersection
	equal [ graph2::merge.segments {300 80 100 200 0} {400 80 300 400 0} ] {{300 80 100 200 0} {400 80 300 400 0}}

	# coincide
	equal [ graph2::merge.segments {300 80 100 200 0} {400 80 100 200 0} ] {{} {300 80 100 200 0}}
	
	# next is longer
	equal [ graph2::merge.segments {300 80 100 200 0} {400 80 150 300 0} ] {{} {300 80 100 300 0}}
	
	# current is longer
	equal [ graph2::merge.segments {300 80 100 300 0} {400 80 150 200 0} ] {{} {300 80 100 300 0}}
	
	
	# down
	equal [ graph2::merge.segments {300 80 100 300 0} {301 80 150 200 30100} ] {{301 80 100 200 30100} {300 80 200 300 0}}
	equal [ graph2::merge.segments {300 80 100 300 0} {301 80 150 400 30100} ] {{} {301 80 100 400 30100}}
	
	# up
	equal [ graph2::merge.segments {300 80 100 300 0} {301 80 200 400 10100} ] {{300 80 100 200 0} {301 80 200 400 10100}}
	equal [ graph2::merge.segments {300 80 100 300 0} {301 80 200 250 10100} ] {{300 80 100 200 0} {301 80 200 300 10100}}
	
	equal [ graph2::merge.segments {300 80 100 300 0} {301 80 100 400 10100} ] {{} {301 80 100 400 10100}}
	equal [ graph2::merge.segments {300 80 100 300 0} {301 80 100 250 10100} ] {{} {301 80 100 300 10100}}
	
	
	# down
	equal [ graph2::merge.segments {301 80 100 400 30100} {300 80 100 300 0} ] {{} {301 80 100 400 30100}}
	equal [ graph2::merge.segments {301 80 100 300 30100} {300 80 200 400 0} ] {{301 80 100 300 30100} {300 80 300 400 0}}
	
	# up
	equal [ graph2::merge.segments {301 80 100 400 10100} {300 80 200 300 0} ] {{} {301 80 100 400 10100}}
	equal [ graph2::merge.segments {301 80 100 300 10100} {300 80 200 400 0} ] {{} {301 80 100 400 10100}}	
	
	equal [ graph2::success.status ] 1
}

tproc merge.on.1.line_test { } {
	graph2::stor.clear
	
	set items {
		{1 80 300 400 0} {2 80 350 450 0}
		{3 80 150 250 0} {4 80 100 200 0}}

	equal [ graph2::merge.on.1.line $items ] {{4 80 100 250 0} {1 80 300 450 0}}
	
	equal [ graph2::success.status ] 1
}

tproc icons.touch_test { } {
	set rect1 {100 action hi "" 100 200 50 20 0 0}
	set rect2 {200 action fu "" 150 210 60 30 0 0}
	equal [ graph2::icons.touch $rect1 $rect2 ] 1
	
}

tproc cut.simple_test { } {
	# above
	equal [ graph2::cut.simple {10 7 100 200 6} 300 400 6 8 ] {{10 7 100 200 6} {}}
	equal [ graph2::cut.simple {10 7 100 200 6} 200 400 6 8 ] {{10 7 100 200 6} {}}
	
	# top only
	equal [ graph2::cut.simple {10 7 100 350 6} 300 400 6 8 ] {{10 7 100 300 6} {}}
	equal [ graph2::cut.simple {10 7 100 400 6} 300 400 6 8 ] {{10 7 100 300 6} {}}
	
	# two ends
	equal [ graph2::cut.simple {10 7 100 500 6} 300 400 6 8 ] {{10 7 100 300 6} {10 7 400 500 8}}
	
	# below
	equal [ graph2::cut.simple {10 7 400 500 6} 300 400 6 8 ] {{} {10 7 400 500 6}}
	equal [ graph2::cut.simple {10 7 350 500 6} 300 400 6 8 ] {{} {10 7 400 500 8}}
	
	# inside
	equal [ graph2::cut.simple {10 7 400 500 6} 400 500 6 8 ] {{} {}}
}

tproc segment.cut.segment_test { } {
	graph2::stor.clear

	set left_far    {20 200 100 150 40100}
	set left_touch  {20 200 100 200 40100}
	set right_far   {20 200 300 400 40100}
	set right_touch {20 200 200 300 40100}
	
	equal [ graph2::segment.cut.segment 200 $left_far ] [list $left_far {}]
	equal [ graph2::segment.cut.segment 200 $left_touch ] [list $left_touch {}]
	equal [ graph2::segment.cut.segment 200 $right_far ] [list {} $right_far]
	equal [ graph2::segment.cut.segment 200 $right_touch ] [list {} $right_touch]
	
	set middle_left {20 400 100 300 40100}
	set middle_right {20 400 100 300 20100}
	equal [ graph2::segment.cut.segment 200 $middle_left ] {{20 400 100 200 40100} {20 400 200 300 0}}
	equal [ graph2::segment.cut.segment 200 $middle_right ] {{20 400 100 200 0} {20 400 200 300 20100}}	
}

tproc lines.cut_test { } {
	graph2::stor.clear

	set left_far    {20 50 100 150 40100}
	set right_far   {50 50 300 400 40100}
	
	set left_touch  {40 60 100 200 40100}
	set right_touch {60 60 200 300 40100}

	set middle_right {70 50 100 300 20100}	
	
	set up {80 200 0 200 10100}
	set up2 {90 200 1000 2000 10100}
	
	set hor50 [ list $left_far $right_far $middle_right ]
	set hor60 [ list $left_touch $right_touch ]
	
	set ver200 [ list $up $up2 ]
	
	array set hors [list 50 $hor50 60 $hor60]
	array set vers [list 200 $ver200]
	
	graph2::lines.cut hors vers
	graph2::lines.cut vers hors
	
	equal $hors(50) {{20 50 100 150 40100} {50 50 300 400 40100} {70 50 100 200 0} {70 50 200 300 20100}}
	equal $hors(60) {{40 60 100 200 40100} {60 60 200 300 40100}}
	
	equal $vers(200) {{80 200 0 50 10100} {80 200 50 60 0} {80 200 60 200 0} {90 200 1000 2000 10100}}

}

tproc get.only_test { } {

	equal [ graph2::get.only "" "" "" "" ] ""
	equal [ graph2::get.only 1 "" "" "" ] 1
	equal [ graph2::get.only "" 2 "" "" ] 2
	equal [ graph2::get.only "" "" 3 "" ] 3
	equal [ graph2::get.only "" "" "" 4 ] 4
	equal [ graph2::get.only 1 "" 5 "" ] ""
	equal [ graph2::get.only "" 2 "" 6 ] ""
	equal [ graph2::get.only 7 "" 3 "" ] ""
	equal [ graph2::get.only 9 "" "" 4 ] ""
	equal [ graph2::get.only 1 "" 5 6 ] ""
	equal [ graph2::get.only "" 2 "" 6 ] ""
	equal [ graph2::get.only 7 4 3 "" ] ""
	equal [ graph2::get.only 9 6 1 4 ] ""
	
}



