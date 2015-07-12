# How to generate a supervision tree in DRAKON Editor.

1. In DRAKON Editor, change the language to "Erlang". File / File properties... / Language: Erlang
2. Create one or more structure diagrams. Insert / New diagram... / Structure diagram
3. Icons of type "Entity" will be workers. Icons of type "Entity with fields" (with a horizontal line) will be supervisors.

Workers must be leaves (they should not have any children).
DRAKON Editor will generate .erl files for each supervisor except "empty" supervisors.
An "empty" supervisor has an empty bottom part.
"Empty" supervisors should not have children.

It is possible to have many supervision trees.

## Fields

### Supervisor

<name>
restart = temporary | transient | permanent
shutdown = infinity | brutal_kill | <milliseconds>
-------
strategy = one_for_one | one_for_all | rest_for_one | simple_one_for_one
max_restart = <0 or max number of restarts before giving up>
max_time = <1 or time to try in milliseconds before giving up>

Information above the horizontal line describes the supervisor itself.
Information below the line is related to the children.

Example

session_root_sup
restart  = permanent
shutdown = 5000
-----------------
strategy    = simple_one_for_one
max_restart = 0
max_time    = 1

The supervisor which is the root of a tree should have only its name in the upper part of the icon.

Example

mega_root_sup
-----------------
strategy    = simple_one_for_one
max_restart = 0
max_time    = 1


### Worker

<name>
restart = temporary | transient | permanent
shutdown = infinity | brutal_kill | <milliseconds>

Example

session_element
restart = temporary
shutdown = brutal_kill


DRAKON Editor will not generate source files for workers.
It is up to the developer to create worker modules.
A worker is expected to have a start_link/0 function.
