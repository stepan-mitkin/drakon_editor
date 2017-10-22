# DRAKON Editor plugin demo.
# by Stepan Mitkin
# stipan.mitkin@gmail.com
# 7 February 2014
# http://drakon-editor.sourceforge.net/

# Part 3: Object-orientation, keywords and sections.


# Register the gen_d::generate procedure as the code generator for language "D".
gen::add_generator "D" gen_d::generate

namespace eval gen_d {

# These keywords can be used in function headers.
variable keywords {
	abstract
	const
	private
    package
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

variable d_keywords {
abstract
alias
align
asm
assert
auto

body
bool
break
byte

case
cast
catch
cdouble
cent
cfloat
char
class
const
continue
creal

dchar
debug
default
delegate
delete (deprecated)
deprecated
do
double

else
enum
export
extern

false
final
finally
float
for
foreach
foreach_reverse
function

goto

idouble
if
ifloat
immutable
import
in
inout
int
interface
invariant
ireal
is

lazy
long

macro (unused)
mixin
module

new
nothrow
null

out
override

package
pragma
private
protected
public
pure

real
ref
return

scope
shared
short
static
struct
super
switch
synchronized

template
this
throw
true
try
typedef (deprecated)
typeid
typeof

ubyte
ucent
uint
ulong
union
unittest
ushort

version
void
volatile (deprecated)

wchar
while
with

__FILE__
__MODULE__
__LINE__
__FUNCTION__
__PRETTY_FUNCTION__

__gshared
__traits
__vector
__parameters

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

	set hfile [ replace_extension $filename "d" ]
	
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

# Builds a collection of code snippet generators specific to the D language.
proc make_callbacks { } {
	set callbacks {}

	gen::put_callback callbacks assign			gen_d::assign
	gen::put_callback callbacks compare			gen_d::compare
	gen::put_callback callbacks compare2		gen_d::compare
	gen::put_callback callbacks while_start 	gen_d::while_start
	gen::put_callback callbacks if_start		gen_d::if_start
	gen::put_callback callbacks elseif_start	gen_d::elseif_start
	gen::put_callback callbacks if_end			gen_d::if_end
	gen::put_callback callbacks else_start		gen_d::else_start
	gen::put_callback callbacks pass			gen_d::pass
	gen::put_callback callbacks return_none		gen_d::return_none
	gen::put_callback callbacks block_close		gen_d::block_close
	gen::put_callback callbacks comment			gen_d::comment
	gen::put_callback callbacks bad_case		gen_d::bad_case
	gen::put_callback callbacks for_declare		gen_d::foreach_declare	
	gen::put_callback callbacks for_init		gen_d::foreach_init
	gen::put_callback callbacks for_check		gen_d::foreach_check
	gen::put_callback callbacks for_current		gen_d::foreach_current
	gen::put_callback callbacks for_incr		gen_d::foreach_incr
	gen::put_callback callbacks and				gen_d::and
	gen::put_callback callbacks or				gen_d::or
	gen::put_callback callbacks not				gen_d::not
	gen::put_callback callbacks break			"break;"
	gen::put_callback callbacks declare			gen_d::declare
	gen::put_callback callbacks shelf			gen_d::shelf
				
	gen::put_callback callbacks body			gen_d::generate_body
	gen::put_callback callbacks signature		gen_d::extract_signature
	gen::put_callback callbacks native_foreach	gen_d::native_foreach

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
	
	# Extract the keywords that decorete the signature.
	lassign [ get_keywords $parameters ] prop_list parameters2
	
	set type "procedure"
    set signature [ gen::create_signature $type $prop_list $parameters2 $returns ]

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

	puts $fhandle "import std.range;"
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
