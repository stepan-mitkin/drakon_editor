
tproc zoomup_test { } {
	equal [ mwc::zoomup 0 ] 20
	equal [ mwc::zoomup 20 ] 40
	equal [ mwc::zoomup 95 ] 100
	equal [ mwc::zoomup 100 ] 105
	equal [ mwc::zoomup 500 ] 500
	equal [ mwc::zoomup 600 ] 500
}

tproc zoomdown_test { } {
	equal [ mwc::zoomdown 600 ] 500
	equal [ mwc::zoomdown 110 ] 105
	equal [ mwc::zoomdown 40 ] 20
	equal [ mwc::zoomdown 20 ] 20
	equal [ mwc::zoomdown 0 ] 20
}

tproc zoom_vertices_test { } {
	set mwc::zoom 100
	list_equal [ mwc::zoom_vertices {10 20 30} ] {10 20 30}
	set mwc::zoom 50
	list_equal [ mwc::zoom_vertices {10 20 30} ] {5 10 15}
	set mwc::zoom 300
	list_equal [ mwc::zoom_vertices {10 20 30} ] {30 60 90}
	
	set mwc::zoom 100
}


tproc diagram_info_test { } {
	set sql [ read_all_text ../scripts/schema.sql ]
	equal [ mod::create dd :memory: t1 20 1 $sql ] ""
	mwc::init dd
	mv::init dd dummy_canvas::cnvs
	
	mw::init_mock
	ui::init_mock
	
	mwc::do_create_dia first 0 0 drakon
	mwc::do_create_dia second 0 0 drakon
	
	equal [ mwc::get_diagram_parameter 1 one ] ""
	equal [ mwc::get_diagram_parameter 1 two ] ""

	mwc::set_diagram_parameter 1 one 1
	mwc::set_diagram_parameter 1 two 2
	mwc::set_diagram_parameter 2 two 222
	mwc::set_diagram_parameter 1 one 111

	equal [ mwc::get_diagram_parameter 1 one ] 111
	equal [ mwc::get_diagram_parameter 1 two ] 2
	equal [ mwc::get_diagram_parameter 2 one ] ""
	equal [ mwc::get_diagram_parameter 2 two ] 222

	mwc::delete_tree_items

	equal [ dd onecolumn { select count(*) from diagrams } ] 1
	equal [ mwc::get_diagram_parameter 1 one ] 111
	equal [ mwc::get_diagram_parameter 1 two ] 2
	equal [ mwc::get_diagram_parameter 2 one ] ""
	equal [ mwc::get_diagram_parameter 2 two ] ""

	com::undo dd

	equal [ mwc::get_diagram_parameter 1 one ] 111
	equal [ mwc::get_diagram_parameter 1 two ] 2
	equal [ mwc::get_diagram_parameter 2 one ] ""
	equal [ mwc::get_diagram_parameter 2 two ] 222

	com::redo dd

	equal [ dd onecolumn { select count(*) from diagrams } ] 1
	equal [ mwc::get_diagram_parameter 1 one ] 111
	equal [ mwc::get_diagram_parameter 1 two ] 2
	equal [ mwc::get_diagram_parameter 2 one ] ""
	equal [ mwc::get_diagram_parameter 2 two ] ""

	com::undo dd
	com::undo dd
	com::undo dd

	equal [ dd onecolumn { select count(*) from diagram_info } ] 0
	equal [ dd onecolumn { select count(*) from diagrams } ] 0
	mod::close dd
}

