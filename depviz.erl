#!/usr/env/escript

-module(depviz).
-export([main/1]).

main([Directory, Output]) ->
    io:format("Looking into ~p~n", [Directory]),
    AppsDeps = filelib:wildcard(Directory ++ "/apps/*/"),
    AA = [extract_deps(AD) || AD <- AppsDeps],

    DepsDeps = filelib:wildcard(Directory ++ "/deps/*/"),
    DD = [extract_deps(D) || D <- DepsDeps],

    file:write_file(Output++".dot", graphviz(AA ++ DD)),
    io:format("~s", [os:cmd("dot "++Output++".dot -Tpng -o "++Output++".png")]).

extract_deps(Dir) ->
    AppName = lists:last(string:tokens(Dir, "/")),
    Dependecies = case file:consult(Dir ++ "/rebar.config") of
        {ok, RebarConfig} ->
            Deps = proplists:get_value(deps, RebarConfig, []),
            [{Name, Version} || {Name, _, {_, _, Version}} <- Deps];
        {error, _} ->
            []
                  end,
    {list_to_atom(AppName), Dependecies}.

graphviz(Deps) ->
    ["digraph G { ",
     "ratio=1.0;",
     [draw_single_deps(Dep) || Dep <- Deps],
     "}"].

draw_single_deps({Name, Deps}) ->
    [io_lib:format("~p->~p [label=\"~p\"];~n", [Name, DepName, prepare_version(Version)]) ||
     {DepName, Version} <- Deps].

prepare_version({tag, Version}) when is_list(Version) ->
    {tag, list_to_atom(Version)};
prepare_version({branch, Name}) when is_list(Name) ->
    {branch, list_to_atom(Name)};
prepare_version(Other) when is_list(Other) ->
    list_to_atom(Other).
