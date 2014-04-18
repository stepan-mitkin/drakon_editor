
tproc to_tokens_test { } {
	# lexing state
	set state [ search::state.make idle cool 10 200 20 0 0 ]
	set state2 [ search::state.token $state u ]
	list_equal $state2 { token {u} 10 201 21 200 20 }
	set state3 [ search::state.new_line $state2 ]
	list_equal $state3 { idle {} 11 202 0 0 0 }
	set state4 [ search::state.append $state2 m ]
	list_equal $state4 { token {u m} 10 202 22 200 20 }
	set result {}
	set state5 [ search::state.other $state result "?" ]
	list_equal [ lindex $result 0 ] {? 200 10 20}
	list_equal $state5 { idle {} 10 201 21 0 0 }
	set state6 [ search::state.flush $state4 result ]
	list_equal [ lindex $result 1 ] {um 200 10 20}
	list_equal $state6 { idle {} 10 202 22 0 0 }

	# lexing state machine
	# idle
	set result {}
	set state2 [ search::state.idle.next $state result "\n" ]
	list_equal $state2 { idle "" 11 201 0 0 0 }
	list_equal $result {}

	set state2 [ search::state.idle.next $state result " " ]
	list_equal $state2 { whitespace {{ }} 10 201 21 200 20 }
	list_equal $result {}

	set state2 [ search::state.idle.next $state result "n" ]
	list_equal $state2 { token {n} 10 201 21 200 20 }
	list_equal $result {}

	set state2 [ search::state.idle.next $state result "?" ]
	list_equal $state2 { idle "" 10 201 21 0 0 }
	list_equal $result {{? 200 10 20}}

	# token
	set result {}
	set state2 [ search::state.token.next $state4 result "\n" ]
	list_equal $state2 { idle "" 11 203 0 0 0 }
	list_equal $result {{um 200 10 20}}

	set result {}
	set state2 [ search::state.token.next $state4 result " " ]
	list_equal $state2 { whitespace {{ }} 10 203 23 202 22 }
	list_equal $result {{um 200 10 20}}

	set result {}
	set state2 [ search::state.token.next $state4 result "n" ]
	list_equal $state2 { token {u m n} 10 203 23 200 20 }
	list_equal $result {}

	set result {}
	set state2 [ search::state.token.next $state4 result "?" ]
	list_equal $state2 { idle "" 10 203 23 0 0 }
	list_equal $result {{um 200 10 20} {? 202 10 22}}

	# whitespace
	set state4 [ search::state.whitespace $state " " ]
	set result {}
	set state2 [ search::state.whitespace.next $state4 result "\n" ]
	list_equal $state2 { idle "" 11 202 0 0 0 }
	list_equal $result {{{ } 200 10 20}}

	set result {}
	set state2 [ search::state.whitespace.next $state4 result " " ]
	list_equal $state2 { whitespace {{ } { }} 10 202 22 200 20 }
	list_equal $result {}

	set result {}
	set state2 [ search::state.whitespace.next $state4 result "n" ]
	list_equal $state2 { token {n} 10 202 22 201 21 }
	list_equal $result {{{ } 200 10 20}}

	set result {}
	set state2 [ search::state.whitespace.next $state4 result "?" ]
	list_equal $state2 { idle "" 10 202 22 0 0 }
	list_equal $result {{{ } 200 10 20} {? 201 10 21}}

	# Lexing real strings
	check_to_tokens "preved" { preved }
	check_to_tokens "\tpreved  " { "\t" preved "  " }
	check_to_tokens "preved  2:0?" { preved "  " 2 : 0 ? }
	check_to_tokens "preved  200c:0x00ff - (mff20p.foo600)?" { preved "  " 200c : 0x00ff " " - " " "(" mff20p . foo600 ")" ? }
	check_to_tokens "proc cool\n    return m;\nfoo\n" { proc " " cool "    " return " " m ";" foo }
}

proc check_tokens { bigtext } {
	set tokens [ search::to_tokens $bigtext ]
	set lines [ split $bigtext "\n" ]

	foreach token $tokens {
		set text [ lindex $token 0 ]
		set char [ lindex $token 1 ]
		set line [ lindex $token 2 ]
		set lchar [ lindex $token 3 ]
		set length [ string length $text ]
		set last [ expr { $char + $length - 1 } ]
		set last2 [ expr { $lchar + $length - 1 } ]
		set atext [ string range $bigtext $char $last ]

		set aline [ lindex $lines $line ]
		set atext2 [ string range $aline $lchar $last2 ]

		equal $atext $text
		equal $atext2 $text
	}
}

