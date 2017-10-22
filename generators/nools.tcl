
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
	
	set rules0 [ gen::extract_rules $gdb ]
	
	set rules [ transform_rules $rules0 ]
	
	if { [ graph::errors_occured ] } { return }

	set hfile [ replace_extension $filename "nools" ]
	set f [ open_output_file $hfile ]
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

proc put_together_vars { conditions } {
    set vars {}
    foreach condition $conditions {
        set cond_vars [ lindex $condition 3 ]
        set vars [concat $vars $cond_vars]
    }
    return [lsort -unique $vars]
}

proc transform_rules { rules } {
    set result {}
    foreach rule $rules {
        set signature [ dict get $rule signature ]        
        set conditions [ dict get $rule conditions ]
        set actions [ dict get $rule actions ]
        lassign $signature name params diagram_id
        check_params $diagram_id $params
        set conditions2 [transform_conditions $diagram_id $signature $conditions $actions]
        set vars [put_together_vars $conditions2]
        set rule2 [ list signature $signature conditions $conditions2 actions $actions vars $vars]
        lappend result $rule2
    }
    return $result
}


proc check_params { diagram_id params } {
    if { $params == {} } {
        gen::report_error $diagram_id {} "Variables are not defined"
    }
}

proc transform_conditions { diagram_id signature conditions actions } {
    set conditions2 {}
    set count [llength $conditions]
    foreach condition $conditions {
        lappend conditions2 [transform_condition $diagram_id $condition $count]
    }
    return $conditions2
}

variable neg_ops { "isUndefined" "isNull" "isFalse" "!=" "!==" ">=" "<=" }
variable ops { "isDefined" "isNotNull" "isTrue" "==" "===" "<" ">" }

proc negate_operator { tokens } {
    variable neg_ops
    variable ops
    set count [ llength $ops ]
    for {set i 0} {$i < $count} {incr i} {
        set op [ lindex $ops $i]
        set neg_op [ lindex $neg_ops $i]
        set tokens2 [ try_negate_operator $tokens $op $neg_op ]
        if { $tokens2 != {}} {
            return $tokens2
        }
        set tokens2 [ try_negate_operator $tokens $neg_op $op ]
        if { $tokens2 != {}} {
            return $tokens2
        }
    }
    return {}
}

proc try_negate_operator { tokens op neg_op } {
    set i 0
    set pos -1
    set t ""
    foreach token $tokens {
        lassign $token type text
        if { $text == $op } {
            set pos $i
            set t $type
            break
        }
        incr i
    }
    if {$pos == -1} {
        return {}
    }
    
    set token2 [ list $t $neg_op ]
    return [lreplace $tokens $pos $pos $token2]
}

proc contains_logical { tokens } {
    set ops {"and" "or" "||" "&&"}
    foreach token $tokens {
        set type [ lindex $token 0]
        set text [ lindex $token 1]
        if {$type == "op" && [lsearch $ops $text] != -1} {
            return 1
        }
    }
    return 0
}

proc extract_variables { tokens } {
    set property 0
    set result {}
    foreach token $tokens {
        lassign $token type text
        if {$property} {
            set property 0
        } else {
            if {$type == "token"} {
                lappend result $text
            } elseif {$text == "."} {
                set property 1
            }        
        }
    }
    return $result
}

proc transform_condition { diagram_id condition count } {
    lassign $condition type text neg
    set tokens [hl::lex $text]
    set vars [extract_variables $tokens]
    if {$neg} {
        
        if { [contains_logical $tokens ] } {
            gen::report_error $diagram_id {} "Cannot negate a condition with logical operators"
            return {}
        }
        set tokens2 [ negate_operator $tokens ]
        if { $tokens2 == {} } {
            if { $count != 1 } {
                gen::report_error $diagram_id {} "Cannot negate this condition"
                return {}
            }
            set tokens2 $tokens
        } else {
            set neg 0
        }
        set text2 [join_tokens $tokens2]
        return [list $type $text2 $neg $vars]
    } else {
        return [list $type $text $neg $vars]
    }
}


proc join_tokens { tokens } {
    set text ""
    foreach token $tokens {
        set ttext [lindex $token 1]        
        append text $ttext
    }
    return $text
}

proc print_to_file { fhandle rules } {
	set no 1
	foreach rule $rules {
	
		set signature [ dict get $rule signature ]
		lassign $signature name params
		set conditions [ dict get $rule conditions ]
		set actions [ dict get $rule actions ]
		set vars [ dict get $rule vars ]
		set name2 "$name - $no"
		print_rule $fhandle $name2 $params $conditions $actions $vars
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

proc join_conditions { conditions } {
    set long_texts {}
    foreach condition $conditions {
        lassign $condition type text neg        
        lappend long_texts $text
    }
    return [join $long_texts " && " ]
}

proc must_negate { conditions } {
    set cond [ lindex $conditions 0 ]
    return [ lindex $cond 2]
}

proc make_var { param } {
    lassign $param type name
    return "$name: $type"
}

proc get_lines { text } {
    set parts [ split $text "\n" ]
    set result {}
    foreach part $parts {
        set trimmed [ string trim $part ]
        if {$trimmed != ""} {
            lappend result $trimmed
        }
    }
    return $result
}

proc print_conditions { fhandle params_text conditions vars} {
    set params [ get_lines $params_text ]
    set cond [ join_conditions $conditions ]
    set neg [ must_negate $conditions ]
	
	set selected_vars {}
	foreach param $params {
        set var_name [lindex $param 1]
        if {[lsearch $vars $var_name] != -1 } {
            lappend selected_vars $param
        }        
	}

	set count [ llength $selected_vars ]
	set last [ expr { $count - 1 } ]
	
	for {set i 0} {$i < $count} {incr i} {
        set param [lindex $selected_vars $i]
        
        set var [ make_var $param ]
        if {$i != $last} {
            set exp2 $var
        } else {
            set exp2 "$var $cond"
        }
        if {$neg} {
            set exp "not($exp2)"
        } else {
            set exp "$exp2"
        }
        puts $fhandle "        $exp;"
	}
}

proc print_action { fhandle action } {
	lassign $action type text
	puts $fhandle "        $text"
}

proc print_rule { fhandle name2 params conditions actions vars } {
	puts $fhandle "rule \"$name2\" \{"
	puts $fhandle "    when \{"
	print_conditions $fhandle $params $conditions $vars
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

