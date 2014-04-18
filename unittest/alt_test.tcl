
tproc get_alt_item_test { } {
	alt::init_db
	
	# lines
	test_alt_item 201 horizontal 10 20 30 0 0 0
	test_alt_item 202 vertical 11 21 0 41 0 0
	
	# rectangles
	test_alt_item 203 action 13 23 33 43 0 0
	test_alt_item 204 insertion 14 24 34 44 0 0
	test_alt_item 205 loopstart 15 25 35 45 0 0
	test_alt_item 206 loopend 16 26 36 46 0 0
	test_alt_item 207 branch 17 27 37 47 0 0
	test_alt_item 208 address 18 28 38 48 0 0
	test_alt_item 209 select 19 29 39 49 0 0
	test_alt_item 210 case 110 210 310 410 0 0
	test_alt_item 211 commentin 111 211 311 411 0 0
	test_alt_item 212 beginend 112 212 312 412 0 0
	
	# compound
	test_alt_item 213 if 113 213 313 413 513 0
	test_alt_item 214 arrow 114 214 314 414 514 0
	test_alt_item 215 arrow 115 215 315 415 515 1
	test_alt_item 216 commentout 116 216 316 416 516 0
	test_alt_item 217 commentout 117 217 317 417 517 1
}

proc test_alt_item { item_id type x y w h a b } {
	alt::insert $item_id $type $x $y $w $h $a $b
	unpack [ alt::get_item $item_id ] x2 y2 w2 h2 a2 b2
	equal $x2 $x
	equal $y2 $y
	equal $w2 $w
	equal $h2 $h
	equal $a2 $a
	equal $b2 $b
}
