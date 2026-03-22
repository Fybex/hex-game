% Hex: управління станом гри
% Зберігає ігри як dynamic facts з dict-based станом
:- module(game_state, [
    create_game/4,
    create_game/5,
    create_game/6,
    apply_move/5,
    apply_ai_move/3,
    get_state/2,
    cleanup_game/1,
    state_to_json/2
]).

:- use_module(game_logic).
:- use_module(ai).
:- use_module(game_store).
:- use_module(game_json).

% Створення гри

% create_game(++Size, ++HumanColor, --GameId, --State)
% Єдине призначення: створити гру з типовою глибиною.
create_game(Size, HumanColor, GameId, State) :-
    create_game(Size, HumanColor, _, human_vs_ai, GameId, State).

% create_game(++Size, ++HumanColor, ++Depth, --GameId, --State)
% Єдине призначення: створити гру з явною глибиною.
% uuid/1 — генерує унікальний ідентифікатор (вбудований SWI-Prolog).
create_game(Size, HumanColor, Depth, GameId, State) :-
    create_game(Size, HumanColor, Depth, human_vs_ai, GameId, State).

% create_game(++Size, ++HumanColor, ++Depth, ++Mode, --GameId, --State)
% Створює нову гру з явною або типовою глибиною пошуку AI та режимом гри.
% Якщо Depth не задано, використовується типовий рівень для розміру дошки.
create_game(Size, HumanColor, RequestedDepth, Mode, GameId, FinalState) :-
    uuid(GameId),
    resolve_depth(Size, RequestedDepth, Depth),
    initial_state(Size, HumanColor, Depth, Mode, InitialState),
    store_game(GameId, InitialState),
    maybe_apply_ai_first_move(GameId, InitialState, FinalState).

% Хід гравця

% apply_move(++GameId, ++Row, ++Col, --NewState, --AiMove)
% Єдине призначення: застосувати хід людини (+ хід AI).
% Може бути невдалим (fail), якщо хід невалідний або гра завершена.
% AiMove = ai_move(Row, Col) або none.
apply_move(GameId, Row, Col, FinalState, AiMove) :-
    lookup_game(GameId, State),
    State.status = playing,
    Player = State.current_player,
    Player \= none,
    validate_current_player(State, Player),
    apply_player_move(State, Player, Row, Col, Board1, Moves1),
    opponent(Player, NextPlayer),
    next_state_after_turn(State, Board1, Moves1, NextPlayer, PlayerState),
    (PlayerState.status = finished
    -> FinalState = PlayerState,
       AiMove = none
    ;  State.mode = human_vs_ai
    -> apply_ai_turn(State, Board1, Moves1, State.ai_color, Player, FinalState, AiMove)
    ;  FinalState = PlayerState,
       AiMove = none
    ),
    replace_game(GameId, FinalState).

% apply_ai_move(++GameId, --NewState, --AiMove)
% Застосовує один хід AI для поточного гравця.
apply_ai_move(GameId, FinalState, ai_move(AiRow, AiCol)) :-
    lookup_game(GameId, State),
    State.status = playing,
    Player = State.current_player,
    Player \= none,
    apply_ai_move_to_board(State, State.board, State.moves, Player, AiRow, AiCol, Board1, Moves1),
    opponent(Player, NextPlayer),
    next_state_after_turn(State, Board1, Moves1, NextPlayer, FinalState),
    replace_game(GameId, FinalState).

% Отримання стану

% get_state(++GameId, --State)
get_state(GameId, State) :- lookup_game(GameId, State).

% Очищення

% cleanup_game(++GameId)
% Видаляє гру зі сховища.
cleanup_game(GameId) :- delete_game(GameId).

% Допоміжні предикати

% resolve_depth(++Size, ?RequestedDepth, --Depth)
% resolve_depth(+Size, +RequestedDepth, -Depth) — використати задану глибину
% resolve_depth(+Size, -RequestedDepth, -Depth) — визначити типову для розміру
resolve_depth(Size, RequestedDepth, Depth) :-
    (integer(RequestedDepth)
    -> Depth = RequestedDepth
    ;  ai:max_depth(Size, Depth)
    ).

