#!/usr/bin/tclsh


package require Tk

set g_recent "Hello!"
set g_keys {}

proc close_and_save { } {
	global g_keys
	array set keys_array $g_keys

	set f [ open keys.txt w ]
	set count [ llength $g_keys ]
	set half [ expr { $count / 2 } ]
	
	puts $f "set codes \{"
	foreach keysym [ lsort [ array names keys_array ] ] {
		set keycode $keys_array($keysym)
		puts $f "    $keysym $keycode"
	}
	puts $f "\}"
	close $f
	exit
}

proc on_press { keycode state unicode_sym keysym keysymn } {
	variable g_recent
	variable g_keys

	set g_recent "$keysym -> $keycode"
	lappend g_keys $keysym $keycode
}

wm title . "Key recorder"
label .what -textvariable g_recent -width 50
button .close_butt -text Close -command close_and_save
pack .what
pack .close_butt

bind . <KeyPress> { on_press %k %s %A %K %N }
