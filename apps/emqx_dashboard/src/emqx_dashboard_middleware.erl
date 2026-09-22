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
    Req1 = rewrite_legacy_api_path(Req),
    add_cors_flag(Req1, Env).

%% The dashboard web frontend still requests the legacy `/api/v5` prefix,
%% while the backend now serves the API under `/api/v4` (to align with the
%% EMQX 4.x management API). Rewrite the v5 prefix to v4 so both the legacy
%% v5 frontend and the v4 API clients keep working against the same handlers.
rewrite_legacy_api_path(Req) ->
    case cowboy_req:path(Req) of
        <<"/api/v5", Rest/binary>> ->
            cowboy_req:path(<<"/api/v4", Rest/binary>>, Req);
        _ ->
            Req
    end.

add_cors_flag(Req, Env) ->
    CORS = emqx_conf:get([dashboard, cors], false),
    case CORS andalso cowboy_req:header(<<"origin">>, Req, undefined) =/= undefined of
        false ->
            {ok, Req, Env};
        true ->
            Req2 = cowboy_req:set_resp_header(<<"Access-Control-Allow-Origin">>, <<"*">>, Req),
            {ok, Req2, Env}
    end.