tproc undo_test { } {
	set sql [ read_all_text ../scripts/schema.sql ]
	equal [ mod::create dd :memory: t1 20 1 $sql ] ""
	mwc::init dd
	mv::init dd dummy_canvas::cnvs
	mw::init_mock
	ui::init_mock
	
	mwc::do_create_dia first 0 0 drakon
	check_state { first } { 1 first } first
	check_undo "Create diagram" ""
	
	mwc::do_create_dia first 0 0 drakon
	#equal [ ui::complained_mock ] "Diagram with name 'first' already exists."
	ui::init_mock
	
	check_state { first } { 1 first } first
	check_undo "Create diagram" ""

	
	mwc::do_create_dia second 0 0 drakon
	check_state { first second } { 1 first 2 second } second
	check_undo "Create diagram" ""
		
	mwc::delete_tree_items
	check_state { first } { 1 first } ""
	check_undo "Delete diagram" ""

	mwc::do_create_dia third 0 0 drakon

	check_state { first third } { 1 first 2 third } third
	check_undo "Create diagram" ""

	mw::select_dia 1 0

	mwc::current_dia_changed

	check_state { first third } { 1 first 2 third } first
	check_undo "Create diagram" ""

	set diagram_id [ mwc::get_dia_id first ]
	set node_id [ mwc::get_diagram_node $diagram_id ]
	mwc::do_rename_dia $node_id xfirst
	check_state { third xfirst } { 1 xfirst 2 third } xfirst
	check_undo "Rename diagram" ""

	mw::select_dia 2 0
	mwc::current_dia_changed
	check_state { third xfirst } { 1 xfirst 2 third } third
	check_undo "Rename diagram" ""
	
	mwc::delete_tree_items
	check_state { xfirst } { 1 xfirst } ""
	check_undo "Delete diagram" ""
	
	##### Start playing with undo now #####
	com::undo dd
	check_state { third xfirst } { 1 xfirst 2 third } third
	check_undo "Rename diagram" "Delete diagram"

	com::redo dd
	check_state { xfirst } { 1 xfirst } ""
	check_undo "Delete diagram" ""

	##### Start undoing again #####

	com::undo dd
	check_state { third xfirst } { 1 xfirst 2 third } third
	check_undo "Rename diagram" "Delete diagram"
	

	com::undo dd
	check_state { first third } { 1 first 2 third } first
	check_undo "Create diagram" "Rename diagram"

	com::undo dd
	check_state { first } { 1 first } ""
	check_undo "Delete diagram" "Create diagram"
	
	com::undo dd
	check_state { first second } { 1 first 2 second } second
	check_undo "Create diagram" "Delete diagram"
	
	com::undo dd
	check_state { first } { 1 first } first
	check_undo "Create diagram" "Create diagram"

	com::undo dd
	check_state {	 } { } ""
	check_undo "" "Create diagram"
	
	##### Nothing to undo now. Let's redo everything #####
	
	com::redo dd
	com::redo dd
	com::redo dd
	com::redo dd
	com::redo dd
	com::redo dd
	
	
	check_state { xfirst } { 1 xfirst } ""
	check_undo "Delete diagram" ""
	
	mod::close dd
}


tproc switch_to_item_test { } {
	set sql [ read_all_text ../scripts/schema.sql ]
	equal [ mod::create dd :memory: t1 20 1 $sql ] ""
	mwc::init dd
	mv::init dd dummy_canvas::cnvs
	dummy_canvas::clear

	mw::init_mock
	ui::init_mock
	
	set mw::canvas_width 200
	set mw::canvas_height 100
	
	mwc::do_create_dia first 0 0 drakon
	mwc::do_create_item action

	mwc::do_create_dia second 0 0 drakon
	mwc::do_create_item action
	mwc::do_change_text [ list 2 old 0 ] "cool"
	
	set oldx $mwc::scroll_x
	set oldy $mwc::scroll_y
	

	mwc::switch_to_item 1

	
	set itemx [ mod::one dd x items item_id 1 ]
	set itemy [ mod::one dd y items item_id 1 ]
	
	set expected_x [ expr { $itemx - 100 } ]
	set expected_y [ expr { $itemy - 50 } ]
	
	equal $mwc::scroll_x $expected_x
	equal $mwc::scroll_y $expected_y
	
	equal [ dd onecolumn { select current_dia from state } ] 1
	

	com::undo dd
	
	equal [ dd onecolumn { select current_dia from state } ] 2
	equal $mwc::scroll_x $oldx
	equal $mwc::scroll_y $oldy
	
	mod::close dd
}

tproc insert_action_test { } {
	set sql [ read_all_text ../scripts/schema.sql ]
	equal [ mod::create dd :memory: t1 20 1 $sql ] ""
	mwc::init dd
	mv::init dd dummy_canvas::cnvs
	dummy_canvas::clear
	
	mw::init_mock
	ui::init_mock
	
	mwc::do_create_dia first 0 0 drakon
	
	
	mwc::scroll 20 50
	mw::scroll {20 50} 1
	mwc::do_create_item action
	
	check_item 6 1 action {} 1 120 100 50 20
	
	mwc::scroll 10 30
	mw::scroll {10 30} 1
	mwc::do_create_item action
	
	check_item 6 1 action {} 0 120 100 50 20
	check_item 7 1 action {} 1 110 80 50 20

	
	list_equal [ mb eval { select item_id, x, y, w, h from item_shadows order by item_id } ] {
		1 170 60 100 20 2 170 390 60 20 3 170 80 0 290 4 170 60 200 0 5 370 60 60 30 6 120 100 50 20 7 110 80 50 20
	}
	
	equal [ mb eval { select count(*)
		from primitives} ] 20
	
	com::undo dd
	check_item 6 1 action {} 1 120 100 50 20
	
	com::undo dd
	equal [ dd onecolumn { select count(*) from items } ] 5
	
	com::redo dd
	com::redo dd
	
	check_item 6 1 action {} 0 120 100 50 20
	check_item 7 1 action {} 1 110 80 50 20
	equal [ dd onecolumn { select count(*) from items } ] 7
	
	list_equal [ mb eval { select item_id, x, y, w, h from item_shadows order by item_id } ] {
		1 170 60 100 20 2 170 390 60 20 3 170 80 0 290 4 170 60 200 0 5 370 60 60 30 6 120 100 50 20 7 110 80 50 20
	}
	
	equal [ mb onecolumn { select count(*)
		from primitives} ] 20


	
	com::undo dd
	com::undo dd

	equal [ mb onecolumn { select count(*)
		from primitives} ] 8

	equal [ mb onecolumn { select count(*)
		from item_shadows} ] 5
		
	mod::close dd
}

