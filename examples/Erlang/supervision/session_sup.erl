-module(session_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() -> supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init(_) ->
    RestartStrategy = {simple_one_for_one, 0, 1},
    Children = [
       {session_element, {session_element, start_link, []}, temporary, brutal_kill, worker, [session_element]}
    ],
    {ok, {RestartStrategy, Children}}.

