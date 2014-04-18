namespace eval mwc {

proc create_dia_node { node_id ignored } {
	lassign [ get_node_info $node_id ] parent type foo diagram_id
	set name [ get_node_text $node_id ]
	mtree::add_item $parent $type $name $node_id
}

proc delete_dia_node { node_id ignored } {
	mtree::remove_item $node_id
}

proc is_diagram { type } {
	if { $type == "item" || $type == "data" } {
		return 1
	} else {
		return 0
	}
}

proc rename_dia_node { node_id ignored } {
	lassign [ get_node_info $node_id ] parent type foo diagram_id
	set name [ get_node_text $node_id ]
	mtree::rename_item $node_id $name
	
	set selection [ mtree::get_selection ]
	if { [ llength $selection ] == 1 } {
		set selected_node [ lindex $selection 0 ]
		if { $selected_node == $node_id && [ is_diagram $type ] } {
			set mw::current_name $name
		}
	}
}

proc get_node_text { node_id } {
	variable db
	lassign [ get_node_info $node_id ] parent type name diagram_id
	if { [ is_diagram $type ] } {
		return [ $db onecolumn {
			select name from diagrams where diagram_id = :diagram_id } ]
	}
	
	return $name
}


}
