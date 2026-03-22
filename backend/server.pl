% Hex: HTTP сервер
% Роздає JSON API та статичні файли фронтенду
:- module(server, [start_server/1, stop_server/1]).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_cors)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_files)).

:- use_module(game_logic).
:- use_module(game_state).

% CORS — дозволяємо запити з будь-якого origin (для розробки)
:- set_setting(http:cors, [*]).

% Маршрутизація

:- http_handler('/api/new_game', handle_new_game, [method(post)]).
:- http_handler('/api/move',     handle_move,     [method(post)]).
:- http_handler('/api/ai_move',  handle_ai_move,  [method(post)]).
:- http_handler('/api/state',    handle_state,    [method(get)]).
:- http_handler('/api/health',   handle_health,   [method(get)]).

% Статичні файли фронтенду (після збірки)
:- http_handler('/', http_reply_from_files('../frontend/build', []), [prefix]).

% Запуск і зупинка

% start_server(++Port)
start_server(Port) :- http_server(http_dispatch, [port(Port), timeout(300)]),
                      format('Hex server started on port ~w~n', [Port]).

% stop_server(++Port)
stop_server(Port) :- http_stop_server(Port, []).

% Обробники

% POST /api/new_game
% Тіло: {"size": 5, "human_color": "blue"}
% Відповідь: {"game_id": "...", "state": {...}}
handle_new_game(Request) :-
    cors_enable(Request, [methods([post])]),
    http_read_json_dict(Request, Body),
    Size = Body.get(size, 5),
    HumanColorAtom = Body.get(human_color, "blue"),
    ModeAtom = Body.get(mode, "human_vs_ai"),
    atom_string(HumanColor, HumanColorAtom),
    atom_string(Mode, ModeAtom),
    (get_dict(depth, Body, DepthVal), integer(DepthVal) -> Depth = DepthVal ; true),
    create_game(Size, HumanColor, Depth, Mode, GameId, _),
    get_state(GameId, State),
    state_to_json(State, JsonState),
    reply_json_dict(json{game_id: GameId, state: JsonState}).

% POST /api/move
% Тіло: {"game_id": "...", "row": 2, "col": 3}
% Відповідь: {"state": {...}, "ai_move": {"row": R, "col": C} | null}
handle_move(Request) :-
    cors_enable(Request, [methods([post])]),
    http_read_json_dict(Request, Body),
    atom_string(GameId, Body.game_id),
    Row = Body.row,
    Col = Body.col,
    (apply_move(GameId, Row, Col, _, AiMoveResult)
    -> get_state(GameId, NewState),
       state_to_json(NewState, JsonState),
       (AiMoveResult = ai_move(AiR, AiC)
       -> AiMoveJson = json{row: AiR, col: AiC}
       ;  AiMoveJson = null
       ),
       reply_json_dict(json{state: JsonState, ai_move: AiMoveJson})
    ;  reply_json_dict(json{error: "Invalid move"}, [status(400)])
    ).

% POST /api/ai_move
% Тіло: {"game_id": "..."}
% Відповідь: {"state": {...}, "ai_move": {"row": R, "col": C}}
handle_ai_move(Request) :-
    cors_enable(Request, [methods([post])]),
    http_read_json_dict(Request, Body),
    atom_string(GameId, Body.game_id),
    (apply_ai_move(GameId, NewState, ai_move(AiR, AiC))
    -> state_to_json(NewState, JsonState),
       reply_json_dict(json{
           state: JsonState,
           ai_move: json{row: AiR, col: AiC}
       })
    ;  reply_json_dict(json{error: "Unable to make AI move"}, [status(400)])
    ).

% GET /api/state?game_id=...
% Відповідь: {"state": {...}}
handle_state(Request) :-
    cors_enable(Request, [methods([get])]),
    http_parameters(Request, [game_id(GameId, [atom])]),
    (get_state(GameId, State)
    -> state_to_json(State, JsonState),
       reply_json_dict(json{state: JsonState})
    ;  reply_json_dict(json{error: "Game not found"}, [status(404)])
    ).

% GET /api/health
handle_health(Request) :-
    cors_enable(Request, [methods([get])]),
    reply_json_dict(json{status: "ok"}).

% CORS preflight

:- http_handler('/api/', handle_preflight, [method(options), prefix]).

handle_preflight(Request) :-
    cors_enable(Request, [methods([get, post, options])]).
