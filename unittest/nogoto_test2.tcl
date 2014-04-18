

tproc algo2_test { } {
	algo2::empty
	algo2::empty_if 0
	algo2::empty_if 1
	equal [ algo2::left_if 0 ] A
	equal [ algo2::left_if 1 ] 0
	algo2::nested_empty_if 0 0 0
	algo2::nested_empty_if 0 0 1
	algo2::nested_empty_if 0 1 0
	algo2::nested_empty_if 1 0 0
	
	equal [ algo2::nested_if 0 0 0 ] AC
	equal [ algo2::nested_if 0 0 1 ] A
	equal [ algo2::nested_if 0 1 0 ] AC
	equal [ algo2::nested_if 0 1 1 ] A
	equal [ algo2::nested_if 1 0 0 ] A
	equal [ algo2::nested_if 1 0 1 ] A
	equal [ algo2::nested_if 1 1 0 ] AB
	equal [ algo2::nested_if 1 1 1 ] AB

	equal [ algo2::nested_if2 0 0 0 ] ACE
	equal [ algo2::nested_if2 0 0 1 ] AE
	equal [ algo2::nested_if2 0 1 0 ] ACE
	equal [ algo2::nested_if2 0 1 1 ] AE
	equal [ algo2::nested_if2 1 0 0 ] AD
	equal [ algo2::nested_if2 1 0 1 ] AD
	equal [ algo2::nested_if2 1 1 0 ] ABD
	equal [ algo2::nested_if2 1 1 1 ] ABD

	equal [ algo2::nested_if3 0 0 0 ] ACE
	equal [ algo2::nested_if3 0 0 1 ] AGE
	equal [ algo2::nested_if3 0 1 0 ] ACE
	equal [ algo2::nested_if3 0 1 1 ] AGE
	equal [ algo2::nested_if3 1 0 0 ] AFD
	equal [ algo2::nested_if3 1 0 1 ] AFD
	equal [ algo2::nested_if3 1 1 0 ] ABD
	equal [ algo2::nested_if3 1 1 1 ] ABD

	equal [ algo2::nested_if4 0 0 0 ] AICE
	equal [ algo2::nested_if4 0 0 1 ] AIGE
	equal [ algo2::nested_if4 0 1 0 ] AICE
	equal [ algo2::nested_if4 0 1 1 ] AIGE
	equal [ algo2::nested_if4 1 0 0 ] AHFD
	equal [ algo2::nested_if4 1 0 1 ] AHFD
	equal [ algo2::nested_if4 1 1 0 ] AHBD
	equal [ algo2::nested_if4 1 1 1 ] AHBD

	equal [ algo2::normal_if 1 ] B
	equal [ algo2::normal_if 0 ] A
	
	equal [ algo2::one_op ] 300
	equal [ algo2::right_if 0 ] 0
	equal [ algo2::right_if 1 ] A
	
	equal [ algo2::denormalized 0 0 0 ] ABCF
	equal [ algo2::denormalized 0 0 1 ] ABCF
	equal [ algo2::denormalized 0 1 0 ] ABDF
	equal [ algo2::denormalized 0 1 1 ] ABEF
	equal [ algo2::denormalized 1 0 0 ] ADF
	equal [ algo2::denormalized 1 0 1 ] AEF
	equal [ algo2::denormalized 1 1 0 ] ADF
	equal [ algo2::denormalized 1 1 1 ] AEF
	
	
	equal [ algo2::xloop_simple 10 ] 362880
	equal [ algo2::xloop_simple2 10 ] 362880
	equal [ algo2::xloop_2exits 10 ] 24
	
	equal [ algo2::switch_bug {foo 1 1 1} "moo" ] 2-foo
	equal [ algo2::switch_bug {1 1 1 1} "moo" ] 2-xU
	equal [ algo2::switch_bug {1 1 1 1} "good" ] UVUVUVUV
	equal [ algo2::switch_bug {1 1 1 1 1 1} "good" ] UVUVUVUVUVUV
}

tproc after_others_test { } {
	set order {
		10 {20 30 40}
		20 {30 40}
		30 {40}
		40 {}
		50 {60 70 80}
	}
	
	equal [ nogoto::choose_latest $order 10 ] 10
	equal [ nogoto::choose_latest $order {10 20} ] 20
	equal [ nogoto::choose_latest $order {10 20 30} ] 30
	equal [ nogoto::choose_latest $order {10 20 30 40} ] 40
	equal [ nogoto::choose_latest $order {10 50} ] {}
}

tproc find_common_point_test { } {
	set path0 {10 20 30}
	set path1 {20 30 40}
	set path2 {80 90 20}
	set path3 {40 50 60}
	
	set paths_a [ list $path0 $path1 $path2 ]
	set paths_b [ list $path1 $path3 ]
	set paths_c [ list $path0 $path3 ]
	set paths_d [ list $path0 ]
	
	equal [ nogoto::find_common_point $paths_a ] 20
	equal [ nogoto::find_common_point $paths_b ] 40
	equal [ nogoto::find_common_point $paths_c ] {}
	equal [ nogoto::find_common_point $paths_d ] 10
	
}