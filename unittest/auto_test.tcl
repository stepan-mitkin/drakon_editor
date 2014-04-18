

proc test.build { src_filename dst_filename } {
	#catch {
		set result [ mod::open db $src_filename drakon ]
		set message [ lindex $result 1 ]
		
		if { $message != "" } {
			return 0
		}
		
		mwc::init db
		
		set result [ gen::generate_no_gui $dst_filename ]
		mod::close db
		return $result
	#} message

	#if { $message != "" } {
	#	puts $message
	#	exit 1
	#}
}


proc test.build_good { name } {
	puts $name
	set ext "cs"
	set in ../testdata/$name
	
	set src_filename [ file normalize $in ]
	set out [ file dirname $in ]

	set out_dir [ file normalize $out ]


	set dst_filename "${src_filename}.${ext}"
	
	return [ test.build $src_filename $dst_filename ]
}

proc test.build_bad { name } {
	if { [ test.build_good $name ] } {
		error "Error expected when building $name."
	}
#	puts [ graph::get_error_list ]
}

tproc automaton_test { } {
	test.build_bad "sm_no_branches.drn"
	test.build_bad "sm_no_receive.drn"
	test.build_bad "sm_receive_middle.drn"	
	test.build_bad "sm_receive_end.drn"
	test.build_bad "sm_no_receive_middle.drn"
}