% validate_current_player(++State, ++Player)
% Перевіряє, що Player має право ходити (в режимі human_vs_ai — лише human_color).
validate_current_player(State, Player) :-
    (State.mode = human_vs_ai
    -> State.human_color = Player
    ;  true
    ).

% initial_state(++Size, ++HumanColor, ++Depth, ++Mode, --State)
% Формує початковий стан гри як SWI-Prolog dict.
initial_state(Size, HumanColor, Depth, Mode, State) :-
    initial_board(Size, Board),
    opponent(HumanColor, AiColor),
    State = state{
        board: Board,
        size: Size,
        current_player: blue,
        status: playing,
        winner: none,
        moves: [],
        human_color: HumanColor,
        ai_color: AiColor,
        depth: Depth,
        mode: Mode
    }.

% maybe_apply_ai_first_move(++GameId, ++State, --FinalState)
% Якщо AI грає за blue (перший хід), одразу робить хід.
maybe_apply_ai_first_move(GameId, State, FinalState) :-
    (State.mode = human_vs_ai,
     State.ai_color = blue
    -> apply_ai_move_to_board(State, State.board, State.moves, blue, _, _, Board1, Moves1),
       next_state_after_turn(State, Board1, Moves1, red, FinalState),
       replace_game(GameId, FinalState)
    ;  FinalState = State
    ).

% apply_player_move(++State, ++Player, ++Row, ++Col, --Board1, --Moves1)
% Перевіряє валідність і застосовує хід до дошки. Може бути невдалим (fail).
apply_player_move(State, Player, Row, Col, Board1, Moves1) :-
    Board = State.board,
    Size = State.size,
    valid_move(Board, Size, Row, Col),
    set_cell(Board, Size, Row, Col, Player, Board1),
    Moves1 = [move(Player, Row, Col) | State.moves].

% apply_ai_turn(++State, ++Board, ++Moves, ++AiColor, ++NextPlayer,
%               --FinalState, --AiMove)
% Виконує хід AI і перевіряє результат.
apply_ai_turn(State, Board, Moves, AiColor, NextPlayer, FinalState, ai_move(AiRow, AiCol)) :-
    apply_ai_move_to_board(State, Board, Moves, AiColor, AiRow, AiCol, Board1, Moves1),
    next_state_after_turn(State, Board1, Moves1, NextPlayer, FinalState).

% apply_ai_move_to_board(++State, ++Board, ++Moves, ++Player,
%                        --AiRow, --AiCol, --NextBoard, --NextMoves)
% Викликає ai_move і застосовує результат до дошки.
apply_ai_move_to_board(State, Board, Moves, Player, AiRow, AiCol, NextBoard, NextMoves) :-
    Size = State.size,
    Depth = State.depth,
    ai_move(Board, Size, Player, Depth, AiRow, AiCol),
    set_cell(Board, Size, AiRow, AiCol, Player, NextBoard),
    NextMoves = [move(Player, AiRow, AiCol) | Moves].

% next_state_after_turn(++State, ++Board, ++Moves, ++NextPlayer, --FinalState)
% Перевіряє game_over і формує наступний стан (finished або playing).
next_state_after_turn(State, Board, Moves, NextPlayer, FinalState) :-
    Size = State.size,
    (game_over(Board, Size, win(Winner))
    -> FinalState = State.put(_{
           board: Board,
           current_player: none,
           status: finished,
           winner: Winner,
           moves: Moves
       })
    ; all_valid_moves(Board, Size, [])
    -> FinalState = State.put(_{
           board: Board,
           current_player: none,
           status: finished,
           winner: none,
           moves: Moves
       })
    ;  FinalState = State.put(_{
           board: Board,
           current_player: NextPlayer,
           moves: Moves
       })
    ).
