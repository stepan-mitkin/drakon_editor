-module(fsm_demo).
-export([run/0]).

run() ->
	standalone(),
	fsm_based()
.


standalone() ->
	io:fwrite("~n~n", []),
	io:fwrite("standalone state machine test~n", []),
	io:fwrite("=============================~n", []),	
	Text = "var foo = bar.SomeMethod2(n + 10/x, c >= 10);",
	Tokens = lexer:lex(Text),
	
	io:fwrite("Text: ~s~n", [Text]),
	io:fwrite("Tokens:~n", []),
	lists:foreach(
		fun(Item) ->
			{Type, TText} = Item,
			io:fwrite("~w - ~s~n", [Type, TText])
			end,
		Tokens)
.



fsm_based() ->
	io:fwrite("~n~n", []),
	io:fwrite("gen_fsm state machine test~n", []),
	io:fwrite("==========================~n", []),	
	{ok, Door} = code_door:create("abc"),
	
	io:fwrite("~nTyping the code...~n", []),
	timer:sleep(1000),	
	code_door:key(Door, "a"),
	timer:sleep(1000),
	code_door:key(Door, "b"),
	timer:sleep(1000),
	code_door:key(Door, "c"),
	timer:sleep(1000),
	io:fwrite("Waiting, doing nothing...~n", []),		
	timer:sleep(10000),


	io:fwrite("~nTyping the code once more...~n", []),	
	timer:sleep(1000),	
	code_door:key(Door, "a"),
	timer:sleep(1000),
	code_door:key(Door, "b"),	
	timer:sleep(1000),
	io:fwrite("Waiting too long...~n", []),	
	timer:sleep(6000),
	
	io:fwrite("~nTyping the code again...~n", []),	
	timer:sleep(1000),	
	code_door:key(Door, "a"),
	timer:sleep(1000),
	code_door:cancel(Door),
	timer:sleep(1000),
	
	code_door:stop(Door),
	
	"Done!"
.
