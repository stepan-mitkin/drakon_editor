
proc test.check_con { diagram_name begin end type ori ovals } {
	set diagram_id [ gdb onecolumn { select diagram_id from diagrams where name = :diagram_name } ]
	set con_ids [ tab::connection_head_keys ]
	set found {}
	foreach con_id $con_ids {
		set vertex1 [ tab::get_connection_vertex1 $con_id ]
		set vertex2 [ tab::get_connection_vertex2 $con_id ]
		set vd [ tab::get_vertex_diagram_id $vertex1 ]
		set item_id1 [ tab::get_vertex_item_id $vertex1 ]
		set item_id2 [ tab::get_vertex_item_id $vertex2 ]
		if { $vd != $diagram_id } { continue }
		lassign [ gdb eval { select text, text2 from items where item_id = :item_id1 } ] v1text v1text2
		set text1 "${v1text}${v1text2}"
		lassign [ gdb eval { select text, text2 from items where item_id = :item_id2 } ] v2text v2text2
		set text2 "${v2text}${v2text2}"
		set atype [ tab::get_connection_head $con_id ]
		set aori [ tab::get_connection_orientation $con_id ]

		set aoval_ids [ tab::get_connection_ovals $con_id ]
		set aovals {}
		foreach oval $aoval_ids {
			set oval_id [ tab::get_vertex_item_id $oval ]
			lappend aovals [ gdb eval { select text from items where item_id = :oval_id } ]
		}

		lappend found "$diagram_name: $text1 -> $text2 $atype-$aori \($aovals\)"

		if { $text1 != $begin } { continue }
		if { $text2 != $end } { continue }


		set adiagram_name [ gdb onecolumn { select name from diagrams where diagram_id = :vd } ]
		equal $text1 $begin
		equal $text2 $end
		equal $atype $type
		equal $aovals $ovals
		equal $aori $ori
		return
	}
	
	puts "not found:"
	puts "$diagram_name: $begin -> $end $type-$ori \($ovals\)"
	puts -nonewline "found instead: "
	if { [llength $found ] == 0 } {
		puts "nothing"
	} else {
		puts ""
		foreach item $found {
			puts $item
		}
	}

	exit

}

