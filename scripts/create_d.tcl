
package require Tk

namespace eval mwd {

variable name_edit ""
variable name ""
variable root <bad-root>
variable type silhouette
variable dialect drakon
variable window <bad-window>
variable callback
variable sibling 0

proc change_state { new_state args } {
	foreach arg $args {
		$arg configure -state $new_state
	}
}

proc create_d_init { win data } {
	variable name
	variable root
	variable window
	variable callback
	variable sibling
	variable type
	variable name_edit ""
	variable dialect

	set dialect drakon
	set window $win
	lassign $data callback sibling

	set type primitive
	set name ""

	wm title $window [ mc2 "Create diagram" ]
	set root [ ttk::frame $window.root  ]
	set name_edit [ ttk::entry $root.name -textvariable mwd::name -width 40 ]

	set middle [ ttk::frame $root.middle -padding "5 5 5 5" ]
	set drakon_details [ ttk::frame $middle.drakon_details -relief sunken -padding "5 5 5 5" ]
	ttk::radiobutton $drakon_details.sil -text [ mc2 "Silhouette" ] -value silhouette -variable mwd::type
	ttk::radiobutton $drakon_details.sm -text [ mc2 "State machine" ] -value sm -variable mwd::type
	ttk::radiobutton $drakon_details.pri -text [ mc2 "Primitive" ] -value primitive -variable mwd::type

	set to_drakon [ list mwd::change_state normal $drakon_details.sil $drakon_details.pri $drakon_details.sm ]
	set to_data [ list mwd::change_state disabled $drakon_details.sil $drakon_details.pri $drakon_details.sm ]
	
	ttk::radiobutton $middle.drakon -text [ mc2 "DRAKON flowchart" ] -value drakon -variable mwd::dialect -command $to_drakon
	ttk::radiobutton $middle.structure -text [ mc2 "Structure diagram" ] -value structure -variable mwd::dialect -command $to_data

	
	
	set low [ ttk::frame $root.lower -padding "5 0 5 0" ]
	ttk::button $low.ok -text [ mc2 "Ok" ] -command mwd::ok
	ttk::button $low.cancel -text [ mc2 "Cancel" ] -command mwd::close
	

	pack $root -expand yes -fill both
	pack $root.name -expand yes -fill x -padx 5 -pady 10

	pack $middle -expand yes -side top -fill both
	pack $middle.structure -side top -anchor w -pady 10
	pack $middle.drakon -side top -anchor w
	pack $middle.drakon_details -side top -anchor w

	
	pack $drakon_details.sm -side top -anchor w
	pack $drakon_details.sil -side top -anchor w
	pack $drakon_details.pri -side top -anchor w
	
	pack $low -expand yes -fill x
	pack $low.cancel -side right -padx 5 -pady 10
	pack $low.ok -side right -padx 5 -pady 10

	bind $window <Return> mwd::ok
	bind $window <Escape> mwd::close

	focus $root.name
}

proc create_diagram_dialog { callback sibling } {
	variable name_edit ""
	ui::modal_window .create_d mwd::create_d_init [ list $callback $sibling ]
	focus $name_edit
}


proc ok { } {
  variable window
  variable callback
	variable sibling
  variable name
  variable type
  variable dialect
  
  set sil $type

  set trimmed [ string trim $name ]
  if { $trimmed == "" } {
    tk_messageBox -message [ mc2 "No text entered." ] -parent $window
    return
  }

  set result [ $callback $name $sil $sibling $dialect ]
  if { $result != "" } {
    tk_messageBox -message $result -parent $window
    return
  }

  destroy $window
}

proc close { } {
  variable window
  destroy $window
}

}

