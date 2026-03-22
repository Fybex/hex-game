% Hex: серіалізація стану гри в JSON-сумісні структури
:- module(game_json, [
    state_to_json/2
]).

:- use_module(game_logic).

% state_to_json(++State, --Json)
% Єдине призначення: серіалізувати стан для браузера.
% Зворотній напрямок (Json → State) не підтримується:
% Json містить null замість none і масиви замість списку.
state_to_json(State, Json) :-
    Board = State.board,
    Size = State.size,
    board_to_json_rows(Board, Size, 1, Rows),
    moves_to_json(State.moves, JsonMoves),
    WinnerAtom = State.winner,
    (WinnerAtom = none -> WinnerJson = null ; WinnerJson = WinnerAtom),
    Depth = State.depth,
    Json = json{
        board: Rows,
        size: Size,
        current_player: State.current_player,
        status: State.status,
        winner: WinnerJson,
        moves: JsonMoves,
        human_color: State.human_color,
        ai_color: State.ai_color,
        depth: Depth,
        mode: State.mode
    }.

% board_to_json_rows(++Board, ++Size, ++CurrentRow, --Rows)
% Конвертує плоский список дошки в список рядків
board_to_json_rows(_, Size, Row, []) :-
    Row > Size,
    !.
board_to_json_rows(Board, Size, Row, [JsonRow|Rest]) :-
    row_to_json(Board, Size, Row, 1, JsonRow),
    NextRow is Row + 1,
    board_to_json_rows(Board, Size, NextRow, Rest).

% row_to_json(++Board, ++Size, ++Row, ++CurrentCol, --JsonRow)
row_to_json(_, Size, _, Col, []) :-
    Col > Size,
    !.
row_to_json(Board, Size, Row, Col, [CellAtom|Rest]) :-
    cell_at(Board, Size, Row, Col, Cell),
    (Cell = empty -> CellAtom = null ; CellAtom = Cell),
    NextCol is Col + 1,
    row_to_json(Board, Size, Row, NextCol, Rest).

% moves_to_json(++Moves, --JsonMoves)
% Конвертує список ходів (зворотній порядок) у JSON.
% reverse/2 — перевертає список (вбудований).
% maplist/3 — застосовує Goal до кожної пари елементів двох списків.
moves_to_json(Moves, JsonMoves) :-
    reverse(Moves, OrderedMoves),
    maplist(move_to_json, OrderedMoves, JsonMoves).

% move_to_json(++Move, --Json)
move_to_json(move(Player, Row, Col), json{player: Player, row: Row, col: Col}).
