
gen::add_generator Javascript gen_js::generate_js
gen::add_generator DrakonJS gen_js::generate_clean_js

namespace eval gen_js {

variable keywords {
abstract 	arguments 	boolean 	break 	byte
case 	catch 	char 	class 	const
continue 	debugger 	default 	delete 	do
double 	else 	enum 	eval 	export
extends 	false 	final 	finally 	float
for 	function 	goto 	if 	implements
import 	in 	instanceof 	int 	interface
let 	long 	native 	new 	null
package 	private 	protected 	public 	return
short 	static 	super 	switch 	synchronized
this 	throw 	throws 	transient 	true
try 	typeof 	var 	void 	volatile
while 	with 	yield
}

variable handlers {}

variable variables {}

proc extract_variables { gdb diagram_id } {
	variable variables
	set vars [ gen::extract_variables $gdb $diagram_id  "var" ]
	if {$vars != "" } {
		lappend variables $diagram_id
		lappend variables $vars
	}
}


proc highlight { tokens } {
	variable keywords
	return [ gen_cs::highlight_generic $keywords $tokens ]
}

proc shelf { primary secondary } {
	return "$secondary = $primary;"
}


proc foreach_init { item_id first second } {
	set index_var "_ind$item_id"
	set keys_var "_keys$item_id"
	set coll_var "_col$item_id"
	set length_var "_len$item_id"
	lassign [ parse_key_value $first ] key value
	if { $key == "" } {
		return "var $index_var = 0;\nvar $coll_var = $second;\nvar $length_var = $coll_var.length;"
	} else {
		return "var $index_var = 0;\nvar $coll_var = $second;\nvar $keys_var = Object.keys\($coll_var\); \nvar $length_var = $keys_var.length;"
	}
}

proc foreach_check { item_id first second } {
	set index_var "_ind$item_id"
	set length_var "_len$item_id"
	return "$index_var < $length_var"
}

proc foreach_current { item_id first second } {
	set index_var "_ind$item_id"
	set coll_var "_col$item_id"
	set keys_var "_keys$item_id"
	lassign [ parse_key_value $first ] key value
	if { $key == "" } {
        return "var $first = $coll_var\[$index_var\];"
    } else {
        return "var $key = $keys_var\[$index_var\]; var $value = $coll_var\[$key\];"
    }
}

proc compare { variable constant } {
    return "$variable === $constant"
}

proc foreach_incr { item_id first second } {
	set index_var "_ind$item_id"
	return "$index_var++;"
}

proc parse_key_value { item } {
    set parts [ split $item "," ]
    if { [ llength $parts ] > 1 } {
        set key [ string trim [ lindex $parts 0 ] ]
        set value [ string trim [ lindex $parts 1 ] ]
    } else {
        set value [ string trim [ lindex $parts 0 ] ]
        set key ""
    }
    
    return [ list $key $value ]
}

proc make_callbacks { } {
	set callbacks {}
	
	gen::put_callback callbacks assign			gen_java::assign
	gen::put_callback callbacks compare			gen_js::compare
	gen::put_callback callbacks compare2		gen_js::compare
	gen::put_callback callbacks while_start 	gen_java::while_start
	gen::put_callback callbacks if_start		gen_java::if_start
	gen::put_callback callbacks elseif_start	gen_java::elseif_start
	gen::put_callback callbacks if_end			gen_java::if_end
	gen::put_callback callbacks else_start		gen_java::else_start
	gen::put_callback callbacks pass			gen_java::pass
	gen::put_callback callbacks continue		gen_java::p.continue
	
	gen::put_callback callbacks return_none		gen_js::p.return_none
	
	gen::put_callback callbacks block_close		gen_java::block_close
	gen::put_callback callbacks comment			gen_java::commentator
	
	gen::put_callback callbacks bad_case		gen_js::p.bad_case
	gen::put_callback callbacks for_init		gen_js::foreach_init
	gen::put_callback callbacks for_check		gen_js::foreach_check
	gen::put_callback callbacks for_current		gen_js::foreach_current
	gen::put_callback callbacks for_incr		gen_js::foreach_incr
	gen::put_callback callbacks body			gen_js::generate_body
	gen::put_callback callbacks signature		gen_js::extract_signature
	gen::put_callback callbacks and				gen_java::p.and
	gen::put_callback callbacks or				gen_java::p.or
	gen::put_callback callbacks not				gen_java::p.not
	gen::put_callback callbacks break			"break;"
	gen::put_callback callbacks declare			gen_js::p.declare
	gen::put_callback callbacks for_declare		gen_js::for_declare
	gen::put_callback callbacks shelf		gen_js::shelf
	
    gen::put_callback callbacks change_state 	gen_js::change_state
    gen::put_callback callbacks shutdown 	""
    gen::put_callback callbacks fsm_merge   0
    
	return $callbacks
}

proc extract_signature { text name } {
	set lines [ gen::separate_from_comments $text ]
	set first_line [ lindex $lines 0 ]
	set first [ lindex $first_line 0 ]
	if { $first == "#comment" } {
		return [ list {} [ gen::create_signature "comment" {} {} {} ]]
	}

    variable handlers
    set is_handler [ contains $handlers $name ]
    
	set parameters {}
	if { $is_handler } {
        lappend parameters {self {}}
	}
	foreach current $lines {
        if { $is_handler } {
            set left [ lindex $current 0 ]
            if { $left == "private" || $left == "state machine" } {
                continue
            }
        }
		lappend parameters $current
	}

	return [ list {} [ gen::create_signature procedure public $parameters "" ] ]
}


proc change_state { next_state machine_name returns } {
    #item 1832
    
    if {$next_state == ""} {
        #item 1836
        set change "self.state = null;"
    } else {
        #item 1835
        set change "self.state = \"${next_state}\";"
    }
    
    if {$returns == {}} {
		return $change
	} else {
		set output [lindex $returns 1]
		return "$change\n$output"
	}
}

proc p.declare { type name value } {
	return "var $name = $value;"
}

proc generate_body { gdb diagram_id start_item node_list sorted incoming } {
	set callbacks [ make_callbacks ]
	return [ cbody::generate_body $gdb $diagram_id $start_item $node_list \
		$sorted $incoming $callbacks ]
}


proc p.return_none { } {
	return "return null;"
}

proc p.block_close { output depth } {
	upvar 1 $output result
	set line [ gen::make_indent $depth ]
	append line "\}"
	lappend result $line
}

proc p.bad_case { switch_var select_icon_number } {
    if {[ string compare -nocase $switch_var "select" ] == 0} {
    	return "throw \"Not expected condition.\";"
    } else {	
		return "throw \"Unexpected switch value: \" + $switch_var;"
	}
	
}

proc for_declare { item_id first second } {
	return ""
}

proc generate_js { db gdb filename } {
	generate $db $gdb $filename 0
}

proc generate_clean_js { db gdb filename } {
	generate $db $gdb $filename 1
}


proc generate { db gdb filename is_clean} {
    # prepare
    
	variable variables
	set variables {}    
    
	set callbacks [ make_callbacks ]
	lassign [ gen::scan_file_description $db { header footer } ] header footer
	
	# state machines
	
    set machines [ sma::extract_many_machines $gdb $callbacks ]
     
    variable handlers
    set handlers [ append_sm_names $gdb ]
    set machine_ctrs [ make_machine_ctrs $gdb $machines ]

    #set machine_decl [ make_machine_declares $machines ]	
    set machine_decl {}
	
	# fix
	
    set diagrams [ $gdb eval {
        select diagram_id from diagrams } ]
    
    set keys {":" "\{" "\}"}
    
    foreach diagram_id $diagrams {
		if {$is_clean} {
			extract_variables $gdb $diagram_id
			gen::rewrite_clean $gdb $diagram_id $keys
		}
        gen::fix_graph_for_diagram $gdb $callbacks 1 $diagram_id
    }

    if { [ graph::errors_occured ] } { return }
    
    # generate
    
	set use_nogoto 1
	set functions [ gen::generate_functions $db $gdb $callbacks $use_nogoto ]
	
	set functions [ build_tasks $functions ]

	if { [ graph::errors_occured ] } { return }

    # write output
    
	set hfile [ replace_extension $filename "js" ]
	set f [ open_output_file $hfile ]
	catch {
		p.print_to_file $f $functions $header $footer $machine_decl $machine_ctrs
	} error_message

	catch { close $f }
	if { $error_message != "" } {
		error $error_message
	}
}

proc make_machine_ctrs { gdb machines } {
    set result ""
    foreach machine $machines {
        set states [ dict get $machine "states"]
        set param_names [ dict get $machine "param_names" ]
        set messages [ dict get $machine "messages" ]
        set name [ dict get $machine "name" ]

        set ctr [make_machine_ctr $gdb $name $states $param_names $messages]

        append result "\n$ctr\n"
    }
    return $result
}

proc get_function { gdb name state message} {
    set diagram_name "${name}_${state}_${message}"
    set found [ $gdb onecolumn {
        select count(*)
        from diagrams
        where name = :diagram_name
    } ]
    
    if { $found == 1 } {
        return $diagram_name
    } else {
        return "function\(\) \{\}"
    }
}

proc make_machine_ctr { gdb name states param_names messages } {
    set lines {}
    
    if {0} {
		foreach state $states {
			foreach message $messages {
				set fun [ get_function $gdb $name $state $message ]
				lappend lines \
				 "${name}_state_${state}.$message = $fun;"            
			}
			lappend lines "${name}_state_${state}.state_name = \"$state\";"
		}
	}
    
    
    set params [ lrange $param_names 1 end ]
    set params_str [ join $params ", " ]

    lappend lines "function ${name}\(\) \{"

    lappend lines \
     "  var _self = this;"
    lappend lines \
     "  _self.type_name = \"$name\";"

    set first [ lindex $states 0 ]
    lappend lines "  _self.state = \"${first}\";"
    
    foreach message $messages {
        lappend lines \
         "  _self.$message = function\($params_str\) \{"
        
        lappend lines \
         "    var _state_ = _self.state;"
        set first 1
        foreach state $states {

			set call ""
			set method [gen::make_normal_state_method $name $state $message ]
			if {[gen::diagram_exists $gdb $method ]} {
				set call "      return ${method}(_self, $params_str\);"
			} else {
				set method [gen::make_default_state_method $name $state]
				if {[gen::diagram_exists $gdb $method ]} {
					set call "      return ${method}(_self, $params_str\);"
				}				
			}

			if { $call != "" } {
				if {$first} {
					lappend lines \
					 "    if \(_state_ == \"$state\"\) \{"
				} else {
					lappend lines \
					 "    else if \(_state_ == \"$state\"\) \{"				
				}
				
				lappend lines $call				
				
				lappend lines \
				 "    \}"
				 
				 set first 0
			}
		}
        lappend lines \
         "    return null;"
        lappend lines \
         "  \};"
    }
    
    lappend lines \
     "\}"
    
    return [ join $lines "\n" ]
}

proc make_machine_declares { machines } {
    set lines {}
    foreach machine $machines {
        set states [ dict get $machine "states"]
        set name [ dict get $machine "name" ]
        foreach state $states {
            lappend lines "var ${name}_state_${state} = \{\};"
        }
    }
    return [ join $lines "\n" ]
}

proc append_sm_names { gdb } {
    #item 1852
    set ids {}
    #item 1825
    $gdb eval {
    	select diagram_id, original, name
    	from diagrams
    	where original is not null
    } {
    	set sm_name $original
    	set new_name "${sm_name}_$name"
    	$gdb eval {
    		update diagrams
    		set name = :new_name
    		where diagram_id = :diagram_id
    	}
    	lappend ids $new_name
    }
    #item 1853
    return $ids
}

proc is_closure { name } {
    if { [ string match "* function" $name ] } {
        return 1
    }
    
    if { [ string match "*=function" $name ] } {
        return 1
    }
    
    return 0
}    

proc build_declaration { name signature } {
	lassign $signature type access parameters returns
	if { [ is_closure $name ] } {
        set result "$name\("
    } else {
        set result "function $name\("
    }
    
	set params [ gen::get_param_names $parameters ]
	set params_list [ join $params ", " ]
	append result $params_list
	append result "\) \{"
	return $result
}

proc p.print_to_file { fhandle functions header footer machine_decl machine_ctrs } {
	variable variables
	if { $header != "" } {
		puts $fhandle $header
	}
	set version [ version_string ]
	puts $fhandle \
	    "// Autogenerated with DRAKON Editor $version"

    puts $fhandle $machine_decl
	foreach function $functions {
		lassign $function diagram_id name signature body
		set name [ normalize_name $name ]
		set type [ lindex $signature 0 ]
		if { $type != "comment" } {
			puts $fhandle ""
			set declaration [ build_declaration $name $signature ]
			puts $fhandle $declaration
			set vars [gen::print_variables $variables $diagram_id $signature "var"]
			if {$vars != "" } {
				puts $fhandle $vars
			}
			set lines [ gen::indent $body 1 ]
			puts $fhandle $lines
			puts $fhandle "\}"
		}
	}
	puts $fhandle $machine_ctrs
	puts $fhandle ""
	puts $fhandle $footer
}





}

