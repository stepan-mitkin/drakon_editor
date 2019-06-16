
gen::add_generator NX gen_nx::generate

namespace eval gen_nx {

variable keywords

array set keywords [array get gen_tcl::keywords]

proc highlight { tokens } {
	return [gen_tcl::highlight tokens]
}

proc make_callbacks { } {
	set callbacks {}
	
	gen::put_callback callbacks assign			gen_tcl::p.assign
	gen::put_callback callbacks compare			gen_tcl::p.compare
	gen::put_callback callbacks compare2		gen_tcl::p.compare2
	gen::put_callback callbacks while_start 	gen_tcl::p.while_start
	gen::put_callback callbacks if_start		gen_tcl::p.if_start
	gen::put_callback callbacks elseif_start	gen_tcl::p.elseif_start
	gen::put_callback callbacks if_end			gen_tcl::p.if_end
	gen::put_callback callbacks else_start		gen_tcl::p.else_start
	gen::put_callback callbacks pass			gen_tcl::p.pass
	gen::put_callback callbacks continue		gen_tcl::p.continue
	gen::put_callback callbacks return_none		gen_tcl::p.return_none
	gen::put_callback callbacks block_close		gen_tcl::p.block_close
	gen::put_callback callbacks comment			gen_tcl::p.comment
	gen::put_callback callbacks bad_case		gen_tcl::p.bad_case
	gen::put_callback callbacks for_init		gen_tcl::foreach_init
	gen::put_callback callbacks for_check		gen_tcl::foreach_check
	gen::put_callback callbacks for_current		gen_tcl::foreach_current
	gen::put_callback callbacks for_incr		gen_tcl::foreach_incr
	gen::put_callback callbacks body			gen_tcl::generate_body
	gen::put_callback callbacks signature		gen_nx::extract_signature
	gen::put_callback callbacks and				gen_tcl::p.and
	gen::put_callback callbacks or				gen_tcl::p.or
	gen::put_callback callbacks not				gen_tcl::p.not
	gen::put_callback callbacks break			"break"
	gen::put_callback callbacks declare			gen_tcl::p.declare
	gen::put_callback callbacks for_declare		gen_tcl::for_declare
	gen::put_callback callbacks shelf			gen_tcl::shelf
	gen::put_callback callbacks if_cond			gen_tcl::if_cond
	gen::put_callback callbacks native_foreach		gen_tcl::native_foreach


	return $callbacks
}

proc generate { db gdb filename } {
	global errorInfo
	set callbacks [ make_callbacks ]

	gen::fix_graph $gdb $callbacks 0
	unpack [ gen::scan_file_description $db { header footer } ] header footer

	set use_nogoto 1
	set functions [ gen::generate_functions $db $gdb $callbacks $use_nogoto ]

	tab::generate_tables $gdb $callbacks 0

	if { [ graph::errors_occured ] } { return }



	set hfile [ replace_extension $filename "tcl" ]
	set f [ open_output_file $hfile ]
	catch {
		p.print_to_file $f $functions $header $footer
	} error_message
	set savedInfo $errorInfo
	
	catch { close $f }
	if { $error_message != "" } {
		puts $errorInfo
		error $error_message savedInfo
	}
}

proc p.print_proc { weak_signature fhandle procedure class_name depth } {

    lassign $procedure diagram_id name signature body

    if {$class_name == ""} {
        
    } else {

        set name $class_name
    }

    lassign $signature type prop_list parameters returns
    array set props $prop_list

    set indent [ gen::make_indent $depth ]

    set body_depth [ expr { $depth + 1 } ]
    set lines [ gen::indent $body $body_depth ]

    # if {$name == "Shutdown"} {

    #     set props(access) "public"
    #     set returns "void"
    # } else {
        
    # }

    set header ""

    if {$props(access) == "none"} {
        
    } else {

        append header ":$props(access) method "
    }

    if {$props(dispatch) == "normal"} {
        
    } else {

		# find -checkalways parameter, remove it from dispatch properties
		# and set a separate variable for it

		set ca_index -exact [lsearch $props(dispatch) "-checkalways"]

		if {$ca_index -ne -1} {
			set checkalways [lindex $props(dispatch) $ca_index]
			set $props(dispatch) [lreplace $ca_index $ca_index]
		}

        append header [join $props(dispatch) " "]
    }

    append header "$name \{"

    # if {$name == "Shutdown"} {

	# 	set params {}
    # } else {

        set params [ map2 $parameters gen_cs::take_first ]

        # if {[lindex $params 0 ] == "state machine"} {

        #     set params [ lrange $params 1 end ]
        # } else {
            
        # }
    # }

	
    append header [ join $params " " ]

    append header "\)"

	if {info exists checkalways} {
		append header " $checkalways "
	}
	
    if {$type == "ctr"} {
        
    } else {

        append header "-returns $returns "
    }

    puts $fhandle ""

    if {$props(dispatch) == "abstract"} {

        puts $fhandle "$indent$header;"
    } else {

        puts $fhandle "$indent$header \{"

        # if {$name == "Shutdown"} {
        #     #item 1807
        #     puts $fhandle "$indent    if \(State == StateNames.Destroyed\) \{"
        #     puts $fhandle "$indent        return;"
        #     puts $fhandle "$indent    \}"
        #     puts $fhandle "$indent    State = StateNames.Destroyed;"
        # } else {
            
        # }
        #item 1808
        puts $fhandle $lines
        puts $fhandle "$indent\}"
    }
}

proc print_procs { weak_signature fhandle procedures class_name depth } {
    foreach procedure $procedures {
        p.print_proc $weak_signature $fhandle $procedure $class_name $depth
    }
}

proc p.print_to_file { fhandle functions header class footer } {
	set version [ version_string ]
	puts $fhandle \
	    "# Autogenerated with DRAKON Editor $version"

	puts $fhandle ""
	puts $fhandle "package require nx"
	puts $fhandle ""
	if { $header != "" } {
		puts $fhandle $header
	}

	puts $fhandle $class

	init_current_file $fhandle
	gen_tcl::generate_data_struct

    set public    [ lfilter_user $functions gen_java::method_of_access "public"    ]
    set none      [ lfilter_user $functions gen_java::method_of_access "none"      ]
    set protected [ lfilter_user $functions gen_java::method_of_access "protected" ]
    set private   [ lfilter_user $functions gen_java::method_of_access "private"   ]

	print_procs 0 $fhandle $public "" 1
	print_procs 0 $fhandle $protected "" 1
	print_procs 0 $fhandle $private "" 1
	print_procs 0 $fhandle $none "" 1

    if {$class != ""} {
        puts $fhandle "\}"
    }

	puts $fhandle ""
	puts $fhandle $footer
}

}

