

tproc extract_sections_test { } {
	list_equal [ gen::extract_sections {} ] {}

	set no_sections {
		"one two three"
		"four five six"
		"seven eight nine"
		"== no section =="
	}

	list_equal [ gen::extract_sections [ join $no_sections "\n" ] ] {}

	set two_sections {
		" === first section === "
		" one two three"
		" four five six "
		""
		" == not a section === "
		" === not a section either == "
		" === second section === "
		"line 1"
		"line 2"
	}

	array set sections [ gen::extract_sections [ join $two_sections "\n" ] ]
	equal [ llength [ array names sections ] ] 2
	set first "first section"
	set second "second section"
	equal $sections($first) " one two three\n four five six \n\n == not a section === \n === not a section either == "
	equal $sections($second) "line 1\nline 2"
}

tproc extract_return_type_test { } {	
	equal [ gen_c::extract_return_type "returns int " ] int
	equal [ gen_c::extract_return_type "returns const char * " ] "const char *"
}

tproc extract_tcl_signature_test { } {
	# Gets the path of all language generators.
	proc load_generators {} {
		set script_path [ file dirname [ file normalize [ info script ] ] ]
		set drakon_editor_path [string trimright $script_path "unittest" ]
		set scripts [ glob -- "$drakon_editor_path/generators/*.tcl" ]
		foreach script $scripts {
		  source $script
		}		
	}

	namespace eval gen {
	    
	array set generators {}
	
	# Makes array of all language generators. This procedure is called by language generator files. In the beginning of every language generator there is calling code.
	proc add_generator { language generator } {
		variable generators
		if { [ info exists generator($language) ] } {
			error "Generator for language $language already registered."
		}
		set gen::generators($language) $generator
	}
	
	}
	load_generators
	
	
	# Tests correct working of function parameter comments for all suporrted languages.
	foreach { language generator } [ array get gen::generators ] {
		puts "----------------------------------"
		puts $language
		
		namespace eval current_file_generation_info {}
		set current_file_generation_info::language $language
		set current_file_generation_info::generator $generator
		
		# Sets language generator namespace.
		set find [string first :: $generator]
		set generator_namespace [ string range $generator 0 $find-1 ]
	    
		# These 3 lines is to check if current generator have commentator procedure.
		# If not commentator_status_var is set to "" .
		set commentator_for_namespace_text "::commentator"
		set commentator_call_text "$generator_namespace$commentator_for_namespace_text"
		set commentator_status_var [ namespace which $commentator_call_text ]
		
		# If language generator has commentator procedure, gets current generator line comment sign, removes space before and after it and sets result as sign for function parameter comment.
		if { $commentator_status_var != "" } {
			set function_parameter_comment_sign [ $commentator_call_text "" ]
			set function_parameter_comment_sign [string trim $function_parameter_comment_sign " " ]
		}
		
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
			
			if { $commentator_status_var == "" } {
				puts "commentator procedure in language generator does not exists."
				puts "Using // sign"
			} else {
				puts $commentator_call_text
				puts "commentator procedure returns $function_parameter_comment_sign . Using // sign."
			}
			
			# Checks function parameter comment correct working for languages in "if" condition above and for languages that does not have commentator function.
			# If language does not have commentator function, it will use // as function parameter comment sign.
			good_signature_tcl { " " " #comment " "" "what?" } comment "" {} ""
		
			good_signature_tcl { "" 
				"" 
				" argc // number "
				" argv // arguments "
				" "
				} procedure public { "argc" "argv" } ""
		
			good_signature_tcl { "one"
				"two" } procedure public { "one" "two" } ""
				
			puts OK
		
		} else {
			
			# Checks function parameter comment correct working for languages that have commentator procedure and whose line comment sign is # .
			if { $function_parameter_comment_sign == "#" } {

			puts $commentator_call_text
			puts "commentator procedure returns $function_parameter_comment_sign . Using # sign."
			
			good_signature_tcl { "" 
				"" 
				" argc # number "
				" argv # arguments "
				" "
				} procedure public { "argc" "argv" } ""
		
			good_signature_tcl { "one"
				"two" } procedure public { "one" "two" } ""
			
			puts OK
			
			} else {
			
			puts $commentator_call_text
			puts "commentator procedure returns $function_parameter_comment_sign . Using $function_parameter_comment_sign sign."
			
			# Checks function parameter comment correct working for languages that have commentator procedure and whose line comment sign is NOT # .
			
			good_signature_tcl { " " " #comment " "" "what?" } comment "" {} ""
			    
			good_signature_tcl [list "" \
				"" \
				[string map [list // $function_parameter_comment_sign] " argc // number "] \
				[string map [list // $function_parameter_comment_sign] " argv // arguments "] \
				" " \
			] procedure public { "argc" "argv" } ""
		
			good_signature_tcl { "one"
				"two" } procedure public { "one" "two" } ""
			
			puts OK
			
			}
		}
	    
	}
	
	puts "----------------------------------------------"
	puts "extract_tcl_signature_test successfully ended."
	puts "=============================================="

}

tproc extract_for_test { } {
	list_equal [ gen::p.extract_for " set i 0; i < length; incr i" ] { "set i 0" "i < length" "incr i" }
	list_equal [ gen::p.extract_for "set i 0 ; i < length ; incr i " ] { "set i 0" "i < length" "incr i" }
	equal [ gen::p.extract_for "" ] ""
	equal [ gen::p.extract_for "set i 0; moo" ] ""
	equal [ gen::p.extract_for "set i 0; moo;" ] ""
	equal [ gen::p.extract_for "; moo; boo" ] ""
	equal [ gen::p.extract_for "one; ; three" ] ""
}

tproc extract_foreach_test { } {
	list_equal [ gen::p.extract_foreach "foreach item; collection " ] { "item" "collection" }
	list_equal [ gen::p.extract_foreach "foreach type item; collection " ] { "type item" "collection" }	
	list_equal [ gen::p.extract_foreach "for item; collection " ] {}
	list_equal [ gen::p.extract_foreach "foreach ; collection " ] {}
	list_equal [ gen::p.extract_foreach "foreach item; " ] {}
	list_equal [ gen::p.extract_foreach "foreach ; " ] {}
	list_equal [ gen::p.extract_foreach "foreach item; collection; what? " ] {}
}

proc good_signature_tcl { lines type access parameters returns } {
	set text [ join $lines "\n" ]
	unpack [ gen_tcl::extract_signature $text foo ] message signature
	equal $message ""

	unpack $signature atype aaccess aparameters areturns
	equal $atype $type
	equal $aaccess $access
	set par_part0 {}
	foreach par $aparameters {
		lappend par_part0 [ lindex $par 0 ]
	}
	list_equal $par_part0 $parameters
	equal [ lindex $areturns 0 ] $returns
}

proc good_signature { lines type access parameters returns } {
	set text [ join $lines "\n" ]
	unpack [ gen_c::extract_signature $text foo ] message signature
	equal $message ""
	unpack $signature atype aaccess aparameters areturns
	equal $atype $type
	equal $aaccess $access
	set par_part0 {}
	foreach par $aparameters {
		lappend par_part0 [ lindex $par 0 ]
	}
	list_equal $par_part0 $parameters
	equal $areturns $returns
}

proc bad_signature { lines } {
	set text [ join $lines "\n" ]
	unpack [ gen_c::extract_signature $text name ] message signature
	if { $message == "" } {
		error "Error message expected."
	}
}

tproc extract_cpp_signature_test { } {
#good things
#funcions
	good_signature_cpp { "" } function {
	abstract 0 access static const 0 dispatch normal inline 0 type function} {} void
	good_signature_cpp { "public" } function {abstract 0 access 
		public const 0 dispatch normal inline 0 type function } {} void
		
	good_signature_cpp { "static" } function {abstract 0 access 
		static const 0 dispatch static inline 0 type function } {} void

	good_signature_cpp { "int i" "const char* b // foo" } function {
		abstract 0 access static const 0 dispatch normal inline 0 type function } {
		"int i" "const char* b"} void

	good_signature_cpp { "int i" "const char* b // foo" " returns   struct p* // u"
		} function {
		abstract 0 access static const 0 dispatch normal inline 0 type function } {
		"int i" "const char* b"} "struct p*"

	good_signature_cpp { "" " public function " "int i" "const char* b // foo" " returns   struct p* // u"
		} function {
		abstract 0 access public const 0 dispatch normal inline 0 type function } {
		"int i" "const char* b"} "struct p*"

	good_signature_cpp { "" " static function " "int i" "const char* b // foo" " returns   struct p* // u"
		} function {
		abstract 0 access static const 0 dispatch static inline 0 type function } {
		"int i" "const char* b"} "struct p*"

	good_signature_cpp { "" " public inline function " "int i" "const char* b // foo" " returns   struct p* // u"
		} function {
		abstract 0 access public const 0 dispatch normal inline 1 type function } {
		"int i" "const char* b"} "struct p*"

#methods
	good_signature_cpp { "" " public method "
		} method {
		abstract 0 access public const 0 dispatch normal inline 0 type method } {
		} "void"

	good_signature_cpp { "" " public inline method "
		} method {
		abstract 0 access public const 0 dispatch normal inline 1 type method } {
		} "void"

	good_signature_cpp { "" " protected const method " "const char* u" "unsigned int i"
		" returns  unsigned int // asdf"
		} method {
		abstract 0 access protected const 1 dispatch normal inline 0 type method } {
			"const char* u" "unsigned int i"
		} "unsigned int"

	good_signature_cpp { "" " private static method " "const char* u" "unsigned int i"
		" returns  unsigned int // asdf"
		} method {
		abstract 0 access private const 0 dispatch static inline 0 type method } {
			"const char* u" "unsigned int i"
		} "unsigned int"

	good_signature_cpp { "" " public virtual method " "const char* u" "unsigned int i"
		" returns  unsigned int // asdf"
		} method {
		abstract 0 access public const 0 dispatch virtual inline 0 type method } {
			"const char* u" "unsigned int i"
		} "unsigned int"

	good_signature_cpp { "" " public virtual abstract method " "const char* u" "unsigned int i"
		" returns  unsigned int // asdf"
		} method {
		abstract 1 access public const 0 dispatch virtual inline 0 type method } {
			"const char* u" "unsigned int i"
		} "unsigned int"

	good_signature_cpp { "" " public abstract method " "const char* u" "unsigned int i"
		" returns  unsigned int // asdf"
		} method {
		abstract 1 access public const 0 dispatch virtual inline 0 type method } {
			"const char* u" "unsigned int i"
		} "unsigned int"

#slots
	good_signature_cpp { "" " public slot "
		} slot {
		abstract 0 access public const 0 dispatch normal inline 0 type slot } {
		} "void"

	good_signature_cpp { "" " public inline slot "
		} slot {
		abstract 0 access public const 0 dispatch normal inline 1 type slot } {
		} "void"

	good_signature_cpp { "" " protected const slot " "const char* u" "unsigned int i"
		" returns  unsigned int // asdf"
		} slot {
		abstract 0 access protected const 1 dispatch normal inline 0 type slot } {
			"const char* u" "unsigned int i"
		} "unsigned int"

	good_signature_cpp { "" " public virtual slot " "const char* u" "unsigned int i"
		" returns  unsigned int // asdf"
		} slot {
		abstract 0 access public const 0 dispatch virtual inline 0 type slot } {
			"const char* u" "unsigned int i"
		} "unsigned int"

	good_signature_cpp { "" " public virtual abstract slot " "const char* u" "unsigned int i"
		" returns  unsigned int // asdf"
		} slot {
		abstract 1 access public const 0 dispatch virtual inline 0 type slot } {
			"const char* u" "unsigned int i"
		} "unsigned int"

	good_signature_cpp { "" " public abstract slot " "const char* u" "unsigned int i"
		" returns  unsigned int // asdf"
		} slot {
		abstract 1 access public const 0 dispatch virtual inline 0 type slot } {
			"const char* u" "unsigned int i"
		} "unsigned int"

#signals
	good_signature_cpp { "" " signal " "const char* u" "unsigned int i"
		} signal {
		abstract 0 access public const 0 dispatch normal inline 0 type signal } {
			"const char* u" "unsigned int i"
		} "void"

		
#constructors
	good_signature_cpp { "" " public ctr "
		} ctr {
		abstract 0 access public const 0 dispatch normal inline 0 type ctr } {
		} ""
		
	good_signature_cpp { "" " protected inline ctr "
		} ctr {
		abstract 0 access protected const 0 dispatch normal inline 1 type ctr } {
		} ""

	good_signature_cpp { "" " ctr " "foo bar" "woo doo"
		} ctr {
		abstract 0 access private const 0 dispatch normal inline 0 type ctr } {
			"foo bar" "woo doo"
		} ""

#destructors
	good_signature_cpp { "" " public dtr "
		} dtr {
		abstract 0 access public const 0 dispatch virtual inline 0 type dtr } {
		} ""
		
	good_signature_cpp { "" " dtr "
		} dtr {
		abstract 0 access public const 0 dispatch virtual inline 0 type dtr } {
		} ""

	good_signature_cpp { "" " virtual dtr "
		} dtr {
		abstract 0 access public const 0 dispatch virtual inline 0 type dtr } {
		} ""

#bad things

	# alien keyword
	bad_signature_cpp { "public bad" }
	
	# ctr with return type
	bad_signature_cpp { "ctr" "returns int" }
	
	# dtr with return type
	bad_signature_cpp { "dtr" "returns int" }
	
	# returns not last
	bad_signature_cpp { "public method" "returns int" "something else" }

	# destructor with parameters
	bad_signature_cpp { "public dtr" "" "something else" }
	
	# inconsistent access
	bad_signature_cpp { "public private method" "" }
	
	# inconsistent access 2
	bad_signature_cpp { "public protected method" "" }

	# inconsistent dispatch
	bad_signature_cpp { "virtual static method" "" }

	# inconsistent proc type
	bad_signature_cpp { "function method" "" }
	
	# inconsistent proc type 2
	bad_signature_cpp { "ctr method" "" }

	# inconsistent proc type 3
	bad_signature_cpp { "ctr dtr" "" }

	# public static function
	bad_signature_cpp { "public static" "" }
	
	# bad access for function
	bad_signature_cpp { "protected function" "" }
	#bad_signature_cpp { "private function" "" }
	
	# bad function dispatch
	bad_signature_cpp { "virtual" "" }
	bad_signature_cpp { "virtual function" "" }	
	
	# bad function dispatch 2
	bad_signature_cpp { "abstract" "" }
	bad_signature_cpp { "abstract function" "" }

	# bad ctr dispatch
	bad_signature_cpp { "virtual ctr" "" }
	bad_signature_cpp { "static ctr" "" }
	
	# const ctr
	bad_signature_cpp { "const ctr" "" }
	
	# abstract ctr
	bad_signature_cpp { "abstract ctr" "" }

	# bad dtr dispatch
	bad_signature_cpp { "static dtr" "" }
	
	# const dtr
	bad_signature_cpp { "const dtr" "" }
	
	# abstract dtr
	bad_signature_cpp { "abstract dtr" "" }

	# non-public dtr
	bad_signature_cpp { "private dtr" "" }
	bad_signature_cpp { "protected dtr" "" }
	
	# abstract inline
	bad_signature_cpp { "abstract inline method" "" }
	
	# static slot
	bad_signature_cpp { "static slot" "" }
	
	# virtual signal
	bad_signature_cpp { "virtual signal" "" }
	
	# static signal
	bad_signature_cpp { "static signal" "" }
	
	# const signal
	bad_signature_cpp { "const signal" "" }	

	# abstract signal
	bad_signature_cpp { "abstract signal" "" }	
	
}

tproc extract_java_signature_test { } {
	#good things
	good_signature_java { "" } method {
			access none 
			dispatch normal
			type method
		} {} void {}

	good_signature_java { "#comment" } comment {
			access none 
			dispatch normal
			type method
		} {} void {}

	good_signature_java { "protected" } method {
			access protected 
			dispatch normal
			type method
		} {} void {}

	good_signature_java { "public abstract" } method {
			access public 
			dispatch abstract
			type method
		} {} void {}

	good_signature_java { "private ctr" } ctr {
			access private 
			dispatch normal
			type ctr
		} {} "" {}

	good_signature_java { "protected override" } method {
			access protected 
			dispatch override
			type method
		} {} void {}

	good_signature_java { "override" } method {
			access none 
			dispatch override
			type method
		} {} void {}

	good_signature_java { 
			"protected static"
			""
			"ArrayList<Integer> values // preved"
			"String message"
			""
			"returns Iterator<String>"			
			"throws Exception1 Exception2"
		} method {
			access protected 
			dispatch static
			type method
		} {"ArrayList<Integer> values" "String message"} "Iterator<String>" "Exception1 Exception2"


	good_signature_java { 
			""
			"ArrayList<Integer> values // preved"
			"String message"
			""
			"throws Exception1 Exception2"
		} method {
			access none 
			dispatch normal
			type method
		} {"ArrayList<Integer> values" "String message"} "void" "Exception1 Exception2"
		
	good_signature_java { 
			""
			"ArrayList<Integer> values // preved"
			""			
			"String message"
		} method {
			access none 
			dispatch normal
			type method
		} {"ArrayList<Integer> values" "String message"} "void" ""

	# bad stuff		
	bad_signature_java { 
			"protected override public"
		} 

	bad_signature_java { 
			"protected override abstract"
		} 

	bad_signature_java { 
			"protected override foobar"
		} 

}


proc good_signature_cpp { lines type props parameters returns } {
	set text [ join $lines "\n" ]
	unpack [ gen_cpp::extract_signature $text foo ] message signature

	equal $message ""
	unpack $signature atype aprops aparameters areturns
	equal $atype $type
	array_equal $aprops $props
	set par_part0 {}
	foreach par $aparameters {
		lappend par_part0 [ lindex $par 0 ]
	}
	list_equal $par_part0 $parameters
	equal $areturns $returns
}

proc bad_signature_cpp { lines } {
	set text [ join $lines "\n" ]
	unpack [ gen_cpp::extract_signature $text name ] message signature
	if { $message == "" } {
		puts $signature
		error "Error message expected."
	}
}

proc good_signature_java { lines type props parameters returns throws } {
	set text [ join $lines "\n" ]
	unpack [ gen_java::extract_signature $text foo ] message signature

	equal $message ""
	
	unpack $signature atype aprops aparameters areturns athrows
	equal $atype $type
	array_equal $aprops $props
	equal $athrows $throws

	set par_part0 {}
	foreach par $aparameters {
		lappend par_part0 [ lindex $par 0 ]
	}
	list_equal $par_part0 $parameters
	equal $areturns $returns
}

proc bad_signature_java { lines } {
	set text [ join $lines "\n" ]
	unpack [ gen_java::extract_signature $text name ] message signature
	if { $message == "" } {
		puts $signature
		error "Error message expected."
	}
}


tproc extract_java_class_test { } {
	set good1 { "" "class Foo \{" "" }
	set good2 { "" "public class Foo2 extends Bar" "" }
	set good3 { "" "enum Moo" " " }
	set good4 { "" "enum Moo2\{" }
	set bad1 { "" "foo bar" "" }
	set bad2 { "" "public class" "" }
	equal [ gen_java::extract_class_name [ join $good1 "\n" ] ] "Foo"
	equal [ gen_java::extract_class_name [ join $good2 "\n" ] ] "Foo2"
	equal [ gen_java::extract_class_name [ join $good3 "\n" ] ] "Moo"
	equal [ gen_java::extract_class_name [ join $good4 "\n" ] ] "Moo2"
	equal [ gen_java::extract_class_name [ join $bad1 "\n" ] ] ""
	equal [ gen_java::extract_class_name [ join $bad2 "\n" ] ] ""
}


tproc push_test { } {
	set stack {}
	nsorter::push stack 10
	nsorter::push stack 20
	nsorter::push stack 30
	list_equal $stack {10 20 30}
}

tproc pop_test { } {
	set stack {10 20 30 40}
	
	equal [ nsorter::pop stack ] 40
	list_equal $stack {10 20 30}

	equal [ nsorter::pop stack ] 30
	list_equal $stack {10 20}

	equal [ nsorter::pop stack ] 20
	list_equal $stack {10}

	equal [ nsorter::pop stack ] 10
	list_equal $stack {}

	equal [ nsorter::pop stack ] ""
	list_equal $stack {}
	
	equal [ nsorter::pop stack ] ""
	list_equal $stack {}	
}

tproc nsorter_test { } {

	nsorter::init megadb 10
	nsorter::add_node 10
	nsorter::complete_construction
	list_equal [ nsorter::sort ] {10}



	nsorter::init megadb 10
	
	nsorter::add_node 40
	nsorter::add_node 30
	nsorter::add_node 20
	nsorter::add_node 10	
	
	nsorter::add_link 10 2 20
	nsorter::add_link 10 1 30
	nsorter::add_link 20 1 40
	nsorter::add_link 30 1 40
	
	nsorter::complete_construction
	list_equal [ nsorter::sort ] {10 20 30 40}


	nsorter::init megadb 10

	nsorter::add_node 60
	nsorter::add_node 50	
	nsorter::add_node 40
	nsorter::add_node 30
	nsorter::add_node 20
	nsorter::add_node 10	
	
	nsorter::add_link 10 1 20
	nsorter::add_link 20 1 40
	nsorter::add_link 20 2 30
	nsorter::add_link 30 1 60
	nsorter::add_link 40 1 50
	nsorter::add_link 40 2 50
	nsorter::add_link 50 1 60
	nsorter::complete_construction
#	puts [ nsorter::sort ]
	list_equal [ nsorter::sort ] {10 20 30 40 50 60}



	nsorter::init megadb 10

	nsorter::add_node 60
	nsorter::add_node 50	
	nsorter::add_node 400
	nsorter::add_node 30
	nsorter::add_node 20
	nsorter::add_node 10	
	
	nsorter::add_link 10 1 50
	nsorter::add_link 50 1 60
	nsorter::add_link 10 2 20
	nsorter::add_link 20 1 30
	nsorter::add_link 20 2 400
	nsorter::add_link 30 1 400
	nsorter::add_link 400 1 60
	nsorter::complete_construction
#	puts [ nsorter::sort ]
	list_equal [ nsorter::sort ] {10 20 30 400 50 60}


	nsorter::init megadb A

	nsorter::add_node A
	nsorter::add_node B	
	nsorter::add_node C
	nsorter::add_node D
	
	nsorter::add_link A 1 C
	nsorter::add_link A 2 B
	nsorter::add_link B 1 C
	nsorter::add_link B 2 D
	nsorter::add_link C 1 D
	nsorter::complete_construction
#	puts [ nsorter::sort ]
	list_equal [ nsorter::sort ] {A B C D}
	


	nsorter::init megadb A

	nsorter::add_node A
	nsorter::add_node B	
	nsorter::add_node C
	nsorter::add_node D
	
	nsorter::add_link A 1 C
	nsorter::add_link A 2 B
	nsorter::add_link B 1 D
	nsorter::add_link C 1 D
	nsorter::add_link C 2 D
	nsorter::complete_construction
#	puts [ nsorter::sort ]
	list_equal [ nsorter::sort ] {A B C D}



	nsorter::init megadb A

	nsorter::add_node A
	nsorter::add_node B	
	nsorter::add_node C
	nsorter::add_node D
	nsorter::add_node E
	
	nsorter::add_link A 1 B
	nsorter::add_link B 1 D
	nsorter::add_link B 2 C
	nsorter::add_link C 1 A
	nsorter::add_link C 2 E
	nsorter::add_link D 1 E	
	nsorter::complete_construction
#	puts [ nsorter::sort ]
	list_equal [ nsorter::sort ] {A B C D E}
	
	
	
	nsorter::init megadb A

	nsorter::add_node A
	nsorter::add_node B	
	nsorter::add_node C
	
	nsorter::add_link A 1 B
	nsorter::add_link B 1 B
	nsorter::add_link B 2 C
	nsorter::complete_construction
#	puts [ nsorter::sort ]
	list_equal [ nsorter::sort ] {A B C}


	nsorter::init megadb A

	nsorter::add_node A
	nsorter::add_node B	
	nsorter::add_node C
	
	nsorter::add_link A 1 B
	nsorter::add_link B 1 A
	nsorter::add_link B 2 C
	nsorter::complete_construction
#	puts [ nsorter::sort ]
	list_equal [ nsorter::sort ] {A B C}
	
}

tproc extract_copying_test { } {
	equal [ gen_cpp::extract_copying "\n \n copying = yes \n" ] 1
	equal [ gen_cpp::extract_copying "\n \n copying = no \n" ] 0
	
	equal [ gen_cpp::extract_copying "\n \n copying =  \n" ] 0
	equal [ gen_cpp::extract_copying "\n asdf \n what's this? \n" ] 0
	equal [ gen_cpp::extract_copying "" ] 0
}

tproc extract_class_name_test { } {
	equal [ gen_cpp::extract_class_name "  class foo // good" ] foo
	equal [ gen_cpp::extract_class_name " struct foo2 // better" ] foo2
	equal [ gen_cpp::extract_class_name "  template<class T>\nclass bar: public moo" ] bar
	equal [ gen_cpp::extract_class_name "asdfasdf/n/n  /nasdf" ] ""
	equal [ gen_cpp::extract_class_name "" ] ""
}

