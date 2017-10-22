namespace eval colors {

###	Old colors
#	variable canvas_bg "#e0e0ff"
#	variable if_bg "#ffffb0"
#	variable for_bg "#c0ffc0"
#	variable case_bg "#ffe0d0"
#	variable action_bg "#ffffff"	
#	variable text_fg "#000000"
#	variable line_fg "#000000"
#	variable vertex_fg "#000000"
#	variable comment_bg "#e0e0e0"
	
	variable canvas_bg "#d0d0ff"
	variable if_bg "#ffffc0"
	variable for_bg "#cfffcf"
	variable case_bg "#ffefdf"
	variable action_bg "#ffffff"	
	variable text_fg "#000000"
	variable line_fg "#000000"
	variable vertex_fg "#000000"
	variable comment_bg "#e0e0e0"
	variable comment_fg "#ffffc0"
	
	variable syntax_identifier "#000000"
	variable syntax_string "#d00000"
	variable syntax_keyword "#00008B"
	variable syntax_number "#d00000"
	variable syntax_comment "#228B22"
	variable syntax_operator "#800080"

### Dark night
#	variable canvas_bg "#001027"
#	variable if_bg "#171700"
#	variable for_bg "#001700"
#	variable case_bg "#170000"
#	variable action_bg "#000000"	
#	variable text_fg "#ffffb0"
#	variable line_fg "#ccccdc"
#	variable vertex_fg "#000040"
#	variable comment_bg "#303030"
}

namespace eval texts {


array set resources [ list \
	language "English" \
	yes "Yes" \
	no  "No"  \
	end "End" ]


proc init {} {
	put yes [ mc2 "Yes" ]
	put no  [ mc2 "No"  ]
	put end [ mc2 "End" ]
}

proc get { id } {
	variable resources
	return $resources($id)
}

proc put { id value } {
	variable resources
	set trimmed [ string trim $value ]
	if { $trimmed == "" } { return }
	set resources($id) $trimmed
}


}
