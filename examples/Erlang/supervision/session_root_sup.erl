-module(session_root_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() -> supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init(_) ->
    RestartStrategy = {one_for_all, 5, 3600},
    Children = [
       {session_sup, {session_sup, start_link, []}, permanent, 5000, supervisor, [session_sup]},
       {session_store, {session_store, start_link, []}, permanent, 2000, worker, [session_store]},
       {foobar_sup, {foobar_sup, start_link, []}, permanent, 5555, supervisor, [foobar_sup]}
    ],
    {ok, {RestartStrategy, Children}}.

