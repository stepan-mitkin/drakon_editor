
gen::add_generator nools gen_nools::generate

namespace eval gen_nools {

variable keywords

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
and assert modify retract fire
}

proc highlight { tokens } {
	variable keywords
	return [ gen_cs::highlight_generic $keywords $tokens ]
}


proc generate { db gdb filename } {
	global errorInfo
	
	set rules [ gen::extract_rules $gdb ]
	
	if { [ graph::errors_occured ] } { return }


	set hfile [ replace_extension $filename "nools" ]
	set f [ open $hfile w ]
	catch {
		print_to_file $f $rules
	} error_message
	set savedInfo $errorInfo
	
	catch { close $f }
	if { $error_message != "" } {
		puts $errorInfo
		error $error_message savedInfo
	}
}



proc print_to_file { fhandle rules } {
	set no 1
	foreach rule $rules {
		set signature [ dict get $rule signature ]
		lassign $signature name params
		set conditions [ dict get $rule conditions ]
		set actions [ dict get $rule actions ]
		set name2 "$name - $no"
		print_rule $fhandle $name2 $params $conditions $actions
		incr no
	}
}

proc print_variables { fhandle params } {
	set parts [ split $params "\n" ]
	foreach part $parts {
		set trimmed [ string trim $part ]
		if { $trimmed != "" } {
			puts $fhandle "        $trimmed;"
		}
	}
}

proc print_condition { fhandle condition } {
	lassign $condition type text neg
	if {$neg} {
		puts $fhandle "        not($text);"
	} else {
		puts $fhandle "        $text;"
	}
}

proc print_action { fhandle action } {
	lassign $action type text
	puts $fhandle "        $text"
}

proc print_rule { fhandle name2 params conditions actions } {
	puts $fhandle "rule \"$name2\" \{"
	puts $fhandle "    when \{"
	print_variables $fhandle $params
	foreach condition $conditions {
		print_condition $fhandle $condition
	}
	puts $fhandle "    \}"
	puts $fhandle "    then \{"
	foreach action $actions {
		print_action $fhandle $action
	}	
	puts $fhandle "    \}"	
	puts $fhandle "\}"
	puts $fhandle ""
}

}

