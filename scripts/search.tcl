namespace eval search {

variable g_current -1
variable db <bad-db-search>

proc init { dbname } {
	variable db
	p.init_db
	set db $dbname
}


# state:
#  name
#  buffer
#  line
#  char_no
#  line_char_no

proc state.make { name buffer line char lchar start_char start_lchar } {
	return [ list $name $buffer $line $char $lchar $start_char $start_lchar ]
}

proc state.new {} {
	return [ state.make "idle" "" 0 0 0 0 0 ]
}

proc state.start { state name c } {
	lassign $state foo foo2 line char lchar
	set start_char $char
	set start_lchar $lchar
	incr char
	incr lchar	
	set buffer [ list $c ]
	return [ state.make $name $buffer $line $char $lchar $start_char $start_lchar ]
}

proc state.token { state c } {
	return [ state.start $state "token" $c ]
}

proc state.whitespace { state c } {
	return [ state.start $state "whitespace" $c ]
}

proc state.new_line { state } {
	lassign $state name buffer line char lchar
	incr line
	incr char
	set lchar 0

	return [ state.make "idle" "" $line $char $lchar 0 0 ]
}

proc state.append { state c } {
	lassign $state name buffer line char lchar s_char s_lchar
	incr char
	incr lchar
	lappend buffer $c
	return [ state.make $name $buffer $line $char $lchar $s_char $s_lchar ]
}

proc p.append { result buffer start line start_line } {
	upvar 1 $result output
	set buffer_text [ join_strings $buffer ]
	if { $buffer_text != "" } {
		lappend output [ list $buffer_text $start $line $start_line ]
	}
}

proc state.other { state result c } {
	upvar 1 $result output
	lassign $state name buffer line char lchar
	p.append output $c $char $line $lchar
	incr char
	incr lchar
	return [ state.make "idle" "" $line $char $lchar 0 0 ]
}

proc state.flush { state result } {
	upvar 1 $result output
	lassign $state name buffer line char lchar s_char s_lchar
	p.append output $buffer $s_char $line $s_lchar
	return [ state.make "idle" "" $line $char $lchar 0 0 ]
}

proc p.alpha { c } {
	if { $c == "_" || [ string is alnum $c ] } { return 1 }
	return 0
}

proc state.idle.next { state result c } {
	upvar 1 $result output
	if { $c == "\n" } {
		return [ state.new_line $state ]
	} elseif { [ string is space $c ] } {
		return [ state.whitespace $state $c ]
	} elseif { [ p.alpha $c ] } {
		return [ state.token $state $c ]
	} else {
		return [ state.other $state output $c ]
	}
}

proc state.token.next { state result c } {
	upvar 1 $result output
	if { $c == "\n" } {
		set state [ state.flush $state output ]
		return [ state.new_line $state ]
	} elseif { [ string is space $c ] } {
		set state [ state.flush $state output ]
		return [ state.whitespace $state $c ]
	} elseif { [ p.alpha $c ] } {
		return [ state.append $state $c ]
	} else {
		set state [ state.flush $state output ]
		return [ state.other $state output $c ]
	}
}

proc state.whitespace.next { state result c } {
	upvar 1 $result output
	if { $c == "\n" } {
		set state [ state.flush $state output ]
		return [ state.new_line $state ]
	} elseif { [ string is space $c ] } {
		return [ state.append $state $c ]
	} elseif { [ p.alpha $c ] } {
		set state [ state.flush $state output ]
		return [ state.token $state $c ]
	} else {
		set state [ state.flush $state output ]
		return [ state.other $state output $c ]
	}
}

proc p.state_name { state } {
	return [ lindex $state 0 ]
}

proc to_tokens { text } {
	set length [ string length $text ]
	set result {}
	
	set state [ state.new ]

	repeat i $length {
		set c [ string index $text $i ]
		set state_name [ p.state_name $state ]
		set state [ state.$state_name.next $state result $c ]
	}

	state.flush $state result
	return $result
}

proc p.match { haystack_chars needle_chars start } {
	set needle_length [ llength $needle_chars ]
	repeat i $needle_length {
		set hay_index [ expr { $start + $i } ]
		set hay [ lindex $haystack_chars $hay_index ]
		set needle [ lindex $needle_chars $i ]
		if { $hay != $needle } {
			return 0
		}
	}
	return 1
}

proc find_occurences { haystack needle } {
	if { $haystack == "" || $needle == "" } {
		return {}
	}

	set hay_chars [ split $haystack "" ]
	set needle_chars [ split $needle "" ]
	set hay_length [ llength $hay_chars ]
	set needle_length [ llength $needle_chars ]

	set result {}
	
	set start 0
	set line_start 0
	set line 0
	while { $start + $needle_length <= $hay_length } {
		if { [ lindex $hay_chars $start ] == "\n" } {
			incr start
			incr line
			set line_start 0
		} elseif { [ p.match $hay_chars $needle_chars $start ] } {
			lappend result [ list $start $line $line_start $needle_length ]
			incr start $needle_length
			incr line_start $needle_length
		} else {
			incr start
			incr line_start
		}
	}

	return $result
}

proc p.token_match { haystack needle start } {
	set needle_length [ llength $needle ]
	repeat i $needle_length {
		set hay_index [ expr { $start + $i } ]
		set hay_token [ lindex $haystack $hay_index ]
		set needle_token [ lindex $needle $i ]
		set hay_text [ lindex $hay_token 0 ]
		set needle_text [ lindex $needle_token 0 ]
		if { $hay_text != $needle_text } {
			return 0
		}
	}
	return 1
}

proc p.is_not_whitespace { token } {
	set text [ lindex $token 0 ]
	set trimmed [ string trim $text ]
	if { $trimmed == "" } {
		return 0
	} else {
		return 1
	}
}

proc remove_whitespace { tokens } {
	return [ filter -list $tokens -fun search::p.is_not_whitespace ]
}

proc find_token_occurences { haystack needle } {
	set result {}
	set haystack [ remove_whitespace $haystack ]
	set needle_length [ llength $needle ]
	set haystack_length [ llength $haystack ]
	if { $needle_length == 0 } {
		return {}
	}
	set start 0
	while { $start + $needle_length <= $haystack_length } {
		if { [ p.token_match $haystack $needle $start ] } {
			set hay_token [ lindex $haystack $start ]
			lassign $hay_token token_text token_start token_line token_lstart

			set last [ expr { $start + $needle_length - 1 } ]
			set last_token [ lindex $haystack $last ]
			lassign $last_token last_text last_start
			set last_text_length [ string length $last_text ]

			set match_length [ expr { $last_start - $token_start + $last_text_length } ]

			lappend result [ list $token_start $token_line $token_lstart $match_length ]
			incr start $needle_length
		} else {
			incr start
		}
	}
	return $result
}

proc p.build_segment_list { haystack_length occurences } {
	set result {}
	set prev_start 0
	foreach match $occurences {
		lassign $match start line lstart length
		set prev_length [ expr { $start - $prev_start } ]
		lappend result [ list 0 $prev_start $prev_length ]
		lappend result [ list 1 $start $length ]
		set prev_start [ expr { $start + $length } ]
	}
	set last_length [ expr { $haystack_length - $prev_start } ]
	lappend result [ list 0 $prev_start $haystack_length ]
	return $result
}

proc replace_occurences { haystack replacement occurences } {
	set hlength [ string length $haystack ]
	set segments [ p.build_segment_list $hlength $occurences ]
	set result ""
	foreach segment $segments {
		lassign $segment use_needle start length
		if { $use_needle } {
			append result $replacement
		} elseif { $length > 0 } {
			set last [ expr { $start + $length - 1 } ]
			set hay_fragment [ string range $haystack $start $last ]
			append result $hay_fragment
		}
	}
	return $result
}

proc replace_one { haystack replacement start length } {
	if { $length == 0 } {
		return $haystack
	}
	set last [ expr { $start + $length - 1 } ]
	return [ string replace $haystack $start $last $replacement ]
}

proc p.init_db { } {
	variable g_current

	catch { searchdb close }
	sqlite3 searchdb :memory:

	searchdb eval {
		create table matches
		(
			match_id integer primary key,
			object_type text,
			object_id integer,
			start integer,
			length integer,
			line integer,
			line_start integer,
			replaced integer
		);

		create table objects
		(
			object_type text,
			object_id integer,
			original text,
			changed text,
			primary key (object_type, object_id)
		);

		create table lines
		(
			line_id integer primary key,
			object_type text,
			object_id integer,
			line_no integer,
			line_text text,
			show_text text,
			ordinal integer
		);

		create unique index line_ord on lines (ordinal);

		create unique index lines_key on lines (object_type,
			object_id, line_no);

		create table results
		(
			result_id integer primary key,
			match_id integer
		);
		create unique index results_by_match on results (match_id);
	}
	set g_current -1
}

proc to_tokens_nw { text } {
	set tokens [ to_tokens $text ]
	return [ remove_whitespace $tokens ]
}

proc p.search_makes_sense { diagram_id current_only whole needle } {
	if { $needle == "" } { return 0 }
	if { $whole && [ string trim $needle ] == "" } { return 0 }
	if { $current_only && $diagram_id == "" } { return 0 }
	return 1
}

proc p.scan_texts { db needle diagram_id current_only whole icase } {

	if { $icase } {
		set needle [ string tolower $needle ]
	}
	if { $whole } {
		set needle_tokens [ to_tokens_nw $needle ]
	} else {
		set needle_tokens {}
	}
	
	if { $current_only } {
		p.scan_diagram $db $needle $needle_tokens $diagram_id $whole $icase
	} else {
		set file_description [ $db onecolumn { select description from state } ]
		p.scan 0 file_description $file_description $needle $needle_tokens $whole $icase
		
		$db eval { select diagram_id id from diagrams } {
			p.scan_diagram $db $needle $needle_tokens $id $whole $icase
		}
	}
}

proc p.scan { object_id object_type text needle needle_tokens whole icase } {
	if { $icase } {
		set text [ string tolower $text ]
	}
	if { $whole } {
		set tokens [ to_tokens_nw $text ]
		set occurences [ find_token_occurences $tokens $needle_tokens ]
	} else {
		set occurences [ find_occurences $text $needle ]
	}
	foreach match $occurences {
		lassign $match start line line_start length
		searchdb eval {
			insert into matches (object_type, object_id, start, line, line_start, length)
				values (:object_type, :object_id, :start, :line, :line_start, :length )
		}
	}
}

proc p.scan_diagram { db needle needle_tokens diagram_id whole icase } {
	$db eval { select item_id, text, text2 from items where diagram_id = :diagram_id
		and type != 'loopend'
	} {
		p.scan $item_id icon $text $needle $needle_tokens $whole $icase
		p.scan $item_id secondary $text2 $needle $needle_tokens $whole $icase
	}
	$db eval { select name, description from diagrams where diagram_id = :diagram_id } {
		p.scan $diagram_id diagram_description $description $needle $needle_tokens $whole $icase
		p.scan $diagram_id diagram_name $name $needle $needle_tokens $whole $icase
	}
}

proc p.save_original_texts { } {
	searchdb eval {
		select object_type, object_id from matches
		group by object_type, object_id } {
	
		set text [ p.get_actual_text $object_type $object_id ]
		searchdb eval { 
			insert into objects
			(object_type, object_id, original)
			values (:object_type, :object_id, :text)
		}
	}
	
	searchdb eval { update matches set replaced = 0 }
}

proc p.build_diagram_list { } {
	variable db
	return [ $db eval {
		select diagram_id
		from diagrams
		order by name } ]
}

proc p.add_icons { diagram_id } {
	variable db
	$db eval {
		select i.item_id item_id, i.type type, i.text text, d.name dia_name
		from items i inner join diagrams d
			on i.diagram_id = d.diagram_id
		where i.diagram_id = :diagram_id
		order by x, y
	} {
		set header "$dia_name: item $item_id '$type'"
		p.add_lines $header icon $item_id
		p.add_lines $header secondary $item_id
	}
}

proc p.add_lines { header object_type object_id } {
	set text [ searchdb onecolumn {
		select original
		from objects
		where object_type = :object_type
			and object_id = :object_id } ]
	if { $text == "" } { return }
	set lines [ split $text "\n" ]
	searchdb eval {
		select line
		from matches
		where object_type = :object_type
			and object_id = :object_id
		group by line
		order by line
	} {
		set line_text [ lindex $lines $line ]
		set ordinal [ searchdb onecolumn {
			select count(*) from lines } ]
		set show_text "$header: $line_text"
		searchdb eval {
			insert into lines
			(object_type, object_id, line_no, line_text, show_text, ordinal)
			values
			(:object_type, :object_id, :line, :line_text, :show_text, :ordinal) }
	}
}

proc p.sort_results { } {
	variable g_current
	searchdb eval {
		select object_type, object_id, line_no
		from lines
		order by ordinal
	} {
		searchdb eval {
			select match_id
			from matches
			where object_type = :object_type
				and object_id = :object_id
				and line = :line_no
			order by match_id
		} {
			searchdb eval {
				insert into results (match_id) values (:match_id) }
		}
	}
	
	set g_current [ searchdb onecolumn { select min(result_id) from results } ]
	if { $g_current == "" } {
    set g_current -1
  }
}

proc p.build_result { } {
	variable db
	p.save_original_texts
	p.add_lines [ mc2 "File description" ] file_description 0
	set diagrams [ p.build_diagram_list ]
	foreach diagram_id $diagrams {
		set name [ $db onecolumn {
			select name
			from diagrams
			where diagram_id = :diagram_id } ]
		p.add_lines [ mc2 "$name: diagram name" ] diagram_name $diagram_id
		p.add_lines [ mc2 "$name: diagram description" ] diagram_description $diagram_id
		p.add_icons $diagram_id
	}
	p.sort_results	
}

proc find_all { db needle diagram_id current_only whole icase } {
	if { ![ p.search_makes_sense $diagram_id $current_only $whole $needle ] } {
		return 0
	}
	p.init_db
	p.scan_texts $db $needle $diagram_id $current_only $whole $icase
	p.build_result
	return 1
}

proc replace_all { db needle diagram_id current_only whole icase replacement } {
	if { ![ p.search_makes_sense $diagram_id $current_only $whole $needle ] } {
		return 0
	}
	p.init_db
	p.scan_texts $db $needle $diagram_id $current_only $whole $icase
	p.build_result
	p.replace_all_kernel $replacement
	set count [ searchdb onecolumn { select count(*) from matches } ]
	p.init_db
	return $count
}

proc p.replace_for_object { object_type object_id original replacement } {
	set occurences {}
	searchdb eval {
		select start, length
		from matches
		where object_type = :object_type
			and object_id = :object_id
		order by match_id
	} {
		lappend occurences [ list $start foo foo $length ]
	}
	return [ replace_occurences $original $replacement $occurences ]
}

proc p.replace_all_kernel { replacement } {
	set file {}
	set icons {}
	set secondaries {}
	set diagrams {}

	searchdb eval {
		select object_type, object_id, original
		from objects
	} {
		set changed [ p.replace_for_object $object_type $object_id $original $replacement ]
		set change [ list $object_id $changed ]

		switch $object_type {
			"icon" {
				lappend icons $change
			}
			"secondary" {
				lappend secondaries $change
			}			
			"diagram_description" {
				lappend diagrams $change
			}
			"file_description" {
				lappend file $change
			}
		}
	}
	
	mwc::global_replace $file $diagrams $icons $secondaries
	mwc::adjust_icon_sizes
}

proc get_match_object { } {
	variable g_current
	if { $g_current == -1 } {
		return ""
	}
  searchdb eval {
    select object_type, object_id, m.match_id match_id
    from matches m
      inner join results r on m.match_id = r.match_id
    where r.result_id = :g_current
  } {
    if { [ p.match_valid $match_id ] } {
      return [ list $object_type $object_id ]
    }
  }
  return ""
}

proc p.get_current_match_id { } {
	variable g_current
	if { $g_current == -1 } {
		return ""
	}
	searchdb eval { select match_id from results where result_id = :g_current } {
		if { [ p.match_valid $match_id ] } {
			return $match_id
		}
	}
	return ""
}

proc get_current_match { } {
	set match_id [ p.get_current_match_id ]
	searchdb eval { select object_type, object_id, line, line_start, length
		from matches where match_id = :match_id
	} {
		set active [ list $line_start $length ]
		set line_text [ searchdb onecolumn { select line_text from lines
			where object_type = :object_type
			and object_id = :object_id
			and line_no = :line } ]
		
		set others {}
	
		searchdb eval { select length length2, line_start line_start2
			from matches
			where object_type = :object_type
				and object_id = :object_id
				and line = :line
				and match_id != :match_id
				and replaced = 0
			order by match_id
		} {
			lappend others [ list $line_start2 $length2 ]
		}
		return [ list $line_text $active $others ]
	}
	return ""
}

proc p.set_current_match { match_id } {
 	variable g_current
	searchdb eval {
		select result_id
		from results
		where match_id = :match_id
	} {
		set g_current $result_id
	}
}

proc set_current_list_item { ordinal } {
  
  searchdb eval {
    select object_type, object_id, line_no
    from lines
    where ordinal = :ordinal
  } {
    searchdb eval {
      select match_id
      from matches
      where object_type = :object_type
        and object_id = :object_id
        and line = :line_no
      order by match_id
    } {
      if { [ p.match_valid $match_id ] } {
        p.set_current_match $match_id
        return 1
      }
    }
    
    p.set_current_match [ searchdb onecolumn {
      select min(match_id)
      from matches
      where object_type = :object_type
        and object_id = :object_id
        and line = :line_no } ]
    return 1      
  }
  return 0
}

proc get_current_list_item { } {
	variable g_current
	if { $g_current == -1 } {
		return -1
	}
	searchdb eval { 
		select object_type, object_id, line
		from matches m inner join results r
			on m.match_id = r.match_id
		where r.result_id = :g_current } {		
		
		set ordinal [ searchdb onecolumn {
			select ordinal from lines
			where object_type = :object_type
				and object_id = :object_id
				and line_no = :line } ]
		return $ordinal
	}
	return -1
}

proc get_match_count { } {
	return [ searchdb eval {
		select count(*) from results } ]
}

proc get_list { } {
	variable g_current
	if { $g_current == -1 } {
		return {}
	}
	set result [ searchdb eval {
		select show_text from lines order by ordinal } ]
	return $result
}

proc p.get_actual_text { object_type object_id } {
	variable db
	switch $object_type {
		"file_description" {
			return [ $db onecolumn { select description from state } ]
		}
		"diagram_name" {
			return [ $db onecolumn { select name from diagrams
				where diagram_id = :object_id } ]
		}
		"diagram_description" {
			return [ $db onecolumn { select description from diagrams
				where diagram_id = :object_id } ]
		}
		"icon" {
			return [ $db onecolumn { select text from items
				where item_id = :object_id } ]
		}
		"secondary" {
			return [ $db onecolumn { select text2 from items
				where item_id = :object_id } ]
		}
		
		default {
			error [ mc2 "Wrong object type: \$object_type" ]
		}
	}
}

proc p.match_valid { match_id } {
	searchdb eval { select object_type, object_id, replaced
		from matches
		where match_id = :match_id } {
	
		if { $replaced } {
			return 0
		}
		set new_text [ p.get_actual_text $object_type $object_id ]
		set original_text [ searchdb onecolumn {
			select original from objects
			where object_type = :object_type
			and object_id = :object_id } ]
		if { $new_text == $original_text } {
			return 1
		}
	}
	return 0
}

proc next { } {
	variable g_current
	if { $g_current == -1 } {
		return 0
	}
	set max [ searchdb onecolumn { select max(result_id) from results } ]
	set next [ expr { $g_current + 1 } ]
	for { set i $next } { $i <= $max } { incr i } {
    set match_id [ searchdb onecolumn { 
      select match_id
      from results
      where result_id = :i } ]
      
		if { [ p.match_valid $match_id ] } {
			set g_current $i
			return 1
		}
	}
	return 0
}

proc previous { } {
	variable g_current
	if { $g_current == -1 } {
		return 0
	}
	set min [ searchdb onecolumn { select min(result_id) from results } ]
	set prev [ expr { $g_current - 1 } ]
	for { set i $prev } { $i >= $min } { incr i -1 } {
		set match_id [ searchdb onecolumn { 
			select match_id
			from results
			where result_id = :i } ]
	
		if { [ p.match_valid $match_id ] } {
			set g_current $i
			return 1
		}
	}
	return 0
}

proc set_text { object_type object_id replaced } {
	switch $object_type {
		"icon" {
			mwc::change_icon_text $object_id $replaced
			return 1
		}
		"secondary" {
			mwc::change_icon_secondary_text $object_id $replaced
			return 1
		}
		"diagram_name" {
			return [ mwc::change_dia_name_only $object_id $replaced ]
		}
		"diagram_description" {
			mwc::do_dia_properties_kernel $object_id $replaced
			return 1
		}
		"file_description" {
			mwc::do_file_description foo $replaced
			return 1
		}
		default {
			error [ mc2 "Unsupported object_type: \$object_type" ]
		}
	}
}

proc update_original { object_type object_id replaced } {
	searchdb eval {
		update objects
		set original = :replaced
		where object_type = :object_type
			and object_id = :object_id }
}

proc update_lines { object_type object_id replaced } {
	set lines [ split $replaced "\n" ]
	searchdb eval {
		select line_id, line_no
		from lines
		where object_type = :object_type
			and object_id = :object_id
	} {
		set line_text [ lindex $lines $line_no ]
		searchdb eval {
			update lines
			set line_text = :line_text
			where line_id = :line_id }
	}
}

proc shift_remaining { match_id replacement } {
	set match [ searchdb eval { select object_type, object_id, length, line
		from matches where match_id = :match_id } ]
	lassign $match object_type object_id old_length line_no
	set rlength [ string length $replacement ]
	set diff [ expr { $rlength - $old_length } ]
	searchdb eval { 
		select match_id, start, length, line, line_start
		from matches
		where object_type = :object_type
			and object_id = :object_id
			and match_id > :match_id
	} {
		set new_start [ expr { $start + $diff } ]
		searchdb eval {
			update matches
			set start = :new_start
			where match_id = :match_id }
		if { $line_no == $line } {
			set new_lstart [ expr { $line_start + $diff } ]
			searchdb eval {
				update matches
				set line_start = :new_lstart
				where match_id = :match_id }
		}			
	}
}


proc replace { replacement } {
	set match_id [ p.get_current_match_id ]
	if { $match_id == "" } { return 0 }
	searchdb eval {
		select object_type, object_id, start, length, line
		from matches
		where match_id = :match_id
	} {
		set text [ p.get_actual_text $object_type $object_id ]
		set replaced [ replace_one $text $replacement $start $length ]
		set success [ set_text $object_type $object_id $replaced ]

		if { !$success } { return 0 }
		if { $object_type == "icon" || $object_type == "secondary" } {
			mwc::adjust_icon_sizes_current
		}
		update_original $object_type $object_id $replaced
		update_lines $object_type $object_id $replaced
		shift_remaining $match_id $replacement
		searchdb eval {
			update matches
			set replaced = 1
			where match_id = :match_id
		}
		return 1
	}
	return 0
}

}




