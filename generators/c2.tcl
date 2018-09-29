# C without goto operator.
# by Alexey Gavrilov based on work by  Stepan Mitkin
# algavrilov2013@gmail.com
# 1 September 2018
# http://drakon-editor.sourceforge.net/

# C without goto operator.


# Register the gen_c2::generate procedure as the code generator for language "C2".
gen::add_generator "C2" gen_c2::generate

namespace eval gen_c2 {

# These keywords can be used in function headers.
variable keywords {
	abstract
	const
	private
    package
	inline
    protected
    public
    export
    nothrow
    ref
    auto
    override
    @property
    pure
    shared
    static
}

variable c2_keywords {
auto
break
case
char
const
continue
default
do
double
else
enum
extern
float
for
goto
if
int
inline
long
register
return
short
signed
sizeof
static
struct
switch
typedef
union
unsigned
void
volatile
while

}

# An optional procedure for syntax highlighting
proc highlight { tokens } {
	variable c2_keywords
	return [ gen_cs::highlight_generic $c2_keywords $tokens ]
}

# The code generator procedure. It will be called by DRAKON Editor.
# Arguments:
#   db - A handle to the database of the original file. Read only!
#   gdb - A handle to the temporary database. Read-write.
#   filename - The .drn filename.
proc generate { db gdb filename } {
	global errorInfo
	variable callbacks
	variable language
	set language "c"
	
	set callbacks [ make_callbacks ]
	# Construct the callbacks dictionary
	set machines [ sma::extract_many_machines \
     $gdb $callbacks ]
	set sm_header [ gen_cpp::build_sm_header $machines ]
    set sm_body [ gen_cpp::build_sm_body $gdb $machines ]
	    #item 2280
    gen_cpp::append_sm_names $gdb
    #item 2833888
    gen_cpp::zap_cleanups $gdb
    #item 2792
    tab::generate_tables $gdb $callbacks 0

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
	#set nogoto 1
	#set functions [ gen::generate_functions \
	#	$db $gdb $callbacks $nogoto ]

	# Abort if any errors happened so far.
	if { [ graph::errors_occured ] } { return }

	#set hfile [ replace_extension $filename "c" ]
	  #item 923
    set sections { 
      h_header h_footer c_header c_footer class options
      structure globals
    }
    lassign [ gen::scan_file_description $db $sections ] \
      h_header h_footer c_header c_footer class options \
      structure globals
    #item 2359
    lassign \
    [gen_cpp::build_globals $globals] \
    g_header g_body
    #item 905
    set functions [ gen::generate_functions $db $gdb  \
    	$callbacks 1 ]
    #item 895
    if {[ graph::errors_occured ]} {
        
    } else {

        set copying 0
        set class_name ""

        set functions [ gen_cpp::update_returns $gdb $functions ]

        lassign [ gen_cpp::sort_functions $functions $language $class_name ] \
        free_funs \
        ctrs dtrs methods signals slots

        set h_filename [ replace_extension $filename "h" ]
        set c_filename [ replace_extension $filename $language ]
        set filenames [ list $h_filename $c_filename ]
		
		

        lassign [ open_files $filenames "w" ] hfile cfile

        catch {
            gen_cpp::print_header $h_filename $hfile $free_funs \
            $ctrs $dtrs $methods $signals $slots \
            $h_header $h_footer $class $copying $class_name \
            $language $sm_header $g_header
            
            gen_cpp::print_cpp $h_filename $cfile $free_funs \
            $ctrs $dtrs $methods $slots \
            $c_header $c_footer $class_name \
            $language $sm_body $g_body
        } error_message

        close_files [ list $hfile $cfile ]

        if {$error_message == ""} {
            
        } else {

            puts $::errorInfo
            error $error_message
        }
    }
	
	
}



# Builds a collection of code snippet generators specific to the D language.
proc make_callbacks { } {
	set callbacks {}

	gen::put_callback callbacks assign			gen_c2::assign
	gen::put_callback callbacks compare			gen_c2::compare
	gen::put_callback callbacks compare2		gen_c2::compare
	gen::put_callback callbacks while_start 	gen_c2::while_start
	gen::put_callback callbacks if_start		gen_c2::if_start
	gen::put_callback callbacks elseif_start	gen_c2::elseif_start
	gen::put_callback callbacks if_end			gen_c2::if_end
	gen::put_callback callbacks else_start		gen_c2::else_start
	gen::put_callback callbacks pass			gen_c2::pass
	gen::put_callback callbacks return_none		gen_c2::return_none
	gen::put_callback callbacks block_close		gen_c2::block_close
	gen::put_callback callbacks comment			gen_c2::comment
	gen::put_callback callbacks bad_case		gen_c2::bad_case
	gen::put_callback callbacks for_declare		gen_c2::foreach_declare	
	gen::put_callback callbacks for_init		gen_c2::foreach_init
	gen::put_callback callbacks for_check		gen_c2::foreach_check
	gen::put_callback callbacks for_current		gen_c2::foreach_current
	gen::put_callback callbacks for_incr		gen_c2::foreach_incr
	gen::put_callback callbacks and				gen_c2::and
	gen::put_callback callbacks or				gen_c2::or
	gen::put_callback callbacks not				gen_c2::not
	gen::put_callback callbacks break			"break;"
	gen::put_callback callbacks declare			gen_c2::declare
	gen::put_callback callbacks shelf			gen_c2::shelf
				
	gen::put_callback callbacks body			gen_c2::generate_body
	gen::put_callback callbacks signature		gen_cpp::extract_signature
	gen::put_callback callbacks native_foreach	gen_c2::native_foreach

	return $callbacks
}

# A simple variable assignment.
proc assign { variable value } {
	return "$variable = $value;"
}

# A comparison of two values.
proc compare { variable constant } {
	return "$variable == $constant"
}

# The beginning of an eternal __while__ loop.
proc while_start { } {
	return "while (true) \{"
}

# The left part of an __if__ condition
proc if_start { } {
	return "if \("
}

# slse if expression
proc elseif_start { } {
    return "\} else if \("
}

# The right part of __if__ condition
proc if_end { } {
    return "\) \{"
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
    return "return;"
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
    	return "throw new Exception\(\"Not expected condition.\"\);"
    } else {	
		return "throw new Exception\(\"Not expected $switch_var\"\);"
	}
}

