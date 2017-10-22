gen::add_generator "Go" gen_go::generate

namespace eval gen_go {

# These keywords can be used in function headers.
variable keywords {
    break        default      func         interface    select
    case         defer        go           map          struct
    chan         else         goto         package      switch
    const        fallthrough  if           range        type
    continue     for          import       return       var
	bool string
	int uint
	int8 int16 int32 int64
	uint8 uint16 uint32 uint64
	float32 float64
	complex64 complex128
	byte rune uintptr
	true false
	nil
	len cap
}


# An optional procedure for syntax highlighting
proc highlight { tokens } {
	variable keywords
	return [ gen_cs::highlight_generic $keywords $tokens ]
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

	# Extract sections from the file descriptions
	lassign [ gen::scan_file_description $db { header footer } ] header footer

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

	set hfile [ replace_extension $filename "go" ]
	
	# Open the output file and write the code.
	set f [ open_output_file $hfile ]
	catch {
		print_to_file $f $functions $header $footer
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

# Builds a collection of code snippet generators specific to the Go language.
proc make_callbacks { } {
	set callbacks {}

	gen::put_callback callbacks assign			gen_go::assign
	gen::put_callback callbacks compare			gen_go::compare
	gen::put_callback callbacks compare2		gen_go::compare
	gen::put_callback callbacks while_start 	gen_go::while_start
	gen::put_callback callbacks if_start		gen_go::if_start
	gen::put_callback callbacks elseif_start	gen_go::elseif_start
	gen::put_callback callbacks if_end			gen_go::if_end
	gen::put_callback callbacks else_start		gen_go::else_start
	gen::put_callback callbacks pass			gen_go::pass
	gen::put_callback callbacks return_none		gen_go::return_none
	gen::put_callback callbacks block_close		gen_go::block_close
	gen::put_callback callbacks comment			gen_go::comment
	gen::put_callback callbacks bad_case		gen_go::bad_case
	gen::put_callback callbacks for_declare		gen_go::foreach_declare	
	gen::put_callback callbacks for_init		gen_go::foreach_init
	gen::put_callback callbacks for_check		gen_go::foreach_check
	gen::put_callback callbacks for_current		gen_go::foreach_current
	gen::put_callback callbacks for_incr		gen_go::foreach_incr
	gen::put_callback callbacks and				gen_go::and
	gen::put_callback callbacks or				gen_go::or
	gen::put_callback callbacks not				gen_go::not
	gen::put_callback callbacks break			"break"
	gen::put_callback callbacks declare			gen_go::declare
	gen::put_callback callbacks shelf			gen_go::shelf
				
	gen::put_callback callbacks body			gen_go::generate_body
	gen::put_callback callbacks signature		gen_go::extract_signature
	gen::put_callback callbacks native_foreach	gen_go::native_foreach

	return $callbacks
}

# A simple variable assignment.
proc assign { variable value } {
	return "$variable = $value"
}

# A comparison of two values.
proc compare { variable constant } {
	return "$variable == $constant"
}

# The beginning of an eternal __while__ loop.
proc while_start { } {
	return "for \{"
}

# The left part of an __if__ condition
proc if_start { } {
	return "if "
}

# slse if expression
proc elseif_start { } {
    return "\} else if "
}

# The right part of __if__ condition
proc if_end { } {
    return " \{"
}

# else expression
proc else_start { } {
    return "\} else \{"
}

# Empty expression.
proc pass { } {
    return ""
}

# Early exit from a function
proc return_none { } {
    return "return"
}

# End of a block.
# Appends a line with an indented closing curly to the output.
proc block_close { output depth } {
    upvar 1 $output result
    set line [ gen::make_indent $depth ]
    append line "\}"
    lappend result $line
}

# A one-line comment.
proc comment { line } {
    return "// $line"
}

# Raises an error when the control reaches an unexpected "case" branch.
proc bad_case { switch_var select_icon_number } {
    if {[ string compare -nocase $switch_var "select" ] == 0} {
    	return "panic\(\"Not expected condition.\"\)"
    } else {	
		return "panic\(\"Not expected $switch_var\"\)"
	}
}

proc native_foreach { for_it for_var } {
	return "for $for_it := range $for_var \{"
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
    return "($left) && ($right)"
}

# OR logical operator
proc or { left right } {
    return "($left) || ($right)"
}

# NOT logical operator
proc not { operand } {
    #item 633
    return "!\($operand\)"
}

# Declares and inits a variable
proc declare { type name value } {
    if { $value == "" } {
        return "var $name $type"
    } else {
        return "$name := $value"
    }
}

# Builds code for a __shelf__ icon.
proc shelf { primary secondary } {
    return "$secondary = $primary"
}

# DRAKON Editor could not generate a body for the function.
# The code generation failed.
# Probably, the algorithm is too complex for the generator.
# The plugin is supposed to fix this.
# We resort to the loop generator that always works, but is quite slow.
proc generate_body { gdb diagram_id start_item node_list items incoming } {
	set name [ $gdb onecolumn {
		select name from diagrams where diagram_id = :diagram_id
	} ]
	error "Diagram $name is too complex"
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
		set returns ""
	} else {
		set last [ lindex $pairs end ]
		set start [ lindex $last 0 ]
		if { [ string match "returns *" $start ] } {
			set arguments [ lrange $pairs 0 end-1]
			set returns [ gen_cpp::extract_return_type $start ]
		} else {
			set arguments $pairs
			set returns ""
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
	# Separate code from comments that start with //
	set pairs_raw [ gen::separate_from_comments $text ]
	# Get only meaningful lines.
	set pairs [ drop_empty_lines $pairs_raw ]

	lassign [ get_return_type_and_arguments $pairs ] returns parameters
	

	
	set type "procedure"
    set signature [ gen::create_signature $type {} $parameters $returns ]

	# No errors occurred.
	set error_message ""
    return [ list $error_message $signature ]
}

# Writes everything to the output file.
proc print_to_file { fhandle functions header footer } {
	# Print the proud banner first.
	set version [ version_string ]
	puts $fhandle \
	    "// Autogenerated with DRAKON Editor $version"


	puts $fhandle ""
	puts $fhandle $header
	puts $fhandle ""
	# Print the functions, one by one.
	foreach function $functions {
		lassign $function diagram_id name signature body
		puts $fhandle ""
		set declaration [ build_declaration $name $signature ]
		puts $fhandle $declaration
		set lines [ gen::indent $body 1 ]
		puts $fhandle $lines
		puts $fhandle "\}"
	}
	puts $fhandle ""
	puts $fhandle $footer
}

# Builds the header of a function.
proc build_declaration { name signature } {
	lassign $signature type access parameters returns
	
	if { $parameters == {} } {
	
        set params2 ""
        set self ""
    } else {
        set first_line [ lindex $parameters 0 ]
        set first [ lindex $first_line 0 ]
        set first_name [ lindex $first 0 ]
        if { $first_name == "self" } {
            set params2 [ lrange $parameters 1 end ]
            set self "\($first\)"
        } else {
            set params2 $parameters
            set self ""
        }
    }
	
	set result "func $self $name\("
	set params {}
	foreach parameter $params2 {
		lappend params [ lindex $parameter 0 ]
	}
	append result [ join $params ", " ]
	return "$result\) $returns \{"
}


}