tproc take_selection_from_shadow_test { } {
	set sql [ read_all_text ../scripts/schema.sql ]
	equal [ mod::create base :memory: t1 20 1 $sql ] ""
	mv::init base dummy_canvas::cnvs
	mwc::init base
	dummy_canvas::clear
	
	set dia { insert diagrams diagram_id 7	name 'seventh' origin "'0 0'" }
	set act1 { insert items item_id 101 diagram_id 7 type 'action' 
		text 'preved' selected 0 
		x 40 y 20 w 20 h 10 a 0 b 0 }
	set act2 { insert items item_id 102 diagram_id 7 type 'action' 
		text 'preved2' selected 1 
		x 140 y 40 w 20 h 20 a 0 b 0 }
		
	mod::apply base [ list $dia $act1 $act2 ]
	
	mv::insert 101 foo
	mv::select 101 foo
	
	mv::insert 102 foo
	
	
	equal [ mod::one base selected items item_id 101 ] 0
	equal [ mod::one base selected items item_id 102 ] 1
	equal [ mod::one mb selected item_shadows item_id 101 ] 1
	equal [ mod::one mb selected item_shadows item_id 102 ] 0
	
	mwc::start_action "Test start action"
	
	mwc::take_selection_from_shadow 7

	equal [ mod::one base selected items item_id 101 ] 1
	equal [ mod::one base selected items item_id 102 ] 0
	equal [ mod::one mb selected item_shadows item_id 101 ] 1
	equal [ mod::one mb selected item_shadows item_id 102 ] 0
	
	mwc::undo

	equal [ mod::one base selected items item_id 101 ] 0
	equal [ mod::one base selected items item_id 102 ] 1
	equal [ mod::one mb selected item_shadows item_id 101 ] 0
	equal [ mod::one mb selected item_shadows item_id 102 ] 1
	
	mwc::redo

	equal [ mod::one base selected items item_id 101 ] 1
	equal [ mod::one base selected items item_id 102 ] 0
	equal [ mod::one mb selected item_shadows item_id 101 ] 1
	equal [ mod::one mb selected item_shadows item_id 102 ] 0
	
	equal [ mb onecolumn { select count(*) from primitives } ] 12

	mod::close base
}

tproc take_shapes_from_shadow_test { } {
	set sql [ read_all_text ../scripts/schema.sql ]
	equal [ mod::create base :memory: t1 20 1 $sql ] ""
	mv::init base dummy_canvas::cnvs	
	mwc::init base
	dummy_canvas::clear

			
	set dia { insert diagrams diagram_id 7	name 'seventh' origin "'0 0'" }
	set act1 { insert items item_id 101 diagram_id 7 type 'action' 
		text 'preved' selected 0 
		x 40 y 20 w 20 h 10 a 0 b 0 }
	set act2 { insert items item_id 102 diagram_id 7 type 'action' 
		text 'preved2' selected 0 
		x 140 y 40 w 20 h 20 a 0 b 0 }
	set act3 { insert items item_id 103 diagram_id 7 type 'action' 
		text 'preved3' selected 0 
		x 80 y 80 w 40 h 10 a 0 b 0 }
		
	mod::apply base [ list $dia $act1 $act2 $act3 ]
	
	mv::insert 101 foo
	mv::insert 102 foo
	mv::insert 103 foo
	
	mb eval { update item_shadows set x = 20, y = 30, w = 40, 
		h = 50, a = 60, b = 70	where item_id = 101 }
	
	mwc::start_action "Test start action"
	mwc::take_shapes_from_shadow { 101 102 }
		
	list_equal [ mb eval { select x, y, w, h, a, b 
		from item_shadows where item_id = 101 } ] { 20 30 40 50 60 70 }
	list_equal [ base eval { select x, y, w, h, a, b 
		from items where item_id = 101 } ] { 20 30 40 50 60 70 }

	list_equal [ mb eval { select x, y, w, h, a, b 
		from item_shadows where item_id = 102 } ] { 140 40 20 20 0 0 }
	list_equal [ base eval { select x, y, w, h, a, b 
		from items where item_id = 102 } ] { 140 40 20 20 0 0 }
		

	mwc::undo


	list_equal [ mb eval { select x, y, w, h, a, b 
		from item_shadows where item_id = 101 } ] { 40 20 20 10 0 0 }
	list_equal [ base eval { select x, y, w, h, a, b 
		from items where item_id = 101 } ] { 40 20 20 10 0 0 }

	list_equal [ mb eval { select x, y, w, h, a, b 
		from item_shadows where item_id = 102 } ] { 140 40 20 20 0 0 }
	list_equal [ base eval { select x, y, w, h, a, b 
		from items where item_id = 102 } ] { 140 40 20 20 0 0 } 


	mwc::redo

	list_equal [ mb eval { select x, y, w, h, a, b 
		from item_shadows where item_id = 101 } ] {20 30 40 50 60 70 }
	list_equal [ base eval { select x, y, w, h, a, b 
		from items where item_id = 101 } ] { 20 30 40 50 60 70 }

	list_equal [ mb eval { select x, y, w, h, a, b 
		from item_shadows where item_id = 102 } ] { 140 40 20 20 0 0 }
	list_equal [ base eval { select x, y, w, h, a, b 
		from items where item_id = 102 } ] { 140 40 20 20 0 0 }

		
	mod::close base
}