proc take_first { list } {
	return [ lindex $list 0 ]
}

proc check_to_tokens { bigtext expected } {
	check_tokens $bigtext
	set tokens [ search::to_tokens $bigtext ]
	set texts [ map -list $tokens -fun take_first ]
	list_equal $texts $expected
}

tproc find_occurences_test { } {
	check_occurences "left" "right"  {}
	check_occurences "" "right"  {}
	check_occurences "right" "left"  {}
	check_occurences "left" "left" {{0 0 0 4}}
	check_occurences "from left" "left"  {{5 0 5 4}}
	check_occurences "left to" "left"  {{0 0 0 4}}
	check_occurences "mmmmmmmm" "mmm"  {{0 0 0 3} {3 0 3 3}}
	check_occurences "leftLeftleft" "left"  {{0 0 0 4} {8 0 8 4}}
	check_occurences "leftLeftleft" "Left"  {{4 0 4 4}}
	check_occurences " moofoo\n3foo\nfoobar" "foo" {{4 0 4 3} {9 1 1 3} {13 2 0 3}}
}

tproc find_token_occurences_test { } {
	check_token_occurences "left" "right"  {}
	check_token_occurences "" "right"  {}
	check_token_occurences "right" "left"  {}
	check_token_occurences "left" "left" {{0 0 0 4}}
	check_token_occurences "from left" "left"  {{5 0 5 4}}
	check_token_occurences "left to" "left"  {{0 0 0 4}}
	check_token_occurences "mmmmmmmm" "mmm"  {}
	check_token_occurences "leftLeftleft" "left"  {}
	check_token_occurences "left Left left" "left"  {{0 0 0 4} {10 0 10 4}}
	check_token_occurences "leftLeftleft" "Left"  {}
	check_token_occurences "left Left left" "Left"  {{5 0 5 4}}
	check_token_occurences "moo foo\n?foo\nfoo-arfoo" "foo" {{4 0 4 3} {9 1 1 3} {13 2 0 3}}
	check_token_occurences "(1 + 3) / 2 and ( 1+3 )/2 or (1+3)/20" "(1 + 3)/2" {{0 0 0 11} {16 0 16 9}}
}


proc check_token_occurences { haystack needle expected } {
	set hay_tokens [ search::to_tokens $haystack ]
	set needle_tokens [ search::to_tokens $needle ]
	set needle_tokens [ search::remove_whitespace $needle_tokens ]
	set actual [ search::find_token_occurences $hay_tokens $needle_tokens ]
	check_occurences_kernel $haystack $needle $actual $expected 1
}

proc check_occurences { haystack needle expected } {
	set actual [ search::find_occurences $haystack $needle ]
	check_occurences_kernel $haystack $needle $actual $expected 0
}

proc check_occurences_kernel { haystack needle actual expected ignore_space } {
	set needle_length [ string length $needle ]
	list_equal $actual $expected
	set lines [ split $haystack "\n" ]
	foreach match $actual {
		set line_no [ lindex $match 1 ]
		set line_start [ lindex $match 2 ]
		set length [ lindex $match 3 ]
		set line [ lindex $lines $line_no ]
		set last [ expr { $line_start + $length - 1 } ]
		set aneedle [ string range $line $line_start $last ]
		
		if { $ignore_space } {
			set needle2 [ string map { " " "" "\t" "" } $needle ]
			set aneedle2 [ string map { " " "" "\t" "" } $aneedle ]
			equal $aneedle2 $needle2
		} else {
			equal $aneedle $needle
		}
	}
}

proc replace_all_check { haystack needle replacement whole icase expected } {
	set search_hay $haystack
	if { $icase } {
		set needle [ string tolower $needle ]
		set search_hay [ string tolower $search_hay ]
	}
	if { $whole } {
		set ne_tokens [ search::to_tokens $needle ]
		set ha_tokens [ search::to_tokens $search_hay ]
		set ne_tokens [ search::remove_whitespace $ne_tokens ]
		set occurences [ search::find_token_occurences $ha_tokens $ne_tokens ]
		
	} else {
		set occurences [ search::find_occurences $search_hay $needle ]
	}
	set actual [ search::replace_occurences $haystack $replacement $occurences ]
	equal $actual $expected	
}

