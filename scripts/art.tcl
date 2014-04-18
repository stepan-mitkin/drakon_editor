
namespace eval art {


proc p.generate_accessors { ns table field } {
	set getter "::${ns}::get_${table}_${field}"
	set array_name "t_${table}_${field}"
	set body "variable $array_name\n"
	append body "if \{ \[ info exists $array_name\(\$key\) \] \} \{\n"
	append body "    return \$$array_name\(\$key\)\n"
	append body "\} else \{\n"
	append body "    return \{\}\n"
	append body "\}"
	proc $getter { key } $body

	set setter "::${ns}::set_${table}_${field}"
	set setter_body "variable $array_name\n"
	append setter_body "set $array_name\(\$key\) \$value"
	proc $setter { key value } $setter_body

	set remover "::${ns}::remove_${table}_${field}"
	set remover_body "variable $array_name\n"
	append remover_body "unset $array_name\(\$key\)"
	proc $remover { key } $remover_body	

	set keys "::${ns}::${table}_${field}_keys"
	set keys_body "variable $array_name\n"
	append keys_body "return \[ array names $array_name \]"
	proc $keys { } $keys_body
}

proc create { ns table field } {
	set name "${ns}::t_${table}_${field}"
	if { [ info exists $name ] } {
		p.unset_array $name
	}
	set command [ list variable $name ]
	set command2 [ list array set $name {} ]
	uplevel #0 $command
	uplevel #0 $command2

	p.generate_accessors $ns $table $field
}

proc create_table { ns table fields } {
	foreach field $fields {
		create $ns $table $field
	}
	set counter "::${ns}::g_${table}_next_id"
	uplevel #0 "if \{ !\[info exists $counter \]\} \{ variable $counter \}"
	uplevel #0 "set $counter 1"

	set id_getter "::${ns}::${table}_next_id"
	set body "variable $counter\n"
	append body "set result \$$counter\n"
	append body "incr $counter\n"
	append body "return \$result"
	proc $id_getter { } $body

	set inserter "::${ns}::insert_${table}"
	set body ""
	foreach field $fields {
		append body "set_${table}_${field} \$id \$$field\n"
	}
 	set arguments [ linsert $fields 0 id ]
	proc $inserter $arguments $body


	set fetcher "::${ns}::fetch_${table}"
	set body "set result \[ list id \$id \]\n"
	foreach field $fields {
		append body "lappend result $field \[ get_${table}_${field} \$id \]\n"
	}
	append body "return \$result"
	proc $fetcher { id } $body

	set printer "::${ns}::print_${table}"
	
	set first_field [ lindex $fields 0 ]
	set body "set keys \[ ${table}_${first_field}_keys \]\n"
	append body "puts \"$table: \[ llength \$keys \] rows\"\n"
	append body "foreach id \$keys \{ puts \[ fetch_${table} \$id \]  \}\n"
	proc $printer {} $body
}

proc p.unset_array { name } {
	set command [ list array unset $name ]
	uplevel #0 $command
}

}