tproc change_text_test { } {
	set sql [ read_all_text ../scripts/schema.sql ]
	equal [ mod::create base :memory: t1 20 1 $sql ] ""
	mv::init base dummy_canvas::cnvs	
	mwc::init base
	dummy_canvas::clear

			
	set dia { insert diagrams diagram_id 7	name 'seventh' origin "'0 0'" }
	set act1 { insert items item_id 101 diagram_id 7 type 'action' 
		text 'preved' selected 0 
		x 40 y 20 w 20 h 10 a 0 b 0 }
		
	mod::apply base [ list $dia $act1 ]
	
	mv::insert 101 foo
	
	dummy_canvas::clear
	
	mwc::do_change_text [ list 101 preved 0 ] docha
	
	equal [ mod::one base text items item_id 101 ] docha
	
	mwc::undo
	
	equal [ mod::one base text items item_id 101 ] preved

	mwc::redo
	
	equal [ mod::one base text items item_id 101 ] docha
	
	dummy_canvas::check {
		{coords 1 {-10 0 90 40}} 
		{coords 2 {0 20}}
		{itemconfigure 2 -text docha}
		{coords 1 {20 10 60 30}}
		{coords 2 {30 20}}		
		{itemconfigure 2 -text preved}
		{coords 1 {-10 0 90 40}}
		{coords 2 {0 20}}
		{itemconfigure 2 -text docha}	
	}

	mod::close base
}

proc check_item { item_id diagram_id type text selected x y w h } {
	dd eval { select * from items where item_id = :item_id } row {
		equal $row(item_id)			$item_id
		equal $row(diagram_id)	$diagram_id
		equal $row(type)				$type
		equal $row(text)				$text
		equal $row(selected)		$selected
		equal $row(x)						$x
		equal $row(y)						$y
		equal $row(w)						$w
		equal $row(h)						$h
	}
}

proc check_scroll { name cx cy mx my } {
	set cs [ mw::get_scroll_mock ]
	set id [ mod::one dd diagram_id diagrams name '$name' ]
	if { $id == "" } { error "Diagram $name not found." }
	set ms [ mod::one dd origin diagrams diagram_id $id ]
	set acx [ lindex $cs 0 ]
	set acy [ lindex $cs 1 ]
	set amx [ lindex $ms 0 ]
	set amy [ lindex $ms 1 ]
	equal $acx $cx
	equal $acy $cy
	equal $amx $mx
	equal $amy $my
}

proc check_undo { undo redo } {
	equal [ mw::get_undo_mock ] $undo
	equal [ mw::get_redo_mock ] $redo
}

proc check_state { dia_list diagrams current } {
	list_equal [ mwc::get_diagrams ] $dia_list
#	list_equal [ mw::get_diagrams_mock ] $dia_list
	set diagram_id [ mwc::get_dia_id $current ]
	set node_id [ mwc::get_diagram_node $diagram_id ]
	equal [ mwc::get_selected_from_tree ] $node_id
	equal [ mwc::get_current_dia ] $diagram_id
	list_equal [ dd eval { 
		select diagram_id, name from diagrams order by diagram_id
	} ] $diagrams
	equal [ current_name ] $current
}

proc current_name { } {
	set id [ dd onecolumn { select current_dia from state } ] 
	if { $id == "" } { return "" }
	return [ mod::one dd name diagrams diagram_id $id ]
}