proc native_foreach { for_it for_var } {
	return "foreach ($for_it; $for_var) \{"
}

# Declares the iterator and/or the iterated variable.
# We don't need this in D.
proc foreach_declare { item_id first second } {
    return ""
}

# Initialises the iterator.
# With D, we declare and init a range.
proc foreach_init { item_id first second } {
	return "auto _rng_$first = $second;"
}

# Checks whether it is time to exit the iteration. 
proc foreach_check { item_id first second } {
	return "!_rng_$first.empty"
}

# Gets the current element from the iterator.
proc foreach_current { item_id first second } {
	return "auto $first = _rng_$first.front;"
}

# Advances the iterator.
proc foreach_incr { item_id first second } {
    #item 32
    return "_rng_$first.popFront();"
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
	return "$type $name;"
    } else {
	return "$type $name = $value;"
    }
}

# Builds code for a __shelf__ icon.
proc shelf { primary secondary } {
    return "$secondary = $primary;"
}

# DRAKON Editor could not generate a body for the function.
# The code generation failed.
# Probably, the algorithm is too complex for the generator.
# The plugin is supposed to fix this.
# We resort to the loop generator that always works, but is quite slow.
proc generate_body { gdb diagram_id start_item node_list items incoming } {
    set callbacks [ make_callbacks ]
    return [ cbody2::generate_body $gdb $diagram_id $start_item $node_list \
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

proc only_keywords { text } {
	variable keywords
	set parts [ split $text " " ]
	foreach part $parts {
		if { ![ contains $keywords $part ] } {
			return 0
		}
	}
	return 1
}

proc get_keywords { parameters } {
	if { $parameters == {} } {
		set prop_list {}
		set parameters2 {}
	} else {
		set first [ lindex $parameters 0 ]
		set rest [ lrange $parameters 1 end ]
		set code_part [ lindex $first 0 ]
		if { [ only_keywords $code_part ] } {
			set prop_list $code_part
			set parameters2 $rest
		} else {
			set prop_list {}
			set parameters2 $parameters
		}
	}		
	
	return [ list $prop_list $parameters2 ]	
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
	set result ""
	if { $access != "" } {
		append result "$access "
	}
	if { $name == "ctr" } {
		append result "this\("	
	} elseif { $name == "dtr" } {
		append result "~this\("	
	} else {
		append result "$returns $name\("
	}
	set params {}
	foreach parameter $parameters {
		lappend params [ lindex $parameter 0 ]
	}
	append result [ join $params ", " ]
	return "$result\) \{"
}


}
