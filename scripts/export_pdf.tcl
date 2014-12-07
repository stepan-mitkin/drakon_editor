
namespace eval export_pdf {

variable file_handle ""
variable dia_width ""
variable dia_height ""
variable header_height 15
variable diagram
variable dia_file


variable pr_papersizes { a0 a1 a2 a3 a4 a5 a6 11x17 ledger legal letter }
variable pr_encodings { cp1250 cp1251 cp1252 cp1253 cp1257 }

variable pr_file ""

variable pr_papersize
variable pr_orientation
variable pr_margin
variable pr_scale
variable pr_encoding

variable pr_colors

variable canvas_width
variable canvas_height

variable font_size_base ""

variable use_count 0

proc export { } {
	mwc::save_view
	if { ![ prepare_export ] } { return }
	p.reset_origin
	p.get_args
	ui::modal_window .export_window export_pdf::p.init {} .
}

proc prepare_export	 { } {
	variable file_handle
	variable diagram
	variable dia_file

	set diagram [ mwc::get_current_dia ]
	if { $diagram == "" } { return 0 }
	
	set prim_count [ mwc::get_prim_count ]
	if { $prim_count == 0 } {
		tk_messageBox -parent . -message [ mc2 "This diagram is empty." ] -title Error
	return 0
	}
	set dia_file [ mw::get_filename ]

	p.create_db
	mv::render_to export_pdf::p.db_render $diagram 
	return 1
}

proc p.get_args { } {
	p.get_arg papersize a4
	p.get_arg orientation portrait
	p.get_arg scale 100
	p.get_arg margin 11
	p.get_arg encoding cp1252
	p.get_arg colors 0
}

proc p.save_args { } {
	p.save_arg papersize
	p.save_arg orientation
	p.save_arg scale
	p.save_arg margin
	p.save_arg encoding
	p.save_arg colors
}

proc p.get_paper_size { format } {
	return $pdf4tcl::paper_sizes($format)
}

proc p.mm_to_units { mm } {
	set ratio $pdf4tcl::units(mm)
	return [ expr { $ratio * $mm } ]
}

proc p.is_number { value } {
	if { [ scan $value %f ] == {} } { return 0 }
	return 1
}

proc p.page_size_units { } {
	variable pr_papersize
	variable pr_orientation
	variable pr_margin
	variable header_height

	set margin [ p.mm_to_units $pr_margin ]
	set size [ p.get_paper_size $pr_papersize ]
	if { $pr_orientation == "portrait" } {
		set width [ lindex $size 0 ]
		set height [ lindex $size 1 ]
	} else {
		set width [ lindex $size 1 ]
		set height [ lindex $size 0 ]
	}

	set real_width [ expr { $width - $margin * 2 } ]
	set real_height [ expr { $height - $margin * 2 - $header_height } ]
	return [ list $real_width $real_height ]
}

proc p.check { } {
	variable pr_papersize
	variable pr_orientation
	variable pr_margin
	variable pr_scale
	variable pr_encoding
	
	if { ![ string is double $pr_margin ] } { return [ mc2 "Margin is not a number" ] }
	if { ![ string is double $pr_scale ] } { return [ mc2 "Scale is not a number" ] }

	if { $pr_margin < 0 } { return [ mc2 "Margin is negative." ] }
	set size [ p.page_size_units ]
	set width [ lindex $size 0 ]
	set height [ lindex $size 1 ]
	if { $width < 20 } { return [ mc2 "Margins are too wide." ] }
	if { $height < 20 } { return [ mc2 "Margins are too wide." ] }
	if { $pr_scale < 5 || $pr_scale > 500 } { return [ mc2 "Scale should be between 5 and 500." ] }

	return ""
}

proc p.apply_args { } {
	set message [ p.check ]
	if { $message != "" } {
		p.complain $message
		return
	}
	
	p.save_args
	p.redraw
}

proc p.fit_one { } {
	variable dia_width
	variable dia_height
	variable canvas_width
	variable canvas_height
	variable pr_scale
	
	set old_scale $pr_scale
	set pr_scale 100
	
	set cscale [ p.find_canvas_scale ]
	set message [ p.check ] 
	if { $message != "" } {
		set pr_scale $old_scale
		p.complain $message
		return
	}
	
	set sizeu [ p.page_size_units ]
	set widthu [ lindex $sizeu 0 ]
	set heightu [ lindex $sizeu 1 ]
	set widthc [ expr { $cscale * ($dia_width + 5) } ]
	set heightc [ expr { $cscale * ($dia_height + 5) } ]

	set xscale [ expr { $widthu * $cscale / $widthc } ]
	set yscale [ expr { $heightu * $cscale / $heightc } ]
	set xs_height [ expr { $xscale * $dia_height } ]
	set ys_width [ expr { $yscale * $dia_width } ]
	
	if { $xs_height > $heightu } { 
		set scale $yscale
	} elseif { $ys_width > $widthu } {
		set scale $xscale
	} elseif { $xscale > $yscale } {
		set scale $xscale
	} else {
		set scale $yscale
	}

	set pr_scale [ expr { ceil($scale * 2000.0) / 10.0 } ]
	p.apply_args
}

proc p.complain { message } {
	tk_messageBox -parent .export_window -message $message -title Error
}

proc p.start_export { } {
	variable pr_file
	set message [ p.check ]
	if { $message != "" } {
		p.complain $message
		return
	}
	
	p.save_args

	if { $pr_file == "" } {
		p.complain [ mc2 "Output file name not chosen." ]
		focus .export_window.root.middle.file
		return
	}
	
	if { $::use_log } {
		p.save_as_pdf
	} else {
		if { [ catch {
			p.save_as_pdf
		} message ] } {
			p.complain $message
			return
		}
	}
	destroy .export_window
}

proc p.browse { } {
	variable pr_file
	set filename [ ds::requestspath export .pdf .export_window ]
	if { $filename != "" } {
		set pr_file $filename
	}
}

proc p.save_arg { parameter } {
	variable diagram
	set varname "pr_$parameter"
	variable $varname
	set value [ set $varname ]
	mwc::set_diagram_parameter $diagram $parameter $value
}

proc p.get_arg { parameter default } {
	variable diagram
	set varname "pr_$parameter"
	variable $varname
	set value [ mwc::get_diagram_parameter $diagram $parameter ]
	if { $value == "" } {
		set $varname $default
	} else {
		set $varname $value
	}
}

proc p.print_db { } {
	prdb eval { 
		select * from primitives } row {
		log "$row(prim_id) $row(type) $row(fill) $row(outline) $row(text)"
	}
	prdb eval { 
		select * from coords } row {
		log "$row(prim_id) $row(ordinal) $row(x) $row(y)"
	}
}

proc p.close_db { } {
	prdb close
}

proc p.create_db { } {
	catch { prdb close }
	sqlite3 prdb :memory:
	prdb eval {
		create table primitives
		(
			prim_id integer primary key,
			type text,
			fill text,
			outline text,
			text text
		);
		
		create table coords
		(
			prim_id integer,
			ordinal integer,
			x double,
			y double,
			primary key (prim_id, ordinal)
		);
	}
}

proc p.get_list_of_chars { } {
	set texts [ prdb eval { select text from primitives } ]
	return [ make_char_set $texts ]
}

proc p.print_char_set { char_set } {
	set fp [ open "chars.txt" w ]
	fconfigure $fp -encoding utf-8
	foreach char $char_set {
		set s [ format %c $char ]
		puts $fp $s
	}
	close $fp
}

proc p.real_scale { } {
	variable pr_scale
	return [ expr { $pr_scale / 100.0 / 2.0 } ]
}

proc p.save_as_pdf {	} {
	variable pr_file
	variable pr_encoding
	variable pr_orientation
	variable pr_papersize
	variable pr_margin

	set margin [ join [ list [ string trim $pr_margin ] mm ] "" ]
	set scale [ p.real_scale ]
	p.do_save_as_pdf $pr_file $pr_encoding $pr_papersize $pr_orientation $margin $scale 1
}

proc p.get_font_info { } {
	array set props [ mwc::get_file_properties ]
	
	if { ![ info exists props(pdf_font) ] } { return "" }
	if { ![ info exists props(pdf_font_size) ] } { return "" }
	
	set font $props(pdf_font)
	set size $props(pdf_font_size)
	
	set fonts [ fprops::get_pdf_fonts ]
	if { ![ contains $fonts $font ] } { return "" }
	if { [ string trim $size ] == "" } { return "" }
	if { ![string is integer $size ] } { return "" }
	if { $size < 3 } { return "" }
	
	return [ list $font $size ]
}

proc p.get_font { } {
	set font_info [ p.get_font_info ]
	if { $font_info == "" } {
		set size 13
		set font $::script_path/fonts/LiberationMono-Regular.ttf
	} else {
		set size [ lindex $font_info 1 ]
		set font_filename [ lindex $font_info 0 ]
		set font $::script_path/fonts/$font_filename
	}
	
	return [ list $font $size ]
}

proc p.do_save_as_pdf { filename codepage paper_size orientation margin scale headers } {
	variable dia_width
	variable dia_height
	variable header_height
	variable diagram
	variable dia_file
	variable font_size_base
	variable use_count
	
	set base_font base$use_count
	set main_font main$use_count
	incr use_count
	
	lassign [ p.get_font ] font_filename font_size_base

	pdf4tcl::loadBaseTrueTypeFont $base_font $font_filename		
	pdf4tcl::createFont $base_font $main_font $codepage
	
	if { $orientation == "portrait" } {
		set landscape 0
	} else {
		set landscape 1
	}

	# create a pdf object
	catch { mypdf destroy }
	pdf4tcl::new mypdf -paper $paper_size -margin $margin -landscape $landscape
	set font_size [ expr { int($font_size_base * $scale) } ]
	
	
	set area [ p.page_size_units ]
	set page_width [ lindex $area 0 ]
	set page_height [ lindex $area 1 ]
	
	set rows [ expr { ceil( $dia_height / $page_height * $scale ) } ]
	set columns [ expr { ceil ( $dia_width / $page_width * $scale ) } ]
	
	repeat row $rows {
		repeat column $columns {
			mypdf setFont $font_size $main_font
			p.print_page $row $column $page_width $page_height $scale $headers
			if { $headers } {
				mypdf setFont 8 $main_font
				p.print_header $row $column $diagram $dia_file $page_width
			}
		}
	}
	
	mypdf write -file $filename
	mypdf destroy
}

proc p.print_header { row column diagram dia_file page_width } {
	variable header_height
	incr row
	incr column
	set name [ mwc::get_dia_name $diagram ]
	set text "$row-$column $dia_file / $name"
	set width [ mypdf getStringWidth $text ]
	set x [ expr { $page_width - $width } ]
	set y [ expr { $header_height * 0.8 } ]
	mypdf setFillColor "#000000"
	mypdf setStrokeColor "#000000"	 
	mypdf text $text -x $x -y $y
}

proc p.print_page { row column page_width page_height scale headers } {
	variable header_height
	variable pr_colors
	
	mypdf startPage

	if { $pr_colors } {
		mypdf setFillColor  $colors::canvas_bg
		mypdf setStrokeColor $colors::canvas_bg	
		set back_height [ expr { $page_height * 2 } ]
		mypdf rectangle 0 0 $page_width $back_height -filled 1
	}	
	mypdf setLineStyle 0.5
	
	set shift_x [ expr { -$page_width * $column } ]
	set shift_y [ expr { -$page_height * $row } ]
	if { $headers } {
		set shift_y [ expr { $shift_y + $header_height } ]
	}
	
	prdb eval { select * from primitives order by prim_id } {
		p.print_prim_to_pdf $prim_id $type $fill $outline $text $shift_x $shift_y $scale
	}
	
	p.print_margins $page_width $page_height $headers
}

proc p.print_margins { page_width page_height headers } {
	variable header_height
	mypdf setLineStyle 0

	mypdf setFillColor "#ffffff"
	mypdf setStrokeColor "#ffffff"
	
	set w [ expr { $page_width + 1000 } ]
	set h [ expr { $page_height + 1000 } ]
	
	# Left margin
	mypdf rectangle -500 -500 499 $h -filled 1

	# Right margin
	mypdf rectangle [ expr { $page_width + 1 } ] -500 500 $h -filled 1

	# Top margin
	set th 499
	if { $headers } {
		incr th $header_height
	}
	mypdf rectangle -500 -500 $w $th -filled 1

	# Bottom margin
	mypdf rectangle -500 [ expr { $page_height + $header_height + 1 } ] $w 500 -filled 1
	
	mypdf setLineStyle 0.75
}

proc p.db_render { args } {
	set type [ lindex $args 1 ]
	set coords [ lindex $args 2 ]
	set remaining [ lrange $args 3 end ]
	array set rem_array $remaining
	set text [ get_optional_argument rem_array -text ]
	set text_esc [ sql_escape $text ]
	set text_esc [ string map { "\t" "		" } $text_esc ]
	set fill [ get_optional_argument rem_array -fill ]
	set outline [ get_optional_argument rem_array -outline ]
	set anchor [ get_optional_argument rem_array -anchor ]
	
	if { $type == "text" && $anchor == "w" } {
		set type "text_left"
	}
	
	set prim_id [ mod::next_key prdb primitives prim_id ]
	set command [ wrap insert primitives prim_id $prim_id type '$type' text '$text_esc' \
		fill '$fill' outline '$outline' ]

	mod::apply prdb $command


	set coord_count [ expr { [ llength $coords ] / 2 } ]
	repeat i $coord_count {
		set index_x [ expr { $i * 2 } ]
		set index_y [ expr { $index_x + 1 } ]
		set x [ lindex $coords $index_x ]
		set y [ lindex $coords $index_y ]
		set command [ wrap insert coords prim_id $prim_id ordinal $i x $x y $y ]

		mod::apply prdb $command
	}	 
}


proc p.print_prim_to_pdf { prim_id type fill outline text shift_x shift_y scale } {


	if { $type == "text" } {
		p.print_text $prim_id $fill $text $shift_x $shift_y $scale "center"
	} elseif { $type == "text_left" } {
		p.print_text $prim_id $fill $text $shift_x $shift_y $scale "left"
	} elseif { $type == "rectangle" } {
		p.print_rectangle $prim_id $fill $outline $shift_x $shift_y $scale
	} elseif { $type == "line" } {
		p.print_line $prim_id $fill $shift_x $shift_y $scale
	} elseif { $type == "polygon" } {
		p.print_poly $prim_id $fill $outline $shift_x $shift_y $scale
	}
}

proc p.print_text { prim_id fill text shift_x shift_y scale align } {
	variable pr_colors
	prdb eval {
		select x, y from coords where prim_id = :prim_id and ordinal = 0
	} {
		if { $pr_colors } {
			set color $fill
		} else {
			set color "#000000"
		}
		mypdf setFillColor $color
		set x [ expr { $x * $scale + $shift_x } ]
		set y [ expr { $y * $scale + $shift_y } ]
		p.print_text_lines $text $x $y $scale $align
	}
}

proc p.print_rectangle { prim_id fill outline shift_x shift_y scale } {
	variable pr_colors
	prdb eval { select x, y from coords where prim_id = :prim_id
		and ordinal = 0 } {
		set left [ expr { $x * $scale + $shift_x } ]
		set top [ expr { $y * $scale + $shift_y } ]
	}
	prdb eval { select x, y from coords where prim_id = :prim_id
		and ordinal = 1 } {
		set right [ expr { $x * $scale + $shift_x } ]
		set bottom [ expr { $y * $scale + $shift_y } ]
	}
	
	set width [ expr { $right - $left } ]
	set height [ expr { $bottom - $top } ]


	if { $pr_colors } {
		mypdf setFillColor $fill
		mypdf setStrokeColor $outline	
	} else {
		mypdf setFillColor "#ffffff"
		mypdf setStrokeColor "#000000"
	}
	
	mypdf rectangle $left $top $width $height -filled 1
}

proc p.print_text_lines { text x y scale align } {
	variable font_size_base
	set spacing 0.0
	set font_size [ expr { ceil($scale * $font_size_base ) } ]
	
	set text [ string map { "\t" "    " } $text ]
	set lines [ split $text "\n" ]
	set max_width 0
	foreach line $lines {
		set width [ mypdf getStringWidth $line ]
		if { $width > $max_width } {
			set max_width $width
		}
	}
	set count [ llength $lines ]
	if { $align == "center" } {
		set left [ expr { $x - $max_width * 0.5 } ]
	} else {
		set left $x
	}
	set height [ expr { $font_size * ( 1 + $spacing) * $count } ]
	set first [ expr { $y - $height * 0.5 + $font_size * 0.75 } ]
	
	repeat i $count {
		set ty [ expr { $first + $font_size * (1 + $spacing) * $i } ]
		set line [ lindex $lines $i ]
		mypdf text $line -x $left -y $ty
	}
}

proc p.print_line { prim_id fill shift_x shift_y scale } {
	variable pr_colors
	
	if { $pr_colors } {
		mypdf setFillColor $fill
		mypdf setStrokeColor $fill	
	} else {
		mypdf setFillColor "#000000"
		mypdf setStrokeColor "#000000"
	}

	set start [ prdb onecolumn { select min(ordinal) from coords
		where prim_id = :prim_id } ]
	prdb eval { select x, y from coords where prim_id = :prim_id and ordinal = :start } {
		set x0 [ expr { $x * $scale + $shift_x } ]
		set y0 [ expr { $y * $scale + $shift_y } ]
	}
	
	prdb eval { select x, y from coords where prim_id = :prim_id and ordinal > :start
		order by ordinal } {

		set x [ expr { $x * $scale + $shift_x } ]
		set y [ expr { $y * $scale + $shift_y } ]
	 

		mypdf line $x0 $y0 $x $y
		
		set x0 $x
		set y0 $y
	}
	
}

proc p.print_poly { prim_id fill outline shift_x shift_y scale } {
	variable pr_colors
	if { $pr_colors } {
		mypdf setFillColor $fill
		mypdf setStrokeColor $outline	
	} else {
		mypdf setFillColor "#ffffff"
		mypdf setStrokeColor "#000000"
	}

	set command { mypdf polygon }
	prdb eval { select x, y from coords where prim_id = :prim_id order by ordinal } {
		set x [ expr { $x * $scale + $shift_x } ]
		set y [ expr { $y * $scale + $shift_y } ]
	
		lappend command $x $y
	}
	lappend command -filled 1
	set foo [ {*}$command ]
}

proc measure_diagram { } {
	set margin 20
	
	set left 1000000
	set top 1000000
	set right -1000000
	set bottom -1000000
	
	prdb eval { select * from coords } {
		if { $x < $left } {
			set left $x
		}
		
		if { $x > $right } {
			set right $x
		}
		
		if { $y < $top } {
			set top $y
		}
		
		if { $y > $bottom } {
			set bottom $y
		}
	}
	
	set left [ expr { $left - $margin } ]
	set top [ expr { $top - $margin } ]
	set right [ expr { $right + $margin } ]
	set bottom [ expr { $bottom + $margin } ]
	
	return [ list $left $top $right $bottom ]
}

proc p.reset_origin { } {
	variable dia_width
	variable dia_height
	
	set box [ measure_diagram ]
	lassign $box left top right bottom
	
	set dia_width [ expr { $right - $left + 2 } ]
	set dia_height [ expr { $bottom - $top + 2 } ]
	
	prdb eval { select * from coords } {
		set x2 [ expr { $x - $left + 1 } ]
		set y2 [ expr { $y - $top + 1 } ]
		prdb eval { update coords
			set x = :x2, y = :y2
			where prim_id = :prim_id and ordinal = :ordinal }
	}	 
}

proc p.init { win data } {
	variable pr_papersizes
	variable pr_encodings

	wm title $win [ mc2 "Export to PDF" ]

	grid rowconfigure $win 0 -weight 1
	grid columnconfigure $win 0 -weight 1
	
	set root [ string map { .. . } $win.root ]
	
	ttk::frame $root -padding "0 0 0 10"
	grid $root -row 0 -column 0 -sticky nsew
	grid rowconfigure $root 0 -weight 1
	grid columnconfigure $root 1 -weight 1
	
	ttk::frame $root.left
	grid $root.left -column 0 -row 0 -sticky nsew
	
	canvas $root.canvas	 -bg white -relief sunken
	grid $root.canvas -column 1 -row 0 -sticky nsew
	
	ttk::frame $root.left.psize -padding "3 3 3 3"
	ttk::label $root.left.psize.slabel -text [ mc2 "Paper size" ]
	ttk::combobox $root.left.psize.sizes -values $pr_papersizes -state readonly -textvariable export_pdf::pr_papersize
	ttk::label $root.left.psize.sclabel -text [ mc2 "Scale, %" ]
	ttk::entry $root.left.psize.scvalue -textvariable export_pdf::pr_scale
	ttk::label $root.left.psize.enlabel -text [ mc2 "Encoding" ]
	ttk::combobox $root.left.psize.envalue -values $pr_encodings -state normal -textvariable export_pdf::pr_encoding
	ttk::label $root.left.psize.mlabel -text [ mc2 "Margin, mm" ]
	ttk::entry $root.left.psize.mvalue -textvariable export_pdf::pr_margin
	
	pack $root.left.psize -fill x
	grid columnconfigure $root.left.psize 1 -weight 1		
	grid $root.left.psize.slabel -row 0 -column 0 -padx 3 -pady 3 -sticky e
	grid $root.left.psize.sizes -row 0 -column 1 -padx 3 -pady 3 -sticky we
	grid $root.left.psize.sclabel -row 1 -column 0 -padx 3 -pady 3 -sticky e
	grid $root.left.psize.scvalue -row 1 -column 1 -padx 3 -pady 3 -sticky we
	grid $root.left.psize.enlabel -row 2 -column 0 -padx 3 -pady 3 -sticky e
	grid $root.left.psize.envalue -row 2 -column 1 -padx 3 -pady 3 -sticky we
	grid $root.left.psize.mlabel -row 3 -column 0 -padx 3 -pady 3 -sticky e
	grid $root.left.psize.mvalue -row 3 -column 1 -padx 3 -pady 3 -sticky we
	
	ttk::labelframe $root.left.orientation -padding "3 3 3 3" -text [ mc2 "Orientation" ]
	ttk::radiobutton $root.left.orientation.portrait -text [ mc2 "Portrait" ] -variable export_pdf::pr_orientation -value portrait
	ttk::radiobutton $root.left.orientation.landscape -text [ mc2 "Landscape" ] -variable export_pdf::pr_orientation -value landscape
	pack $root.left.orientation	 -padx 3 -pady 3
	pack $root.left.orientation.portrait -side left -padx 15
	pack $root.left.orientation.landscape -side left -padx 15
	
	ttk::checkbutton $root.left.colors -variable export_pdf::pr_colors -text [ mc2 "Colors" ]
	pack $root.left.colors -padx 3 -pady 3

	ttk::button $root.left.one -text [ mc2 "Fit one page" ] -command export_pdf::p.fit_one
	pack $root.left.one -padx 3 -pady 3	 
	ttk::button $root.left.apply -text [ mc2 "Apply" ] -command export_pdf::p.apply_args
	pack $root.left.apply -padx 3 -pady 3
	
	ttk::label $root.left.message -textvariable export_pdf::pr_message
	pack $root.left.message -padx 3 -pady 3 -fill x

	ttk::frame $root.middle -padding "3 3 3 3"
	grid $root.middle -column 0 -row 1 -columnspan 2 -sticky we

	ttk::label $root.middle.label -text [ mc2 "Output file:" ]
	ttk::button $root.middle.browse -text "..." -command export_pdf::p.browse
	pack $root.middle.browse -side right -padx 3 -pady 3
	
	ttk::entry $root.middle.file -textvariable export_pdf::pr_file
	pack $root.middle.file -side right -fill x -expand 1	-padx 3 -pady 3
	pack $root.middle.label -side right

	ttk::frame $root.bottom -padding "3 3 3 3"
	grid $root.bottom -column 0 -row 2 -columnspan 2 -sticky we
	
	ttk::button $root.bottom.cancel -text [ mc2 "Cancel" ] -command export_pdf::p.close
	pack $root.bottom.cancel -side right -padx 3 -pady 3

	ttk::button $root.bottom.export -text [ mc2 "Export" ] -command export_pdf::p.start_export
	pack $root.bottom.export -side right -padx 3 -pady 3

	bind $win <Escape> export_pdf::p.close
	bind $win <Return> export_pdf::p.start_export
	bind $root.canvas <Configure> "export_pdf::p.canvas_resized %w %h"

	ui::bind_entry_win_copypaste $root.middle.file

	focus $root.middle.file
}

proc p.find_canvas_scale {	} {
	variable canvas_width
	variable canvas_height
	variable dia_width
	variable dia_height
	variable pr_scale
	set paper_size [ p.page_size_units ]
	lassign $paper_size paper_width paper_height
	
	set paper_width [ expr { $paper_width * 2 / $pr_scale * 100.0} ]
	set paper_height [ expr { $paper_height * 2 / $pr_scale * 100.0} ]
 
	if { $paper_width > $dia_width || $paper_height > $dia_height} {
		set pwidth $paper_width
		set pheight $paper_height
	} else {
		set pwidth $dia_width
		set pheight $dia_height
	}
	set w [ expr { $canvas_width - 10 } ]
	set h [ expr { $canvas_height - 10 } ]
	if { $w < 50 } { set w 50 }
	if { $h < 50 } { set h 50 }
	set xscale [ expr { $w / $pwidth } ]
	set yscale [ expr { $h / $pheight } ]
	if { $xscale < $yscale } {
		set scale $xscale
	} {
		set scale $yscale
	}
	return $scale
}

proc p.scale_coordinates { prim_id scale } {
	set result {}
	prdb eval { select x, y from coords where prim_id = :prim_id
		order by ordinal
	} {
		set x1 [ expr { 5 + $x * $scale } ]
		set y1 [ expr { 5 + $y * $scale } ]
		lappend result $x1 $y1
	}
	return $result
}

proc p.draw_preview_diagram { scale } {
	set canvas .export_window.root.canvas
	$canvas delete all
	prdb eval { 
		select * from primitives order by prim_id
	} {
		set coords [ p.scale_coordinates $prim_id $scale ]

		if { $type == "rectangle" || $type == "polygon" } {
			$canvas create $type $coords -fill $fill -outline $outline
		} elseif { $type == "line" } {
			$canvas create $type $coords -fill $fill
		}
	}
	
}

proc p.canvas_resized { w h } {
	variable canvas_width
	variable canvas_height
	set canvas_width $w
	set canvas_height $h
	p.redraw
}

proc p.redraw {	 } {
	set scale [ p.find_canvas_scale ]
	p.draw_preview_diagram $scale
	if { [ p.check ] == "" } {
		p.draw_grid $scale
	}
}

proc p.draw_grid { scale } {
	variable canvas_width
	variable canvas_height
	
	set sizeu [ p.page_size_units ]
	set widthu [ lindex $sizeu 0 ]
	set heightu [ lindex $sizeu 1 ]
	set rscale [ p.real_scale ]
	set widthp [ expr { int($widthu / $rscale * $scale ) } ]
	set heightp [ expr { int($heightu / $rscale * $scale ) } ]
	for { set x 5 } { $x < $canvas_width } { incr x $widthp } {
		.export_window.root.canvas create line $x 0 $x $canvas_height -fill "#0000ff"
	}
	for { set y 5 } { $y < $canvas_height } { incr y $heightp } {
		.export_window.root.canvas create line 0 $y $canvas_width $y -fill "#0000ff"
	}
}

proc p.close { } {
	destroy .export_window
}


}
