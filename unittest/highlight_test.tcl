tproc hl_to_tokens_test { } {

	set actual [ hl::to_tokens "foo bar + \(2.4 - mo12.bar / \(0xaf* Ministers\)\)" ]
	
	set expected {{token foo} {space { }} {token bar} {space { }} {op +} {space { }} 
		{op (} {number 2} {op .} {number 4} {space { }} {op -} {space { }}
		{token mo12} {op .} {token bar} {space { }} {op /} {space { }} {op (}
		{number 0xaf} {op *} {space { }} {token Ministers} {op )} {op )}
	}
	list_equal $actual $expected

}