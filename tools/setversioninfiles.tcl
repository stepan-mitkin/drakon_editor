package require sqlite3

proc set_version_in_files { folder } {
	set path "$folder/*"
	set files [ glob -nocomplain $path ]
	foreach file $files {
		print_version_in_file $file
	}
}

proc print_version_in_file { file } {
	if { [ catch {
		sqlite3 db $file
		set version [ db onecolumn {
			select value from info where key = 'version' } ]
		puts "$file: $version"
	} ] } {

	}
}


proc set_version_in_file { file } {
	if { [ catch {
		sqlite3 db $file
		set version [ db onecolumn {
			select value from info where key = 'version' } ]
		if { $version == 5 } {
			db eval {
				update info set value = 4 where key = 'version'
			}
			puts $file
		}
	} ] } {
		puts "error processing $file "
	}
}


set_version_in_files ../examples
set_version_in_files ../design
set_version_in_files ../testdata