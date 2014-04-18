# Test utilities

proc tproc { name args body } {
	global ut_all_tests
	
	lappend ut_all_tests $name
	proc $name $args $body
}

proc equal { actual expected { comment "" } } {
	#puts "actual:   $actual"
	#puts "expected: $expected"
	#puts ""
	
	
	global ut_current_test
	if { $actual != $expected } {
		if { $actual == "" } { set actual <empty> }
		if { $expected == "" } { set expected <empty> }
		set message "\n    $ut_current_test: equal:\nactual  : $actual\nexpected: $expected\n$comment\n"
		error $message
	}
}

proc list_equal { actual expected } {
	global ut_current_test
	set i 0
	foreach act $actual exp $expected {
		if { $act != $exp } {
			puts $actual
			set message "\n    $ut_current_test: list_equal:\nindex   : $i\nactual  : $act\nexpected: $exp\n"
			error $message
		}
		incr i
	}
}

proc tree_equal { actual expected } {
	set alength [ llength $actual ]
	set elength [ llength $expected ]
	if { $alength != $elength } {
		set message "tree nodes have different lengths at root\nactual:\n$actual\nexpected:\n$expected"
		error $message
	}
	
	tree_equal_kernel $actual $expected {}
}

proc is_complex { text } {
	if { [ string first " " $text ] != -1 } {
		return 1
	}
	
	if { [ string first "\t" $text ] != -1 } {
		return 1
	}	
	
	if { [ string first "\n" $text ] != -1 } {
		return 1
	}	
	
	return 0
}

proc tree_equal_kernel { actual expected path } {
	set alength [ llength $actual ]
	set elength [ llength $expected ]
	if { $alength != $elength } {
		set message "tree nodes have different lengths at $path\nactual:\n$actual\nexpected:\n$expected"
		error $message
	}
	
	if { ![ is_complex $expected ] } {
		set aitem [ lindex $actual 0 ]
		set eitem [ lindex $expected 0 ]
		if { $eitem != $aitem } {
			set message "tree nodes are different at $path\nactual:\n$aitem\nexpected:\n$eitem"
			error $message
		}
	} else {
		for { set i 0 } { $i < $alength } { incr i } {
			set new_path $path
			lappend new_path $i
			set aitem [ lindex $actual $i ]
			set eitem [ lindex $expected $i ]
			
			tree_equal_kernel $aitem $eitem $new_path
		}
	}
}

proc array_equal { actual expected } {
	array set actual_a $actual
	array set expected_a $expected
	set actual_keys [ lsort -dictionary [ array names actual_a ] ]
	set expected_keys [ lsort -dictionary [ array names expected_a ] ]
	list_equal $actual_keys $expected_keys
	foreach key $actual_keys {
		set actual_item $actual_a($key)
		set expected_item $expected_a($key)
		equal $actual_item $expected_item
	}
}

### main ###

proc testmain { } {
	global ut_all_tests ut_current_test
	
	foreach test $ut_all_tests {
		set ut_current_test $test
		puts $test
		$test
	}
}

proc testone { torun } {
	global ut_all_tests ut_current_test
	
	foreach test $ut_all_tests {
    if { $torun == $test } {
      set ut_current_test $test
      puts $test
      $test
    }
	}
}

