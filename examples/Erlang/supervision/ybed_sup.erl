-module(ybed_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() -> supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init(_) ->
    RestartStrategy = {one_for_all, 0, 1},
    Children = [
       {ybed, {ybed, start_link, []}, permanent, 5000, worker, [ybed]}
    ],
    {ok, {RestartStrategy, Children}}.

