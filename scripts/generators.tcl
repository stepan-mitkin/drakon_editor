

proc load_generators {} {
	global script_path
	set scripts [ glob "$script_path/generators/*.tcl" ]
	foreach script $scripts {
	  source $script
	}		
}

namespace eval gen {
array set generators {}

proc get_generators {} {
	variable generators
	return [ array get generators ]
}

proc add_generator { language generator } {
	variable generators
	if { [ info exists generator($language) ] } {
		error "Generator for language $language already registered."
	}
	set generators($language) $generator
}

proc p.shout { message } {
	mw::set_status $message
	tk_messageBox -parent . -message $message -type ok
}

proc report_error { diagram_id items message } {
	graph::p.error $diagram_id $items $message
	error $message
}

proc get_start_icon { gdb diagram_id } {
	return [ $gdb onecolumn {
		select start_icon
		from branches
		where diagram_id = :diagram_id
			and ordinal = 1 } ]
}



proc generate { } {
	variable generators

	array set properties [ mwc::get_file_properties ]
	if { ![ info exists properties(language) ] } {
		mw::set_status "Language not configured, showing file properties."
		fprops::show_dialog gen::generate
		return
	}
	
	set language $properties(language)
	mw::set_status "Generating code for '$language' language..."
	update

	if { ![ info exists generators($language) ] } {
		p.shout "No generator for language '$language'."
		return
	}

	lassign $generators($language) generator extension
	
	
	# That namespace is used by some procedures (p.separate_line) to store some variebles for current file generation.
	namespace eval current_file_generation_info {}
	set current_file_generation_info::language $language
	set current_file_generation_info::generator $generator
	
	
	set db [ mwc::get_db ]

	mw::show_errors
	
	graph::verify_all $db

	if { ![ graph::errors_occured ] } {
		if { [ catch { p.do_generate $generator $language } result ] } {
			if { ![ graph::errors_occured ] } {
				mw::show_red_result
				p.shout "Error occurred: $result"
				puts "Error info $result\nFull info: $::errorInfo"
				return
			}
		}
	}

	mw::get_errors
}


proc generate_no_gui { dst_filename } {
	variable generators
	
	set db [ mwc::get_db ]

	array set properties [ mwc::get_file_properties ]
	if { ![ info exists properties(language) ] } {
		puts "Language not configured. Choose a language."
		puts "In main menu: File / File properties..."
		exit 1
	}
	
	set language $properties(language)

	if { ![ info exists generators($language) ] } {
		puts "No generator for language '$language'."
		exit 1
	}

	lassign $generators($language) generator extension
	
	
	# That namespace is used by some procedures (p.separate_line) to store some variebles for current file generation.
	namespace eval current_file_generation_info {}
	set current_file_generation_info::language $language
	set current_file_generation_info::generator $generator
	
	
	graph::verify_all $db

	if { ![ graph::errors_occured ] } {
		if { [ catch { p.do_generate $generator $language $dst_filename } result ] } {
		puts $::errorInfo
			if { ![ graph::errors_occured ] } {
				puts $result
			}
		}
	}
	

	set error_list [ graph::get_error_list ]

	if { [ llength $error_list ] != 0 } {
		foreach error_line $error_list {
			puts $error_line
		}
		return 0
	}
	return 1
}


proc p.do_generate { generator language { filename "" } } {
	global g_filename
	set db [ mwc::get_db ]
	set gdb "gdb"
	if { $filename == "" } {
		set filename $g_filename
	}
	$generator $db $gdb $filename
	if { [ graph::errors_occured ] } {
		mw::set_status "Errors occured."
		mw::get_errors
	} else {
		mw::set_status "Code generation for '$language' language complete."
	}
}

proc p.try_extract_header { line } {
	set trimmed [ string trim $line ]
	set length [ string length $trimmed ]
	if { $length < 7 } { return "" }
	set begin [ string range $trimmed 0 2 ]
	set end [ string range $trimmed end-2 end ]
	if { $begin != "===" || $end != "===" } { return "" }
	set middle [ string range $trimmed 3 end-3 ]
	set header [ string trim $middle ]
	return $header
}

proc process_shelf { gdb item_id shelf_proc } {
	lassign [ $gdb eval {
		select text, text2
		from items
		where item_id = :item_id
	} ] text text2
	
	set new_text [ $shelf_proc $text $text2 ]
	

	
	$gdb eval {
		update vertices
		set text = :new_text,
			type = 'action'
		where item_id = :item_id
	}
}

proc fix_graph_stage_1 { gdb callbacks append_semicolon diagram_id } {
	fix_graph_stage_1_core $gdb $callbacks $append_semicolon $diagram_id 1
}


proc extract_rules { gdb } {
	variable paths
	variable paths2
	set paths {}	
	set paths2 {}
	
	set diagrams [ $gdb eval {
		select diagram_id from diagrams } ]
	
	set rules {}
	
	foreach diagram_id $diagrams {
		fix_diagram_for_rules $gdb $diagram_id
	}

	split_interleaving_paths
	
	return [lsort -unique $paths2]
}

proc split_interleaving_paths {} {
	variable paths
	
	foreach path $paths {
		lassign $path signature steps
		split_interleaving $signature $steps 0 "if" {} {}
	}	
}


proc finish_split_path { signature conditions actions } {
	variable paths2
	
	set diagram_id [ lindex $signature 2 ]
	if { [llength $actions] == 0 } {
		return
	}

	if { [llength $conditions] == 0 } {
		report_error $diagram_id {} "There must be a condition before an action"
		return
	}		
	
	set path [ list signature $signature conditions $conditions actions $actions ]
	lappend paths2 $path
}

proc split_interleaving { signature steps i state conditions actions } {
	if { $i >= [llength $steps] } {
		finish_split_path $signature $conditions $actions
	} else {
		set item [ lindex $steps $i ]
		set type [ lindex $item 0 ]
		incr i
		if {$state == "if"} {
			if {$type == "if"} {
				lappend conditions $item
				split_interleaving $signature $steps $i "if" $conditions $actions
			} else {
				lappend actions $item
				split_interleaving $signature $steps $i "action" $conditions $actions				
			}
		} else {
			if {$type == "if"} {
				finish_split_path $signature $conditions $actions
				lappend conditions $item
				split_interleaving $signature $steps $i "if" $conditions {}
			} else {
				lappend actions $item
				split_interleaving $signature $steps $i "action" $conditions $actions				
			}			
		}	
	}
}


proc get_start_info { gdb diagram_id } {
	lassign [ $gdb eval {
		select start_icon, params_icon
		from branches 
		where diagram_id = :diagram_id
			and ordinal = 1
	} ] start_icon params_icon

	set name [ $gdb onecolumn { select name from diagrams where diagram_id = :diagram_id } ]


	if { $params_icon == "" } {
		set params_text ""
	} else {
		set params_text [ $gdb onecolumn {
			select text from vertices where vertex_id = :params_icon } ]
	}
	
	set start_item [ find_start_item $gdb $diagram_id ]	

	return [list $start_icon $params_icon $name $params_text $start_item ]
}

variable paths {}
variable paths2 {}


proc extract_paths { gdb diagram_id } {
	set start_info [ get_start_info $gdb $diagram_id ]
	lassign $start_info start_icon params_icon name params_text start_item
	
	set signature [ list $name $params_text $diagram_id ]
	
	set next [ p.link_dst $gdb $start_icon 1 ]
	extract_paths_from_icon $gdb $diagram_id $signature $next {}
}

proc extract_paths_from_icon { gdb diagram_id signature vertex_id path } {
	variable paths
	lassign [ $gdb eval {
		select text, type, item_id, b
		from vertices
		where vertex_id = :vertex_id } ] text type item_id swapped
	if {$type == "beginend"} {
		lappend paths [ list $signature $path ]
	} elseif { $type == "action" } {
		set item [ list "action" $text ]
		set one [ p.link_dst $gdb $vertex_id 1 ]
		lappend path $item
		extract_paths_from_icon $gdb $diagram_id $signature $one $path
	} elseif { $type == "if"} {
		set one [ p.link_dst $gdb $vertex_id 1 ]
		set two [ p.link_dst $gdb $vertex_id 2 ]
		if { $swapped } {
			set neg1 0
			set neg2 1
		} else {
			set neg1 1
			set neg2 0
		}
		set item1 [ list "if" $text $neg1 ]
		set item2 [ list "if" $text $neg2 ]
		set path1 $path
		set path2 $path
		lappend path1 $item1 
		lappend path2 $item2
		extract_paths_from_icon $gdb $diagram_id $signature $one $path1
		extract_paths_from_icon $gdb $diagram_id $signature $two $path2
	} else {
		report_error $diagram_id $item_id "Unsupported item type"
		return
	}

}

proc fix_diagram_for_rules { gdb diagram_id } {
	
	
	set loops [ $gdb eval {
		select vertex_id
		from vertices
		where type = 'loopstart' 
			and diagram_id = :diagram_id } ]	
			
	if { $loops != {} } {
		report_error $diagram_id "" "Rules cannot have loops"
		return
	}
	
	set selects [ $gdb eval {
		select vertex_id
		from vertices
		where type = 'select' 
			and diagram_id = :diagram_id } ]

	foreach select $selects {
		p.rewire_select $gdb $select $callbacks
	}	
	
	p.clean_tech_vertices $gdb $diagram_id
	
	extract_paths $gdb $diagram_id
}

proc fix_graph_stage_1_core { gdb callbacks append_semicolon diagram_id do_selects } {

	set shelf_proc [ get_callback $callbacks shelf ]
	
	set shelves [ $gdb eval {
		select item_id
		from items
		where diagram_id = :diagram_id
		and type = 'shelf'
	} ]
	
	foreach shelv $shelves {
		process_shelf $gdb $shelv $shelf_proc
	}

	if { $do_selects } {
		set starts [ $gdb eval {
			select vertex_id
			from vertices
			where type = 'loopstart' 
				and diagram_id = :diagram_id } ]

		foreach start $starts {
			p.rewire_loop $gdb $start $callbacks $append_semicolon
		}


		set selects [ $gdb eval {
			select vertex_id
			from vertices
			where type = 'select' 
				and diagram_id = :diagram_id } ]

		foreach select $selects {
			p.rewire_select $gdb $select $callbacks
		}
	}
		
	set ifs [ $gdb eval {
		select vertex_id
		from vertices
		where type = 'if' 
			and diagram_id = :diagram_id } ]
	
	foreach if_id $ifs {
		p.rewire_if $gdb $if_id
	}

	p.clean_tech_vertices $gdb $diagram_id
}


proc get_trimmed_lines { text } {
	set raw_lines [ split $text "\n" ]
	set lines {}
	foreach raw_line $raw_lines {
		set line [string trim $raw_line]
		if { $line != "" } {
			lappend lines $line
		}
	}
	return $lines	
}

proc get_raw_lines { text } {
	set raw_lines [ split $text "\n" ]
	set lines {}
	foreach raw_line $raw_lines {
		set line [string trim $raw_line]
		if { $line != "" } {
			lappend lines $raw_line
		}
	}
	return $lines	
}

proc ends_with_operator { text } {
	set trimmed [ string trim $text ]
	set last [ string range $trimmed end end ]
	set map {, . \{ . \( . - . + . / . * . : . % . ^ .}
	set mapped [ string map $map $last ]
	if {$mapped == "."} {
		return 1
	}
	return 0
}

proc is_lambda { line } {
	set parts [ split $line "=" ]
	if {[llength $parts] != 2} {
		return 0
	}
	set second [string trim [ lindex $parts 1 ]]
	set second_parts [ split $second " " ]

	set part0 [ lindex $second_parts 0]
	if {$part0 == "function"} {
		return 1
	}
	
	return 0
}

proc get_clean_type { text } {
	set raw_lines [ get_raw_lines $text ]
	if { [llength $raw_lines] < 2 } {
		return {}
	}
	set first_whitespace "\[ \t\]*"	
	set lines {}
	set first 1

	foreach raw $raw_lines {
		if {!$first && ![string match $first_whitespace $raw]} {
			return {}
		}
		set first 0
		
		set line [string trim $raw]
		
		if {[ends_with_operator $line]} {
			return {}
		}
		
		lappend lines $line
	}
	
	set first [ lindex $lines 0 ]
	
	if { $first == "return" } {
		set type "struct"
	} elseif { [string match "*=" $first ] } {
		set type "struct"
	} elseif { [is_lambda $first ] } {
		set type "lambda"
	} else {
		set type "proc"
	}	
	
	return [list $type $lines]
}

proc has_operator_chars { text } {
	set map {, . \[ . \] . \( . \) . \" . \' . \{ . \} .}
	set mapped [ string map $map $text ]
	set pattern "*\\.*"
	return [string match $pattern $mapped ]
}

proc get_variable_name { line var_keyword } {
	
	set parts [ split $line "=" ]
	if { [ llength $parts ] < 2 } {
		return ""
	}
	
	set first [ lindex $parts 0 ]
	set first [ string trim $first ]

	if { [has_operator_chars $first ] } {
		return ""
	}	
	
	
	if {[llength $first ] > 1} {
		return ""
	}
	
	return $first	
}

proc get_variables_from_item { text var_keyword } {
	set result {}
	set lines [ get_trimmed_lines $text ]
	foreach line $lines {
		set var_name [ get_variable_name $line $var_keyword ]
		if { $var_name != "" } {
			lappend result $var_name
		}
	}
	return $result
}

proc get_item_text { gdb diagram_id item_id } {
	lassign [ $gdb eval {
		select text
		from items
		where diagram_id = :diagram_id
		and item_id = :item_id
	} ] text
	return $text
}

proc set_item_text { gdb diagram_id item_id text} {
	$gdb eval {
		update items
		set text = :text
		where diagram_id = :diagram_id
		and item_id = :item_id
	}
}

proc clean_proc { lines indent} {
	set first [lindex $lines 0]
	set rest [lrange $lines 1 end]
	set result "$indent${first}\(\n$indent    "
	set rest_text [ join $rest ",\n$indent    "]
	return $result${rest_text}\n$indent\)
}



proc clean_lambda { lines keys } {
	lassign $keys field_ass lambda_start lambda_end
	set first [lindex $lines 0]
	set second [lindex $lines 1]
	set body_lines [lrange $lines 1 end]
	
	set parts [ split $first "=" ]
	set left [ string trim [ lindex $parts 0 ]]
	set right [ lindex $parts 1 ]
	set vars [ lrange $right 1 end]
	set vars_str [ join $vars ", " ]
	set body "    ${second}\(\n        "
	if { [llength $body_lines] == 1} {
		set rest_text "    $second"
	} elseif { $second == "return" } {
		set rest_text [ clean_struct $body_lines $keys "    "]
	} else {
		set rest_text [ clean_proc $body_lines "    "]
	}
	return "$left = function\($vars_str\) $lambda_start\n$rest_text\n$lambda_end"
}

proc clean_struct_field { line field_ass } {
	set first [ string first ":" $line ]
	if {$first == -1} {
		error "Field name is missing in line: $line"
	}
	incr first
	set value [ string range $line $first end]
	set value [ string trim $value]
	incr first -2
	set name [ string range $line 0 $first ]
	set name [ string trim $name]
	return "$name $field_ass $value"
}

proc clean_struct { lines keys indent} {
	set field_ass [ lindex $keys 0 ]
	set first [lindex $lines 0]
	set rest [lrange $lines 1 end]
	set rest_lines {}
	foreach line $rest {
		set formatted [ clean_struct_field $line $field_ass]
		lappend rest_lines $formatted
	}
	set rest_text [ join $rest_lines ",\n$indent    "]
	return "$indent${first} \{\n$indent    $rest_text\n$indent\}"
}

proc rewrite_clean_text { text keys} {
	set clean_type [ get_clean_type $text]
	if { $clean_type == "" } {
		return $text
	}
	lassign $clean_type type lines
	if { $type == "proc" } {
		return [ clean_proc $lines ""]		
	} elseif {$type == "lambda"} {
		return [ clean_lambda $lines $keys ]
	} else {
		return [ clean_struct $lines $keys ""]
	}
}

proc rewrite_clean_for_item { gdb vertex_id field_ass } {
	set text [ p.vertex_text $gdb $vertex_id ]	
	set text2 [ rewrite_clean_text $text $field_ass ]
	
	$gdb eval {
		update vertices
		set text = :text2
		where vertex_id = :vertex_id
	}
}

proc rewrite_clean { gdb diagram_id field_ass } {
	set actions [ $gdb eval {
		select vertex_id
		from vertices
		where type = 'action' 
			and diagram_id = :diagram_id } ]
	
	foreach vertex_id $actions {
		rewrite_clean_for_item $gdb $vertex_id $field_ass
	}
}

proc extract_variables { gdb diagram_id var_keyword } {	
	set vars  [get_variables_from_diagram $gdb $diagram_id $var_keyword]
	return $vars
}

proc get_variables_from_diagram { gdb diagram_id var_keyword } {
	set actions [ $gdb eval {
		select item_id
		from items
		where diagram_id = :diagram_id
		and (type = 'action' or type = 'loopstart')
	} ]

	set variables {}
	foreach item_id $actions {
		set text [get_item_text $gdb $diagram_id $item_id]
		set vars [ get_variables_from_item $text $var_keyword ]
		set variables [ concat $variables $vars ]
	}
	
	return [lsort -unique $variables ]
}

proc fix_graph_for_diagram { gdb callbacks append_semicolon diagram_id } {


	fix_graph_stage_1 $gdb $callbacks $append_semicolon $diagram_id

	p.remove_branch_icons $gdb $diagram_id

	p.glue_actions $gdb $callbacks $diagram_id

	append_condition_lines $gdb $diagram_id $callbacks
	
	while { [ p.short_circuit $gdb $callbacks $diagram_id ] } { }

}

proc fix_graph_for_diagram_to { gdb callbacks append_semicolon diagram_id } {


	fix_graph_stage_1_core $gdb $callbacks $append_semicolon $diagram_id 0

	p.remove_branch_icons $gdb $diagram_id

	p.glue_actions $gdb $callbacks $diagram_id

	append_condition_lines $gdb $diagram_id $callbacks
	
	while { [ p.short_circuit $gdb $callbacks $diagram_id ] } { }

}



proc append_condition_lines { gdb diagram_id callbacks } {
	set if_cond [ get_optional_callback $callbacks if_cond ]

	if { $if_cond == "" } { return }

	$gdb eval {
		select vertex_id, text, item_id
		from vertices
		where type = 'if'
		and diagram_id = :diagram_id
	} {
		set text2 [ $if_cond $text ]	
		$gdb eval {
			update vertices
			set text = :text2
			where vertex_id = :vertex_id
		}
	}
}

proc fix_graph { gdb callbacks append_semicolon } {
	set diagrams [ $gdb eval {
		select diagram_id from diagrams } ]

	newfor::clear
	foreach diagram_id $diagrams {
		if { [ mwc::is_drakon $diagram_id ] } {
			fix_graph_for_diagram $gdb $callbacks $append_semicolon $diagram_id
		}
	}
}

proc p.v_type { gdb vertex_id } {
	return [ $gdb onecolumn {
		select type
		from vertices
		where vertex_id = :vertex_id
	} ]
}

proc p.set_vertex_text { gdb vertex_id text } {
	$gdb eval {
		update vertices
		set text = :text
		where vertex_id = :vertex_id
	}
}

proc p.has_one_entry { gdb vertex_id } {
	set count [ $gdb onecolumn {
		select count(*)
		from links
		where dst = :vertex_id } ]
	
	return [ expr { $count == 1 } ]
}

proc p.short_circuit { gdb callbacks diagram_id } {
	set and [ get_callback $callbacks and ]
	set or [ get_callback $callbacks or ]
	set not [ get_callback $callbacks not ]
	
	set ifs [ $gdb eval {
		select vertex_id
		from vertices
		where type = 'if' 
			and diagram_id = :diagram_id } ]

	set result 0

	foreach if_id $ifs {
		set text [ p.vertex_text $gdb $if_id ]
		set one [ p.link_dst $gdb $if_id 1 ]
		set two [ p.link_dst $gdb $if_id 2 ]
		set one_type [ p.v_type $gdb $one ]
		
		if { $one != $if_id && $one_type == "if" && [ p.has_one_entry $gdb $one ] } {
			set ctext [ p.vertex_text $gdb $one ]
			set cone [ p.link_dst $gdb $one 1 ]
			set ctwo [ p.link_dst $gdb $one 2 ]

			if { $ctwo == $two } {
				set result 1
				# OR
				p.set_link_dst $gdb $if_id 1 $cone
				p.unlink $gdb $one
				$gdb eval { delete from vertices where vertex_id = :one }
				set ntext [ $or $text $ctext ]
				p.set_vertex_text $gdb $if_id $ntext
				
			} elseif { $cone == $two } {
				set result 1			
				# OR NOT
				p.set_link_dst $gdb $if_id 1 $ctwo
				p.unlink $gdb $one
				$gdb eval { delete from vertices where vertex_id = :one }
				set ntext [ $or $text [ $not $ctext ] ]
				p.set_vertex_text $gdb $if_id $ntext			
			}
		}

		set text [ p.vertex_text $gdb $if_id ]
		set one [ p.link_dst $gdb $if_id 1 ]
		set two [ p.link_dst $gdb $if_id 2 ]
		set two_type [ p.v_type $gdb $two ]
		
		if { $two != $if_id && $two_type == "if" && [ p.has_one_entry $gdb $two ] } {
			set ctext [ p.vertex_text $gdb $two ]
			set cone [ p.link_dst $gdb $two 1 ]
			set ctwo [ p.link_dst $gdb $two 2 ]

			if { $cone == $one } {
				set result 1
				# AND
				p.set_link_dst $gdb $if_id 2 $ctwo
				p.unlink $gdb $two
				$gdb eval { delete from vertices where vertex_id = :two }
				set ntext [ $and $text $ctext ]
				p.set_vertex_text $gdb $if_id $ntext
				
			} elseif { $ctwo == $one } {
				set result 1			
				# AND NOT
				p.set_link_dst $gdb $if_id 2 $cone
				p.unlink $gdb $two
				$gdb eval { delete from vertices where vertex_id = :two }
				set ntext [ $and $text [ $not $ctext ] ]
				p.set_vertex_text $gdb $if_id $ntext				
			}
		}

		
		if { $result } { break }
	}
	
	return $result
}

proc p.rewire_if { gdb if_id } {
	set b [ $gdb onecolumn {
		select b
		from vertices
		where vertex_id = :if_id } ]
	if { $b } {
		set one [ p.link_dst $gdb $if_id 1 ]
		set two [ p.link_dst $gdb $if_id 2 ]
		$gdb eval {
			update links set dst = :two
			where src = :if_id and ordinal = 1;
			
			update links set dst = :one
			where src = :if_id and ordinal = 2;			
			
			update vertices set b = 0
			where vertex_id = :if_id;
		}
	}
}

proc p.clean_tech_vertices { gdb diagram_id } {
	set vertices [ $gdb eval {
		select vertex_id
		from vertices
		where type is null or type == ''
			and diagram_id = :diagram_id
	} ]
	foreach vertex_id $vertices {
		$gdb eval {
			delete from links
			where src = :vertex_id;
			delete from vertices
			where vertex_id = :vertex_id
		}
	}
}

proc p.vertex_exists { gdb vertex_id } {
	set count [ $gdb onecolumn {
		select count(*) from vertices
		where vertex_id = :vertex_id } ]
	return [ expr { $count > 0 } ]
}

proc p.get_following { gdb vertex_id } {
	set dsts [ $gdb eval {
		select dst
		from links
		where src = :vertex_id } ]
	if { [ llength $dsts ] != 1 } { return "" }
	set dst [ lindex $dsts 0 ]
	

	return $dst
}

proc p.get_single_next { gdb vertex_id } {
	set dsts [ $gdb eval {
		select dst
		from links
		where src = :vertex_id } ]
	if { [ llength $dsts ] != 1 } { return "" }
	set dst [ lindex $dsts 0 ]
	
	set incoming [ $gdb onecolumn {
		select count(*)
		from links
		where dst = :dst } ]
	if { $incoming != 1 } { return "" }

	return $dst
}

proc p.same_type { gdb vertex1 vertex2 } {
	set type1 [ p.vertex_type $gdb $vertex1 ]
	set type2 [ p.vertex_type $gdb $vertex2 ]
	if { $type1 == "insertion" } { set type1 action }
	if { $type2 == "insertion" } { set type2 action }	
	return [ expr { $type1 == $type2 } ]
}

proc p.merge_vertices { gdb vertex_id next commentator line_end } {
	set this_text [ p.vertex_text $gdb $vertex_id ]
	set that_text [ p.vertex_text $gdb $next ]
	set that_item [ p.vertex_item $gdb $next ]
	set marker [ $commentator "item $that_item" ]
	set this [ string trim $this_text ]
	set that [ string trim $that_text ]
	if { $this == "" && $that == "" } {
		set new_text ""
	} elseif { $this == "" && $that != "" } {
		set new_text "$marker\n$that_text"
	} elseif { $this != "" && $that == "" } {
		set new_text $this_text
	} else {
		set new_text "$this_text$line_end\n$marker\n$that_text"
	}
	$gdb eval {
		update vertices
		set text = :new_text
		where vertex_id = :vertex_id
	}

	p.delete_vertex $gdb $next
}

proc p.glue_actions { gdb callbacks diagram_id } {

	set can_glue [ get_optional_callback $callbacks can_glue ]
	if { $can_glue != "" } {

		set commentator [ get_callback $callbacks comment ]
		set line_end [ get_optional_callback $callbacks line_end ]
		set vertices [ $gdb eval {
			select vertex_id
			from vertices
			where type != 'beginend'
				and diagram_id = :diagram_id
		} ]
		foreach vertex_id $vertices {
			if { ![ p.vertex_exists $gdb $vertex_id ] } { continue }
			set next [ p.get_single_next $gdb $vertex_id ]
			while { $next != "" && [ p.same_type $gdb $vertex_id $next ] } {
				p.merge_vertices $gdb $vertex_id $next $commentator $line_end
				set next [ p.get_single_next $gdb $vertex_id ]
			}		
		}
	}
}

proc p.remove_branches_from_dia { gdb diagram_id } {
	
	set vertices [ $gdb eval {
		select vertex_id
		from vertices
		where diagram_id = :diagram_id } ]

	foreach vertex_id $vertices {
		set type [ p.vertex_type $gdb $vertex_id ]
		if { $type == "branch" || $type == "address" } {
			p.delete_vertex $gdb $vertex_id
		}
	}
}

proc p.remove_branch_icons { gdb diagram_id } {
	lassign [ $gdb eval {
		select start_icon, header_icon
		from branches
		where diagram_id = :diagram_id
			and ordinal = 1 
	} ] start_icon header_icon
	if { $header_icon != "" } {
		p.link $gdb $start_icon 1 $header_icon
	}
	p.remove_branches_from_dia $gdb $diagram_id
}


proc p.extract_foreach { text } {
	if { ![ string match "foreach *" $text ] } { return "" }
	set foreach_length [ string length "foreach " ]
	set body [ string range $text $foreach_length end ]
	set parts [ split $body ";" ]
	if { [ llength $parts ] != 2 } { return "" }
	set result {}
	foreach part $parts {
		set trimmed [ string trim $part ]
		if { $trimmed == "" } { return "" }
		lappend result $trimmed
	}
	return $result	
}

proc p.extract_for { text } {
	set parts [ split $text ";" ]
	if { [ llength $parts ] != 3 } { return "" }
	set result {}
	foreach part $parts {
		set trimmed [ string trim $part ]
		if { $trimmed == "" } { return "" }
		lappend result $trimmed
	}
	return $result
}

proc p.vertex_text { gdb vertex_id } {
	return [ $gdb onecolumn { select text from vertices
		where vertex_id = :vertex_id } ]
}

proc p.link_dst { gdb src ordinal } {
	return [ $gdb onecolumn {
		select dst
		from links	
		where src = :src and ordinal = :ordinal } ]
}

proc p.link_const { gdb src ordinal } {
	return [ $gdb onecolumn {
		select constant
		from links	
		where src = :src and ordinal = :ordinal } ]
}


proc p.set_link_constant { gdb src ordinal constant } {
	$gdb eval {
		update links
		set constant = :constant
		where src = :src and ordinal = :ordinal
	}
}

proc p.set_link_dst { gdb src ordinal dst } {
	$gdb eval {
		update links
		set dst = :dst
		where src = :src and ordinal = :ordinal
	}
}


proc p.delete_vertex { gdb vertex_id } {
	set oords [ $gdb eval {
		select ordinal
		from links
		where src = :vertex_id } ]
	if { [ llength $oords ] > 1 } {
		error "Should be at most one link for vertex $vertex_id"
	}
	
	if { [ llength $oords ] == 1 } {
		set oord [ lindex $oords 0 ]
		set next_vertex [ p.link_dst $gdb $vertex_id $oord ]
		$gdb eval {
			update links
			set dst = :next_vertex
			where dst = :vertex_id;
		}
	}
	
	$gdb eval {
		delete from links
		where src = :vertex_id;		
	
		delete from vertices
		where vertex_id = :vertex_id;
	}
}

proc p.rewire_select { gdb select callbacks } {
	set ordinals [ $gdb eval {
		select ordinal
		from links
		where src = :select } ]

	foreach ordinal $ordinals {
		set dst [ p.link_dst $gdb $select $ordinal ]
		set constant [ p.vertex_text $gdb $dst ]
		p.set_link_constant $gdb $select $ordinal $constant
		p.delete_vertex $gdb $dst
	}
	
	p.replace_select_ifs $gdb $select $ordinals $callbacks
}

proc p.switch_var { item_id } {
	return "_sw${item_id}_"
}

proc p.save_declare { gdb diagram_id type name value callbacks } {
	set declarer [ get_callback $callbacks declare ]
	set line [ $declarer $type $name $value ]
	p.save_declare_kernel $gdb $diagram_id $line 0
}

proc p.save_declare_kernel { gdb diagram_id lines loop} {
	set lines_list [ split $lines "\n" ]
	foreach line $lines_list {
		$gdb eval {
			insert into declares (diagram_id, line, loop)
			values (:diagram_id, :line, :loop)
		}
	}
}

proc p.get_declares { gdb diagram_id has_iterators } {
	if { $has_iterators } {
		return [ $gdb eval {
			select line
			from declares 
			where diagram_id = :diagram_id } ]
	} else {
		return [ $gdb eval {
			select line
			from declares 
			where diagram_id = :diagram_id and loop = 0 } ]
	}
}

proc p.replace_select_ifs { gdb select ordinals callbacks } {
	set assign [ get_callback $callbacks assign ]
	set bad_case [ get_callback $callbacks bad_case ]
	
	set select_item [ p.vertex_item $gdb $select ]
	set select_icon_number $select_item
	set select_text [ p.vertex_text $gdb $select ]	
	set diagram_id [ p.vertex_diagram $gdb $select ]
	
	set select_item [ expr { $select_item * 10000 } ]
	set compare [ get_callback $callbacks compare ]
	
	
	if {[string match -nocase "Select" $select_text]} {
		set select_mode_var 2
	} else {
		set select_mode_var 1
	}
		
	if {$select_mode_var == 1} {
		if { ![ is_variable $select_text ] } {
			
			set var_name [ p.switch_var $select_item ]
			set init_text [ $assign $var_name $select_text ]
			set init_id [ p.insert_vertex $gdb $diagram_id $select_item action $init_text "" 0 ]
			p.relink $gdb $select $init_id
			set parent $init_id
			p.save_declare $gdb $diagram_id "int" $var_name "0" $callbacks
		} else {
			
			set var_name [ string map {"\$" "" } $select_text ]
			set parent ""	
		}
	} elseif {$select_mode_var == 2} {
		set parent ""
	}
	
	set count [ llength $ordinals ]
	set last [ expr { $count - 1 } ]
	for { set i 0 } { $i < $count } { incr i } {
	
		incr select_item
		set ordinal [ lindex $ordinals $i ]
		set const [ p.link_const $gdb $select $ordinal ]
		set dst [ p.link_dst $gdb $select $ordinal ]
		
		if { $i == $last && ($const == "" || [string compare -nocase $const "Else"] == 0) } {
			p.link $gdb $parent 1 $dst
		} else {
			
			if {$select_mode_var == 1} {
				set comp_text [ $compare $var_name $const ]
			} elseif {$select_mode_var == 2} {
				set comp_text $const
			}
			
			set if_id [ p.insert_vertex $gdb $diagram_id $select_item if $comp_text "" 0 ]

			
			if { $i == $last } {
				
				if {$select_mode_var == 1} {
					set fail_text [ $bad_case $var_name $select_icon_number ]
				} elseif {$select_mode_var == 2} {
					set fail_text [ $bad_case $select_text $select_icon_number ]
				}
				
				incr select_item
				set fail_id [ p.insert_vertex $gdb $diagram_id $select_item action $fail_text "" 0 ]
				
				p.link $gdb $if_id 2 $dst
				p.link $gdb $if_id 1 $fail_id
				p.link $gdb $fail_id 1 $dst
			} else {
				p.link $gdb $if_id 2 $dst
			}
			
			if { $parent == "" } {
				p.relink $gdb $select $if_id
			} else {
				p.link $gdb $parent 1 $if_id
			}			
			
			set parent $if_id
		}		
	}
	

	p.unlink $gdb $select
	p.delete_vertex $gdb $select
}

proc p.unlink { gdb src } {
	$gdb eval {
		delete from links
		where src = :src }
}

proc p.vertex_type { gdb vertex_id } {
	return [ $gdb onecolumn {
		select type
		from vertices
		where vertex_id = :vertex_id } ]
}

proc p.vertex_item { gdb vertex_id } {
	return [ $gdb onecolumn {
		select item_id
		from vertices
		where vertex_id = :vertex_id } ]
}

proc p.vertex_diagram { gdb vertex_id } {
	return [ $gdb onecolumn {
		select diagram_id
		from vertices
		where vertex_id = :vertex_id } ]
}

proc p.get_next { gdb src ordinal } {
	return [ $gdb onecolumn {
		select dst
		from links
		where src = :src and ordinal = :ordinal } ]
}

proc p.next_on_skewer { gdb vertex_id } {
	return [ p.get_next $gdb $vertex_id 1 ]
}

proc p.find_end { gdb diagram_id start } {
	set current [ p.get_next $gdb $start 2 ]
	while { 1 } {
		if { $current == "" } { break }
		set type [ p.vertex_type $gdb $current ]
		if { $type == "loopend" } {
			return $current
		}
		set current [ p.next_on_skewer $gdb $current ]
	}

	set item_id [ p.vertex_item $gdb $start ]
	report_error $diagram_id $item_id "End not found for loop start"
}

proc has_branches { gdb diagram_id } {
	set count [ $gdb onecolumn {
		select count(*)
		from branches where diagram_id = :diagram_id } ]
	return [ expr { $count > 0 } ]
}


proc p.rewire_loop { gdb start callbacks append_semicolon } {
	set diagram_id [ p.vertex_diagram $gdb $start ]

	

	set end [ p.find_end $gdb $diagram_id $start ]
	set text [ p.vertex_text $gdb $start ]
	set item_id [ p.vertex_item $gdb $start ]

	set type ""
	set parts ""
	if { [ string match "foreach *" $text ] && $callbacks != "" } {
		set parts [ p.extract_foreach $text ]
		set type "foreach"
	} else {
		set parts [ p.extract_for $text ]
		set type "for"
	}


	
	if { $parts == "" } {
		set diagram_id [ p.vertex_diagram $gdb $start ]
		set item_id [ p.vertex_item $gdb $start ]
		set item_text [ p.vertex_text $gdb $start ]
		graph::p.error $diagram_id [ list $item_id ] "Error in loop statement: $item_text"
		report_error $diagram_id $item_id "Error in loop item $item_id: $item_text"
	}

	if { $type == "for" } {
		p.rewire_for $gdb $start $end $parts $append_semicolon
	} elseif { $type == "foreach" } {
		p.rewire_foreach $gdb $diagram_id $start $end $parts $callbacks
	}
}

proc p.insert_vertex { gdb diagram_id item_id type text text2 b } {
	set vertex_id [ mod::next_key $gdb vertices vertex_id ]
	$gdb eval {
		insert into vertices (vertex_id, diagram_id, item_id, type, text, text2, b)
			values (:vertex_id, :diagram_id, :item_id, :type, :text, :text2, :b)
	}
	return $vertex_id
}

proc p.relink { gdb old_dst new_dst } {
	$gdb eval {
		update links
		set dst = :new_dst
		where dst = :old_dst
	}
}

proc p.link { gdb src ordinal dst } {
	$gdb eval {
		insert into links (src, ordinal, dst)
			values (:src, :ordinal, :dst)
	}
}

proc append_digits { number digits } {
	append number $digits
	return $number
}

proc p.rewire_foreach { gdb diagram_id start end parts callbacks } {

	set cinit [ get_callback $callbacks for_init ]
	set ccheck [ get_callback $callbacks for_check ]
	set ccurrent [ get_callback $callbacks for_current ]
	set cincr [ get_callback $callbacks for_incr ]
	set declare [ get_callback $callbacks for_declare ]
	set native_foreach [ get_optional_callback $callbacks native_foreach ]
	
	lassign $parts first second

	set diagram_id [ p.vertex_diagram $gdb $start ]
	set item_id [ p.vertex_item $gdb $start ]

	set tinit [ $cinit $item_id $first $second ]
	set tcheck [ $ccheck $item_id $first $second ]
	set tcurrent [ $ccurrent $item_id $first $second ]
	set tincr [ $cincr $item_id $first $second ]
	set for_declare [ $declare $item_id $first $second ]
	set loop [ expr { $native_foreach != "" } ]
	p.save_declare_kernel $gdb $diagram_id $for_declare $loop

	# check must always be present
	set vid [ append_digits $item_id 0002 ]
	set check_id [ p.insert_vertex $gdb $diagram_id $vid "if" $tcheck "" 0 ]
	if { $loop } {
		newfor::put $vid [ list $item_id $parts ]
	}

	if { $tinit == "" } {
		p.relink $gdb $start $check_id
	} else {
		set vid [ append_digits $item_id 0001 ]
		set init_id [ p.insert_vertex $gdb $diagram_id $vid "action" $tinit "" 0 ]
		p.relink $gdb $start $init_id
		p.link $gdb $init_id 1 $check_id

		if { $loop } {
			newfor::put $vid 1
		}
	}

	if { $tincr == "" } {
		p.relink $gdb $end $check_id
	} else {
		set vid [ append_digits $item_id 0003 ]
		set advance_id [ p.insert_vertex $gdb $diagram_id $vid "action" $tincr "" 0 ]
		p.relink $gdb $end $advance_id
		p.link $gdb $advance_id 1 $check_id
		if { $loop } {
			newfor::put $vid 1
		}
	}

	set first_loop [ p.get_next $gdb $start 2 ]
	set after_loop [ p.get_next $gdb $start 1 ]
	p.link $gdb $check_id 1 $after_loop

	if { $tcurrent == "" } {
		p.link $gdb $check_id 2 $first_loop
	} else {
		set vid [ append_digits $item_id 0004 ]
		set current_id [ p.insert_vertex $gdb $diagram_id $vid "action" $tcurrent "" 0 ]
		p.link $gdb $check_id 2 $current_id
		p.link $gdb $current_id 1 $first_loop
		if { $loop } {
			newfor::put $vid 1
		}
	}

	
	$gdb eval {
		delete from links where src = :start;
		delete from vertices where vertex_id in (:start, :end);
	}	

}

proc p.rewire_for { gdb start end parts append_semicolon } {
	set diagram_id [ p.vertex_diagram $gdb $start ]
	lassign $parts init check advance
	set item_id [ p.vertex_item $gdb $start ]
	if { $append_semicolon } {
		append init ";"
		append advance ";"
	}
	set init_id [ p.insert_vertex $gdb $diagram_id [ append_digits $item_id 0001 ] "action" $init "" 0 ]
	set check_id [ p.insert_vertex $gdb $diagram_id [ append_digits $item_id 0002 ] "if" $check "" 0 ]
	set advance_id [ p.insert_vertex $gdb $diagram_id [ append_digits $item_id 0003 ] "action" $advance "" 0 ]
	p.relink $gdb $end $advance_id
	p.link $gdb $advance_id 1 $check_id
	p.relink $gdb $start $init_id
	p.link $gdb $init_id 1 $check_id
	set first_loop [ p.get_next $gdb $start 2 ]
	set after_loop [ p.get_next $gdb $start 1 ]
	p.link $gdb $check_id 1 $after_loop
	p.link $gdb $check_id 2 $first_loop
	$gdb eval {
		delete from links where src = :start;
		delete from vertices where vertex_id in (:start, :end);
	}	
}

proc extract_sections { text } {
	set lines [ split $text "\n" ]
	set result {}
	set buffer ""
	set current_header ""
	foreach line $lines {
		set header [ p.try_extract_header $line ]
		if { $header != "" } {
			if { $buffer != "" } {
				lappend result $current_header $buffer
				set buffer ""
				set current_header $header
			}
			set current_header $header
		} elseif { $current_header != "" } {
			if { $buffer != "" } {
				append buffer "\n"
			}
			set no_r [ string map { "\r" "" } $line ]
			append buffer $no_r
		}
	}

	if { $buffer != "" } {
		lappend result $current_header $buffer
	}

	return $result
}



proc p.separate_line { text } {
	
	set language $current_file_generation_info::language
	set generator $current_file_generation_info::generator


	# These 2 lines is to get current generator namespace. 
	set find [string first :: $generator]
	set generator_namespace [ string range $generator 0 $find-1 ]

	# These 3 lines is to check is current generator have commentator procedure.
	# If there is no commentator procedure, commentator_status_var is set to "" .
	set commentator_for_namespace_text "::commentator"
	set commentator_call_text "$generator_namespace$commentator_for_namespace_text"
	set commentator_status_var [ namespace which $commentator_call_text ]
	
	# If current language does not have commentator procedure or current languages is in if conditions, then // sign for function parameter commenting will be used.
	# It is done so for compability with diagrams which are made with previous versions of DRAKON Editor.
	# If you are adding new language generator to DRAKON Editor and want to use line comment sign as
	# commenting sign for function parameters, just make commentator procedure in your language generator
	# as it is for example in AutoHotkey code generator.
	if { $commentator_status_var == "" ||
	$language == "C" ||
	$language == "C#" ||
	$language == "C++" ||
	$language == "D" ||
	$language == "Erlang" ||
	$language == "Java" ||
	$language == "Javascript" ||
	$language == "Lua" ||
	$language == "Processing.org" ||
	$language == "Python 2.x" ||
	$language == "Python 3.x" ||
	$language == "Tcl" ||
	$language == "Verilog" } {
		
		set first [ string first "//" $text ]
	
	} else {
		
		# Get current generator line comment simbol and calculate its length without space sign.
		set current_lang_line_comment [ $commentator_call_text "" ]
		set trimmed_current_lang_line_comment [string trim $current_lang_line_comment " " ]
		set current_lang_line_comment_length [ string length $trimmed_current_lang_line_comment ]
		
		set first [ string first $trimmed_current_lang_line_comment $text ]
	}
	
	if { $first == -1 } {
		set part0 $text
		set part1 ""
	} else {
		set part0end [ expr { $first - 1 } ]
		
		set length_var_exists [ info exists current_lang_line_comment_length ]
		if { $length_var_exists == 1 } {
		set part1start [ expr { $first + $current_lang_line_comment_length } ]
		} else {
			set part1start [ expr { $first + 2 } ]
		}
		
		set part0 [ string range $text 0 $part0end ]
		set part1 [ string range $text $part1start end ]
	}
	set part0tr [ string trim $part0 ]
	set part1tr [ string trim $part1 ]
	return [ list $part0tr $part1tr ]
}

proc separate_from_comments { text } {
	set row_lines [ split $text "\n" ]
	set lines {}
	foreach row $row_lines {
		set parts [ p.separate_line $row ]
		if { [ lindex $parts 0 ] != "" } {
			lappend lines $parts
		}
	}
	return $lines
}

proc create_signature { fun_type access arguments returns } {
	return [ list $fun_type $access $arguments $returns ]
}

proc extract_return_type { line } {
	set return_length [ string length "returns " ]
	set return_length_1 [ expr { $return_length - 1 } ]
	
	if { [ string range $line 0 $return_length_1 ] == "returns " } {
		set remainder [ string range $line $return_length end ]
		return [ string trim $remainder ]
	}
	
	return ""
}

proc p.contains_return { text } {
	set lines [ split $text "\n" ]
	foreach line $lines {
		set line2 [ string trim $line ]
		if { [ string match "return *" $line2 ] } { return 1 }
		if { [ string match "throw *" $line2 ] } { return 1 }
		if { $line2 == "throw;" } { return 1 }
	}
	return 0
}

proc p.has_connections { gdb vertex_id } {
	set count [ $gdb onecolumn {
		select count(*)
		from links
		where src = :vertex_id } ]
	return [ expr { $count > 0 } ]
}

proc p.check_links { gdb } {
	$gdb eval { select src from links } {

		if { [ string trim $src ] == "" } {
			error "links without src"
		}
	}
}

proc many_exists { gdb vertex_id } {
	set exits [ $gdb onecolumn {
		select count(*)
		from links
		where src = :vertex_id } ]
	return [ expr { $exits > 1 } ]
}

proc one_entry_exit { gdb vertex_id } {
	set entries [ $gdb onecolumn {
		select count(*)
		from links
		where dst = :vertex_id } ]

	set exits [ $gdb onecolumn {
		select count(*)
		from links
		where src = :vertex_id } ]

	return [ expr { $entries == 1 && $exits == 1 } ]
}

proc p.classify_return { text } {
	if { [ p.contains_return $text ] } {
		return has_return
	} else {
		return last_item
	}
}

proc p.scan_vertices { result_list gdb vertices commentor } {
	upvar 1 $result_list result
	foreach vertex_id $vertices {
		lassign [ $gdb eval { select text, type, b, item_id
			from vertices where vertex_id = :vertex_id
		} ] text type b item_id

		if { ![p.has_connections $gdb $vertex_id ] } { continue }
		set text_lines [ split $text "\n" ]
		set body [ list $type $text_lines $b ]
		set links {}
		$gdb eval { select src, ordinal, dst, constant
				from links where src = :vertex_id 
				order by ordinal} {
			set code {}
			if { [ p.contains_return $text ] } {
				set next_item "has_return"
			} elseif { [ p.vertex_type $gdb $dst ] == "beginend" } {
				set next_item "last_item"
			} elseif { [ one_entry_exit $gdb $dst ] &&
						[ many_exists $gdb $vertex_id ]} {
				set merged_item [ p.vertex_item $gdb $dst ]
				set code [ list [ $commentor "item $merged_item" ] ]
				set next_text [ p.vertex_text $gdb $dst ]
				foreach line [ split $next_text "\n" ] {
					lappend code $line
				}

				set next_vertex [ p.next_on_skewer $gdb $dst ]
				
				if { [ p.contains_return $next_text ] } {
					set next_item "has_return"
				} elseif { [ p.vertex_type $gdb $next_vertex ] == "beginend" } {
					set next_item "last_item"
				} else {
					set next_item [ p.vertex_item $gdb $next_vertex ]
				}

				$gdb eval {
					update links set dst = :next_vertex 
					where src = :src and ordinal = :ordinal;
					delete from links where src = :dst;
				}
			} else {
				set next_item [ p.vertex_item $gdb $dst ]
			}
			lappend links [ list $next_item $constant $code ]
		}
		lappend result $item_id [ list $body $links ]
	}
}

proc find_start_vertex { gdb diagram_id } {
	set start_icon [ get_start_icon $gdb $diagram_id ]
	set real_start [ p.next_on_skewer $gdb $start_icon ]
	return $real_start
}


proc find_start_item { gdb diagram_id } {
	set start_icon [ get_start_icon $gdb $diagram_id ]
	set real_start [ p.next_on_skewer $gdb $start_icon ]
	set start_item [ p.vertex_item $gdb $real_start ]

	return $start_item
}

proc generate_nodes { gdb diagram_id commentor } {
	set result {}
	set conditionals [ $gdb eval {
		select vertex_id from vertices 
		where diagram_id = :diagram_id
		and type in ('if', 'select') } ]
		

	p.scan_vertices result $gdb $conditionals $commentor

	set normals [ $gdb eval {
		select vertex_id from vertices 
		where diagram_id = :diagram_id
		and type not in ('if', 'select', 'beginend', '' ) } ]


	p.scan_vertices result $gdb $normals $commentor


	set uni {}
	foreach {item_id node} $result {
		if { [ contains $uni $item_id ] } {
			error "$item_id not unique"
		} else {
			lappend uni $item_id
		}
	}

	return $result

}

proc add_line { result line base depth } {
	upvar 1 $result output
	set indent [ make_indent [ expr { $base + $depth } ] ]
	lappend output "$indent$line"
}

proc add_lines { result before lines after base depth } {
	upvar 1 $result output
	set indent [ make_indent [ expr { $base + $depth } ] ]
	set length [ llength $lines ]
	set last [ expr { $length - 1 } ]
	repeat i $length {
		set line [ lindex $lines $i ]

		if { $i == 0 } {
			set line [ join [ list $before $line ] {} ]
		}
		if { $i == $last } {
			append line $after
		}
		
		set line [ join [ list $indent $line ] {} ]
		lappend output $line
	}
}

proc make_indent { depth } {
	set indent ""
	repeat i $depth {
		append indent "    "
	}
	return $indent
}

proc indent { lines depth } {
	set result {}
	set spaces [ make_indent $depth ]

	foreach line $lines {
		lappend result "$spaces$line"
	}

	return [ join $result "\n" ]
}

proc scan_file_description { db section_names } {
	set description [ $db onecolumn {
		select description
		from state
		where row = 1 } ]
	array set sections [ extract_sections $description ]
	
	set result {}
	foreach name $section_names {
		if { [ info exists sections($name) ] } {
			set section $sections($name)
		} else {
			set section ""
		}
		lappend result $section
	}
	return $result
}


proc get_diagram_start { gdb diagram_id } {
	return [ $gdb eval {
		select start_icon, params_icon
		from branches 
		where diagram_id = :diagram_id
			and ordinal = 1
	} ]
}

proc generate_function { gdb diagram_id callbacks nogoto to } {

	set extract_signature [ get_callback $callbacks signature ]
	set generate_body [ get_callback $callbacks body ]
	set commentator [ get_callback $callbacks comment ]
	set enforce_nogoto [ get_optional_callback $callbacks enforce_nogoto ]

	set start_info [ get_start_info $gdb $diagram_id ]
	lassign $start_info start_icon params_icon name params_text start_item


	set signature [ $extract_signature $params_text $name ]
	lassign $signature errorMessage real_sign
	if { $errorMessage != "" } {
		report_error $diagram_id {} $errorMessage
	}

	set tree ""
	
	set body ""
	set has_iterators 0
	if { $to } {
		set body [ tree_nogoto $gdb $diagram_id $callbacks $name ]
	} else {
		if { $nogoto } {
			set body [ try_nogoto $gdb $diagram_id $callbacks $name ]
			if { $body == "" && $enforce_nogoto != "" } {
				$enforce_nogoto $name
			}
		}
	
		if { $body == "" } {
			set node_list [ generate_nodes $gdb $diagram_id $commentator ]
			lassign [ sort_items $node_list $start_item ] sorted incoming
			set body [ $generate_body $gdb $diagram_id $start_item $node_list $sorted $incoming]
			set has_iterators 1
		}
	}
	
	set declares [ p.get_declares $gdb $diagram_id $has_iterators ]
	set body [ concat $declares $body ]

	return [ list $diagram_id $name $real_sign $body ]
}

proc tree_nogoto { gdb diagram_id callbacks name } {
	#puts "solving as tree: $name"
	set start_vertex [ find_start_vertex $gdb $diagram_id ]
	set start_item [ p.vertex_item $gdb $start_vertex ]
	set roots [ list $start_vertex ]
	
	set texts {}
	
	set select_to_vertex { }
	set case_to_root { }
		
	$gdb eval {
		select item_id, vertex_id, text
		from vertices
		where type = 'select'
		and diagram_id = :diagram_id		
	} {
		lappend texts $item_id $text
		lappend select_to_vertex $item_id $vertex_id
	}
	
	gdb eval {
		select item_id, vertex_id, text
		from vertices
		where type = 'case'
		and diagram_id = :diagram_id
	} {
		lappend texts $item_id $text
		set dst [ p.link_dst $gdb $vertex_id 1 ]
		set dst_item_id [ p.vertex_item $gdb $dst ]		
		lappend roots $dst
		lappend case_to_root $vertex_id $dst_item_id
	}
	
	
	set item_to_tree { }
	
	set inspector [ get_optional_callback $callbacks inspect_tree ]	
	

	
	foreach vertex_id $roots {
		set item_id [ p.vertex_item $gdb $vertex_id ]	
		set tree [ build_to_subgraph $gdb $name $vertex_id $item_id texts ]
		if { $tree == "" } {
			error "could not solve $name, giving up. Loop maybe?"
		}
		
		if { $inspector != "" } {
			$inspector $tree $name
		}
		
		lappend item_to_tree $item_id $tree
	}
	
	
	

	set start_tree [ dict get $item_to_tree $start_item ]
	set big_tree [ merge_trees $gdb $start_tree $case_to_root $item_to_tree $select_to_vertex ]
	
	
	set result [ print_node $texts $big_tree $callbacks 0 ]
	
	return $result
}

proc merge_trees { gdb node case_to_root item_to_tree select_to_vertex } {
	set length [ llength $node ]
	set first [ lindex $node 0 ]
	set result [ list $first ]
	
	for { set i 1 } { $i < $length } { incr i } {
		set current [ lindex $node $i ]
		if { [ string is integer $current ] } {
			if { [ dict exists $select_to_vertex $current ] } {
				set select_tree [ build_select_tree $gdb $current $case_to_root $item_to_tree $select_to_vertex ]
				lappend result $select_tree
			} else {
				lappend result $current
			}
		} elseif { $current == "break" } {
			lappend result $current		
		} elseif { [ lindex $current 0 ] == "if" } {

			set cond_item [ lindex $current 1 ]
			set then_node [ lindex $current 3 ]
			set else_node [ lindex $current 2 ]
			
			set then [ merge_trees $gdb $then_node $case_to_root $item_to_tree $select_to_vertex]
			set else [ merge_trees $gdb $else_node $case_to_root $item_to_tree $select_to_vertex]
			
			set new_if [ list "if" $cond_item $else $then ]
			
			lappend result $new_if
			
		} else {
			error "unexpected: $current"
		}
	}
	
	return $result
}

proc build_select_tree { gdb sel_item case_to_root item_to_tree select_to_vertex } {
	set sel_vertex [ dict get $select_to_vertex $sel_item ]
	set cases [ $gdb eval {
		select dst
		from links
		where src = :sel_vertex
		order by ordinal
	} ]
	
	set result [ list "sel" $sel_item ]
	
	foreach case_vertex $cases {
		set case_item [ p.vertex_item $gdb $case_vertex ]
		set item_id [ dict get $case_to_root $case_vertex ]
		set subtree [ dict get $item_to_tree $item_id ]
		set expanded [ merge_trees $gdb $subtree $case_to_root $item_to_tree $select_to_vertex]
		lappend result $case_item $expanded
	}
	
	return $result
}

proc build_to_subgraph { gdb name vertex_id item_id texts_name } {
	upvar 1 $texts_name texts
	set db "gen-body"

	nogoto::create_db $db
	
	set log [ expr { $name == "xxxx" } ]
	add_to_graph $gdb $db $vertex_id 0
	
	set tree [ nogoto::generate $db $item_id ]

	set this_texts [ extract_texts $db ]
	set texts [ concat $texts $this_texts ]
	
	
	return $tree
}

proc extract_texts { db } {
	set result {}
	
	$db eval {
		select item_id, text_lines
		from nodes
	} {
		lappend result $item_id $text_lines
	}
	
	return $result
}



proc try_nogoto { gdb diagram_id callbacks name } {
	set db "gen-body"
	set start_vertex [ find_start_vertex $gdb $diagram_id ]
	set start_item [ p.vertex_item $gdb $start_vertex ]
	
	nogoto::create_db $db
	set log [ expr { $name == "xxxx" } ]
	add_to_graph $gdb $db $start_vertex $log
	
	#puts "solving: $name"
	set tree [ nogoto::generate $db $start_item ]
		
	if { $tree == "" } {
		puts "could not solve $name, using goto"
		return ""
	}
	
	set inspector [ get_optional_callback $callbacks inspect_tree ]
	if { $inspector != "" } {
		$inspector $tree $name
	}
	
	set texts [ extract_texts $db ]
	set result [ print_node $texts $tree $callbacks 0 ]
	
	return $result
}


proc get_text_lines { texts item_id } {
	return [ dict get $texts $item_id ]
}

proc condition_line { callback cond_text } {
	set if_start [ get_callback $callback if_start ]
	set if_end [ get_callback $callback if_end ]
	
	set cond "[ $if_start ]$cond_text[ $if_end ]"
	return $cond
}

proc print_select { texts node callback depth } {
	set select [ get_callback $callback select ]
	set case_value [ get_callback $callback case_value ]
	set case_else [ get_callback $callback case_else ]
	set case_end [ get_callback $callback case_end ]	
	set select_end [ get_callback $callback select_end ]
	set bad_case [ get_callback $callback bad_case ]
	set put_default [ get_optional_callback $callback select_gen_default ]	
	if { $put_default == "" } {
		set put_default 1
	}
			
	set result {}
	set indent [ make_indent $depth ]
	set next_depth [ expr { $depth + 2 } ]	
	set header_item [ lindex $node 1 ]
	set header_text [ get_text_lines $texts $header_item ]
	lappend result "${indent}[ $select $header_text ]"
	set length [ llength $node ]
	set last [ expr { $length - 2 } ]
	set had_default 0
	for { set i 2 } { $i < $length } { incr i 2 } {
		set value_id [ expr { $i + 1 } ]
		set key [ lindex $node $i ]
		set value [ lindex $node $value_id ]
		set key_text [ get_text_lines $texts $key ]
		if { [ string trim $key_text ] == "" } {
			lappend result "${indent}   [ $case_else ]"
			set had_default 1
		} else {
			lappend result "${indent}    [ $case_value $key_text ]"
		}
		set clause [ print_node $texts $value $callback $next_depth ]
		set result [ concat $result $clause ]
		if { $i != $last || !$had_default && $put_default } {
			set next_key_id [ expr { $i + 2 } ]
			set next_key [ lindex $node $next_key_id ]
			if { $next_key == "" } {
				set next_key_text ""
			} else {
				set next_key_text [ get_text_lines $texts $next_key ]
			}
			set cend [$case_end $next_key_text]
			if {$cend == "" } {
				set had_default 1			
			}
			lappend result "${indent}    $cend"
		}		
	}
	if { !$had_default && $put_default } {
		lappend result "${indent}    [ $case_else ]"
		lappend result "${indent}    [ $bad_case {} $header_item ]"
	}
	lappend result "${indent}[ $select_end ]"
	return $result
}


proc seq_has_return { texts node } {
	foreach current $node {
		if { [ string is integer $current ] } {
			set text [ get_text_lines $texts $current ]
			if { [ p.contains_return $text ] } {
				return 1
			}
		}
	}
	return 0
}

proc seq_has_break { texts node } {
	if { ![ contains $node "break" ] } {
		return 0
	}

	set rest [ lrange $node 1 end]
	foreach current $rest {
		if { [ string is integer $current ] } {
			set text [ get_text_lines $texts $current ]
			if { [ p.contains_return $text ] } {
				return 0
			}
		}
	}
	return 1
}

proc has_break { texts node } {
	set first [ lindex $node 2 ]
	set second [ lindex $node 3 ]
	if { [ seq_has_break $texts $first  ] } {
		return 1
	}
	if { [ seq_has_break $texts $second ] } {
		return 1
	}
	return 0
} 

proc scan_foreach_exits { texts node } {
	set native 0
	set early 0
	set meaningful "seq"
	set rest [ lrange $node 1 end]
	set start_info ""
	foreach current $rest {
		if { [ lindex $current 0 ] == "if" } {
			set cond_item [ lindex $current 1 ]
			set start_item_info [ newfor::get $cond_item ]

			if { $start_item_info != "" } {
				set start_info $start_item_info
				set native 1
				set exit_branch [ lindex $current 2 ]
				set meaningful [ lrange $exit_branch 0 end-1 ]
			} else {
				if { [ has_break $texts $current ] } {
					set early 1
				}
			}
		}
	}
	return [ list $native $early $meaningful $start_info ]
}

proc add_block { texts node callback depth early early_var result_name } {
	upvar 1 $result_name result
	set compare [ get_callback $callback compare ]

	set block_close [ get_callback $callback block_close ]
	set indent [ make_indent $depth ]
	if {$early} {
		set cond_text [ $compare $early_var 1 ]
		set cond [ condition_line $callback $cond_text]
		lappend result $indent$cond		
		set d2 [ expr { $depth + 1 } ]
		set chunk [print_node $texts $node $callback $d2]
		set result [ concat $result $chunk ]
		$block_close result $depth		
	} else {
		set chunk [print_node $texts $node $callback $depth]
		set result [ concat $result $chunk ]
	}
}
proc print_node { texts node callback depth } {
	return [ print_node_core $texts $node $callback $depth "" ]
}

proc print_node_core { texts node callback depth break_var } {
	set line_end [ get_optional_callback $callback line_end ]
	set commentator [ get_callback $callback comment ]
	set break_str [ get_callback $callback break ]
	set native_foreach [ get_optional_callback $callback native_foreach ]
	#set continue_cb [ get_callback $callback continue ]
	#set continue_str [ $continue_cb ]
	
	set block_close [ get_callback $callback block_close ]
	set while_start [ get_callback $callback while_start ]
	set else_start [ get_callback $callback else_start ]
	set pass [ get_callback $callback pass ]

	set assign [ get_callback $callback assign ]
	set compare [ get_callback $callback compare ]
	set declare [ get_callback $callback declare ]
	
	set length [ llength $node ]
	set result {}
	set was_return 0
	set indent [ make_indent $depth ]
	set next_depth [ expr { $depth + 1 } ]

	for { set i 1 } { $i < $length } { incr i } {
		set current [ lindex $node $i ]
		if { [ string is integer $current ] } {

			set iteration [ newfor::get $current ]

			set text [ get_text_lines $texts $current ]
			set was_return 0
			if { $iteration == "" } {
				set parts [ split $text "\n" ]
				if { [ llength $parts ] != 0 } {
					append_line_end result $i $line_end			
					set comment [ $commentator "item $current" ]
					lappend result $indent$comment
				}

				foreach part $parts {
					if { [ p.contains_return $part ] } {
						set was_return 1
					}
					set line $indent$part
					lappend result $line
				}
			}
		} elseif { $current == "break" } {
			if { !$was_return } {
				if { $break_var != "" } {
					lappend result "${indent}[$assign $break_var 0]"
				}
				lappend result $indent$break_str
			}
			set was_return 0
		} elseif { $current == "continue" } {
			#lappend result $indent$continue_str
			set was_return 0
		} elseif { [ lindex $current 0 ] == "if" } {
			append_line_end result $i $line_end
			
			set cond_item [ lindex $current 1 ]
			set start_item_info [ newfor::get $cond_item ]

			if { $start_item_info == "" } {
				set cond_text [ get_text_lines $texts $cond_item ]
				set comment [ $commentator "item $cond_item" ]
				lappend result $indent$comment

				set cond [ condition_line $callback $cond_text ]
				lappend result $indent$cond
			
				set then_node [ lindex $current 3 ]
				set else_node [ lindex $current 2 ]
				set then [ print_node_core $texts $then_node $callback $next_depth $break_var ]
				set result [ concat $result $then ]
			
				lappend result "$indent[ $else_start ]"
				set else [ print_node_core $texts $else_node $callback $next_depth $break_var ]
				set result [ concat $result $else ]
				$block_close result $depth
			}
			set was_return 0
		} elseif { [ lindex $current 0 ] == "loop" } {
			lassign [scan_foreach_exits $texts $current] native early meaningful fexit
			set loop_item [ lindex $fexit 0 ]
			set early_var ""
			if { $native } {
				if { $early && $meaningful != "seq" } {
					set early_var "normal_$loop_item"
					set decl [ $declare "int" $early_var "" ]
					lappend result "${indent}$decl"
					lappend result "${indent}[$assign $early_var 1]"
				} else {
					set early_var ""
				}
				lassign [ lindex $fexit 1] for_it for_var
				set foreach_header [ $native_foreach $for_it $for_var ]
				lappend result "${indent}$foreach_header"
			} else {
				lappend result "$indent[ $while_start ]"
			}
			set body [ print_node_core $texts $current $callback $next_depth $early_var ]
			set result [ concat $result $body ]
			$block_close result $depth
			if { $native && $meaningful != "seq" } {
				add_block $texts $meaningful $callback $depth $early $early_var result
			}
			set was_return 0
		} elseif { [ lindex $current 0 ] == "sel" } {
			append_line_end result $i $line_end		
			set sel_lines [ print_select $texts $current $callback $depth ]
			set result [ concat $result $sel_lines ]
			
			set was_return 0
		} else {
			error "unexpected: $current"
		}
	}
	
	if { $result == "" } {
		set result [ list "$indent[ $pass ]" ]
	}
	
	return $result
}

proc append_line_end { result_list i line_end } {
	upvar 1 $result_list result
	
	if { $line_end == "" } { return }
	if { $i == 1 } { return }	
		
	set result_length [ llength $result ]

	set end_index [ expr { $result_length - 1 } ]
	set end_item [ lindex $result $end_index ]
	append end_item $line_end
	
	set result [ lreplace $result $end_index $end_index $end_item ]
}

proc link_to_end { gdb ndb vertex_id } {

	lassign [ $gdb eval {
		select diagram_id, item_id
		from vertices
		where vertex_id = :vertex_id
	} ] diagram_id item_id
	
	set end_vertex [ $gdb onecolumn {
		select vertex_id
		from vertices v
		inner join links l on v.vertex_id = l.dst
		where v.type = 'beginend'
		and v.diagram_id = :diagram_id
	} ]
	

	if { $end_vertex == {} } {
		error "end not found"
	}

	set end_item [ p.vertex_item $gdb $end_vertex ]	
	
	if { ![ nogoto::node_exists $ndb $end_item ] } {
		nogoto::insert_node $ndb $end_item "action" ""
	}
	
	nogoto::insert_link $ndb $item_id 0 $end_item normal
}

proc add_to_graph { gdb ndb vertex_id log } {

	set item_id [ p.vertex_item $gdb $vertex_id ]
	if { [ nogoto::node_exists $ndb $item_id ] } { return }
	set text [ p.vertex_text $gdb $vertex_id ]
	set type [ p.vertex_type $gdb $vertex_id ]


	set is_select 0
	if { $type == "beginend" } {
		set type "action"
		set text ""
	} elseif { $type == "select" } {
		set type "action"
		set is_select 1
	}

	nogoto::insert_node $ndb $item_id $type $text
	if { $log } {
		puts "nogoto::insert_node \$db $item_id $type $text"
	}
	
	if { $is_select } {
		link_to_end $gdb $ndb $vertex_id
		return
	}
	
	set ordinals [ $gdb eval {
		select ordinal
		from links
		where src = :vertex_id } ]
		
	set i 0
	foreach ordinal $ordinals {
		set dst [ p.link_dst $gdb $vertex_id $ordinal ]
		set dst_item [ p.vertex_item $gdb $dst ]
		
		nogoto::insert_link $ndb $item_id $i $dst_item normal
		if { $log } {
			puts "nogoto::insert_link \$db $item_id $i $dst_item normal"
		}
		
		incr i
		
		add_to_graph $gdb $ndb $dst $log
	}
}

proc sort_items { node_list start_item } {
	array set nodes $node_list
	set item_ids [ array names nodes ]
	
	if { [ llength $item_ids ] == 0 } {
		return [ list {} {} ]
	}
	
	nsorter::init sortingdb $start_item
	foreach item_id $item_ids {
		nsorter::add_node $item_id
	}
	
	foreach item_id $item_ids {
		set node $nodes($item_id)			
		lassign $node body links
		set i 1
		foreach link $links {
			set dst [ lindex $link 0 ]
			if { $dst != "last_item" && $dst != "has_return" } {
				nsorter::add_link $item_id $i $dst
				incr i
			}
		}
	}
	
	nsorter::complete_construction
	
	set sorted [ nsorter::sort ]
	set incoming [ nsorter::get_incoming_for_nodes ]
	
	return [ list $sorted $incoming ]
}



proc generate_functions { db gdb callbacks nogoto } {

	generate_functions_core $db $gdb $callbacks $nogoto 0
}

proc generate_functions_core { db gdb callbacks nogoto to } {

	set result {}
	$gdb eval {
		select diagram_id
		from diagrams
		order by name
	} {
		if { [ mwc::is_drakon $diagram_id ] && [ has_branches $gdb $diagram_id ] } {
			lappend result [ generate_function $gdb $diagram_id  \
				$callbacks $nogoto $to ]
		}
	}

	return $result
}


proc p.keywords { } {
	return {
		assign
		compare
		compare2
		while_start
		if_start
		elseif_start
		if_end
		else_start
		pass
		continue
		return_none
		block_close
		comment
		bad_case
		for_init
		for_check
		for_current
		for_incr
		for_declare
		body
		signature
		and
		or
		not
		break
		declare
		line_end
		enforce_nogoto
		inspect_tree
		tag
		goto
		shelf
		if_cond
		change_state
		shutdown
		fsm_merge
		select
		case_value
		case_else
		case_end
		select_end
		bad_case
		select_gen_default
		native_foreach
		can_glue
		exit_door
	}
}


proc put_callback { map_name action procedure } {
	upvar 1 $map_name map
	set keywords [ p.keywords ]
	if { ![ contains $keywords $action ] } {
		error "put_callback: Unknown callback action: $action"
	}
	put_value map $action $procedure
}

proc get_callback { map action } {
	set keywords [ p.keywords ]
	if { ![ contains $keywords $action ] } {
		error "get_callback: Unknown callback action: $action"
	}
	return [ get_value $map $action ]
}

proc get_optional_callback { map action } {
	set keywords [ p.keywords ]
	if { ![ contains $keywords $action ] } {
		error "get_optional_callback: Unknown callback action: $action"
	}
	set index [ find_key $map $action ]
	if { $index == -1 } { return "" }
	return [ get_value $map $action ]
}

proc get_param_names { parameters } {
	set params {}
	foreach parameter $parameters {
		lappend params [ lindex $parameter 0 ]
	}
	return $params	
}

proc print_variables { variables diagram_id signature var_keyword } {	
	lassign $signature type access parameters returns
	set params [ get_param_names $parameters ]
	if {[dict exists $variables $diagram_id ]} {
		set vars_all [ dict get $variables $diagram_id ]
		set vars {}
		foreach var $vars_all {
			if { ![contains $params $var] } {
				lappend vars $var
			}
		}
		
		if { $vars != {} } {
			set vars_str [join $vars ", " ]
			set line "    $var_keyword $vars_str"
			return $line
		}
	}
	return ""
}

proc diagram_exists { gdb name } {
	set id [ $gdb onecolumn {
		select diagram_id
		from diagrams
		where name = :name }]
	
	if {$id == ""} {
		return 0
	} else {
		return 1
	}
}

proc make_normal_state_method { name state message } {
	return "${name}_${state}_${message}"
}

proc make_default_state_method { name state } {
	return "${name}_${state}_default"
}

}
