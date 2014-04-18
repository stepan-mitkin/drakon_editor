DRAKON-Erlang state machine demo
================================

DRAKON Editor can generate state machines for Erlang.

There are 2 kinds of generated state machines:

1. gen_fsm-based behaviour.
The generated state machine will live in a separate process.
Benefits:
- The machine can be a full member of the supervision tree, enjoying all benefits of OTP.
- Timeouts can be used.
- Process dictionary can be used.

2. Standalone state machine.
The generated state machine will be just a tuple in the memory.
Benefits:
- Very lightweight.
- No need to think about termination.

code_door.drn contains an gen_fsm-based state machine.
lexer.drn contains a standalone state machine.

How to run
----------
1. Start Erlang from the current directory:
	erl
2. In the Erlang window, compile the gen_fsm state machine:
	c(code_door).
Don't worry about the warnings. They come from unimplemented behaviour methods.
You can implement them, if you want.
3. Compile the standalone state machine:
	c(lexer).
4. Compile the launcher:
	c(fsm_demo).
5. Run the demo:
	fsm_demo:run().
	