tproc nogoto_test { } {

	# Simple
	
	nogotot::Empty
	equal [ nogotot::One 1 ] 2
	equal [ nogotot::Two 1 ] 3
	equal [ nogotot::Three 1 ] 13
	
	# Logic
	
	equal [ nogotot::AND 0 0 ] 0
	equal [ nogotot::AND 0 1 ] 0
	equal [ nogotot::AND 1 0 ] 0
	equal [ nogotot::AND 1 1 ] 1


	equal [ nogotot::AND_NOT 0 0 ] 0
	equal [ nogotot::AND_NOT 0 1 ] 0
	equal [ nogotot::AND_NOT 1 0 ] 1
	equal [ nogotot::AND_NOT 1 1 ] 0

	equal [ nogotot::OR 0 0 ] 0
	equal [ nogotot::OR 0 1 ] 1
	equal [ nogotot::OR 1 0 ] 1
	equal [ nogotot::OR 1 1 ] 1


	equal [ nogotot::OR_NOT 0 0 ] 1
	equal [ nogotot::OR_NOT 0 1 ] 0
	equal [ nogotot::OR_NOT 1 0 ] 1
	equal [ nogotot::OR_NOT 1 1 ] 1
	
	equal [ nogotot::ComplexLogic 0 0 0 0 0 0 ] 0
	equal [ nogotot::ComplexLogic 1 1 1 1 1 1 ] 0
	
	equal [ nogotot::ComplexLogic 0 0 0 1 0 1 ] 1
	equal [ nogotot::ComplexLogic 1 0 1 0 0 0 ] 1

	
	# If
	
	equal [ nogotot::DiagonalIf 0 0 1 ] 2
	equal [ nogotot::DiagonalIf 0 1 1 ] 1001
	equal [ nogotot::DiagonalIf 1 0 1 ] 2
	equal [ nogotot::DiagonalIf 1 1 1 ] 2	
	
	equal [ nogotot::DiagonalIf2 0 0 0 1 ] 11
	equal [ nogotot::DiagonalIf2 0 0 1 1 ] 2
	equal [ nogotot::DiagonalIf2 0 1 0 1 ] 1001
	equal [ nogotot::DiagonalIf2 0 1 1 1 ] 1001
	equal [ nogotot::DiagonalIf2 1 0 0 1 ] 11
	equal [ nogotot::DiagonalIf2 1 0 1 1 ] 2
	equal [ nogotot::DiagonalIf2 1 1 0 1 ] 11
	equal [ nogotot::DiagonalIf2 1 1 1 1 ] 2

	equal [ nogotot::Diamond 0 1 ] 0
	equal [ nogotot::Diamond 1 1 ] 2
	
	equal [ nogotot::EmptyIf 0 1 ] 1
	equal [ nogotot::EmptyIf 1 1 ] 1
	
	equal [ nogotot::NestedDiamond 100 1 ] 2
	equal [ nogotot::NestedDiamond 0 1 ] 1101
	equal [ nogotot::NestedDiamond -100 1 ] 1011

	equal [ nogotot::NestedIf 100 1 ] 2
	equal [ nogotot::NestedIf 0 1 ] 101
	equal [ nogotot::NestedIf -100 1 ] 11

	equal [ nogotot::NestedIf2 100 1 ] 2
	equal [ nogotot::NestedIf2 0 1 ] 101
	equal [ nogotot::NestedIf2 -15 1 ] 11
	equal [ nogotot::NestedIf2 -100 1 ] 1001
	
	# Switch
	
	equal [ nogotot::ProcInSelect  5 ] 1
	equal [ nogotot::ProcInSelect 10 ] 2
	equal [ nogotot::ProcInSelect 30 ] 3
	
	equal [ nogotot::VarInSelect  5 ] 1
	equal [ nogotot::VarInSelect 10 ] 2
	equal [ nogotot::VarInSelect 30 ] 3
	

	# Loops
	
	equal [ nogotot::CheckDo ] 10
	equal [ nogotot::Continue ] 5
	equal [ nogotot::DoCheck ] 10
	equal [ nogotot::DoCheckDo ] 11
	equal [ nogotot::ForEach ] 4
	equal [ nogotot::ForEachBreak ] 3
	equal [ nogotot::NestedLoop ] 55
	equal [ nogotot::SimpleLoop ] 10
	equal [ nogotot::TwoBreaks ] 8
	equal [ nogotot::ThreeBreaks ] 5
	
	# Hybrid
	
	equal [ nogotot::IfInsideLoop ] 506
	equal [ nogotot::JumpFromThen ] 6
	equal [ nogotot::LoopInsideIf 1 ] 1
	equal [ nogotot::LoopInsideIf 0 ] 1100
	
	# Goto
	
	equal [ nogotot::DifferentLoopStarts ] 2
	equal [ nogotot::ExitToAbove ] 4
	
	equal [ nogotot::JumpToThen 0 0 ] 0
	equal [ nogotot::JumpToThen 0 1 ] 0
	equal [ nogotot::JumpToThen 1 0 ] 10
	equal [ nogotot::JumpToThen 1 1 ] 10
}




