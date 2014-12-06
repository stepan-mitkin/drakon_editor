
tproc layer_unlayer { } {
	set sql [ read_all_text ../scripts/schema.sql ]
	equal [ mod::create base :memory: t1 20 1 $sql ] ""
	mv::init base dummy_canvas::cnvs	
	
	set p1 { insert primitives	prim_id 10	above 0	 below 0 }
	set p2 { insert primitives	prim_id 20	above 0	 below 0 }
	set p3 { insert primitives	prim_id 30	above 0	 below 0 }
	set p4 { insert primitives	prim_id 40	above 0	 below 0 }
	set p5 { insert primitives	prim_id 50	above 0	 below 0 }
		
	mod::apply mb [ list $p1 $p2 $p3 $p4 $p5 ]
	
	check_layer icons 0 0 0
	
	mv::layer_primitive 10 icons
	check_layer icons 10 10 1
	
	mv::layer_primitive 20 icons
	check_layer icons 10 20 2
	
	mv::layer_primitive 30 icons	
	check_layer icons 10 30 3

	mv::layer_primitive 40 icons	
	check_layer icons 10 40 4

	mv::layer_primitive 50 icons	
	check_layer icons 10 50 5
	
	
	###

	mv::unlayer_primitive 10
	check_layer icons 20 50 4

	mv::unlayer_primitive 50
	check_layer icons 20 40 3

	mv::unlayer_primitive 30
	check_layer icons 20 40 2
	
	mv::unlayer_primitive 20
	check_layer icons 40 40 1

	mv::unlayer_primitive 40
	check_layer icons 0 0 0

	check_prim 10 0 0 
	check_prim 20 0 0
	check_prim 30 0 0
	check_prim 40 0 0
	check_prim 50 0 0 

	mb close
	mod::close base
}

proc check_layer { name lowest topmost prim_count } {
	set row [ mb eval { select lowest, topmost, prim_count from layers where name = :name } ]
	set alow [ lindex $row 0 ]
	set atop [ lindex $row 1 ]
	set cnt [ lindex $row 2 ]
	equal $alow $lowest
	equal $atop $topmost
	equal $cnt $prim_count
}

proc check_prim { prim_id above below } {
	set row [ mb eval { select above, below from primitives where prim_id = :prim_id } ]
	set aabove [ lindex $row 0 ]
	set abelow [ lindex $row 1 ]
	equal $aabove $above
	equal $abelow $below
}

proc prim_init { } {
	catch { mb close }	
	mv::init base dummy_canvas::cnvs	
	dummy_canvas::clear
	
	set p1 { insert primitives	prim_id 10	above 0	 below 0	 ext_id 100 }
	set p2 { insert primitives	prim_id 20	above 0	 below 0	 ext_id 200 }
	set p3 { insert primitives	prim_id 30	above 0	 below 0	 ext_id 300 }
	set p4 { insert primitives	prim_id 40	above 0	 below 0	 ext_id 400 }
	set p5 { insert primitives	prim_id 50	above 0	 below 0	 ext_id 500 }
		
	mod::apply mb [ list $p1 $p2 $p3 $p4 $p5 ]
}

tproc zplace_test { } {

	prim_init
	
	mv::zplace 10 lines
	mv::zplace 20 icons
	mv::zplace 30 handles
	
	dummy_canvas::check {
		{raise 200 100}
		{raise 300 200}
	}
	

	prim_init

	mv::zplace 30 handles 
	mv::zplace 20 icons 
	mv::zplace 10 lines

	dummy_canvas::check {
		{lower 200 300}
		{lower 100 200}
	}
	

	prim_init

	mv::zplace 30 handles
	mv::zplace 10 lines

	dummy_canvas::check {
		{lower 100 300}
	}


	prim_init

	mv::zplace 10 lines
	mv::zplace 30 handles

	dummy_canvas::check {
		{raise 300 100}
	}


	prim_init

	mv::zplace 10 lines
	mv::zplace 20 icons
	mv::zplace 30 handles
	mv::zplace 40 lines
	mv::zplace 50 icons

	dummy_canvas::check {
		{raise 200 100}
		{raise 300 200}
		{raise 400 100}
		{raise 500 200}
	}
	
	dummy_canvas::clear
	mb close
}




