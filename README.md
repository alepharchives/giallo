Giallo
======

Giallo (Italian pronunciation: [ˈdʒallo], plural gialli) is an Italian
20th-century genre of literature and film, which in Italian indicates crime
fiction and mystery.

Goals
-----

Giallo aims to provide a small and flexible web framework. Giallo
builds on [Cowboy](https://github.com/extend/cowboy) and provides a bare
minimum to implement a basic View-Controller pattern. Yes we've removed
the Model from MVC, this is not a "everything but the kitchen sink" type of
framework.

Giallo can be easily embedded and provides some conveinient methods for
working with Controller and Views while giving possibility to use
standard Cowboy features when necessary.

Getting Started
----

A minimal working app could look like this:

```erlang
-module(minimal_handler).

-export([start/0]).
-export([hi/4]).

start() ->
    giallo:start([{'_', [{"/[...]", minimal_handler, []}]}]).

hi(<<"GET">>, _PathInfo, _Extra, _Req) ->
	{output, <<"Ohai!">>}.

```

This would map the `my_handler` using standard Cowboy
[Routing](http://ninenines.eu/docs/en/cowboy/HEAD/guide/routing) to the
URI `http://yourserver/`. Implementing the action `hi` would make
Giallo output "Ohai!" when performing a GET on `/hi` or anything
below `/hi/extra...`., while outputting `OhNo!` when performing a GET on
anything else. Any action that is implemented explicitly, such as `hi/3`
gets precedence over the standard Cowboy Handler.


The first argument is the HTTP method being used.

The `_PathInfo` argument contains any extra url fragments as binaries in a
list such as `/hi/extra/path/information` would give a list like
`[<<"extra">>, <<"path">>, <<"information">>]`. The exact match, i.e.
`/hi` would result in an empty list, `[]`.

The third argument contains any extra variables that either get passed
from the cowboy dispatcher or via an other action redispatching using
`render_other`.

The `Req` argument is the standard Cowboy [Request]
(https://github.com/extend/cowboy/blob/master/src/cowboy_req.erl#L128) Object.
It's an opaque record so take a look at the functions in
[cowboy_req.erl]
(https://github.com/extend/cowboy/blob/master/src/cowboy_req.erl) on how
to use it.

It's also possible to use standard Cowboy handlers and also to mix the
two behaviors, i.e.

```erlang
-module(default_handler).

-export([start/0]).
-export([hi/4]).

%% Standard Cowboy callback handlers
-export([init/3]).
-export([handle/2]).
-export([terminate/3]).


start() ->
    giallo:start([{'_', [{"/[...]", default_handler, []}]}]).

%% Standard Cowboy callback handlers
init(_Transport, Req, []) ->
	{ok, Req, undefined}.

handle(Req, State) ->
	{ok, Req2} = cowboy_req:reply(200, [], <<"Hello World!">>, Req),
	{ok, Req2, State}.

terminate(_Reason, _Req, _State) ->
	ok.

%% Giallo handler
hi(<<"GET">>, _PathInfo, _Extra, _Req) ->
	{output, <<"Ohai!">>}.

```

This would output "Ohai!" for the same URI's as the previous example but
for anything else it would use the standard Cowboy `handle/2` function.
So any Giallo function takes precedence over Cowboy handlers.

Index action
------------

`index_/4` is a special action that can be implemented and will handle
resource listings, i.e. `http://my.server/path/`. Any handler mapped to
`/path/` will have it's `index_` function executed. `index_` functions
behave the same as any other function and can thus use templating, etc.

```erlang
index_(<<"GET">>, [], _Extra, _Req) ->
    {output, <<"Index listing">>}.

```

Templating
----------

Giallo uses [ErlyDTL](https://github.com/evanmiller/erlydtl) for
standard templating. To dispatch a request from a Giallo controller you
return `ok`, `{ok, Variables}` or `{ok, Variables, Headers}`. Giallo
will then render the template associated with that controller and
action. Giallo compounds the name as `<controller>_<action>`.

Giallo will also try and find a template for a action even though no
action in the controller exists. To remedy the need to implement
boilerplate actions that just exist to render a template you can skip
those altogether and just create the template using the same naming
scheme.

You control how you compile your ErlyDtl templates through rebar. Using
the `erlydtl_opts` directive you can specify where to find your
templates:

```erlang
{erlydtl_opts, [
    {doc_root, "templates"}, % Where to find your templates
    {source_ext, ".html"} % Extension on your uncomplied templates
]}.

```

Session Management
------------------

If you need Session Management you'll have to include the [Giallo
Session Backend](https://github.com/kivra/giallo_session).

_before function
----------------

There's a special function which can be implemented called before_/2
which can be used to preprocess any request before dispatching to any
action. This is especially useful when implementing an authentication
scheme.

The function header looks like:

```erlang
before_(_Action, _Req) ->
    {ok, []}.

```

The first parameter is the Action that is to be performed after
`before_` has been complete. The second parameter is the standard Req
object.

Possible return values are:

* {ok, Extra}: Extra will get passed as the third argument to the action
  and as a variable called `before_` to the templates
* {redirect, Location}: Redirect to the `Location` effectively bypassing
  the Action

Return values
-------------

Here's a list of possible return values from a Giallo controller:

* ok: Continue and render the template for the corresponding action
* {ok, Variables::proplist()}: Same as above but pass in `Variables` to
  the template
* {ok, Variables::proplist(), Headers::proplist()}: Same as above but
  also set additional HTTP Headers
* {redirect, Location::binary() | proplist()}: Send a 302 redirect to the `Location`
* {redirect, Location, Headers::proplist()}: Same as above but also set
  additional HTTP Headers
* {moved, Location::binary() | proplist()}: Send a 301 redirect to the `Location`
* {moved, Location::binary() | proplist(), Headers::proplist()}: Same as above but also set
  additional HTTP Headers
* {render_other, OtherLocationbinary() | ::proplist()}: Render the action and/or
  view from `Location`. Possible values for `Location` are
`[{action, your_action}, {controller, your_handler}]` or a binary
absolute Url
* {render_other, Location::binary() | ::proplist(), Variables::proplist()}: Same
  as above but pass `Variables` that can be retrieved from the `Extra`
  argument
* {output, Output::binary()}: print out the `Output`
* {output, Output::binary(), Headers::proplist()}: Same as above but
  also set additional HTTP Headers
* {json, Data::proplist()}: Encode the `Data` as json and output
* {json, Data::proplist(), Headers::proplist()}: Same as above but
  also set additional HTTP Headers
* {jsonp, Callback::string(), Data::proplist()}: Encode the `Data` as
  valid jsonp using the `Callback`
* {jsonp, Callback::string(), Data::proplist(), Headers::proplist()}: Same as above but
  also set additional HTTP Headers
* not_found: Respond with a 404
* {error, Status::integer()}: Respond with the given error Status Code

## License
It's the [MIT license](http://en.wikipedia.org/wiki/MIT_License). So go ahead
and do what you want!
