%% ----------------------------------------------------------------------------
%%
%% giallo: A small and flexible web framework
%%
%% Copyright (c) 2013 KIVRA
%%
%% Permission is hereby granted, free of charge, to any person obtaining a
%% copy of this software and associated documentation files (the "Software"),
%% to deal in the Software without restriction, including without limitation
%% the rights to use, copy, modify, merge, publish, distribute, sublicense,
%% and/or sell copies of the Software, and to permit persons to whom the
%% Software is furnished to do so, subject to the following conditions:
%%
%% The above copyright notice and this permission notice shall be included in
%% all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
%% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
%% DEALINGS IN THE SOFTWARE.
%%
%% ----------------------------------------------------------------------------

-module(giallo_util).

-export([do_or_else/2]).
-export([do_or_error/6]).

%% API ------------------------------------------------------------------------

do_or_else(F, E) ->
	try F()
	catch Class:Reason ->
			E({exception, Class, Reason, erlang:get_stacktrace()})
	end.

do_or_error(Fun, Req, Handler, Action, Arity, Env) ->
    try Fun()
    catch Class:Reason ->
            error_logger:error_msg(
            "** Giallo handler ~p terminating in ~p/~p~n"
            "   for the reason ~p:~p~n"
            "** Handler state was ~p~n"
            "** Request was ~p~n"
            "** Stacktrace: ~p~n~n",
            [Handler, Action, Arity, Class, Reason, Env,
                cowboy_req:to_list(Req), erlang:get_stacktrace()]),
            {error, 500}
    end.
