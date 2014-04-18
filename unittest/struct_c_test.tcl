
tproc extract_tables_test {} {
	set tables [ st::extract_tables ../testdata/ttab1.txt ]
	equal [ llength $tables ] 4
	
	set tab1 [ lindex $tables 0 ]
	set tab2 [ lindex $tables 1 ]
	set tab3 [ lindex $tables 2 ]
	set tab4 [ lindex $tables 3 ]
	
	list_equal [ lindex $tab1 0 ] {hello bye}
	list_equal [ lindex $tab1 1 ] {one two}

	list_equal [ lindex $tab2 0 ] {left right 1}
	list_equal [ lindex $tab2 1 ] {top bottom 2}
	list_equal [ lindex $tab2 2 ] {front back 3}

	list_equal [ lindex $tab3 0 ] {again}
	list_equal [ lindex $tab3 1 ] {one two three}
	list_equal [ lindex $tab3 2 ] {"" "" ""}
	list_equal [ lindex $tab3 3 ] {1 2 3}		

	list_equal [ lindex $tab4 0 ] {{last one}}
	list_equal [ lindex $tab4 1 ] {{}}
	list_equal [ lindex $tab4 2 ] {begin end}
}

tproc diff_array_test {} {
	equal [ st::diff_arrays {} {} ] {1 {} {}}
	equal [ st::diff_arrays {a} {a} ] {1 {} {}}
	equal [ st::diff_arrays {aaa bbb} {aaa bbb} ] {1 {} {}}
	equal [ st::diff_arrays {ccc aaa bbb} {aaa bbb ccc} ] {1 {} {}}
	
	equal [ st::diff_arrays {a} {} ] {0 a {}}
	equal [ st::diff_arrays {} {b} ] {0 {} b}
	equal [ st::diff_arrays {a} {b} ] {0 a b}
	equal [ st::diff_arrays {a b} {c d} ] {0 {a b} {c d}}
	
	equal [ st::diff_arrays {a b c} {c d e} ] {0 {a b} {d e}}
}

tproc parse_message_signature_test { } {
	equal [ st::parse_message_signature "cool\(\)" bar ] {args {} name cool}
	equal [ st::parse_message_signature "cool\(int value\)" bar ] {args {{type int name value comment {}}} name cool}
	equal [ st::parse_message_signature "cool\(int value, const char* text\)" bar ] {args {{type int name value comment {}} {type {const char*} name text comment {}}} name cool}
	equal [ st::parse_message_signature "cool\(int value, const char* text, struct s1 m\)" bar ] {args {{type int name value comment {}} {type {const char*} name text comment {}} {type {struct s1} name m comment {}}} name cool}
}
