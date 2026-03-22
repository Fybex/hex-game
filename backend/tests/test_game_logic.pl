% Тести: ігрова логіка
:- use_module('../game_logic').
:- use_module(library(plunit)).

:- begin_tests(board_creation).

test(initial_board_size, [true(Len =:= 25)]) :-
    initial_board(5, Board),
    length(Board, Len).

test(initial_board_all_empty) :-
    initial_board(5, Board),
    forall(member(Cell, Board), Cell = empty).

test(board_size_detection, [true(Size =:= 5)]) :-
    initial_board(5, Board),
    board_size(Board, Size).

:- end_tests(board_creation).

:- begin_tests(coordinates).

test(rc_to_index_values, forall(member(R-C-Expected, [1-1-1, 5-5-25, 3-3-13]))) :-
    rc_to_index(5, R, C, I),
    I =:= Expected.

test(index_to_rc_roundtrip) :-
    rc_to_index(5, 3, 4, I),
    index_to_rc(5, I, R, C),
    R =:= 3, C =:= 4.

:- end_tests(coordinates).

:- begin_tests(cell_access).

test(cell_at_empty) :-
    initial_board(5, Board),
    cell_at(Board, 5, 3, 3, empty).

test(set_and_get_cell, [nondet]) :-
    initial_board(5, Board),
    set_cell(Board, 5, 2, 3, blue, Board1),
    cell_at(Board1, 5, 2, 3, blue).

test(set_cell_preserves_others, [nondet]) :-
    initial_board(5, Board),
    set_cell(Board, 5, 2, 3, blue, Board1),
    cell_at(Board1, 5, 1, 1, empty),
    cell_at(Board1, 5, 5, 5, empty).

:- end_tests(cell_access).

:- begin_tests(valid_moves).

test(valid_move_empty_cell) :-
    initial_board(5, Board),
    valid_move(Board, 5, 3, 3).

test(invalid_move_occupied, [fail]) :-
    initial_board(5, Board),
    set_cell(Board, 5, 3, 3, blue, Board1),
    valid_move(Board1, 5, 3, 3).

test(invalid_move_out_of_bounds, [fail]) :-
    initial_board(5, Board),
    valid_move(Board, 5, 0, 1).

test(all_valid_moves_initial, [true(Len =:= 25)]) :-
    initial_board(5, Board),
    all_valid_moves(Board, 5, Moves),
    length(Moves, Len).

test(all_valid_moves_after_move, [nondet, true(Len =:= 24)]) :-
    initial_board(5, Board),
    set_cell(Board, 5, 1, 1, blue, Board1),
    all_valid_moves(Board1, 5, Moves),
    length(Moves, Len).

:- end_tests(valid_moves).

:- begin_tests(neighbors).

test(neighbor_counts, forall(member(R-C-Expected, [3-3-6, 1-1-2, 5-5-2, 1-3-4]))) :-
    neighbors(5, R, C, Nbrs),
    length(Nbrs, Expected).

:- end_tests(neighbors).

:- begin_tests(win_detection).

% blue з'єднує верх (row 1) з низом (row 5)
test(blue_wins_straight_column, [nondet]) :-
    initial_board(5, B0),
    set_cell(B0, 5, 1, 3, blue, B1),
    set_cell(B1, 5, 2, 3, blue, B2),
    set_cell(B2, 5, 3, 3, blue, B3),
    set_cell(B3, 5, 4, 3, blue, B4),
    set_cell(B4, 5, 5, 3, blue, B5),
    wins(B5, 5, blue).

test(blue_no_win_incomplete, [fail]) :-
    initial_board(5, B0),
    set_cell(B0, 5, 1, 3, blue, B1),
    set_cell(B1, 5, 2, 3, blue, B2),
    set_cell(B2, 5, 3, 3, blue, B3),
    wins(B3, 5, blue).

% red з'єднує ліво (col 1) з право (col 5)
test(red_wins_straight_row, [nondet]) :-
    initial_board(5, B0),
    set_cell(B0, 5, 3, 1, red, B1),
    set_cell(B1, 5, 3, 2, red, B2),
    set_cell(B2, 5, 3, 3, red, B3),
    set_cell(B3, 5, 3, 4, red, B4),
    set_cell(B4, 5, 3, 5, red, B5),
    wins(B5, 5, red).

% Зигзагоподібний шлях для blue
test(blue_wins_zigzag, [nondet]) :-
    initial_board(5, B0),
    set_cell(B0, 5, 1, 1, blue, B1),
    set_cell(B1, 5, 2, 1, blue, B2),
    set_cell(B2, 5, 2, 2, blue, B3),
    set_cell(B3, 5, 3, 2, blue, B4),
    set_cell(B4, 5, 3, 3, blue, B5),
    set_cell(B5, 5, 4, 3, blue, B6),
    set_cell(B6, 5, 5, 3, blue, B7),
    wins(B7, 5, blue).

test(game_over_blue_wins, [nondet]) :-
    initial_board(5, B0),
    set_cell(B0, 5, 1, 3, blue, B1),
    set_cell(B1, 5, 2, 3, blue, B2),
    set_cell(B2, 5, 3, 3, blue, B3),
    set_cell(B3, 5, 4, 3, blue, B4),
    set_cell(B4, 5, 5, 3, blue, B5),
    game_over(B5, 5, win(blue)).

:- end_tests(win_detection).