tproc connection_build_test { } {
	sqlite3 ddd ../testdata/structure_test.drn
	set mwc::db ddd
	graph::verify_all ddd
	tab::generate_tables gdb {} 1

	# horizontal

	test.check_con "horizontal" "A" "B" "line" "horizontal" {}
	test.check_con "left arrow" "B" "A" "arrow" "horizontal" {}
	test.check_con "right arrow" "A" "B" "arrow" "horizontal" {}
	test.check_con "left paw" "B" "A" "paw" "horizontal" {}
	test.check_con "right paw" "A" "B" "paw" "horizontal" {}

	test.check_con "simple hal 1" "class Role" "class ApplicationType" "arrow" "horizontal" "ApplicationType"
	test.check_con "simple har 1" "class ApplicationType" "class Role" "arrow" "horizontal" "Role"	
	
	test.check_con "simple hl 2" "class ApplicationType" "class Role" "line" "horizontal" {Role ApplicationType}
	
	test.check_con "simple hvl 1" "class Role" "class LeftPaw" "paw" "horizontal" ApplicationType
	test.check_con "simple hvl 2" "class Role" "class ApplicationType" "paw" "horizontal" {ApplicationType Roles}

	test.check_con "simple hvr 1" "class ApplicationType" "class Role" "paw" "horizontal" Roles
	test.check_con "simple hvr 2" "class ApplicationType" "class Role" "paw" "horizontal" {Roles ApplicationType}

	# horizontal complex

	test.check_con "fork hal 2" "class Role" "class ApplicationType" "arrow" "horizontal" "ApplicationType"
	test.check_con "fork hal 2" "class Attributes" "class ApplicationType" "arrow" "horizontal" "ApplicationType"

	test.check_con "fork har 1" "class ApplicationType" "class Attributes" "arrow" "horizontal" "Attribute"
	test.check_con "fork har 1" "class ApplicationType" "class Role" "arrow" "horizontal" "Role"

	test.check_con "fork hl 2" "class ApplicationType" "class Attributes" "line" "horizontal" {Attribute ApplicationType}
	test.check_con "fork hl 2" "class ApplicationType" "class Role" "line" "horizontal" {Role ApplicationType}

	test.check_con "fork hvr 1" "class ApplicationType" "class Attributes" "paw" "horizontal" "Attributes"
	test.check_con "fork hvr 1" "class ApplicationType" "class Role" "paw" "horizontal" "Roles"
	test.check_con "fork hvr 2" "class ApplicationType" "class Attributes" "paw" "horizontal" "Attributes ApplicationType"
	test.check_con "fork hvr 2" "class ApplicationType" "class Role" "paw" "horizontal" "Roles ApplicationType"

	test.check_con "merge hpr 1" "class Attributes" "class Role" "paw" "horizontal" "Roles"
	test.check_con "merge hpr 1" "class ApplicationType" "class Role" "paw" "horizontal" "Roles"
	test.check_con "merge hpr 2" "class Attributes" "class Role" "paw" "horizontal" "Roles Attribute"
	test.check_con "merge hpr 2" "class ApplicationType" "class Role" "paw" "horizontal" "Roles ApplicationType"

	test.check_con "m2m 2" "class ApplicationType" "class Role" "m2m" "horizontal" "Roles ApplicationTypes"
	
	# vertical

	test.check_con "simple inheritance" "class Method" "class Policy" "up white arrow" "vertical" {}
	test.check_con "simple va 1" "class Method" "class Policy" "up arrow" "vertical" {Method}
	test.check_con "simple vd 1" "class Method" "class Policy" "down arrow" "vertical" {Policy}
	test.check_con "simple vl 2" "class Method" "class Policy" "line" "vertical" {Policy Method}
	test.check_con "simple vp 1" "class Method" "class Policy" "down paw" "vertical" {Policies}
	test.check_con "simple vp 2" "class Method" "class Policy" "down paw" "vertical" {Policies Method}

	# vertical complex

	test.check_con "fork inheritance" "class Method" "class Policy" "up white arrow" "vertical" {}
	test.check_con "fork inheritance" "class Method" "class Attributes" "up white arrow" "vertical" {}

	test.check_con "fork va 1" "class Method" "class Policy" "up arrow" "vertical" {Method}
	test.check_con "fork va 1" "class Method" "class Attributes" "up arrow" "vertical" {Method}

	test.check_con "fork vd 1" "class Method" "class Policy" "down arrow" "vertical" {Policy}
	test.check_con "fork vd 1" "class Method" "class Attributes" "down arrow" "vertical" {Attribute}

	test.check_con "fork vl 2" "class Method" "class Policy" "line" "vertical" {Policy Method}
	test.check_con "fork vl 2" "class Method" "class Attributes" "line" "vertical" {Attribute Method}

	test.check_con "fork vp 1" "class Method" "class Policy" "down paw" "vertical" {Policies}
	test.check_con "fork vp 1" "class Method" "class Attributes" "down paw" "vertical" {Attributes}

	test.check_con "fork vp 2" "class Method" "class Policy" "down paw" "vertical" {Policies Method}
	test.check_con "fork vp 2" "class Method" "class Attributes" "down paw" "vertical" {Attributes Method}


}

proc test.good_diagram { filename } {

	sqlite3 ddd ../testdata/$filename
	set mwc::db ddd
	graph::verify_all ddd

	tab::generate_tables gdb {} 0
}


proc test.bad_diagram { filename } {

	sqlite3 ddd ../testdata/$filename
	set mwc::db ddd
	graph::verify_all ddd

	if { [ catch { tab::generate_tables gdb {} 0 } ] } {
		return
	}

	error "Error expected: $filename"

}

tproc class_build_error_test { } {

	test.bad_diagram "se_class_name_expected.drn"
	test.bad_diagram "se_class_not_expected.drn"
	test.bad_diagram "se_class_expected.drn"
	test.bad_diagram "se_class_already_defined.drn"
	test.bad_diagram "se_error_in_field.drn"
	test.bad_diagram "se_field_defined.drn"
	test.bad_diagram "se_index_field_not_found.drn"
	test.bad_diagram "se_repeating_index_field.drn"
	test.bad_diagram "se_index_expected.drn"

	test.bad_diagram "se_source_field_reuse.drn"
	test.bad_diagram "se_dest_field_reuse.drn"
	test.bad_diagram "se_not_link.drn"

	test.bad_diagram "se_wrong_paw.drn"
	test.bad_diagram "se_wrong_line.drn"
	test.bad_diagram "se_wrong_arrow.drn"
	test.bad_diagram "se_wrong_inherit.drn"

	test.bad_diagram "se_indexed_collection.drn"
	
	test.bad_diagram "se_no_labels.drn"
	
	test.bad_diagram "se_multi.drn"
	
	test.bad_diagram "se_cycle.drn"

	test.bad_diagram "se_id.drn"
}