tproc replace_occurences_test { } {
	replace_all_check "" "" "" 1 1 ""
	replace_all_check "foo" "bar" "moo" 1 1 "foo"
	replace_all_check "foofoo" "foo" "moo" 1 1 "foofoo"
	replace_all_check "foofoo" "foo" "moo" 0 1 "moomoo"
	replace_all_check "FOOfoo" "foo" "moo" 0 1 "moomoo"
	replace_all_check "FOOFOO" "foo" "moo" 0 0 "FOOFOO"
	replace_all_check "foo" "foo" "moo" 0 0 "moo"
	replace_all_check "one - foobar/foo + FOO" "foo" "moo" 0 0 "one - moobar/moo + FOO"
	replace_all_check "one - foobar/foo + FOO" "foo" "moo" 1 0 "one - foobar/moo + FOO"
	replace_all_check "one - foobar/foo + FOO" "foo" "moo" 0 1 "one - moobar/moo + moo"
	replace_all_check "one - foobar/foo + FOO" "foo" "moo" 1 1 "one - foobar/moo + moo"
	replace_all_check "  Ab - bC/ab  -  BC " "ab-bc" "xxx" 1 1 "  xxx/xxx "
	replace_all_check "  Ab - bC/ab  -  bc " "ab-bc" "xxx" 1 0 "  Ab - bC/xxx "
	replace_all_check "one\ntwo\nonetwo\none" "one" "xxx" 1 0 "xxx\ntwo\nonetwo\nxxx"
	replace_all_check "  " "  " "bar" 1 0 "  "
}

tproc replace_one_test { } {
	equal [ search::replace_one "one two three" "TWO" 4 3 ] "one TWO three"
	equal [ search::replace_one "one two three" "" 4 4 ] "one three"
	equal [ search::replace_one "one two three" "xxxxxx" 4 3 ] "one xxxxxx three"
}

proc testdb_set_description { description } {
	testdb eval { update state
		set description = :description }
}

if { 0 } {
tproc replace_all_test { } {
	set sql [ read_all_text ../scripts/schema.sql ]
	catch { mod::close testdb }
	equal [ mod::create testdb :memory: t1 20 1 $sql ] ""

	mv::init testdb dummy_canvas::cnvs	
	dummy_canvas::clear


	testdb_set_description "foo tram-pam-pam foo-foo\nmany foo"
	testdb_add_diagram 10 "dia-10" "a very bar diagram\nreally bar!"
	testdb_add_diagram 20 "dia-20 (foo)" "first line (foo)\nsecond line\nthird line (foo)"
	testdb_add_icon 10 11 action "foo action\naction foo" 10 10
	testdb_add_icon 20 21 action "nothing\nnothing-2\nfoo" 20 20

	mwc::init testdb
	search::init testdb

	set count [ search::replace_all testdb "foo" "" 0 0 0 "fu" ]
	

	check_file_desc "fu tram-pam-pam fu-fu\nmany fu"
	check_diagram_desc 20 "first line (fu)\nsecond line\nthird line (fu)"
	check_item_text 11 "fu action\naction fu"

	com::undo testdb

	check_file_desc "foo tram-pam-pam foo-foo\nmany foo"
	check_diagram_desc 20 "first line (foo)\nsecond line\nthird line (foo)"
	check_item_text 11 "foo action\naction foo"
}
}
proc check_item_text { item_id text } {
	equal [ testdb onecolumn { select text from items where item_id = :item_id } ] $text
}

proc check_diagram_desc { diagram_id text } {
	equal [ testdb onecolumn { select description from diagrams where diagram_id = :diagram_id } ] $text
}

proc check_file_desc { text } {
	equal [ testdb onecolumn { select description from state } ] $text
}

tproc replace_test { } {
	catch { mod::close testdb }
	set sql [ read_all_text ../scripts/schema.sql ]
	equal [ mod::create testdb :memory: t1 20 1 $sql ] ""


	testdb_set_description "foo tram-pam-pam foo-foo\nmany foo"
	testdb_add_diagram 10 "dia-10" "a very bar diagram\nreally bar!"
	testdb_add_diagram 20 "dia-20 (foo)" "first line (foo)\nsecond line\nthird line (foo)"
	testdb_add_icon 10 11 action "foo action\naction foo" 10 10
	testdb_add_icon 20 21 action "nothing\nnothing-2\nfoo" 20 20

	mwc::init testdb
	search::init testdb
	search::find_all testdb "foo" "" 0 0 0
	list_equal [ search::get_current_match ] {"foo tram-pam-pam foo-foo" {0 3} {{17 3} {21 3}}}
	search::next
	list_equal [ search::get_current_match ] {"foo tram-pam-pam foo-foo" {17 3} {{0 3} {21 3}}}
	search::next
	list_equal [ search::get_current_match ] {"foo tram-pam-pam foo-foo" {21 3} {{0 3} {17 3}}}
	search::next
	list_equal [ search::get_current_match ] {"many foo" {5 3} {}}
	search::previous
	search::previous
	list_equal [ search::get_current_match ] {"foo tram-pam-pam foo-foo" {17 3} {{0 3} {21 3}}}

	equal [ search::replace fu ] 1
	equal [ search::get_current_match ] ""
	search::next
	list_equal [ search::get_current_match ] {"foo tram-pam-pam fu-foo" {20 3} {{0 3}}}
	search::previous
	list_equal [ search::get_current_match ] {"foo tram-pam-pam fu-foo" {0 3} {{20 3}}}
	search::next
	search::next
	list_equal [ search::get_current_match ] {"many foo" {5 3} {}}

	equal [ testdb onecolumn { select description from state } ] "foo tram-pam-pam fu-foo\nmany foo"
}

