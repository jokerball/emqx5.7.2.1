%%--------------------------------------------------------------------
%% Copyright (c) 2020-2024 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(emqx_dashboard_middleware).

-behaviour(cowboy_middleware).

-export([execute/2]).

execute(Req, Env) ->
    Req1 = rewrite_v4_path(Req),
    add_cors_flag(Req1, Env).

%% Compose EMQX 4.x compatible routes. The v4 endpoints below are mapped to
%% their v5 counterparts so they share the same handler, and the request is
%% tagged so that it gets authenticated with username/password (4.x style)
%% instead of the v5 API key. See emqx_dashboard:authorize/1.
rewrite_v4_path(Req) ->
    case cowboy_req:path(Req) of
        <<"/api/v4/mqtt/publish_to_client", Rest/binary>> ->
            tag_v4(cowboy_req:path(<<"/api/v5/publish_to_client", Rest/binary>>, Req));
        <<"/api/v4/nodes", Rest/binary>> ->
            tag_v4(cowboy_req:path(<<"/api/v5/nodes", Rest/binary>>, Req));
        _ ->
            Req
    end.

tag_v4(Req) ->
    cowboy_req:meta(v4_api, true, Req).

add_cors_flag(Req, Env) ->
    CORS = emqx_conf:get([dashboard, cors], false),
    case CORS andalso cowboy_req:header(<<"origin">>, Req, undefined) =/= undefined of
        false ->
            {ok, Req, Env};
        true ->
            Req2 = cowboy_req:set_resp_header(<<"Access-Control-Allow-Origin">>, <<"*">>, Req),
            {ok, Req2, Env}
    end.
