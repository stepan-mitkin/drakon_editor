gen::add_generator "KuMir" gen_kumir::generate

namespace eval gen_kumir {

variable d_keywords {
	алг
	нач
	кон
	исп
	кон_исп
	дано
	надо
	арг
	рез
	аргрез
	знач
	цел
	вещ
	лог
	сим
	лит
	таб
	целтаб
	вещтаб
	логтаб
	литтаб
	и
	или
	не
	да
	нет
	утв
	выход
	ввод
	вывод
	нс
	если
	то
	иначе
	все
	выбор
	при
	нц
	кц
	кц_при
	раз
	пока
	для
	от
	до
	шаг
}

# An optional procedure for syntax highlighting
proc highlight { tokens } {
	variable d_keywords
	return [ gen_cs::highlight_generic $d_keywords $tokens ]
}

# The code generator procedure. It will be called by DRAKON Editor.
# Arguments:
#   db - A handle to the database of the original file. Read only!
#   gdb - A handle to the temporary database. Read-write.
#   filename - The .drn filename.
proc generate { db gdb filename } {
	global errorInfo
	
	# Construct the callbacks dictionary
	set callbacks [ make_callbacks ]

	# Get the list of diagrams
	set diagrams [ $gdb eval {
		select diagram_id from diagrams } ]
		
	# Select only DRAKON diagrams and pre-process them.
	foreach diagram_id $diagrams {
		if { [ mwc::is_drakon $diagram_id ] } {
			set append_semicolon 1
			gen::fix_graph_for_diagram $gdb $callbacks $append_semicolon $diagram_id
		}
	}
	
	# Do the code generation
	set nogoto 1
	set functions [ gen::generate_functions \
		$db $gdb $callbacks $nogoto ]

	# Abort if any errors happened so far.
	if { [ graph::errors_occured ] } { return }

	set hfile [ replace_extension $filename "kum" ]
	
	# Open the output file and write the code.
	set f [ create_kumir_file $hfile ]
	catch {
		print_to_file $f $functions
	} error_message
	set savedInfo $errorInfo
	
	# Close the file regardless of exceptions.	
	catch { close $f }
	if { $error_message != "" } {
		puts $errorInfo
		# Rethrow the exception
		error $error_message savedInfo
	}
}

proc create_kumir_file { filename } {	
	set handle [ open $filename w ]
	fconfigure $handle -translation binary -encoding binary
	set bom [binary format ccc 0xEF 0xBB 0xBF]
	puts $handle $bom
	flush $handle
	fconfigure $handle -encoding "utf-8"
	return $handle
}

# Builds a collection of code snippet generators specific to the D language.
proc make_callbacks { } {
	set callbacks {}

	gen::put_callback callbacks assign			gen_kumir::assign
	gen::put_callback callbacks compare			gen_kumir::compare
	gen::put_callback callbacks compare2		gen_kumir::compare
	gen::put_callback callbacks while_start 	gen_kumir::while_start
	gen::put_callback callbacks if_start		gen_kumir::if_start
	gen::put_callback callbacks elseif_start	gen_kumir::elseif_start
	gen::put_callback callbacks if_end			gen_kumir::if_end
	gen::put_callback callbacks if_block_end	gen_kumir::if_block_end	
	gen::put_callback callbacks else_start		gen_kumir::else_start
	gen::put_callback callbacks pass			gen_kumir::pass
	gen::put_callback callbacks return_none		gen_kumir::return_none
	gen::put_callback callbacks block_close		gen_kumir::block_close
	gen::put_callback callbacks comment			gen_kumir::comment
	gen::put_callback callbacks bad_case		gen_kumir::bad_case
	gen::put_callback callbacks for_declare		gen_kumir::foreach_declare	
	gen::put_callback callbacks for_init		gen_kumir::foreach_init
	gen::put_callback callbacks for_check		gen_kumir::foreach_check
	gen::put_callback callbacks for_current		gen_kumir::foreach_current
	gen::put_callback callbacks for_incr		gen_kumir::foreach_incr
	gen::put_callback callbacks and				gen_kumir::and
	gen::put_callback callbacks or				gen_kumir::or
	gen::put_callback callbacks not				gen_kumir::not
	gen::put_callback callbacks break			"\u0432\u044B\u0445\u043E\u0434"
	gen::put_callback callbacks declare			gen_kumir::declare
	gen::put_callback callbacks shelf			gen_kumir::shelf
				
	gen::put_callback callbacks body			gen_kumir::generate_body
	gen::put_callback callbacks signature		gen_kumir::extract_signature
	gen::put_callback callbacks native_foreach	gen_kumir::native_foreach

	return $callbacks
}

# A simple variable assignment.
proc assign { variable value } {
	return "$variable := $value"
}

# A comparison of two values.
proc compare { variable constant } {
	return "$variable = $constant"
}

# The beginning of an eternal __while__ loop.
proc while_start { } {
	return "\u043D\u0446"
}

# The left part of an __if__ condition
proc if_start { } {
	return "\u0435\u0441\u043B\u0438 "
}

# slse if expression
proc elseif_start { } {
    return "\u0438\u043D\u0430\u0447\u0435"
}

# The right part of __if__ condition
proc if_end { } {
    return " \u0442\u043e"
}

proc if_block_end { output depth } {
    upvar 1 $output result
    set line [ gen::make_indent $depth ]
    append line "\u0432\u0441\u0435"
    lappend result $line
}

# else expression
proc else_start { } {
    return "\u0438\u043D\u0430\u0447\u0435"
}

# Empty expression.
proc pass { } {
    return ""
}

# Early exit from a function
proc return_none { } {
    return "\u0432\u044B\u0445\u043E\u0434"
}

# End of a block.
# Appends a line with an indented closing curly to the output.
proc block_close { output depth } {
    upvar 1 $output result
    set line [ gen::make_indent $depth ]
    append line "\u043A\u0446"
    lappend result $line
}

# A one-line comment.
proc comment { line } {
    return "| $line"
}

# Raises an error when the control reaches an unexpected "case" branch.
proc bad_case { switch_var select_icon_number } {
    if {[ string compare -nocase $switch_var "select" ] == 0} {
    	return "\u0432\u044b\u0432\u043e\u0434 \u0022\u041e\u0448\u0438\u0431\u043e\u0447\u043d\u043e\u0435 \u0441\u043e\u0441\u0442\u043e\u044f\u043d\u0438\u0435\u002e\u0022\u002c \u043d\u0441\u003b \u0432\u044b\u0445\u043e\u0434"
    } else {	
		return "\u0432\u044b\u0432\u043e\u0434 \u0022\u041e\u0448\u0438\u0431\u043e\u0447\u043d\u043e\u0435 \u0437\u043d\u0430\u0447\u0435\u043d\u0438\u0435 $switch_var=\u0022, $switch_var, \u043d\u0441\u003b \u0432\u044b\u0445\u043e\u0434"		
	}
}

proc native_foreach { for_it for_var } {
	return ""
}

# Declares the iterator and/or the iterated variable.
# We don't need this in D.
proc foreach_declare { item_id first second } {
    return ""
}

# Initialises the iterator.
# With D, we declare and init a range.
proc foreach_init { item_id first second } {
	return ""
}

# Checks whether it is time to exit the iteration. 
proc foreach_check { item_id first second } {
	return ""
}

# Gets the current element from the iterator.
proc foreach_current { item_id first second } {
	return ""
}

# Advances the iterator.
proc foreach_incr { item_id first second } {
    #item 32
    return ""
}

# AND logical operator
proc and { left right } {
    return "($left) \u0438 ($right)"
}

# OR logical operator
proc or { left right } {
    return "($left) \u0438\u043b\u0438 ($right)"
}

# NOT logical operator
proc not { operand } {
    #item 633
    return "\u043d\u0435 \($operand\)"
}

# Declares and inits a variable
proc declare { type name value } {
    if { $value == "" } {
		return "\u0446\u0435\u043b $name"
    } else {
		return "\u0446\u0435\u043b $name; $name := $value"
    }
}

# Builds code for a __shelf__ icon.
proc shelf { primary secondary } {
    return "$secondary := $primary"
}

# DRAKON Editor could not generate a body for the function.
# The code generation failed.
# Probably, the algorithm is too complex for the generator.
# The plugin is supposed to fix this.
# We resort to the loop generator that always works, but is quite slow.
proc generate_body { gdb diagram_id start_item node_list items incoming } {
    set callbacks [ make_callbacks ]
    return [ cbody::generate_body $gdb $diagram_id $start_item $node_list \
    $items $incoming $callbacks ]
}

# Remove comments
# Drop empty lines.
proc drop_empty_lines { pairs } {
	set result {}
	foreach pair $pairs {
		lassign $pair code comment
		if { $code != {} } {
			lappend result $pair
		}
	}
	return $result
}

# Gets the return type and arguments.
proc get_return_type_and_arguments { pairs } {
	if { $pairs == {} } {
		set arguments {}
		set returns "void"
	} else {
		set last [ lindex $pairs end ]
		set start [ lindex $last 0 ]
		if { [ string match "returns *" $start ] } {
			set arguments [ lrange $pairs 0 end-1]
			set returns [ gen_cpp::extract_return_type $start ]
		} else {
			set arguments $pairs
			set returns "void"
		}
	}
	
	return [ list $returns $arguments ]
}

# This callback generates a signature given the text of the "formal parameters" icon.
# (An optional icon that sits to the right from the diagram header.)
# Here, we just build a simple signature that consists of:
# - arguments
# - return value
# f. ex. int Foo(int a, string b)
proc extract_signature { text name } {
	set lines [get_non_empty_lines $text]
	set guards {}
	set returns ""
	set parameters {}
	foreach line $lines {
		set parts [split $line]
		set first [lindex $parts 0]		
		if {$first == "\u0437\u043d\u0430\u0447"} {
			set returns [string trim [string range $line 4 end]]
		} elseif {$first == "\u0434\u0430\u043d\u043e"} {
			lappend guards $line
		} elseif {$first == "\u043d\u0430\u0434\u043e"} {
			lappend guards $line
		} else {
			lappend parameters $line
		}
	}

	set type "procedure"
    set signature [ gen::create_signature $type $guards $parameters $returns ]

	# No errors occurred.
	set error_message ""
    return [ list $error_message $signature ]
}

proc get_non_empty_lines { text } {
	set result {}
	set lines [ split $text "\n"]
	foreach line $lines {
		set no_comment [strip_comment $line]
		set trimmed [string trim $no_comment ]
		if {$trimmed != ""} {
			lappend result $trimmed
		}
	}

	return $result
}

proc strip_comment {text} {
	set parts [split $text "|"]
	if {[llength $parts] == 0} {
		return ""
	}

	return [lindex $parts 0]
}

# Writes everything to the output file.
proc print_to_file { fhandle functions} {
	# Print the proud banner first.
	set version [ version_string ]
	puts $fhandle \
	    "| \u0421\u0433\u0435\u043d\u0435\u0440\u0438\u0440\u043e\u0432\u0430\u043d\u043e\u0020\u043f\u0440\u0438\u0020\u043f\u043e\u043c\u043e\u0449\u0438\u0020\u0044\u0052\u0041\u004b\u004f\u004e\u0020\u0045\u0064\u0069\u0074\u006f\u0072 $version"

	puts $fhandle ""

	set normal_functions {}
	set introduction ""
	set main ""
	foreach function $functions {
		lassign $function diagram_id name signature body
		if {$name == "\u0433\u043b\u0430\u0432\u043d\u044b\u0439"} {
			set main $function
		} elseif {$name == "\u0432\u0441\u0442\u0443\u043f\u043b\u0435\u043d\u0438\u0435"} {
			set introduction $function
		} else {
			lappend normal_functions $function
		}
	}

	if {$main == ""} {
		error "Отсутствует алгоритм 'главный'"
	}

	if {$introduction != ""} {
		print_introduction $fhandle $introduction
	}

	print_function $fhandle $main

	foreach function $normal_functions {
		print_function $fhandle $function
	}

	puts $fhandle ""	
}


proc print_function { fhandle function } {
	lassign $function diagram_id name signature body
	puts $fhandle ""			
	set declaration [ build_declaration $name $signature ]
	puts $fhandle $declaration
	puts $fhandle "\u043d\u0430\u0447"	
	set lines [ gen::indent $body 1 ]
	puts $fhandle $lines
	puts $fhandle "\u043a\u043e\u043d"
}

proc print_introduction { fhandle function } {
	lassign $function diagram_id name signature body
	set lines [ gen::indent $body 0 ]
	puts $fhandle $lines
	puts ""
}

# Builds the header of a function.
proc build_declaration { name signature } {
	lassign $signature type guards parameters returns
	set result "\u0430\u043b\u0433 " 
	if {$name != "\u0433\u043b\u0430\u0432\u043d\u044b\u0439"} {
		if { $returns != "" } {
			append result "$returns "
		}

		if {[llength $parameters] == 0 } {
			append result "$name"
		} else {
			append result "$name\("
			append result [ join $parameters ", " ]
			append result "\)"
		}
	}

	foreach guard $guards {
		append result "\n    $guard"
	}

	return $result
}


}
