
tproc open_model_ok { } {
	list_equal [ mod::open ddd ../testdata/db1 t1 ] { {20 1} "" }
	list_equal [ mod::open ddd ../testdata/db1 t1 ] { "" "Database name ddd is already used" }

	equal [ mod::one ddd value info key 'version' ] 20
	equal [ mod::one ddd value info key 'start_version' ] 1
	equal [ mod::one ddd value info key 'type' ] t1

	mod::close ddd
}


tproc create_model_ok { } {
	equal [ mod::create ddd ../tmp/good t1 20 1 "" ] ""
	equal [ mod::create ddd ../tmp/good t1 20 1 "" ] "Database name ddd is already used"

	equal [ mod::one ddd value info key 'version' ] 20
	equal [ mod::one ddd value info key 'type' ] t1

	mod::close ddd
}

proc check_open { actual expected } {
	set relevant [ lrange $actual 0 1 ]
	list_equal $relevant $expected
}

tproc open_model_fail { } {
	mod::create ddd ../tmp/bad_type t1000 200 1 ""
	mod::close ddd
	
	mod::create ddd ../tmp/no_version t1 200 1 { delete from info where key = 'version' }
	mod::close ddd
	
	check_open [ mod::open ddd foo/foo/foo t1 ] { "" "File foo/foo/foo does not exist" }
	check_open [ mod::open ddd ../testdata/baddb t1 ] { "" "Incompatible database ../testdata/baddb" }
	check_open [ mod::open ddd ../tmp/bad_type t1 ] { "" "Wrong schema in database ../tmp/bad_type" }
}

tproc create_model_fail { } {
	equal [ mod::create ddd foo/foo/foo t1 20 1 "" ] "Could not create database foo/foo/foo"
	equal [ mod::create ddd ../tmp/fail t1 20 1 "what is this?" ] "Could not init database ../tmp/fail"
}

tproc save_as_model { } {
	equal [ mod::close bad ] "Unknown database name bad"
	equal [ mod::save_as bad foo/foo ] "Unknown database name bad"
	
	mod::create ddd ../tmp/db2 t2 40 1 ""
	mod::close ddd
	
	mod::open ddd ../tmp/db2 t2
	equal [ mod::save_as ddd ../tmp/db3 ] ""
	
	equal [ mod::one ddd value info key 'version' ] 40
	equal [ mod::one ddd value info key 'type' ] t2

	mod::close dd	

	mod::open ddd ../tmp/db2 t2
	equal [ mod::save_as ddd foo/foo/foo ] "Could not create or replace file foo/foo/foo"
	equal [ mod::close ddd ] "Unknown database name ddd"
}



tproc sql_build { } {
	set rowinfo {
		ignored
		monsters
		name 'vania'
		type 10
		speed 20.0
	}
	
	set ins1 [ mod::make_insert $rowinfo ]
	equal $ins1 "insert into monsters (name, type, speed) values ('vania', 10, 20.0);"
	
	set upd1 [ mod::make_update $rowinfo ]
	equal $upd1 "update monsters set type = 10, speed = 20.0 where name = 'vania';"
	
	set del1 [ mod::make_delete { ignored monsters name 'vania' } ]
	equal $del1 "delete from monsters where name = 'vania';"
}

tproc apply_test { } {
	equal [ mod::create ddd :memory: t1 20 1 "" ] ""

	ddd eval {
		create table diagrams
		(
			diagram_id integer primary key,
			name text unique
		);
	}

	mod::apply ddd {
		{ insert diagrams diagram_id 1 name 'foo' }
		{ insert diagrams diagram_id 2 name 'bar' }
		{ insert diagrams diagram_id 3 name 'cool' }
		{ update diagrams diagram_id 2 name 'bar2' }
	}
	
	set dias [ ddd eval { select diagram_id, name from diagrams order by diagram_id } ]
	list_equal $dias { 1 foo 2 bar2 3 cool }
	list_equal [ mod::fetch_with_names ddd diagrams diagram_id 2 diagram_id name ] { diagram_id 2    name bar2 }
	
	mod::apply ddd {
		{ delete diagrams diagram_id 1}
	}

	set dias [ ddd eval { select diagram_id, name from diagrams order by diagram_id } ]
	list_equal $dias { 2 bar2 3 cool }
	
	mod::close ddd
}


tproc next_key_test { } {
	equal [ mod::create ddd :memory: t3 800  1 "" ] ""
	
	ddd eval {
		create table diagrams
		(
			diagram_id integer primary key,
			name text unique
		);
	}	
	
	equal [ mod::next_key ddd diagrams diagram_id ] 1
	
	mod::apply ddd {
		{ insert diagrams name 'foo' } }
	
	equal [ mod::next_key ddd diagrams diagram_id ] 2
	
	mod::apply ddd {
		{ insert diagrams name 'bar' } }
	
	equal [ mod::next_key ddd diagrams diagram_id ] 3
	
	set dias [ ddd eval { select diagram_id, name from diagrams order by diagram_id } ]
	list_equal $dias { 1 foo 2 bar }

	mod::apply ddd {
		{ delete diagrams diagram_id 1 } }
	set dias [ ddd eval { select diagram_id, name from diagrams order by diagram_id } ]
	list_equal $dias { 2 bar }
	equal [ mod::next_key ddd diagrams diagram_id ] 3
	
	mod::apply ddd {
		{ insert diagrams name 'bone' } }
	set dias [ ddd eval { select diagram_id, name from diagrams order by diagram_id } ]
	list_equal $dias { 2 bar  3 bone }
	equal [ mod::next_key ddd diagrams diagram_id ] 4


	mod::apply ddd {
		{ delete diagrams diagram_id 3 } }
	set dias [ ddd eval { select diagram_id, name from diagrams order by diagram_id } ]
	list_equal $dias { 2 bar }
	equal [ mod::next_key ddd diagrams diagram_id ] 3


	mod::apply ddd {
		{ insert diagrams name 'friend' } }
	set dias [ ddd eval { select diagram_id, name from diagrams order by diagram_id } ]
	list_equal $dias { 2 bar  3 friend }
	equal [ mod::next_key ddd diagrams diagram_id ] 4

	mod::close ddd
}
