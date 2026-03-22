% Тести: HTTP API (інтеграційні)
:- use_module('../server').
:- use_module('../game_state').
:- use_module(library(plunit)).
:- use_module(library(http/http_client)).
:- use_module(library(http/http_json)).

:- dynamic test_port/1.

% --- Setup/Teardown ---

start_test_server :-
    (test_port(_) -> true
    ;  Port = 18080,
       start_server(Port),
       assert(test_port(Port))
    ).

stop_test_server :-
    (test_port(Port)
    -> stop_server(Port),
       retract(test_port(Port))
    ;  true
    ).

base_url(URL) :-
    test_port(Port),
    format(atom(URL), 'http://localhost:~w', [Port]).

% --- Тести ---

:- begin_tests(api, [setup(start_test_server), cleanup(stop_test_server)]).

test(health_check) :-
    base_url(Base),
    atom_concat(Base, '/api/health', URL),
    http_get(URL, Dict, [json_object(dict)]),
    Dict.status = "ok".

test(new_game_returns_state) :-
    base_url(Base),
    atom_concat(Base, '/api/new_game', URL),
    http_post(URL,
              json(json{size: 5, human_color: "blue"}),
              Dict,
              [json_object(dict)]),
    _ = Dict.game_id,
    State = Dict.state,
    State.size =:= 5,
    State.status = "playing".

test(new_game_preserves_mode_and_depth) :-
    base_url(Base),
    atom_concat(Base, '/api/new_game', URL),
    http_post(URL,
              json(json{size: 7, human_color: "red", depth: 4, mode: "ai_vs_ai"}),
              Dict,
              [json_object(dict)]),
    State = Dict.state,
    State.size =:= 7,
    State.depth =:= 4,
    State.mode = "ai_vs_ai",
    State.human_color = "red".

test(human_vs_human_move_returns_state_without_ai_response) :-
    base_url(Base),
    atom_concat(Base, '/api/new_game', NewURL),
    http_post(NewURL,
              json(json{size: 5, human_color: "blue", mode: "human_vs_human"}),
              NewDict,
              [json_object(dict)]),
    GameId = NewDict.game_id,
    atom_concat(Base, '/api/move', MoveURL),
    http_post(MoveURL,
              json(json{game_id: GameId, row: 1, col: 1}),
              MoveDict,
              [json_object(dict)]),
    MoveDict.state.mode = "human_vs_human",
    MoveDict.state.current_player = "red",
    MoveDict.ai_move == null.

test(move_returns_ai_response) :-
    base_url(Base),
    atom_concat(Base, '/api/new_game', NewURL),
    http_post(NewURL,
              json(json{size: 5, human_color: "blue"}),
              NewDict,
              [json_object(dict)]),
    GameId = NewDict.game_id,
    atom_concat(Base, '/api/move', MoveURL),
    http_post(MoveURL,
              json(json{game_id: GameId, row: 1, col: 1}),
              MoveDict,
              [json_object(dict)]),
    _ = MoveDict.state,
    _ = MoveDict.ai_move.

test(ai_move_returns_state_in_ai_vs_ai_mode) :-
    base_url(Base),
    atom_concat(Base, '/api/new_game', NewURL),
    http_post(NewURL,
              json(json{size: 5, human_color: "blue", mode: "ai_vs_ai"}),
              NewDict,
              [json_object(dict)]),
    GameId = NewDict.game_id,
    atom_concat(Base, '/api/ai_move', AiMoveURL),
    http_post(AiMoveURL,
              json(json{game_id: GameId}),
              MoveDict,
              [json_object(dict)]),
    AiRow = MoveDict.ai_move.row,
    AiCol = MoveDict.ai_move.col,
    AiRow >= 1, AiRow =< 5,
    AiCol >= 1, AiCol =< 5,
    MoveDict.state.mode = "ai_vs_ai",
    MoveDict.state.current_player = "red".

test(invalid_move_returns_error) :-
    base_url(Base),
    atom_concat(Base, '/api/new_game', NewURL),
    http_post(NewURL,
              json(json{size: 5, human_color: "blue"}),
              NewDict,
              [json_object(dict)]),
    GameId = NewDict.game_id,
    % Робимо хід
    atom_concat(Base, '/api/move', MoveURL),
    http_post(MoveURL,
              json(json{game_id: GameId, row: 1, col: 1}),
              _,
              [json_object(dict)]),
    % Повторний хід на ту саму клітинку
    catch(
        http_post(MoveURL,
                  json(json{game_id: GameId, row: 1, col: 1}),
                  _,
                  [json_object(dict), status_code(Code)]),
        _,
        Code = 400
    ),
    Code =:= 400.

test(get_state_returns_game) :-
    base_url(Base),
    atom_concat(Base, '/api/new_game', NewURL),
    http_post(NewURL,
              json(json{size: 5, human_color: "blue"}),
              NewDict,
              [json_object(dict)]),
    GameId = NewDict.game_id,
    format(atom(StateURL), '~w/api/state?game_id=~w', [Base, GameId]),
    http_get(StateURL, StateDict, [json_object(dict)]),
    _ = StateDict.state.

:- end_tests(api).
