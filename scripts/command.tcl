
namespace eval com {

variable max_actions 50

proc p.clear_early { } {
	variable max_actions
	
	set count [ udb onecolumn { select count(*) from undo_steps } ]
	if { $count >= $max_actions } {
		set latest [ udb onecolumn { select max(step_id) from undo_steps } ]
		set first [ expr { $latest - $max_actions + 2 } ]
		udb eval { delete from undo_actions where step_id < :first }
		udb eval { delete from undo_steps where step_id < :first }	
	}
}

proc p.clear_after { } {
	set current_step [ udb onecolumn { select current_undo from state } ]
	if { $current_step != "" } {
		udb eval { delete from undo_actions where step_id > :current_step }
		udb eval { delete from undo_steps where step_id > :current_step }
	}
}

proc get_current_undo { } {
	return [ udb onecolumn { select current_undo from state } ]
}

proc start_action { name delegates } {
	p.clear_early
	p.clear_after
	
	set step_id [ mod::next_key udb undo_steps step_id ]
	set delegates_e [ sql_escape $delegates ]
	udb eval { insert into undo_steps (step_id, name, delegates) values (:step_id, :name, :delegates_e) }
	udb eval { update state set current_undo = :step_id }
	
	mw::enable_undo $name
	mw::disable_redo
	mw::set_status [ mc2 "Done: \$name." ]
}


proc push { db do do_change undo undo_change } {
	mod::apply $db $do_change
	invoke_all $do 0
	
	set do_change2 [ sql_escape $do_change ]
	set undo_change2 [ sql_escape $undo_change ]

	set current_step [ udb onecolumn { select current_undo from state } ]
	if { $current_step != "" } {
		set prev_action_no [ udb onecolumn {
			select max(action_no) from undo_actions where step_id = :current_step
		} ]
		if { $prev_action_no == "" } { set prev_action_no 0 }
		set action_no [ expr { $prev_action_no + 1 } ]
		set change [
			wrap insert undo_actions \
			step_id $current_step action_no $action_no \
			doit '$do' doit_change '$do_change2' \
			undoit '$undo' undoit_change '$undo_change2' ]

    	log $change
		
		mod::apply udb $change
	}
}


proc run_delegates { delegates } {
  foreach delegate $delegates {
    lassign $delegate fun arg
    $fun $arg
  }
}

proc undo { db } {
	set current_step [ udb onecolumn { select current_undo from state } ]
	if { $current_step == "" || $current_step == 0 } { return }
	
	udb eval { select name, delegates from undo_steps where step_id = :current_step } {
    	run_delegates $delegates
		mw::set_status [ mc2 "Undone: \$name." ]
	}
	
	udb eval { 
		select * from undo_actions where step_id = :current_step order by action_no desc
	} {
		mod::apply $db $undoit_change
		invoke_all $undoit 1
	}
	
	set next_step [ expr { $current_step - 1 } ]
	udb eval { update state set current_undo = :next_step }
	set min_step [ udb onecolumn { select min(step_id) from undo_steps } ]
	if { $next_step < $min_step } {
		mw::disable_undo
	} else {
		set undo_name [ mod::one udb name undo_steps step_id $next_step ]
		mw::enable_undo $undo_name
	}

	set redo_name [ mod::one udb name undo_steps step_id $current_step ]
	mw::enable_redo $redo_name
}

proc redo { db } {
	set old_step [ udb onecolumn { select current_undo from state } ]
	if { $old_step == "" } { return }
	set max_step [ udb onecolumn { select max(step_id) from undo_steps } ]
	set current_step [ expr { $old_step + 1 } ]
	if { $current_step > $max_step } { return }
	
	udb eval { select name, delegates from undo_steps where step_id = :current_step } {
    	run_delegates $delegates
		mw::set_status [ mc2 "Redone: \$name." ]
	}
	
	
	udb eval { update state set current_undo = :current_step }
	
	udb eval { 
		select * from undo_actions where step_id = :current_step order by action_no asc
	} {
		mod::apply $db $doit_change
		invoke_all $doit 1
	}
	
	if { $current_step == $max_step } {
		mw::disable_redo
	} else {
		set future_step [ expr { $current_step + 1 } ]
		set redo_name [ mod::one udb name undo_steps step_id $future_step ]
		mw::enable_redo $redo_name
	}
	
	set undo_name [ mod::one udb name undo_steps step_id $current_step ]
	mw::enable_undo $undo_name
}

}