tproc find_all_test { } {
	create_testdb	"tram-pam-pam\nmany foo"
	testdb_add_diagram 10 "dia-10" "a very bar diagram\nreally bar!"
	testdb_add_diagram 20 "dia-20 (foo)" "first line (foo)\nsecond line\nthird line (foo)"
	testdb_add_icon 10 11 action "foo action\naction foo" 10 10
	testdb_add_icon 10 12 if "foo if" 10 20
	testdb_add_icon 10 13 action "foo if\nif foofoo" 20 10
	testdb_add_icon 20 21 action "nothing\nnothing-2\nfoo" 20 20

	search::init testdb
	
	search::find_all testdb "foo" "" 0 0 0
	set result [ print_results ]
	checkpr $result 0 {file_description 0 1 5 "File description: many foo"}
	checkpr $result 1 {icon 11 0 0 "dia-10: item 11 'action': foo action"}
	checkpr $result 2 {icon 11 1 7 "dia-10: item 11 'action': action foo"}
	checkpr $result 3 {icon 12 0 0 "dia-10: item 12 'if': foo if"}
	checkpr $result 4 {icon 13 0 0 "dia-10: item 13 'action': foo if"}
	checkpr $result 5 {icon 13 1 3 "dia-10: item 13 'action': if foofoo"}
	checkpr $result 6 {icon 13 1 6 "dia-10: item 13 'action': if foofoo"}
	checkpr $result 7 {diagram_name 20 0 8 "dia-20 (foo): diagram name: dia-20 (foo)"}
	checkpr $result 8 {diagram_description 20 0 12 "dia-20 (foo): diagram description: first line (foo)"}
	checkpr $result 9 {diagram_description 20 2 12 "dia-20 (foo): diagram description: third line (foo)"}
	checkpr $result 10 {icon 21 2 0 "dia-20 (foo): item 21 'action': foo"}

	checkln 0 "File description: many foo"
	checkln 1 "dia-10: item 11 'action': foo action"
	checkln 2 "dia-10: item 11 'action': action foo"
	checkln 3 "dia-10: item 12 'if': foo if"
	checkln 4 "dia-10: item 13 'action': foo if"
	checkln 5 "dia-10: item 13 'action': if foofoo"
	checkln 6 "dia-20 (foo): diagram name: dia-20 (foo)"	
	checkln 7 "dia-20 (foo): diagram description: first line (foo)"
	checkln 8 "dia-20 (foo): diagram description: third line (foo)"
	checkln 9 "dia-20 (foo): item 21 'action': foo"
	
	equal [ search::get_current_list_item ] 0
	
	equal [ search::previous ] 0
	equal [ search::get_current_list_item ] 0
	
	equal [ search::next ] 1
	equal [ search::get_current_list_item ] 1
	equal [ search::previous ] 1
	equal [ search::get_current_list_item ] 0
	
	list_equal [ search::get_current_match ] {"many foo" {5 3} {}}
	list_equal [ search::get_match_object ] {file_description 0}
	
	equal [ search::next ] 1
	equal [ search::get_current_list_item ] 1
	list_equal [ search::get_current_match ] {"foo action" {0 3} {}}
	list_equal [ search::get_match_object ] {icon 11}
	
	equal [ search::next ] 1
	equal [ search::get_current_list_item ] 2
	list_equal [ search::get_current_match ] {"action foo" {7 3} {}}
	list_equal [ search::get_match_object ] {icon 11}
	
	equal [ search::next ] 1
	equal [ search::get_current_list_item ] 3
	list_equal [ search::get_current_match ] {"foo if" {0 3} {}}
	list_equal [ search::get_match_object ] {icon 12}
	
	equal [ search::next ] 1
	equal [ search::next ] 1
  equal [ search::get_current_list_item ] 5
  list_equal [ search::get_current_match ] {"if foofoo" {3 3} {{6 3}}}
  
	equal [ search::next ] 1
  equal [ search::get_current_list_item ] 5
  list_equal [ search::get_current_match ] {"if foofoo" {6 3} {{3 3}}}
  
  equal [ search::next ] 1
  equal [ search::next ] 1
  equal [ search::next ] 1
  equal [ search::next ] 1
  
  # reached the end of list
  equal [ search::next ] 0
  equal [ search::get_current_list_item ] 9
  list_equal [ search::get_current_match ] {"foo" {0 3} {}}
  
  # jump to an index out of range
  equal [ search::set_current_list_item 1000 ] 0
  
  # random jump
  equal [ search::set_current_list_item 2 ] 1
  equal [ search::get_current_list_item ] 2
  list_equal [ search::get_current_match ] {"action foo" {7 3} {}}
  
  # jump to the line with several matches
  equal [ search::set_current_list_item 5 ] 1
  equal [ search::get_current_list_item ] 5
  list_equal [ search::get_current_match ] {"if foofoo" {3 3} {{6 3}}}

  # going forward on the same line
	equal [ search::next ] 1
  equal [ search::get_current_list_item ] 5
  list_equal [ search::get_current_match ] {"if foofoo" {6 3} {{3 3}}}

  # going backward on the same line
  equal [ search::previous ] 1
  equal [ search::get_current_list_item ] 5
  list_equal [ search::get_current_match ] {"if foofoo" {3 3} {{6 3}}}
  
  # delete the icon we are standing on
  testdb eval { delete from items where item_id = 13 }
  list_equal [ search::get_current_match ] ""
  
	equal [ search::next ] 1
  equal [ search::get_current_list_item ] 6
  list_equal [ search::get_current_match ] {"dia-20 (foo)" {8 3} {}}
  list_equal [ search::get_match_object ] {diagram_name 20}
  
  testdb eval { update diagrams set name = "different" where diagram_id = 20 }
  list_equal [ search::get_current_match ] ""
  list_equal [ search::get_match_object ] ""
  
	equal [ search::next ] 1
  equal [ search::get_current_list_item ] 7
  
  # jumping back through the gap
  equal [ search::previous ] 1
  equal [ search::get_current_list_item ] 3
  list_equal [ search::get_current_match ] {"foo if" {0 3} {}}
  
  # jumping forward though the gap
  equal [ search::next ] 1  
  equal [ search::get_current_list_item ] 7
  
  # random jump to a changed line
  equal [ search::set_current_list_item 5 ] 1
  equal [ search::get_current_list_item ] 5
  list_equal [ search::get_current_match ] ""
  list_equal [ search::get_match_object ] ""
  
  # going forward to the next intact line
  equal [ search::next ] 1  
  equal [ search::get_current_list_item ] 7  
  list_equal [ search::get_match_object ] {diagram_description 20}
}