proc classify_keywords { keywords name } {
    set errors {}

    set access [ gen_cpp::find_keywords $keywords { private public protected } ]

    set _sw7500000_ [ llength $access ]

    if {($_sw7500000_ == 0) || ($_sw7500000_ == 1)} {
        
    } else {

        lappend errors "$name: inconsistent access: $access"
    }

    set dispatch [ gen_cpp::find_keywords $keywords { -debug -deprecated -checkalways } ]

    set _sw7620000_ [ llength $dispatch ]

    if {$_sw7620000_ == 0} {

        set dispatch "normal"
    }

    set subtype [ gen_cpp::find_keywords $keywords { method } ]

    set _sw7730000_ [ llength $subtype ]

    if {$_sw7730000_ == 0} {
        #item 771
        set subtype "method"
    } else {

        if {$_sw7730000_ == 1} {
            
        } else {

            lappend errors "$name: inconsistent method type: $subtype"
        }
    }

    if {$access == ""} {
        set access "none"
    }

    array set props {}

    set props(access) $access
    set props(dispatch) $dispatch
    set props(type) $subtype

    set proplist [ array get props ]
    set error_message [ join $errors "\n" ]

    return [ list $error_message $proplist ]
}

proc extract_signature { text name } {

    array set props { 
    	access none 
    	dispatch normal
    	type method
    }
    set error_message ""
    set parameters {}
    set returns ""
    set type "method"

    set lines [ gen::separate_from_comments $text ]

    if {[ llength $lines ] == 0} {
        
    } else {

        set first_line [ lindex $lines 0 ]
        set first [ lindex $first_line 0 ]

        if {$first == "#comment"} {

            set type "comment"
        } else {

            set keywords { 
            	public private protected method
            	-debug -deprecated -checkalways
            }

            set found_keywords [ gen_cpp::find_keywords $first $keywords ]

            if {[ llength $found_keywords ] == 0} {

                set start_index 0

                set count [ llength $lines ]

                set i $start_index
                while { 1 } {

                    if {$i < $count} {
                        
                    } else {
                        break
                    }

                    set current [ lindex $lines $i ]
                    set stripped [ lindex $current 0 ]

                    if {[ string match "returns *" $stripped ]} {

                        set returns [ gen_cpp::extract_return_type $stripped ]
                    } else {

                        lappend parameters $current
                    }

                    incr i
                }
            } else {

                set start_index 1

                set alien_keywords [ gen_cpp::find_not_belonging $first $keywords ]

                if {[ llength $alien_keywords ] == 0} {

                    lassign [ classify_keywords $found_keywords $name ] \
                    	error_message prop_list

                    if {$error_message == ""} {

                        array unset props
                        array set props $prop_list
                        set type $props(type)

                        set count [ llength $lines ]

                        set i $start_index
                        while { 1 } {

                            if {$i < $count} {
                                
                            } else {
                                break
                            }

                            set current [ lindex $lines $i ]
                            set stripped [ lindex $current 0 ]

                            if {[ string match "returns *" $stripped ]} {

                                set returns [ gen_cpp::extract_return_type $stripped ]
                            } else {

                                lappend parameters $current
                            }

                            incr i
                        }
                    } else {
                        
                    }
                } else {

                    set error_message \
                        "$name: Unexpected keywords: $alien_keywords"
                }
            }
        }
    }

	if {$returns == ""} {

		set returns "void"
	} else {
		
	}

    set prop_list [ array get props ]

    set signature [ gen::create_signature $type $prop_list $parameters $returns ]
    set result [ list $error_message $signature ]

    return $result
}