proc test.verify_class { name properties fields {indexes {}} } {
	set class_id [ tab::find_class $name ]
	set a_name [ tab::get_class_name $class_id ]
	equal $a_name $name
	
	set a_props [ tab::get_class_properties $class_id ]
	equal $a_props $properties

	set a_fields [ tab::get_class_fields $class_id ]

	foreach field $a_fields {
		set a_field_name [ tab::get_field_name $field ]

		set found [ lsearch $fields $a_field_name ] 
		if { $found == -1 } {
			error "Field $a_field_name unexpected in class $name"
		}
	}
	equal [ llength $a_fields ] [ llength $fields ]
	set a_indexes [ tab::get_class_indexes $class_id ]
	foreach a_index $a_indexes {
		set a_name [ tab::get_index_name $a_index ]
		set found [ lsearch $indexes $a_name ]
		if { $found == -1 } {
			error "Index $a_name in $name"
		}
	}
	equal [ llength $a_indexes ] [ llength $indexes ]
}

proc test.verify_link { src src_field dst dst_field ownership type } {
	set ids [ tab::link_type_keys ]
	foreach id $ids {
		set a_src [ tab::get_link_src_table $id ]
		set a_dst [ tab::get_link_dst_table $id ]
		set a_src_name [ tab::get_class_name $a_src ]
		set a_dst_name [ tab::get_class_name $a_dst ]
		set a_src_field [ tab::get_link_src_field $id ]
		set a_dst_field [ tab::get_link_dst_field $id ]
		if { $src == $a_src_name && $dst == $a_dst_name && $src_field == $a_src_field && $dst_field == $a_dst_field } {
			set a_type [ tab::get_link_type $id ]
			set a_ownership [ tab::get_link_ownership $id ]
			equal $a_type $type
			equal $a_ownership $ownership
			return
		}
	}
	error "Link not found: $src $src_field $dst $dst_field"
}

tproc class_build_success_test { } {
	test.good_diagram "abstract_model.drn"	
	test.verify_class "Role" {} {Name IsApplicationRole} Role_Name
	test.verify_class "Entity" {property1} {Description WhenCreated WhenChanged CreatedBy ChangedBy Version Type} {Entity_WhenCreated Entity_WhenChanged}
	test.verify_class "EntityType" {} {Name} EntityType_Name
	test.verify_class "UserPrincipal" {} {Name IsEnabled ValidFrom ValidTo Organization Groups Activations} UserPrincipal_Organization_Name
	test.verify_class "Company" {} {Name Organization Phone} Company_Organization_Name
	test.verify_class "Organization" {} {Name Principals Companies} Organization_Name

	test.verify_link "Role" "" "Entity" "" "none" "inheritance"	
	test.verify_link "UserPrincipal" "" "Entity" "" "none" "inheritance"
	test.verify_link "CompanyAccessUnit" "" "Entity" "" "none" "inheritance"
	test.verify_link "Company" "" "CompanyAccessUnit" "" "none" "inheritance"
	test.verify_link "Organization" "" "CompanyAccessUnit" "" "none" "inheritance"
	test.verify_link "User" "" "UserPrincipal" "" "none" "inheritance"
	test.verify_link "UserGroup" "" "UserPrincipal" "" "none" "inheritance"
	test.verify_link "Entity" "Type" "EntityType" "" "none" "arrow"

	test.verify_link "Organization" "Companies" "Company" "Organization" "src" "paw"
	test.verify_link "Organization" "Principals" "UserPrincipal" "Organization" "src" "paw"
	test.verify_link "CompanyDetails" "Company" "Company" "" "dst" "arrow"
	test.verify_link "User" "Details" "PersonalDetails" "" "src" "arrow"
	test.verify_link "UserGroup" "Members" "UserPrincipal" "Groups" "none" "m2m"

	test.verify_link "Activation" "Role" "Role" "" "none" "arrow"
	test.verify_link "CompanyAccessUnit" "Activations" "Activation" "AccessUnit" "none" "paw"
	test.verify_link "UserPrincipal" "Activations" "Activation" "Principal" "none" "paw"

}