proc checkln { number expected } {
  set actual [ searchdb onecolumn {
      select show_text from lines where ordinal = :number } ]
  equal $actual $expected
  set list [ search::get_list ]
  set actual2 [ lindex $list $number ]
  equal $actual2 $expected  
}



proc checkpr { results index expected } {
	set actual [ lindex $results $index ]
	list_equal $actual $expected
}

proc print_results { } {
	set result {}
	searchdb eval { select match_id from results order by result_id } {
	searchdb eval { select object_type, object_id, line, line_start from
		matches where match_id = :match_id } {
		set text [ searchdb onecolumn { select show_text from lines
			where object_type = :object_type
				and object_id = :object_id
				and line_no = :line } ]
		lappend result [ list $object_type $object_id $line $line_start $text ]
	} }
	return $result
}

proc testdb_add_diagram { diagram_id name description } {
	testdb eval {
		insert into diagrams
		(diagram_id, name, description)
		values
		(:diagram_id, :name, :description) }
}

proc testdb_add_icon { diagram_id item_id type text x y } {
	testdb eval {
		insert into items
		(item_id, diagram_id, type, text, x, y)
		values
		(:item_id, :diagram_id, :type, :text, :x, :y) }
}

proc create_testdb { description } {
	set sql [ read_all_text ../scripts/schema.sql ]
	catch { testdb close }
	sqlite3 testdb :memory:
	testdb eval $sql
	testdb eval { update state set description = :description }
}

