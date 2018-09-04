
gen::add_generator Erlang gen_erl::generate

namespace eval gen_erl {

variable tdb ""


proc change_state { text state returns } {

	if { $state == "" } {
		set state "final_state"
	}
	set lines [ split $text "\n" ]
	set beginning [ lrange $lines 0 end-1]
	set last [ lindex $lines end ]
	set last_t [ string trim $last ]

	set last2 "\{next_state, $state, $last_t\}"
	
	lappend beginning $last2
	set result [ join $beginning "\n" ]

	return $result
}



proc shelf { primary secondary } {
	return "$secondary = $primary"
}


proc foreach_init { item_id first second } {
	return ""
}

proc foreach_check { item_id first second } {
	return ""
}

proc foreach_current { item_id first second } {
	return ""
}

proc foreach_incr { item_id first second } {
	return ""
}

proc make_callbacks { } {
	set callbacks {}
	
	gen::put_callback callbacks assign			gen_erl::p.assign
	gen::put_callback callbacks compare			gen_erl::p.compare
	gen::put_callback callbacks compare2		gen_erl::p.compare2
	gen::put_callback callbacks while_start 	gen_erl::p.while_start
	gen::put_callback callbacks if_start		gen_erl::p.if_start
	gen::put_callback callbacks elseif_start	gen_erl::p.elseif_start
	gen::put_callback callbacks if_end			gen_erl::p.if_end
	gen::put_callback callbacks else_start		gen_erl::p.else_start
	gen::put_callback callbacks pass			gen_erl::p.pass
	gen::put_callback callbacks continue		gen_erl::p.continue
	gen::put_callback callbacks return_none		gen_erl::p.return_none
	gen::put_callback callbacks block_close		gen_erl::p.block_close
	gen::put_callback callbacks comment			gen_erl::p.comment
	gen::put_callback callbacks bad_case		gen_erl::p.bad_case
	gen::put_callback callbacks for_init		gen_erl::foreach_init
	gen::put_callback callbacks for_check		gen_erl::foreach_check
	gen::put_callback callbacks for_current		gen_erl::foreach_current
	gen::put_callback callbacks for_incr		gen_erl::foreach_incr
	gen::put_callback callbacks body			gen_erl::generate_body
	gen::put_callback callbacks signature		gen_erl::extract_signature
	gen::put_callback callbacks and				gen_erl::p.and
	gen::put_callback callbacks or				gen_erl::p.or
	gen::put_callback callbacks not				gen_erl::p.not
	gen::put_callback callbacks break			"break"
	gen::put_callback callbacks declare			gen_erl::p.declare
	gen::put_callback callbacks for_declare		gen_erl::for_declare
	
	gen::put_callback callbacks line_end		","
	gen::put_callback callbacks enforce_nogoto	gen_erl::enforce_nogoto
	gen::put_callback callbacks inspect_tree	gen_erl::inspect_tree
	gen::put_callback callbacks shelf			gen_erl::shelf
	
	gen::put_callback callbacks change_state	gen_erl::change_state
	gen::put_callback callbacks shutdown ""
	gen::put_callback callbacks fsm_merge   1
	
	gen::put_callback callbacks select				gen_erl::select
	gen::put_callback callbacks case_value			gen_erl::case_value
	gen::put_callback callbacks case_else			gen_erl::case_else
	gen::put_callback callbacks case_end			gen_erl::case_end
	gen::put_callback callbacks select_end			gen_erl::select_end

	gen::put_callback callbacks select_gen_default	0
	
	return $callbacks
}

proc p.declare { type name value } {
	return ""
}

proc generate_body { gdb diagram_id start_item node_list sorted incoming } {
	set callbacks [ make_callbacks ]
	return [ cbody::generate_body $gdb $diagram_id $start_item $node_list \
		$sorted $incoming $callbacks ]
}

proc p.and { left right } {
	return "($left) andalso ($right)"
}

proc p.or { left right } {
	return "($left) orelse ($right)"
}

proc p.not { operand } {
	return "not ($operand)"
}

proc p.assign { variable value } {
	return "$variable = $value"
}

proc p.compare { variable value } {
	return "$variable =:= $value"
}

proc p.compare2 { variable value } {
	return "$variable =:= $value"
}

proc select { text } {
	if { $text == "receive" } {
		return "receive"
	} else {
		return "case $text of"
	}
}

proc case_value { text } {
	return "$text ->"
}

proc case_else { } {
	return "_ ->"
}

proc case_end { next_text } {
	if { [string match "after *" $next_text] } {
		return ""
	} else {
		return ";"
	}
}

proc select_end { } {
	return "end"
}



proc p.while_start { } {
	return ""
}

proc p.if_start { } {
	return "case "
}

proc p.elseif_start { } {
	return ""
}

proc p.if_end { } {
	return " of true -> "
}

proc p.else_start { } {
	return "; false ->"
}
proc p.pass { } {
	return "\[\]"
}

proc p.continue { } {
	return ""
}

proc p.return_none { } {
	return ""
}

proc p.block_close { output depth } {
	upvar 1 $output result
	set line [ gen::make_indent $depth ]
	append line "end"
	lappend result $line
}

proc p.comment { line } {
	return "% $line"
}

proc p.bad_case { switch_var select_icon_number } {
	return "throw\(\"Unexpected switch value\"\)"
}

proc for_declare { item_id first second } {
	return ""
}

proc is_standalone { gdb } {
	set diagram_id [ $gdb onecolumn {
		select diagram_id
		from diagrams
		where name = 'state machine' } ]

	if { $diagram_id == "" } { return 0 }
	
	set params_icon [ $gdb onecolumn {
		select params_icon
		from branches
		where diagram_id = :diagram_id 
		and ordinal = 1 } ]


	if { $params_icon == "" } { return 0 }
	
	set text [ $gdb onecolumn {
		select text
		from vertices
		where vertex_id = :params_icon } ]
	
	set text [ string trim $text ]

	if { $text == "standalone" } {
		return 1
	}

	return 0
}

proc generate { db gdb filename } {
	variable tdb
	set tdb $gdb
	
	set callbacks [ make_callbacks ]
	set standalone [ is_standalone $gdb ]

	lassign [ gen::scan_file_description $db { header footer } ] header footer

	set machine [ sma::extract_machine $gdb $callbacks ]

    set diagrams [ $gdb eval {
    	select diagram_id from diagrams } ]

	foreach diagram_id $diagrams {
        if {[mwc::is_drakon $diagram_id]} {
            gen::fix_graph_for_diagram_to $gdb $callbacks 1 $diagram_id
        }
	}

	set use_nogoto 1
	set functions [ gen::generate_functions_core $db $gdb $callbacks $use_nogoto 1 ]

	if { [ graph::errors_occured ] } { return }

	set trees [ tab::generate_trees $gdb ]
	foreach tree $trees {
		print_tree $filename $tree
	}

	set hfile [ replace_extension $filename "erl" ]
	set module [ file tail [ string map {".drn" ""} $filename ] ]
	set f [ open_output_file $hfile ]
	catch {
		p.print_to_file $gdb $f $functions $header $footer $module $machine $standalone
	} error_message

	catch { close $f }
	if { $error_message != "" } {
		error $error_message
	}
}

proc build_declaration { name signature } {
	lassign $signature type access parameters returns
	set result "$name\("
	set params {}
	foreach parameter $parameters {
		lappend params [ lindex $parameter 0 ]
	}
	set params_list [ join $params ", " ]
	append result $params_list
	append result "\) ->"
	return $result
}

proc skip_diagram { name } {
	if { $name == "CleanUp" } {
		return 1
	}
	
	return 0
}

proc p.print_to_file { gdb fhandle functions header footer module machine standalone } {

	set version [ version_string ]
	puts $fhandle \
	    "% Autogenerated with DRAKON Editor $version"

	puts $fhandle ""
	puts $fhandle "-module\($module\)."
	
	if { $machine != "" && !$standalone } {
		puts $fhandle "-behaviour(gen_fsm)."
	}
	set exported {}
	foreach function $functions {
		lassign $function diagram_id name signature body
		if { [ skip_diagram $name ] } { continue }
		if { [ is_machine_proc $gdb $diagram_id ] } { continue }
		set access [ lindex $signature 1 ]
		if { $access == "public" } {
			set arguments [ lindex $signature 2 ]
			set count [ llength $arguments ]
			lappend exported "$name/$count"
		}
	}
	
	print_machine_headers $fhandle $gdb $machine $standalone
	
	if { [ llength $exported ] > 0 } {
		set exp_list [ join $exported ", " ]
		puts $fhandle "-export\(\[$exp_list\]\)."
	}
	
	if { $header != "" } {
		puts $fhandle $header
	}

	foreach function $functions {
		lassign $function diagram_id name signature body
		lassign [ $gdb eval {
			select state, message_type, ordinal, is_default
			from diagrams
			where diagram_id = :diagram_id } ] state message ordinal is_default
		
		if { [ skip_diagram $name ] } { continue }
		if { [ is_machine_proc $gdb $diagram_id ] } { continue }

		
		set type [ lindex $signature 0 ]
		if { $type != "comment" } {
			puts $fhandle ""
			set declaration [ build_declaration $name $signature ]
			puts $fhandle $declaration
			set lines [ gen::indent $body 1 ]
			puts $fhandle $lines
			puts $fhandle "."
		}
	}
	print_machine_methods $fhandle $gdb $machine $functions $standalone
	puts $fhandle ""
	puts $fhandle $footer
}

proc print_machine_headers { fhandle gdb machine standalone } {
	if { $machine == "" } { return }
	if { $standalone } {
		puts $fhandle "-export\(\[create/1\]\)."
		puts $fhandle "-export\(\[send_event/2\]\)."
		puts $fhandle "-export\(\[get_state/1\]\)."
		puts $fhandle "-export\(\[get_data/1\]\)."		
	} else {				
		set states [ get_states $gdb ]
		foreach state $states {
			puts $fhandle "-export\(\[$state/2\]\)."
		}
		if { ![ has_init $gdb ] } {
			puts $fhandle "-export\(\[init/1\]\)."
		}
		puts $fhandle "-export\(\[start_link/2\]\)."
	
		if { [ dict get $machine "last" ] } {
			puts $fhandle "-export\(\[final_state/2\]\)."
		}
	}	
}

proc get_default { gdb state } {
	set found [ $gdb onecolumn {
		select diagram_id
		from diagrams
		where state = :state
		and is_default = 1 } ]
	
	return $found
}

proc print_machine_methods { fhandle gdb machine functions standalone } {
	if { $machine == "" } { return }
	
	set states [ get_states $gdb ]
	foreach state $states {
		print_state_method $fhandle $gdb $functions $state
	}
	
	if { [ dict get $machine "last" ] } {
		print_final_state $fhandle
	}
	
	set first_state [ get_first_state $machine ]
			
	if { $standalone } {
		puts $fhandle ""	
		puts $fhandle "create\(State) ->"
		puts $fhandle "    \{state_machine, $first_state, State\}."
		puts $fhandle ""	
		puts $fhandle "get_state\(Machine) ->"
		puts $fhandle "    \{state_machine, StateName, _\} = Machine,"
		puts $fhandle "    StateName."		
		puts $fhandle ""	
		puts $fhandle "get_data\(Machine) ->"
		puts $fhandle "    \{state_machine, _, State \} = Machine,"
		puts $fhandle "    State."

		print_send_event $fhandle $gdb $states

	} else {					

		puts $fhandle "\n"
		if { ![ has_init $gdb ] } {
			puts $fhandle "init\(State\) ->"
			puts $fhandle "    \{ok, $first_state, State\}.\n"
		}
		puts $fhandle "start_link\(State, Options\) ->"
		puts $fhandle "    gen_fsm:start_link\(?MODULE, State, Options\).\n"
	}
}

proc print_send_event { fhandle gdb states } {
	puts $fhandle ""
	puts $fhandle "send_event\(Machine, Event\) ->"
	puts $fhandle "    {state_machine, StateName, State} = Machine,"
	puts $fhandle "    NewState = "	
	puts $fhandle "    case StateName of"
	foreach state $states {
		puts $fhandle "    $state ->"
		puts $fhandle "        $state\(Event, State\);"
	}
	puts $fhandle "    _ ->"
	puts $fhandle "        throw\(\{invalid_state, \"Unsupported state\"\}\)"
	puts $fhandle "    end,"
    puts $fhandle "    {next_state, NextStateName, NextState} = NewState,"
    puts $fhandle "    {state_machine, NextStateName, NextState}."
}

proc has_init { gdb } {
	set found [ $gdb onecolumn {
		select count(*)
		from diagrams
		where name = 'init' } ]
		
	return $found
}

proc get_first_state { machine } {
	set boiler [ dict get $machine "boiler" ]
	return [ lindex $boiler 0 ]
}

proc print_state_method { fhandle gdb functions state} {
	array set funs {}
	foreach function $functions {
		lassign $function diagram_id name signature body
		set funs($diagram_id) $function
	}
	
	set default_dia [ get_default $gdb $state ]
	
	puts $fhandle "$state\(Message_, State\) ->"
	puts $fhandle "    case Message_ of"
	
	set cases [ get_cases $gdb $state ]
	
	foreach case $cases {
		set message [ get_message $gdb $case ]
		lassign $funs($case) _ _ _ body		
		puts $fhandle "    $message ->"
		print_body $fhandle $body
		puts $fhandle "    ;"		
	}
	
	puts $fhandle "    _ ->"
	if { $default_dia == "" } {
		puts $fhandle "        throw\(\{invalid_state, \"Message not supported by state '$state'.\"\}\)"		
	} else {
		lassign $funs($default_dia) _ _ _ body	
		print_body $fhandle $body
	}
	puts $fhandle "    end"
	puts $fhandle "."
}

proc get_message { gdb diagram_id } {
	return [ $gdb onecolumn {
		select message_type
		from diagrams
		where diagram_id = :diagram_id } ]
}

proc get_cases { gdb state } {
	return [ $gdb eval {
		select diagram_id
		from diagrams
		where state = :state
		and is_default = 0
		order by ordinal } ]
}

proc print_body { fhandle body } {
	set lines [ gen::indent $body 2 ]
	puts $fhandle $lines	
}

proc print_final_state { fhandle } {
	puts $fhandle "final_state\(_, _\) ->"
	puts $fhandle "    throw\(\{invalid_state, \"Cannot accept messages in the final state.\"\}\)"
	puts $fhandle "."
}

proc get_states { gdb } {
	return [ $gdb eval {
		select state
		from diagrams
		where state is not null and state != ''
		group by state } ]
}

proc is_machine_proc { gdb diagram_id } {
	set state [ $gdb onecolumn {
		select state
		from diagrams
		where diagram_id = :diagram_id } ]
	
	if { $state == "" } {
		return 0
	} else {
		return 1
	}
}


proc extract_signature { text name } {
	set lines [ gen::separate_from_comments $text ]
	set count [ llength $lines ]
	if { $count == 0 } {
		set access "internal"
		set type "function"
		set parameters {}
	} else {
		set first_line [ lindex $lines 0 ]
		set first [ lindex $first_line 0 ]
		if { $first == "#comment" } {
			set access "internal"
			set type "comment"
			set parameters {}
		} else {
			if { $first == "public" } {
				set i 1
				set access "public"
			} else {
				set i 0
				set access "internal"
			}
			set type "function"
			set parameters {}
			while { $i < $count } {
				set current [ lindex $lines $i ]
				lappend parameters $current
				
				incr i
			}
		}
	}

	return [ list {} [ gen::create_signature $type $access $parameters "" ] ]
}


proc complain_dia { name message } {
	variable tdb
	set id [ $tdb onecolumn {
		select diagram_id
		from diagrams
		where name = :name } ]

	graph::p.error $id {} $message
}

proc enforce_nogoto { name } {
	complain_dia $name "Could not generate code for function '$name'.\nTry splitting it into smaller parts."
}

proc inspect_tree { node name } {
	set length [ llength $node ]
	
	for { set i 1 } { $i < $length } { incr i } {
		set current [ lindex $node $i ]
		if { [ string is integer $current ] } {
		
		} elseif { $current == "break" || $current == "continue" ||
			[ lindex $current 0 ] == "loop" } {
			
			complain_dia $name "Function '$name' contains a loop.\nErlang does not support loops."
		} elseif { [ lindex $current 0 ] == "if" } {		
			set then_node [ lindex $current 3 ]
			set else_node [ lindex $current 2 ]
			inspect_tree $then_node $name
			inspect_tree $else_node $name
		}
	}
}

proc print_tree { filename tree } {
	set folder [ file dirname $filename ]
	no_workers_supervise $tree
	print_supervisor $folder $tree
}

proc print_supervisor { folder node } {
	lassign $node id type header text children
	if { $type == "action" } {
		return
	}
	
	set name [ first_line $header ]
	
	set path "$folder/$name.erl"

	
	set text_lines [ split $text "\n" ]
	
	set down_options [ parse_ini $text_lines ]
	if { $down_options == {} } { return }
		
	check_present $down_options $name {strategy max_restart max_time}
	


	set child_specs {}
	foreach child $children {
		lassign $child _ ctype cheader ctext
		if { $ctype == "action" } {
			set node_type "worker"
			set cprops $ctext
		} else {
			set node_type "supervisor"		
			set cprops $cheader
		}
		set cname [ first_line $cprops ]
		set all_child_lines [ split $cprops "\n" ]
		set child_lines [ lrange $all_child_lines 1 end ]
		set child_ops [ parse_ini $child_lines ]
		check_present $child_ops $cname {restart shutdown}
		lappend child_specs [ list $cname $node_type $child_ops ]
	}
	
	print_super_core $path $name $down_options $child_specs
	
	foreach child $children {
		print_supervisor $folder $child
	}
}

proc print_super_core { path name specs child_specs } {
	set strategy [ dict get $specs "strategy" ]
	set max_restart [ dict get $specs "max_restart" ]
	set max_time [ dict get $specs "max_time" ]
	
	set fh [ open $path "w" ]
	puts $fh "-module\($name\)." 
	puts $fh "-behaviour\(supervisor\)."
	puts $fh ""
	puts $fh "-export\(\[start_link/0\]\)."
	puts $fh "-export\(\[init/1\]\)."
	puts $fh ""
	puts $fh "start_link() -> supervisor:start_link\(\{local, ?MODULE\}, ?MODULE, \[\]\)."
	puts $fh ""
	puts $fh "init\(_\) ->"	
	puts $fh "    RestartStrategy = \{$strategy, $max_restart, $max_time\},"
	puts $fh "    Children = \["
	set child_lines {}
	foreach cspec $child_specs {
		lassign $cspec cname type cprops
		set restart [ dict get $cprops "restart"]
		set shutdown [ dict get $cprops "shutdown"]		
		lappend child_lines "       \{$cname, \{$cname, start_link, \[\]\}, $restart, $shutdown, $type, \[$cname\]\}"
	}
	set ch [ join $child_lines ",\n" ]
	puts $fh $ch
	puts $fh "    \],"	
	puts $fh "    \{ok, \{RestartStrategy, Children\}\}."
	puts $fh ""	
	close $fh
}

proc check_present { options name properties } {
	foreach prop $properties {
		if { ![dict exists $options $prop] } {
			error "'$prop' property is missing in '$name'"
		}
	}
}

proc parse_ini { lines } {
	set result {}
	foreach line $lines {
		set trimmed [ string trim $line ]
		set parts [ split $trimmed "=" ]
		if { [ llength $parts ] < 2 } {
			continue
		}
		
		set first [ lindex $parts 0 ]
		set name [ string trim $first ]
		if { $name == "" } {
			continue
		}
		
		set first_len [ string length $first ]
		incr first_len
		
		set rest [ string range $line $first_len end ]
		set value [ string trim $rest ]
		lappend result $name $value
	}
	return $result
}

proc first_line { text } {
	set lines [ split $text "\n" ]
	return [ string trim [ lindex $lines 0 ]]
}

proc no_workers_supervise { node } {
	lassign $node id type header text children
	if { $type == "action" } {
		if { $children != {} } {
			set name [ first_line $text ]
			error "Worker '$name' has children."
		}
	} else {
		foreach child $children {
			no_workers_supervise $child
		}
	}
}

}

