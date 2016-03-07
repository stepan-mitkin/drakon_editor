namespace eval newfor {

array set loops { }


proc clear { } {
	variable loops
	array unset loops
	array set loops { }
}

proc put { key value } {
	variable loops
	set loops($key) $value
}

proc get { key } {
	variable loops
	if { [ info exists loops($key) ] } {
		set result $loops($key)
	} else {
		set result ""
	}
	return $result
}

}
