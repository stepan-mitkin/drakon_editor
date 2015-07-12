-module(de_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() -> supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init(_) ->
    RestartStrategy = {one_for_one, 10, 3600},
    Children = [
       {events, {events, start_link, []}, permanent, 2000, worker, [events]},
       {session_root_sup, {session_root_sup, start_link, []}, permanent, 5000, supervisor, [session_root_sup]},
       {ybed_sup, {ybed_sup, start_link, []}, permanent, 5000, supervisor, [ybed_sup]},
       {de_server, {de_server, start_link, []}, permanent, 2000, worker, [de_server]}
    ],
    {ok, {RestartStrategy, Children}}.

