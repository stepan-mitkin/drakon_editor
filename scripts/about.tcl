
namespace eval ui {
variable about_window "<bad>"

proc noop { } { }

proc about_init { window data } {
 	global script_path
	variable about_window
 	set about_window $window
 
 
  	image create photo about_image -format GIF -file $script_path/images/drakon_editor.gif
  
	wm title $window [ mc2 "About DRAKON Editor" ]
	
	ttk::frame $window.root -padding "5 5 5 5"
	frame $window.root.header -padx 5 -pady 5 -relief sunken -background white
	label $window.root.header.logo -image about_image -bd 0
	set version [ mc2 "DRAKON Editor v. \[ application_start_version \].\[ application_version \] \[version_tag\]\nAuthors: Stepan Mitkin, Alexander Ilyin, Maas-Maarten Zeeman, Vasil Dyadov, Vasili Bachiashvili" ]
	label $window.root.header.text -text $version -background white
	text $window.root.details -height 9 -font main_font -wrap word
	ttk::button $window.root.close -text [ mc2 "Close" ] -command ui::about.close
	
	$window.root.details insert 1.0 [ mc2 "DRAKON helps people understand programs.\n\nThis software is PUBLIC DOMAIN, with the exception of pdf4tcl and the Liberation fonts that have their own licenses.\n\nhttp://drakon-editor.sourceforge.net\ndrakon.editor@gmail.com\nTo see example diagrams in DRAKON language, go to the \\\"examples\\\" folder." ]
	
	
	grid $window.root -column 0 -row 0 -sticky nwse
	grid columnconfigure $window 0 -weight 1
	grid rowconfigure $window 0 -weight 1
	
	grid $window.root.header -column 0 -row 0 -padx 6 -pady 6 -sticky nwse
	pack $window.root.header.logo -side left
	pack $window.root.header.text -fill both -expand 1 -side left
	
	grid $window.root.details -column 0 -row 1 -sticky nwse
	grid $window.root.close -column 0 -row 2 -sticky se  -pady 5 -padx 5

	grid columnconfigure $window.root 0 -weight 1
	grid rowconfigure $window.root 1 -weight 1


	bind $window <Escape> ui::about.close
	bind $window <Return> ui::about.close
}

proc about.close { } {
  variable about_window
  destroy $about_window
  set about_window <bad>
}


proc show_about {  } {
	modal_window .about_window about_init {} .
}

}