tproc create_prim_test { } {
	set sql [ read_all_text ../scripts/schema.sql ]
	equal [ mod::create base :memory: t1 20 1 $sql ] ""
	mv::init base dummy_canvas::cnvs	
	dummy_canvas::clear
#mv::create_prim item_id layer role type coords text rect fore fill

	mv::create_prim 111 icons good rectangle {10 20 30 40} {} {5 15 35 45} #000000 #ffffff
	mv::create_prim 111 icons bad polygon {11 22 33 44} {} {5 15 35 45} #000000 #ffffff
	
	dummy_canvas::check {
		{create rectangle {10 20 30 40} -outline #000000 -fill #ffffff -width 1.0}
		{create polygon {11 22 33 44} -outline #000000 -fill #ffffff -width 1.0} 
		{raise 2 1}
	}
	
	check_layer icons 1 2 2
	
	list_equal [ mb eval { select prim_id, item_id, role, above, below, ext_id, type, rect 
		from primitives where prim_id = 1} ] {
		1 111 good 2 0 1 rectangle	{5 15 35 45}
	}

	list_equal [ mb eval { select prim_id, item_id, role, above, below, ext_id, type, rect 
		from primitives where prim_id = 2} ] {
		2 111 bad 0 1 2 polygon {5 15 35 45}
	}
	
	dummy_canvas::clear
	
	mv::delete_prim 1
	mv::delete_prim 2
	
	dummy_canvas::check {
		{delete 1}
		{delete 2}
	}
	
	check_layer icons 0 0 0

	equal [ mb onecolumn { select count(*) from primitives } ] 0	
	
	mod::close base
}

tproc find_items_test { } {
	set sql [ read_all_text ../scripts/schema.sql ]
	equal [ mod::create base :memory: t1 20 1 $sql ] ""
	mv::init base dummy_canvas::cnvs	
	dummy_canvas::clear

	base eval { insert into diagrams (diagram_id) values (7); }
	
	base eval {
		insert into items (item_id, diagram_id, x, y, w, h, type, a, b)
			values ( 11, 7, 40, 20, 20, 10, 'action', 0, 0);
		insert into items (item_id, diagram_id, x, y, w, h, type, a, b)
			values ( 12, 7, 140, 40, 20, 20, 'action', 0, 0);
		insert into items (item_id, diagram_id, x, y, w, h, type, a, b)
			values ( 13, 7, 80, 80, 40, 10, 'action', 0, 0);
	}
	
	mv::insert 11 1
	mv::insert 12 1
	mv::insert 13 1

	set found [ mv::find_items 50 20 100 80 ]
	list_equal $found { 11 13 }
			
	mod::close base
}

tproc hit_test { } {
	mv::init base dummy_canvas::cnvs
	
	mb eval {
		insert into item_shadows (item_id, selected) values (11, 0);
		insert into item_shadows (item_id, selected) values (12, 0);
		insert into item_shadows (item_id, selected) values (13, 0);
		insert into primitives (item_id, layer_id, rect)
			values ( 11, 2, '20 10 60 30');
		insert into primitives (item_id, layer_id, rect)
			values ( 12, 2, '120 20 160 60');
		insert into primitives (item_id, layer_id, rect)
			values ( 13, 2, '50 70 120 90');
	}

	equal [ mv::hit 80 50 ] ""
	equal [ mv::hit 50 20 ] 11
	equal [ mv::hit 60 80 ] 13
	equal [ mv::hit 60 30 ] 11
			
}

tproc hit_handle_test { } {
	set sql [ read_all_text ../scripts/schema.sql ]
	equal [ mod::create base :memory: t1 20 1 $sql ] ""
	mv::init base dummy_canvas::cnvs	
	dummy_canvas::clear

	set dia { insert diagrams diagram_id 7	name 'seventh' origin "'0 0'" }
	set act { insert items item_id 101 diagram_id 7 type 'action' text 'preved' selected 1 
		x 70 y 50 w 40 h 30 a 0 b 0 }
	
	mod::apply base [ list $dia $act ]
	
	mv::insert 101 foo
	mv::select 101 foo

	equal [ mv::hit_handle 101 30 20 ] "nw"
	equal [ mv::hit_handle 101 70 20 ] "n"
	equal [ mv::hit_handle 101 110 20 ] "ne"
	
	equal [ mv::hit_handle 101 30 50 ] "e"
	equal [ mv::hit_handle 101 110 50 ] "w"

	equal [ mv::hit_handle 101 30 80 ] "sw"
	equal [ mv::hit_handle 101 70 80 ] "s"
	equal [ mv::hit_handle 101 110 80 ] "se"
	
	equal [ mv::hit_handle 101 -8000 -8000 ] ""
	equal [ mv::hit_handle 101 8000 8000 ] ""
	equal [ mv::hit_handle 101 60 50 ] ""

	mod::close base
}

proc drag_test { } {
	set sql [ read_all_text ../scripts/schema.sql ]
	equal [ mod::create base :memory: t1 20 1 $sql ] ""
	mv::init base dummy_canvas::cnvs	
	dummy_canvas::clear
			
	set dia { insert diagrams diagram_id 7	name 'seventh' origin "'0 0'" }
	set act1 { insert items item_id 101 diagram_id 7 type 'action' 
		text 'preved' selected 0 
		x 40 y 20 w 20 h 10 a 0 b 0 }
	set act2 { insert items item_id 102 diagram_id 7 type 'action' 
		text 'preved2' selected 0 
		x 140 y 40 w 20 h 20 a 0 b 0 }
		
	mod::apply base [ list $dia $act1 $act2 ]
	
	mv::insert 101 foo
	mv::select 101 foo
	
	mv::insert 102 foo
	
	
	dummy_canvas::clear
	
	mv::drag 4 7
	
	
	set commands [ dummy_canvas::get ]
	set sorted_commands [ lsort $commands ]
	list_equal $sorted_commands {
		{move 1 4 7}
		{move 10 4 7}
		{move 2 4 7}
		{move 3 4 7}
		{move 4 4 7}
		{move 5 4 7}
		{move 6 4 7}
		{move 7 4 7}
		{move 8 4 7}
		{move 9 4 7}
	}
	
	mb eval { select x, y from item_shadows where item_id = 101 } {
		equal $x 44
		equal $y 27 }
		
	mb eval { select rect from primitives
		where item_id = 101 and layer_id = 2 and role != 'text'} {
		list_equal $rect { 14 7 74 47 }
	}

	mod::close base
}

tproc action_handle_test { } {

	list_equal [ mv::action.nw 1 2 10 20 30 40 50 60 ] { 10 20 29 38 50 60 }
	list_equal [ mv::action.nw 100 200 10 20 30 40 50 60 ] { 10 20 20 10 50 60 }

	list_equal [ mv::action.n 1 2 10 20 30 40 50 60 ] { 10 20 30 38 50 60 }
	list_equal [ mv::action.n 100 200 10 20 30 40 50 60 ] { 10 20 30 10 50 60 }	 
	
	list_equal [ mv::action.ne 1 2 10 20 30 40 50 60 ] { 10 20 31 38 50 60 }
	list_equal [ mv::action.ne -100 200 10 20 30 40 50 60 ] { 10 20 20 10 50 60 }
	
	list_equal [ mv::action.w 1 2 10 20 30 40 50 60 ] { 10 20 31 40 50 60 }
	list_equal [ mv::action.w -100 200 10 20 30 40 50 60 ] { 10 20 20 40 50 60 }

	list_equal [ mv::action.e 1 2 10 20 30 40 50 60 ] { 10 20 29 40 50 60 }
	list_equal [ mv::action.e 100 200 10 20 30 40 50 60 ] { 10 20 20 40 50 60 }

	list_equal [ mv::action.sw 1 2 10 20 30 40 50 60 ] { 10 20 29 42 50 60 }
	list_equal [ mv::action.sw 100 -200 10 20 30 40 50 60 ] { 10 20 20 10 50 60 }

	list_equal [ mv::action.s 1 2 10 20 30 40 50 60 ] { 10 20 30 42 50 60 }
	list_equal [ mv::action.s 100 -200 10 20 30 40 50 60 ] { 10 20 30 10 50 60 }	
	
	list_equal [ mv::action.se 1 2 10 20 30 40 50 60 ] { 10 20 31 42 50 60 }
	list_equal [ mv::action.se -100 -200 10 20 30 40 50 60 ] { 10 20 20 10 50 60 }
}

tproc resize_test { } {
	set sql [ read_all_text ../scripts/schema.sql ]
	equal [ mod::create base :memory: t1 20 1 $sql ] ""
	mv::init base dummy_canvas::cnvs	
	dummy_canvas::clear
			
	set dia { insert diagrams diagram_id 7	name 'seventh' origin "'0 0'" }
	set act1 { insert items item_id 101 diagram_id 7 type 'action' 
		text 'preved' selected 0 
		x 40 y 20 w 20 h 10 a 0 b 0 }
		
	mod::apply base [ list $dia $act1 ]
	
	mv::insert 101 foo
	mv::select 101 foo
	
	dummy_canvas::clear
	
	mv::resize 101 se 10 40
	
	mb eval { select x, y, w, h from item_shadows where item_id = 101 } {
		equal $x 40
		equal $y 20
		equal $w 30
		equal $h 50 }
		
	mb eval { select rect from primitives
		where item_id = 101 and layer_id = 2 and role != 'text'} {
		list_equal $rect { 0 -40 80 80 }		
	}
	
	mod::close base
}

tproc shadow_selection_test { } {
	mv::init base dummy_canvas::cnvs
	mb eval { 
		insert into item_shadows (item_id, selected) values (100, 0);
		insert into item_shadows (item_id, selected) values (101, 1);
		insert into item_shadows (item_id, selected) values (102, 1);
		}
 
	list_equal [ mv::shadow_selection ] { 101 102 }
}



namespace eval dummy_canvas {

variable count 0
variable commands {}

proc check { expected } {
	variable commands
	list_equal $commands $expected
}

proc clear { } {
	variable count
	variable commands
	set count 0
	set commands {}
}

proc cnvs { args } {
	variable commands
	variable count

	lappend commands $args
	if { [ lindex $args 0 ] == "create" } { 
		incr count
		return $count
	}
	return ""
}

proc print { } {
	variable commands
	foreach command $commands {
		puts $command
	}
}

proc get { } {
	variable commands
	return $commands
}

}
