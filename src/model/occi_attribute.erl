%%% @author Jean Parpaillon <jean.parpaillon@free.fr>
%%% @copyright (C) 2013, Jean Parpaillon
%%% 
%%% This file is provided to you under the Apache License,
%%% Version 2.0 (the "License"); you may not use this file
%%% except in compliance with the License.  You may obtain
%%% a copy of the License at
%%% 
%%%   http://www.apache.org/licenses/LICENSE-2.0
%%% 
%%% Unless required by applicable law or agreed to in writing,
%%% software distributed under the License is distributed on an
%%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%%% KIND, either express or implied.  See the License for the
%%% specific language governing permissions and limitations
%%% under the License.
%%% 
%%% @doc
%%%
%%% @end
%%% Created : 19 Aug 2013 by Jean Parpaillon <jean.parpaillon@free.fr>
-module(occi_attribute).
-compile([{parse_transform, lager_transform}]).

-include("occi.hrl").

-export([new/1,
	 get_id/1,
	 get_type_id/1,
	 set_type_id/2,
	 is_required/1,
	 set_required/2,
	 get_occur/1,
	 set_occur/3,
	 is_immutable/1,
	 set_immutable/2,
	 get_default/1,
	 set_default/2,
	 set_value/2,
	 add_value/2,
	 get_value/1,
	 set_title/2,
	 get_title/1,
	 is_scalar/1,
	 check/1]).

-export([reset/1]).

-define(attr_default, [{immutable, false},
		       {minOccurs, 0},
		       {maxOccurs, 1},
		       {default, undefined}]).

new(Id) when is_binary(Id) ->
    new(list_to_atom(binary_to_list(Id)));
new(Id) ->
    #occi_attr{id=Id, properties=dict:from_list(?attr_default)}.

get_id(A) ->
    A#occi_attr.id.

get_type_id(#occi_attr{type_id=Name}) ->
    Name.

set_type_id(A, Id) ->
    A#occi_attr{type_id=Id}.

is_required(A) ->
    dict:fetch(minOccurs, A#occi_attr.properties) > 0.

set_required(A, true) ->
    case get_occur(A) of
	{Min, _Max} when Min > 0 ->
	    A;
	{_Min, _Max} ->
	    A#occi_attr{properties=dict:store(minOccurs, 1, A#occi_attr.properties)}
	end;
set_required(A, false) ->
    A#occi_attr{properties=dict:store(minOccurs, 0, A#occi_attr.properties)}.

get_occur(#occi_attr{properties=Props}) ->
    {dict:fetch(minOccurs, Props), dict:fetch(maxOccurs, Props)}.

set_occur(#occi_attr{properties=Props}=A, Min, Max) ->
    Props2 = dict:store(minOccurs, Min, Props),
    Props3 = dict:store(maxOccurs, Max, Props2),
    Scalar = if 
		 Max > 1 -> false;
		 true -> true
	     end,		     
    A#occi_attr{properties=Props3, scalar=Scalar}.

is_immutable(A) ->
    dict:fetch(immutable, A#occi_attr.properties).

set_immutable(#occi_attr{properties=Props}=A, Val) ->
    A#occi_attr{properties=dict:store(immutable, Val, Props)}.

get_default(#occi_attr{properties=Props}) ->
    dict:fetch(default, Props).

set_default(#occi_attr{properties=Props}=A, Value) ->
    A#occi_attr{properties=dict:store(default, Value, Props)}.

is_scalar(#occi_attr{scalar=Scalar}) ->
    Scalar.

get_value(#occi_attr{value=undefined, scalar=false}) ->
    [];
get_value(#occi_attr{value=Value}) ->
    Value.

set_value(#occi_attr{type_id=Id}=A, Value) ->
    Fun = get_check_fun(Id),
    A#occi_attr{value=Fun(Value)}.

add_value(#occi_attr{scalar=true}, _Value) ->
    throw({error, bad_arity});
add_value(#occi_attr{type_id=Id, value=undefined}=A, Value) ->
    Fun = get_check_fun(Id),
    A#occi_attr{value=[Fun(Value)]};
add_value(#occi_attr{properties=Props, type_id=Id, value=List}=A, Value) ->
    case dict:fetch(maxOccurs, Props) of
	Max when Max < length(List) ->
	    Fun = get_check_fun(Id),
	    A#occi_attr{value=[Fun(Value)|List]};
	_ ->
	    throw({error, bad_arity})
    end.

set_title(A, Title) ->
    A#occi_attr{title=Title}.

get_title(#occi_attr{title=Title}) ->
    Title.

-spec reset(occi_attr()) -> occi_attr().
reset(#occi_attr{}=A) ->
    A#occi_attr{value=get_default(A)}.

%%%
%%% Private functions
%%%
get_check_fun(string) ->
    fun to_string/1;

get_check_fun(integer) ->
    fun to_integer/1;

get_check_fun(float) ->
    fun to_float/1;

get_check_fun(Type) ->
    case occi_category_mgr:get(#occi_type{id=Type, _='_'}) of
	#occi_type{f=Fun} ->
	    Fun;
	{error, Err} ->
	    throw({error, Err})
    end.

check(#occi_attr{value=undefined}=A) ->
    case is_required(A) of
	true -> error;
	false -> ok
    end;
check(#occi_attr{}=_A) ->
    ok.

to_string(X) when is_list(X) ->
    X;
to_string(X) when is_binary(X) ->
    binary_to_list(X);
to_string(X) ->
    throw({error, {einval, X}}).

to_integer(X) when is_integer(X) ->
    X;
to_integer(X) when is_binary(X) ->
    binary_to_integer(X);
to_integer(X) when is_list(X) ->
    list_to_integer(X);
to_integer(X) ->
    throw({error, {einval, X}}).

to_float(X) when is_float(X) ->
    X;
to_float(X) when is_integer(X) ->
    X+0.0;
to_float(X) when is_binary(X) ->
    try binary_to_float(X) of
	V -> V
    catch 
	_:_ ->
	    try binary_to_integer(X) of
		V -> V+0.0
	    catch
		_:_ -> {error, einval}
	    end
    end;
to_float(X) when is_list(X) ->
    try list_to_float(X) of
	V -> V
    catch 
	_:_ ->
	    try list_to_integer(X) of
		V -> V+0.0
	    catch
		_:_ -> {error, einval}
	    end
    end;
to_float(X) ->
    throw({error, {einval, X}}).
