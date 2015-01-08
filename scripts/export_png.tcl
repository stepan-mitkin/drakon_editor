
namespace eval export_png {


proc export { } {
	mwc::save_view
	
	if { $mw::canvas_width < 20 || $mw::canvas_height < 20} {
		tk_messageBox -parent . -message [ mc2 "The diagram window is too small.\nExpand it." ] -title Error
		return
	}

	if { ![ export_pdf::prepare_export ] } { return }
	
	set filename [ ds::requestspath export .png . ]
	if { $filename == "" } { return }
	
	if { [ ui::is_windows ] } {
		tk_messageBox -message [ mc2 "Please, do not move or open any window or diagram while exporting to PNG." ]
	}
	
	set box [ export_pdf::measure_diagram ]
	set image_rect [ calculate_image_pos $box ]
	lassign $image_rect left top right bottom
		
	set old_x [ $mw::canvas canvasx 0 ]
	set old_y [ $mw::canvas canvasy 0 ]
	
	set canvas_width [ expr { $mw::canvas_width - 10 } ]
	set canvas_height [ expr { $mw::canvas_height - 10 } ]
	
	set columns [ expr { ceil(($right - $left) / double($canvas_width)) } ]
	set rows [ expr { ceil(($bottom - $top) / double($canvas_height)) } ]
	
	set width [ expr { $right - $left } ]
	set height [ expr { $bottom - $top } ]
	update
	after 200
	image create photo canvas_all -width $width -height $height
	
	repeat row $rows {
		set ctop [ expr { $top + $row * $canvas_height } ]
		set dtop [ expr { $row * $canvas_height } ]
		repeat column $columns {
			set cleft [ expr { $left + $column * $canvas_width } ]
			set dleft [ expr { $column * $canvas_width } ]			
			p.scroll $cleft $ctop
			update
			p.take_subpicture $dleft $dtop $cleft $ctop $right $bottom
			update
		}
	}
	
	p.scroll $old_x $old_y
	update
	canvas_all write $filename -format png
	image delete canvas_all
	
	if { [ ui::is_windows ] } {
		tk_messageBox -message [ mc2 "Export complete." ]
	}
}

proc p.take_subpicture { dleft dtop cleft ctop right_edget bottom_edge } {
	image create photo canvas_piece -format window -data $mw::canvas
	canvas_all copy canvas_piece -to $dleft $dtop -from 5 5
#	canvas_piece write tmp/$cleft-$ctop.png -format png
	image delete canvas_piece
}

proc calculate_image_pos { diagram_box } {
	lassign $diagram_box left top right bottom
	
	set border 10
	set border2 [ expr { $border + 10 } ]
	set left2 [ expr { int($left * $mwc::zoom / 100.0) - $border2 } ]
	set top2 [ expr { int($top * $mwc::zoom / 100.0) - $border2 } ]
	set right2 [ expr { int($right * $mwc::zoom / 100.0) + $border } ]
	set bottom2 [ expr { int($bottom * $mwc::zoom / 100.0) + $border } ]	
	
	return [ list $left2 $top2 $right2 $bottom2 ]
}

proc p.scroll { x y } {
	set coords [ list $x $y ]
	mw::scroll $coords 1
}

}
