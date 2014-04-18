
namespace eval mod {

variable db_names

proc open { db filename type } {
	variable db_names
	
	if { [ info exists db_names($db) ] } {
		return [ list  {} [ mc2 "Database name \$db is already used" ] ]
	}
	
	if { ![ file exists $filename ] } {
		return [ list  {} [ mc2 "File \$filename does not exist" ] ]
	}
		
	if { [ catch { sqlite3 $db $filename } msg ] } {
		return [ list  {} [ mc2 "Could not open database \$filename" ] $msg ]
	}
	
	if { [ catch {
		set actual_type [ one $db value info key 'type' ]
		set version [ one $db value info key 'version' ]
		set start_version [ one $db value info key 'start_version' ]
	} msg ] }  {
		$db close
		return [ list  {} [ mc2 "Incompatible database \$filename" ] $msg]
	}
	
	if { $actual_type != $type } {
		$db close
		return [ list  {} [ mc2 "Wrong schema in database \$filename" ] "type=$actual_type" ]
	}

	set db_names($db) $filename
	init_undo_db
	return [ list [ list $version $start_version ] "" ]
}

proc init_undo_db { } {
	catch { udb close }
	sqlite3 udb :memory:
	udb eval {
		create table state
		(
			current_undo integer
		);	
		
		create table undo_steps
		(
			step_id integer primary key,
			name text,
			delegates text
		);
		
		create table undo_actions
		(
			step_id integer,
			action_no integer,
			
			doit text,
			doit_change text,
		
			undoit text,
			undoit_change text,
			
			primary key (step_id asc, action_no asc)
		);
		
		insert into state (current_undo) values ('');
	}
}

proc create { db filename type version start_version script } {
	variable db_names
	
	if { [ info exists db_names($db) ] } {
		return [ mc2 "Database name \$db is already used" ]
	}
		
	catch { file delete $filename }
		
	if { [ catch { sqlite3 $db $filename } msg ] } {
		return [ mc2 "Could not create database \$filename" ]
	}
	
	if { [ catch { 
		init $db $type $version $start_version
		if { $script != "" } {
			$db eval $script
		}
	} msg ] } {
		log $msg
		$db close
		return [ mc2 "Could not init database \$filename" ]
	}	
	
	set db_names($db) $filename
	init_undo_db
	return ""
}

proc save_as { db filename } {
	variable db_names
	
	if { ![ info exists db_names($db) ] } {
		return [ mc2 "Unknown database name \$db" ]
	}
	
	set old_name $db_names($db)
	
	if { $filename == $old_name } { return }

	set type [ one $db value info key 'type' ]
	close $db
	
	if { [ catch { file copy -force -- $old_name $filename } ] } {
		return [ mc2 "Could not create or replace file \$filename" ]
	}
	

	set result [ open $db $filename $type ]
	return [ lindex $result 1 ]
}

proc close { db } {
	variable db_names
	
	if { ![ info exists db_names($db) ] } {
		return [ mc2 "Unknown database name \$db" ]
	}	
	
	$db close
	unset db_names($db)
	return ""
}

proc init { db type version start_version } {
	$db eval {
		create table info
		(
			key text primary key,
			value text
		);

		insert into info (key, value) values ('type', :type);	
		insert into info (key, value) values ('version', :version);	
		insert into info (key, value) values ('start_version', :start_version);	
	}
}

proc  fetch { db table key_name key args } {
	set columns [ join $args ", " ]
	set sql "select $columns from $table where $key_name = $key"
	return [ $db eval $sql ]
}

proc one { db column table key_name key } {
	set sql "select $column from $table where $key_name = $key"
	#puts $sql
	return [ $db onecolumn $sql ]
}

proc  fetch_with_names { db table key_name key args } {
	set columns [ join $args ", " ]
	set sql "select $columns from $table where $key_name = $key"
	set row [ $db eval $sql ]
	return [ zip $args $row ]
}

proc exists { db table key_name key } {
	set sql "select count(*) from $table where $key_name = $key"
	set count [ $db eval $sql ]
	return [ expr { $count > 0 } ]
}

proc apply { db changes } {
  if { [ catch {
	foreach change $changes {
		set edit [ lindex $change 0 ]
		switch $edit {
			insert { set sql [ make_insert $change ] }
			update { set sql [ make_update $change ] }
			delete { set sql [ make_delete $change ] }
			default { error [ mc2 "wrong command \$edit" ] }
		}
		#puts $sql
		$db eval $sql
	}
	} msg ] } {
    if { [ info exists sql ] } { log $sql }
    log $msg
    error $msg
  }
}

proc make_insert { rowinfo } {
	set count [ llength $rowinfo ]
	if { $count < 4 } {
		error [ mc2 "rowinfo too short for INSERT" ]
	}

	set table [ lindex $rowinfo 1 ]

	set names {}
	set values {}
	
	set i 2
	while { $i < $count } {
		set name [ lindex $rowinfo $i ]
		incr i
		set value [ lindex $rowinfo $i ]
		incr i
		lappend names $name
		lappend values $value
	}
	set names_expr [ join $names ", " ]
	set values_expr [ join $values ", " ]
	return "insert into $table ($names_expr) values ($values_expr);"
}

proc make_update { rowinfo } {
	set count [ llength $rowinfo ]
	if { $count < 6 } {
		error [ mc2 "rowinfo too short for UPDATE" ]
	}
	
	set table [ lindex $rowinfo 1 ]
	set key_name [ lindex $rowinfo 2 ]
	set key_value [ lindex $rowinfo 3 ]
	
	set pairs {}
	set i 4
	while { $i < $count } {
		set name [ lindex $rowinfo $i ]
		incr i
		set value [ lindex $rowinfo $i ]
		incr i
		lappend pairs "$name = $value"
	}
	set pairs_expr [ join $pairs ", " ]
	return "update $table set $pairs_expr where $key_name = $key_value;"
}

proc make_delete { rowinfo } {
	set count [ llength $rowinfo ]
	if { $count != 4 } {
		error [ mc2 "rowinfo for DELETE should contain <table> <key-field> <key-name>" ]
	}
	
	set table [ lindex $rowinfo 1 ]
	set key_name [ lindex $rowinfo 2 ]
	set key_value [ lindex $rowinfo 3 ]

	return "delete from $table where $key_name = $key_value;"	
}

proc next_key { db table key_column } {
	set sql "select max($key_column) from $table"
	set max [ $db onecolumn $sql ]
	if { $max == "" } { set max 0 }
	return [ expr { $max + 1 } ]
}



}
