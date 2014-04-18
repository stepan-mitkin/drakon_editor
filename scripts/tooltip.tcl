namespace eval mw {
  variable command_id ""
  array set popup_texts {}

  proc register_popup { window x y } {
    variable command_id
    set command_id [ after 300 mw::show_popup $window $x $y ]
  }

  proc bind_popup { window text } {
    variable popup_texts
    set popup_texts($window) $text
    bind $window <Enter> { mw::register_popup %W %X %Y }
    bind $window <Leave> mw::hide_popup
  }
  
  proc hide_popup { } {
	variable command_id
	after cancel $command_id
	wm withdraw .popup
  }
  
  proc show_popup { window x y } {
    variable popup_texts
    incr x 5
    incr y 5
    set text $popup_texts($window)

    wm geometry .popup +$x+$y
    wm deiconify .popup    
    raise .popup

	.popup.frame.label configure -text $text
  }
  
  proc init_popup { } {    
    toplevel .popup
    wm overrideredirect .popup 1
    frame .popup.frame -padx 3 -pady 3 -background "#ffffa0"
    pack .popup.frame
    label .popup.frame.label -background "#ffffa0"
    pack .popup.frame.label
    
    wm withdraw .popup
  }
  
}