tproc noggen_test {} {
	set db nogoto-db

if { 0 } {
}

	nogoto::create_db $db
	nogoto::insert_node $db 9 action {}
	equal [nogoto::generate $db 9] {seq 9}
	
	nogoto::create_db $db
	nogoto::insert_node $db 9 action {}
	nogoto::insert_node $db 10 action {}
		nogoto::insert_link $db 9 0 10 normal
	nogoto::insert_node $db 11 action {}
		nogoto::insert_link $db 10 0 11 normal
	equal [nogoto::generate $db 9] {seq 9 10 11}


	#     9
	# 10	  11
	#     12
	nogoto::create_db $db
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 action {}
	nogoto::insert_node $db 12 action {}
	
	nogoto::insert_link $db 9 0 10 normal
	nogoto::insert_link $db 9 1 11 normal
	nogoto::insert_link $db 10 0 12 normal
	nogoto::insert_link $db 11 0 12 normal
	
	equal [nogoto::generate $db 9] {seq {if 9 {seq 10} {seq 11}} 12}

	#     9
	# 10	  |
	#     12
	nogoto::create_db $db
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 12 action {}
	
	nogoto::insert_link $db 9 0 10 normal
	nogoto::insert_link $db 9 1 12 normal
	nogoto::insert_link $db 10 0 12 normal
	
	equal [nogoto::generate $db 9] {seq {if 9 {seq 10} seq} 12}

	#     9
	# |		  |
	#     12
	nogoto::create_db $db
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 12 action {}
	
	nogoto::insert_link $db 9 0 12 normal
	nogoto::insert_link $db 9 1 12 normal
	
	equal [nogoto::generate $db 9] {seq {if 9 seq seq} 12}

	#	  8
	#     9
	# 10	  11
	#     12
	#     13
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 action {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 13 action {}
	
	nogoto::insert_link $db 8 0 9 normal
	nogoto::insert_link $db 9 0 10 normal
	nogoto::insert_link $db 9 1 11 normal
	nogoto::insert_link $db 10 0 12 normal
	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 12 0 13 normal
	
	equal [nogoto::generate $db 8] {seq 8 {if 9 {seq 10} {seq 11}} 12 13}
	
	# 9
	# 10-----
	# |		11---
	# 12	13	14
	# |		-----
	# |		15
	# -------
	# 16
	
	nogoto::create_db $db
	nogoto::insert_node $db 9 action {}
	nogoto::insert_node $db 10 if {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 14 action {}
	nogoto::insert_node $db 15 action {}
	nogoto::insert_node $db 16 action {}
	
	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db 10 0 12 normal
	nogoto::insert_link $db 10 1 11 normal
	nogoto::insert_link $db 12 0 16 normal
	nogoto::insert_link $db 11 0 13 normal
	nogoto::insert_link $db 13 0 15 normal
	nogoto::insert_link $db 15 0 16 normal
	nogoto::insert_link $db 11 1 14 normal
	nogoto::insert_link $db 14 0 15 normal
	equal [nogoto::generate $db 9] {seq 9 {if 10 {seq 12} {seq {if 11 {seq 13} {seq 14}} 15}} 16}
	
	# 9
	# |
	# 10---------
	# |			|
	# 12---		11---
	# |	  |		|	|
	# 17  18	13	14
	# |	  |		|	|	
	# |----		-----
	# |			|
	# -----------
	# |
	# 16
	
	nogoto::create_db $db
	nogoto::insert_node $db 9 action {}
	nogoto::insert_node $db 10 if {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 if {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 14 action {}
	nogoto::insert_node $db 16 action {}
	nogoto::insert_node $db 17 action {}
	nogoto::insert_node $db 18 action {}
	
	nogoto::insert_link $db  9 0 10 normal
	
	nogoto::insert_link $db 10 0 12 normal
	nogoto::insert_link $db 10 1 11 normal
	
	nogoto::insert_link $db 12 0 17 normal
	nogoto::insert_link $db 12 1 18 normal
	nogoto::insert_link $db 17 0 16 normal
	nogoto::insert_link $db 18 0 16 normal
	
	nogoto::insert_link $db 11 0 13 normal
	nogoto::insert_link $db 11 1 14 normal	
	nogoto::insert_link $db 13 0 16 normal
	nogoto::insert_link $db 14 0 16 normal
	
	equal [nogoto::generate $db 9] {seq 9 {if 10 {seq {if 12 {seq 17} {seq 18}}} {seq {if 11 {seq 13} {seq 14}}}} 16}
	
	
	# 9----
	# |	   |
	# 10---|
	# |	   |	
	# 11---|
	# |	   |	
	# 12   13
	# |	   |	
	# ------
	# |	
	# 14
	
	nogoto::create_db $db
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 if {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 14 action {}
	
	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db  9 1 13 normal

	nogoto::insert_link $db 10 0 11 normal
	nogoto::insert_link $db 10 1 13 normal

	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 11 1 13 normal

	nogoto::insert_link $db 12 0 14 normal
	nogoto::insert_link $db 13 0 14 normal
	
	equal [nogoto::generate $db 9] {seq {if 9 {seq {if 10 {seq {if 11 {seq 12} {seq 13}}} {seq 13}}} {seq 13}} 14}


	# 9---------
	# |	   		|
	# 10---|	|
	# |	   |	|
	# 11---|	|
	# |	   |	|
	# 12   13	|
	# |	   |	|	
	# ----------
	# |	
	# 14
	
	nogoto::create_db $db
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 if {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 14 action {}
	
	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db  9 1 14 normal

	nogoto::insert_link $db 10 0 11 normal
	nogoto::insert_link $db 10 1 13 normal

	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 11 1 13 normal

	nogoto::insert_link $db 12 0 14 normal
	nogoto::insert_link $db 13 0 14 normal
	
	
	equal [nogoto::generate $db 9] {seq {if 9 {seq {if 10 {seq {if 11 {seq 12} {seq 13}}} {seq 13}}} seq} 14}


	
	# 9-----
	# |     |
	# 10	11---
	# |     |	 |
	# |-----	 |
	# 12		 13
	# |			 |
	# |----------
	# 14
	
	nogoto::create_db $db
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 14 action {}
	
	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db  9 1 11 normal
	
	nogoto::insert_link $db 10 0 12 normal
	nogoto::insert_link $db 12 0 14 normal
	
	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 11 1 13 normal
	
	nogoto::insert_link $db 13 0 14 normal
	
	equal [nogoto::generate $db 9] {seq {if 9 {seq 10 12} {seq {if 11 {seq 12} {seq 13}}}} 14}

	# 9---------
	# |			|
	# 10----	|
	# |		|	|
	# |		11--
	# |		|	|
	# 14	 ---12
	# |			|
	# |---------
	# |
	# 13
	
	nogoto::create_db $db
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 if {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 14 action {}

	
	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db  9 1 12 normal
	
	nogoto::insert_link $db 10 0 14 normal
	nogoto::insert_link $db 10 1 11 normal

	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 11 1 12 normal
	
	nogoto::insert_link $db 14 0 13 normal
	nogoto::insert_link $db 12 0 13 normal
	
	equal [nogoto::generate $db 9] {seq {if 9 {seq {if 10 {seq 14} {seq {if 11 seq seq} 12}}} {seq 12}} 13}



	# |
	# 9-----
	# |		|
	# |		|		
	# |		16--
	# 13----|	|	
	# |		17  18	
	# |		|	|	
	# |		|---	
	# |		|		
	# |		|		
	# |		|			
	# |		12
	# |		|	
	# |-----		
	# |				
	# 15			

	nogoto::create_db $db

	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 13 if {}
	nogoto::insert_node $db 16 if {}
	nogoto::insert_node $db 17 action {}
	nogoto::insert_node $db 18 action {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 15 action {}

	nogoto::insert_link $db  9 0 13 normal
	nogoto::insert_link $db  9 1 16 normal
	
	nogoto::insert_link $db 13 0 15 normal
	nogoto::insert_link $db 13 1 17 normal

	nogoto::insert_link $db 16 0 17 normal
	nogoto::insert_link $db 16 1 18 normal
	
	nogoto::insert_link $db 17 0 12 normal
	nogoto::insert_link $db 18 0 12 normal
	nogoto::insert_link $db 12 0 15 normal


	equal [ nogoto::generate $db 9 ] {seq {if 9 {seq {if 13 seq {seq 17 12}}} {seq {if 16 {seq 17} {seq 18}} 12}} 15}


	# |
	# 9-----
	# |		|
	# 10	11-- 	
	# |		|	|	
	# |-----	|	
	# |			|	
	# 12----	|		
	# |		|	|		
	# |		13	|
	# |		|	|
	# |-----	|	
	# |			|	
	# 14		|
	# |			|
	# |---------
	# 15

	nogoto::create_db $db

	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 if {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 14 action {}
	nogoto::insert_node $db 15 action {}

	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db  9 1 11 normal
	
	nogoto::insert_link $db 10 0 12 normal
	
	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 11 1 15 normal

	nogoto::insert_link $db 12 0 14 normal
	nogoto::insert_link $db 12 1 13 normal
	
	nogoto::insert_link $db 13 0 14 normal
	nogoto::insert_link $db 14 0 15 normal

	equal [ nogoto::generate $db 9 ] {seq {if 9 {seq 10 {if 12 seq {seq 13}} 14} {seq {if 11 {seq {if 12 seq {seq 13}} 14} seq}}} 15}



	# 8
	# |
	# |<----
	# |		|
	# 9-----
	# |
	# 10
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}

	nogoto::insert_link $db  8 0 9 normal
	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db  9 1 9 normal
	

	equal [ nogoto::generate $db 8 ] {seq 8 {loop {if 9 {seq break} seq}} 10}


	# 260
	# |	 
	# 262--- 
	# |		|
	# |		|<------
	# |		| 		|
	# |		263-	|
	# |		|	|	|
	# |-----	264	|
	# |			|	|
	# |			----
	# 259
	# |
	# 256
	nogoto::create_db $db
	nogoto::insert_node $db 260 action {}
	nogoto::insert_node $db 262 if {}
	nogoto::insert_node $db 263 if {}
	nogoto::insert_node $db 264 action {}
	nogoto::insert_node $db 259 action {}
	


	nogoto::insert_link $db  260	0	262	normal
	nogoto::insert_link $db  262	0	263	normal
	nogoto::insert_link $db  263	0	259	normal
	nogoto::insert_link $db  263	1	264	normal
	nogoto::insert_link $db  264	0	263	normal
	nogoto::insert_link $db  262	1	259	normal

	nogoto::insert_node $db 256 action {}		
	nogoto::insert_link $db  259	0	256	normal
		

	equal [ nogoto::generate $db 260 ] {seq 260 {if 262 {seq {loop {if 263 {seq break} seq} 264}} seq} 259 256}


	# 8
	# |
	# |<---------
	# |			|
	# |			|
	# 9-----	|
	# |		|	|
	# |		|	|
	# |		|	|	
	# |		11--
	# |		|
	# |		|	
	# |-----
	# |
	# 14
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 14 action {}

	nogoto::insert_link $db  8 0  9 normal
#	nogoto::insert_link $db 10 0  9 normal
	
	nogoto::insert_link $db  9 0 14 normal
	nogoto::insert_link $db  9 1 11 normal	
	
#	nogoto::insert_link $db 12 0 11 normal


	nogoto::insert_link $db 11 0 14 normal
	nogoto::insert_link $db 11 1  9 normal

	equal [ nogoto::generate $db 8 ] {seq 8 {loop {if 9 {seq break} seq} {if 11 {seq break} seq}} 14}


	# 179
	# |
	# |<------------
	# |				|
	# |				|	
	# 1802---		|
	# |		|		|
	# |		1804	|	
	# |		184-	| x
	# |		|	|	|
	# |		|	182	|
	# |-----	|	|
	# |			 ---
	# 183
	
	nogoto::create_db $db
	nogoto::insert_node $db 179 action {}	
	nogoto::insert_node $db 1800002 if {}	
	nogoto::insert_node $db 183 action {}	
	nogoto::insert_node $db 1800004 action {}	
	nogoto::insert_node $db 184 if {}	
	nogoto::insert_node $db 182 action {}
	
	nogoto::insert_link $db 179 0 1800002 normal
	nogoto::insert_link $db 1800002 0 183 normal
	nogoto::insert_link $db 1800002 1 1800004 normal
	nogoto::insert_link $db 1800004 0 184 normal
	nogoto::insert_link $db 184 0 182 normal
	nogoto::insert_link $db 184 1 183 normal
	nogoto::insert_link $db 182 0 1800002 normal
	
	equal [ nogoto::generate $db 179 ] {seq 179 {loop {if 1800002 {seq break} seq} 1800004 {if 184 seq {seq break}} 182} 183}

	# 190
	# |
	# |<---------
	# |			|
	# 196		|
	# |			|	
	# 191---	|
	# |		|	|
	# |		195	|
	# |		|	|	
	# |		198-
	# |		|
	# |		|	
	# |-----
	# |
	# 193
	# |

	
	
	
	nogoto::create_db $db
	nogoto::insert_node $db 190	action	{}
	nogoto::insert_node $db 191	if	{}
	nogoto::insert_node $db 193	action	{}
	nogoto::insert_node $db 195	action	{}
	nogoto::insert_node $db 196	action	{}
	nogoto::insert_node $db 198	if	{}
	
	nogoto::insert_link $db 190	0	196	normal
	nogoto::insert_link $db 196	0	191	normal
	nogoto::insert_link $db 191	0	193	normal
	nogoto::insert_link $db 191	1	195	normal
	nogoto::insert_link $db 195	0	198	normal
	nogoto::insert_link $db 198	0	193	normal
	nogoto::insert_link $db 198	1	196	normal
	


	equal [ nogoto::generate $db 190 ] {seq 190 {loop 196 {if 191 {seq break} seq} 195 {if 198 {seq break} seq}} 193}


	# 260
	# |
	# |   
	# |	 
	# 262--- 
	# |		|
	# |		|<----------
	# |		| 			|
	# |		|			|
	# |		263-		|
	# |		|	|		|
	# |-----	264-	|
	# |			|	|	|
	# |			270	271	|
	# |			|	|	|
	# |			|---	|
	# |			|		|
	# |			--------
	# |
	# 259
	# |
	# 256
	nogoto::create_db $db
	nogoto::insert_node $db 260 action {}
	nogoto::insert_node $db 262 if {}
	nogoto::insert_node $db 263 if {}
	nogoto::insert_node $db 259 action {}
	
	nogoto::insert_node $db 264 if {}
	nogoto::insert_node $db 270 action {}
	nogoto::insert_node $db 271 action {}
	


	nogoto::insert_link $db  260	0	262	normal
	nogoto::insert_link $db  262	0	263	normal
	nogoto::insert_link $db  263	0	259	normal
	nogoto::insert_link $db  263	1	264	normal
	nogoto::insert_link $db  262	1	259	normal

	nogoto::insert_link $db  264	0	270	normal
	nogoto::insert_link $db  264	1	271	normal
	nogoto::insert_link $db  270	0	263	normal
	nogoto::insert_link $db  271	0	263	normal
	
	

	nogoto::insert_node $db 256 action {}		
	nogoto::insert_link $db  259	0	256	normal

	equal [ nogoto::generate $db 260 ] {seq 260 {if 262 {seq {loop {if 263 {seq break} seq} {if 264 {seq 270} {seq 271}}}} seq} 259 256}


	# 260
	# |
	# |   
	# |	 
	# 262--- 
	# |		|
	# |		|<----------
	# |		| 			|
	# |		|			|
	# |		263-		|
	# |		|	|		|
	# |-----	264-	|
	# |			|	|	|
	# |			270	271	|
	# |			|	|	|
	# |			|---	|
	# |			272		|
	# |			|		|
	# |			--------
	# |
	# 259
	# |
	# 256
	nogoto::create_db $db
	nogoto::insert_node $db 260 action {}
	nogoto::insert_node $db 262 if {}
	nogoto::insert_node $db 263 if {}
	nogoto::insert_node $db 259 action {}
	
	nogoto::insert_node $db 264 if {}
	nogoto::insert_node $db 270 action {}
	nogoto::insert_node $db 271 action {}
	nogoto::insert_node $db 272 action {}
	


	nogoto::insert_link $db  260	0	262	normal
	nogoto::insert_link $db  262	0	263	normal
	nogoto::insert_link $db  263	0	259	normal
	nogoto::insert_link $db  263	1	264	normal
	nogoto::insert_link $db  272	0	263	normal
	nogoto::insert_link $db  262	1	259	normal

	nogoto::insert_link $db  264	0	270	normal
	nogoto::insert_link $db  264	1	271	normal
	nogoto::insert_link $db  270	0	272	normal
	nogoto::insert_link $db  271	0	272	normal
	
	

	nogoto::insert_node $db 256 action {}		
	nogoto::insert_link $db  259	0	256	normal
	
	equal [ nogoto::generate $db 260 ] {seq 260 {if 262 {seq {loop {if 263 {seq break} seq} {if 264 {seq 270} {seq 271}} 272}} seq} 259 256}


	
	# 8
	# |
	# |<---------
	# |			|
	# 10		|	
	# |			|
	# 9-----	|
	# |		|	|
	# |		11--
	# |		|
	# 13	12
	# |		|	
	# |-----
	# |
	# 14
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 14 action {}

	nogoto::insert_link $db  8 0 10 normal
	nogoto::insert_link $db 10 0  9 normal
	nogoto::insert_link $db  9 0 13 normal
	nogoto::insert_link $db 13 0 14 normal
	nogoto::insert_link $db  9 1 11 normal
	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 12 0 14 normal
	nogoto::insert_link $db 11 1 10 normal

	equal [ nogoto::generate $db 8 ] {seq 8 {loop 10 {if 9 {seq 13 break} seq} {if 11 {seq 12 break} seq}} 14}


	
	# 8
	# |
	# |<---------
	# |			|
	# 10		|	
	# |			|
	# 9-----	|
	# |		|	|
	# 15-	11--
	# |	 |	|   |
	# 13 16	12--
	# |	 |	|	
	# |-----
	# |
	# 14
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 12 if {}
	nogoto::insert_node $db 14 action {}
	nogoto::insert_node $db 15 if {}
	nogoto::insert_node $db 16 action {}

	nogoto::insert_link $db  8 0 10 normal
	nogoto::insert_link $db 10 0  9 normal
	nogoto::insert_link $db  9 0 15 normal
	nogoto::insert_link $db 13 0 14 normal
	nogoto::insert_link $db  9 1 11 normal
	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 12 0 14 normal
	nogoto::insert_link $db 11 1 10 normal
	
	nogoto::insert_link $db 15 0 13 normal
	nogoto::insert_link $db 15 1 16 normal
	nogoto::insert_link $db 16 0 14 normal
	nogoto::insert_link $db 12 1 10 normal

	equal [ nogoto::generate $db 8 ] {seq 8 {loop 10 {if 9 {seq {if 15 {seq 13} {seq 16}} break} seq} {if 11 {seq {if 12 {seq break} seq}} seq}} 14}


	# 8---------
	# |			|
	# |<----	|
	# |		|	|
	# 9-----	|
	# |---------
	# 10
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 if {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}

	nogoto::insert_link $db  8 0 9 normal
	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db  9 1 9 normal
	nogoto::insert_link $db  8 1 10 normal
	

	equal [ nogoto::generate $db 8 ] {seq {if 8 {seq {loop {if 9 {seq break} seq}}} seq} 10}	

	# |
	# 8-------------
	# |				|
	# |<---------	|
	# |			|	|
	# 10		|	|
	# |			|	|
	# 9-----	|	|
	# |		|	|	|
	# |		11--	|
	# |		|		|
	# 13	12		|
	# |		|		|
	# |-----		|
	# |-------------
	# |
	# 14
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 if {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 14 action {}

	nogoto::insert_link $db  8 0 10 normal
	nogoto::insert_link $db 10 0  9 normal
	nogoto::insert_link $db  9 0 13 normal
	nogoto::insert_link $db 13 0 14 normal
	nogoto::insert_link $db  9 1 11 normal
	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 12 0 14 normal
	nogoto::insert_link $db 11 1 10 normal
	nogoto::insert_link $db  8 1 14 normal

	equal [ nogoto::generate $db 8 ] {seq {if 8 {seq {loop 10 {if 9 {seq 13 break} seq} {if 11 {seq 12 break} seq}}} seq} 14}


	# 8
	# |
	# |<----------
	# |			  |
	# 9---------  |
	# |			| |
	# |<---		| |
	# |    |	| |
	# 10---		| |
	# |		  	| |
	# |---------  |
	# |			  |
	# 11----------
	# |
	# 12
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 if {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 action {}

	nogoto::insert_link $db  8 0  9 normal
	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db  9 1 11 normal
	nogoto::insert_link $db 10 0 11 normal
	nogoto::insert_link $db 10 1 10 normal
	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 11 1  9 normal
	


	equal [ nogoto::generate $db 8 ] {seq 8 {loop {if 9 {seq {loop {if 10 {seq break} seq}}} seq} {if 11 {seq break} seq}} 12}

	
	# |
	# 8-------------
	# |				|
	# |<---------	|
	# |			|	|
	# 10		|	|
	# |			|	|
	# 9-----	|	|
	# |		|	|	|
	# |		11--	|
	# |		|		|
	# 13----		|
	# |		|		|	
	# |		12		|
	# |		|		|
	# |-----		|
	# |				|
	# 15			|
	# |				|	
	# |-------------
	# |
	# 14
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 if {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 13 if {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 14 action {}
	nogoto::insert_node $db 15 action {}

	nogoto::insert_link $db  8 0 10 normal
	nogoto::insert_link $db 10 0  9 normal
	nogoto::insert_link $db  9 0 13 normal
	nogoto::insert_link $db 13 0 15 normal
	nogoto::insert_link $db 13 1 12 normal
	nogoto::insert_link $db 15 0 14 normal
	nogoto::insert_link $db  9 1 11 normal
	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 12 0 15 normal
	nogoto::insert_link $db 11 1 10 normal
	nogoto::insert_link $db  8 1 14 normal


	equal [ nogoto::generate $db 8 ] {seq {if 8 {seq {loop 10 {if 9 {seq {if 13 seq {seq 12}} break} seq} {if 11 {seq 12 break} seq}} 15} seq} 14}


	# |
	# 8
	# |
	# |<------------|
	# |				|
	# 10			|
	# |				|
	# 9-----		|
	# |		|		|
	# |		11------| x
	# |		|		
	# |		16--
	# |		|	|	
	# |		17  18	
	# |		|	|	
	# |		|---	
	# |		|		
	# 13----		
	# |		|			
	# |		12
	# |		|	
	# |-----		
	# |				
	# 15			
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 13 if {}
	nogoto::insert_node $db 15 action {}
	nogoto::insert_node $db 16 if {}
	nogoto::insert_node $db 17 action {}
	nogoto::insert_node $db 18 action {}

	nogoto::insert_link $db  8 0 10 normal
	nogoto::insert_link $db 10 0  9 normal
	nogoto::insert_link $db  9 0 13 normal
	nogoto::insert_link $db  9 1 11 normal
	
	nogoto::insert_link $db 13 0 15 normal
	nogoto::insert_link $db 13 1 12 normal

	nogoto::insert_link $db 11 1 16 normal
	nogoto::insert_link $db 11 0 10 normal
	
	nogoto::insert_link $db 16 0 17 normal
	nogoto::insert_link $db 16 1 18 normal
	nogoto::insert_link $db 17 0 12 normal
	nogoto::insert_link $db 18 0 12 normal
	
	nogoto::insert_link $db 12 0 15 normal


	equal [ nogoto::generate $db 8 ] {seq 8 {loop 10 {if 9 {seq {if 13 seq {seq 12}} break} seq} {if 11 seq {seq {if 16 {seq 17} {seq 18}} 12 break}}} 15}

	
	# |
	# 8
	# |
	# |<------------|
	# |				|
	# 10			|
	# |				|
	# 9-----		|
	# |		|		|
	# |		11------| x
	# |		|		
	# |		16--
	# 13----|	|	
	# |		17  18	
	# |		|	|	
	# |		|---	
	# |		|		
	# |		|		
	# |		|			
	# |		12
	# |		|	
	# |-----		
	# |				
	# 15			
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 13 if {}
	nogoto::insert_node $db 15 action {}
	nogoto::insert_node $db 16 if {}
	nogoto::insert_node $db 17 action {}
	nogoto::insert_node $db 18 action {}

	nogoto::insert_link $db  8 0 10 normal
	nogoto::insert_link $db 10 0  9 normal
	nogoto::insert_link $db  9 0 13 normal
	nogoto::insert_link $db  9 1 11 normal
	
	nogoto::insert_link $db 13 0 15 normal
	nogoto::insert_link $db 13 1 17 normal

	nogoto::insert_link $db 11 1 16 normal
	nogoto::insert_link $db 11 0 10 normal
	
	nogoto::insert_link $db 16 0 17 normal
	nogoto::insert_link $db 16 1 18 normal
	nogoto::insert_link $db 17 0 12 normal
	nogoto::insert_link $db 18 0 12 normal
	
	nogoto::insert_link $db 12 0 15 normal


	equal [ nogoto::generate $db 8 ] {seq 8 {loop 10 {if 9 {seq {if 13 seq {seq 17 12}} break} seq} {if 11 seq {seq {if 16 {seq 17} {seq 18}} 12 break}}} 15}


	# |
	# 8
	# |
	# |<------------|
	# |				|
	# 9-----		|
	# |		|		|
	# |		16--	|
	# |		|	|	|
	# |		|	18--|
	# |		|	|	|
	# |		|---	|	
	# |		|		|	
	# |		12------|
	# |		|	
	# |-----		
	# |				
	# 15			
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 12 if {}
	nogoto::insert_node $db 15 action {}

	nogoto::insert_node $db 16 if {}	
	nogoto::insert_node $db 18 if {}
	

	nogoto::insert_link $db  8 0  9 normal
	
	
	nogoto::insert_link $db  9 0 15 normal
	nogoto::insert_link $db  9 1 16 normal
	


	
	nogoto::insert_link $db 16 0 12 normal
	nogoto::insert_link $db 16 1 18 normal


	nogoto::insert_link $db 18 0 12 normal
	nogoto::insert_link $db 18 1  9 normal
	
	nogoto::insert_link $db 12 0 15 normal
	nogoto::insert_link $db 12 1  9 normal	

	equal [ nogoto::generate $db 8 ] {seq 8 {loop {if 9 {seq break} seq} {if 16 {seq {if 12 {seq break} seq}} {seq {if 18 {seq {if 12 {seq break} seq}} seq}}}} 15}


	



	# |
	# 8
	# |
	# |<------------|
	# |				|
	# 10			|
	# |				|
	# 9-----		|
	# |		|		|
	# |		11------|
	# |		|		|
	# |		16--	|
	# |		|	|	|
	# |		17	18--|
	# |		|	|	|
	# |		|---	|	
	# 13	|		|
	# |		|		|	
	# |		12------|
	# |		|	
	# |-----		
	# |				
	# 15			
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 if {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 15 action {}

	nogoto::insert_node $db 16 if {}
	nogoto::insert_node $db 17 action {}
	nogoto::insert_node $db 18 if {}
	

	nogoto::insert_link $db  8 0 10 normal
	nogoto::insert_link $db 10 0  9 normal
	
	nogoto::insert_link $db  9 0 13 normal
	nogoto::insert_link $db  9 1 11 normal
	
	nogoto::insert_link $db 13 0 15 normal


	nogoto::insert_link $db 11 0 16 normal
	nogoto::insert_link $db 11 1 10 normal
	
	nogoto::insert_link $db 16 0 17 normal
	nogoto::insert_link $db 16 1 18 normal
	
	nogoto::insert_link $db 17 0 12 normal
	nogoto::insert_link $db 18 0 12 normal
	nogoto::insert_link $db 18 1 10 normal
	
	nogoto::insert_link $db 12 0 15 normal
	nogoto::insert_link $db 12 1 10 normal

	equal [ nogoto::generate $db 8 ] {seq 8 {loop 10 {if 9 {seq 13 break} seq} {if 11 {seq {if 16 {seq 17 {if 12 {seq break} seq}} {seq {if 18 {seq {if 12 {seq break} seq}} seq}}}} seq}} 15}


	# |
	# 8
	# |
	# |<------------|
	# |				|
	# 9				|
	# |				|
	# |<----		|
	# |		|		|
	# 10	|		|
	# |		|		|
	# 11----		|
	# |				|
	# 12			|
	# |				|
	# 13------------|
	# |	
	# |
	# |
	# 14
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 action {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 13 if {}
	nogoto::insert_node $db 14 action {}
	

	nogoto::insert_link $db  8 0  9 normal
	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db 10 0 11 normal
	
	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 11 1 10 normal

	nogoto::insert_link $db 12 0 13 normal
	
	nogoto::insert_link $db 13 0 14 normal	
	nogoto::insert_link $db 13 1  9 normal
	

	equal [ nogoto::generate $db 8 ] {seq 8 {loop 9 {loop 10 {if 11 {seq break} seq}} 12 {if 13 {seq break} seq}} 14}	

	# |
	# 8
	# |
	# |<--------------------
	# |						|
	# 9-----				|
	# |		|				|
	# |		10				|
	# |		|				|
	# |		|<----------	|
	# |		|			|	|
	# |		11------	|	|
	# |		|		|	|	|
	# |		|		12	|	|
	# |		|		|	|	|
	# |		|		 ---	|
	# |		 ---------------
	# |
	# 13
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}	
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}	
	nogoto::insert_node $db 11 if {}	
	nogoto::insert_node $db 12 action {}	
	nogoto::insert_node $db 13 action {}
	
	nogoto::insert_link $db  8 0  9 normal
	nogoto::insert_link $db  9 0 13 normal
	nogoto::insert_link $db  9 1 10 normal
	nogoto::insert_link $db 10 0 11 normal
	nogoto::insert_link $db 11 0  9 normal
	nogoto::insert_link $db 11 1 12 normal
	nogoto::insert_link $db 12 0 11 normal
	
	equal [ nogoto::generate $db 8 ] {seq 8 {loop {if 9 {seq break} seq} 10 {loop {if 11 {seq break} seq} 12}} 13}

	# |
	# 8
	# |
	# |<--------------------
	# |						|
	# 9-----				|
	# |		|				|
	# |		10				|
	# |		|				|
	# |		11----------	|	
	# |		|			|	|
	# |		12------	|	|
	# |		|		|	|	|
	# |		|		13	|	|
	# |		|		|	|	|
	# |		|		 ---	|
	# |		|			|	|
	# |		|			14	|
	# |		|			|	|	
	# |-----			----
	# |
	# 15
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}	
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}	
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 if {}	
	nogoto::insert_node $db 13 action {}	
	nogoto::insert_node $db 14 action {}	
	nogoto::insert_node $db 15 action {}
	
	nogoto::insert_link $db  8 0  9 normal
	nogoto::insert_link $db  9 0 15 normal
	nogoto::insert_link $db  9 1 10 normal
	nogoto::insert_link $db 10 0 11 normal
	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 11 1 14 normal
	nogoto::insert_link $db 12 0 15 normal
	nogoto::insert_link $db 12 1 13 normal
	nogoto::insert_link $db 13 0 14 normal
	nogoto::insert_link $db 14 0  9 normal
	equal [ nogoto::generate $db 8 ] {seq 8 {loop {if 9 {seq break} seq} 10 {if 11 {seq {if 12 {seq break} seq} 13} seq} 14} 15}
}



proc print_nodes { db } {

	$db eval {
		select *
		from nodes
		order by item_id
	} {
		puts "$item_id:\toutgoing: $outgoing,\tincount: $incount\tstacks: $stacks"
	}
}
