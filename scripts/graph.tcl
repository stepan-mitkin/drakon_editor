namespace eval graph {



proc copy_from { db } {
	graph2::reset.counter
	
	p.create_db
	$db eval {
		select item_id, diagram_id, type, text, text2, x, y, w, h, a, b
		from items
	} {
		if { $type == "parallel" } {
			set message [ mc2 "Elements of type '\$type' are not supported by the verifier yet." ]
			p.error $diagram_id $item_id $message
		}
		if { $type == "insertion" || $type == "input" || $type == "output" || $type == "process" } {
			set type "action"
		}

		gdb eval {
			insert into items(item_id, diagram_id, type, text, text2, x, y, w, h, a, b)
			values (:item_id, :diagram_id, :type, :text, :text2, :x, :y, :w, :h, :a, :b)
		}
	}
	
	$db eval {
		select diagram_id, name
		from diagrams
	} {
		gdb eval {
			insert into diagrams (diagram_id, name)
			values (:diagram_id, :name)
		}
	}
}

proc p.create_db { } {
	catch { gdb close }
	sqlite3 gdb :memory:
	gdb eval {
		create table diagrams
		(
			diagram_id integer primary key,
			name text,
			state text,
			message_type text,
			ordinal integer,
			is_default integer,
			original text
		);
		
		create table items
		(	
			item_id integer primary key,
			diagram_id integer,
			type text,
			text text,
			text2 text,
			x integer,
			y integer,
			w integer,
			h integer,
			a integer,
			b integer
		);
		
		create index items_by_diagram on items(diagram_id);
		
		create table vertices
		(
			vertex_id integer primary key,
			diagram_id integer,
			x integer,
			y integer,
			w integer,
			h integer,
			a integer,
			b integer,
			item_id integer,
			up integer,
			left integer,
			right integer,
			down integer,
			marked integer,
			type text,
			text text,
			text2 text,
			parent integer
		);
		
		create unique index vertex_by_coord on vertices(diagram_id, x, y);
		
		create table edges
		(
			edge_id integer primary key,
			diagram_id integer,
			point1 text,
			point2 text,
			vertex1 integer,
			vertex2 integer,
			head integer,
			vertical integer,
			items text,
			marked integer
		);
		
		create index edges_by_diagram on edges(diagram_id);
		
		create table errors
		(
			error_id integer primary key,
			diagram_id integer,
			items text,
			message text
		);
		
		create unique index uerror on errors(diagram_id, items, message);
		
		create table results
		(
			result_id integer primary key,
			error_id integer,
			diagram_id integer,
			items text,
			description text
		);
		
		create table branches
		(
			diagram_id integer,		
			ordinal integer,

			header_icon integer,
			start_icon integer,
			params_icon integer,
			first_icon integer,
			
			primary key (diagram_id, ordinal)
		);
		
		create table links
		(
			src integer,
			ordinal integer,
			dst integer,
			direction text,
			constant text,
			primary key (src, ordinal)
		);
		
		create table declares
		(
			declare_id integer primary key,
			diagram_id integer,
			line text,
			loop integer
		);
		
		create index declares_by_diagram on declares(diagram_id);
	}
}

proc get_error_list { } {
	set output {}
	gdb eval { delete from results }
	gdb eval {
		select d.name, e.diagram_id, error_id, items, message
		from errors e inner join diagrams d
			on e.diagram_id = d.diagram_id
		order by d.name, items
	} {
		if { [ llength $items ] > 0 } {
			set item_id [ lindex $items 0 ]
			set description "$name: item $item_id: $message"
		} else {
			set description "$name: $message"
		}
		lappend output $description
		gdb eval {
			insert into results (error_id, diagram_id, items, description)
			values ( :error_id, :diagram_id, :items, :description )
		}
	}
	
	return $output
}

proc get_error_info { error_no } {
	set result_id [ expr { $error_no + 1 } ]
	return [ gdb eval {
		select diagram_id, items
		from results
		where result_id = :result_id } ]
}

proc p.do_build_graph { diagram_id } {

	graph2::extract.manhattan gdb $diagram_id
}


proc p.error { diagram_id items message } {
	if { $diagram_id == "" } {
		error [ mc2 "diagram_id is empty" ]
	}
	set existing [ gdb onecolumn {
		select count(*)
		from errors
		where diagram_id = :diagram_id
			and items = :items
			and message = :message } ]
	if { $existing != 0 } { return }
	gdb eval {
		insert into errors (diagram_id, items, message)
			values (:diagram_id, :items, :message) }
}

proc p.clear { } {
	gdb eval {
		delete from vertices;
		delete from edges;
		delete from errors;
		delete from results;
		delete from branches;
		delete from links;
	}
}


proc p.errors { diagram_id } {
	set count [ gdb onecolumn {
		select count(*) from errors
		where diagram_id = :diagram_id } ]
	return [ expr { $count > 0 } ]
}

proc verify_one { db diagram_id } {
	copy_from $db

	p.do_build_graph $diagram_id
	if { ![ mwc::is_drakon $diagram_id ] } { return }
	if { [ p.errors $diagram_id ] } { return }
	p.do_extract_auto $diagram_id
}

proc is_verilog {} {
	array set properties [ mwc::get_file_properties ]
	if { [ info exists properties(language) ] } {
		set language $properties(language)
		if { $language == "Verilog" } {
			return 1
		}
	}
	return 0
}

proc verify_all { db } {
	if { [ is_verilog ] } {
		verify_all_vlog $db
	} else {
		verify_all_std $db
	}
}

proc verify_all_std { db } {
	copy_from $db
	$db eval {
		select diagram_id
		from diagrams
	} {

		
		p.do_build_graph $diagram_id
		if { ![ mwc::is_drakon $diagram_id ] } { continue }		
		
		if { [ p.errors $diagram_id ] } { continue }
		p.do_extract_auto $diagram_id
	}
}

proc print_db { } {
	puts vertices
	gdb eval {
		select * from vertices
	} {
		puts "vertex_id=$vertex_id item_id=$item_id type=$type"
	}
	
}

proc errors_occured { } {
	set count [ gdb onecolumn {
		select count(*)
		from errors } ]

	return [ expr { $count > 0 } ]
}

}
