% Комплексна перевірка AI: AI vs AI на різних дошках
:- use_module('../game_logic').
:- use_module('../ai').
:- use_module(library(plunit)).

play_full(Board, Size, _, Result) :-
    game_over(Board, Size, Result), !.
play_full(Board, Size, Player, Result) :-
    ai_move(Board, Size, Player, Row, Col),
    set_cell(Board, Size, Row, Col, Player, NewBoard),
    opponent(Player, Next),
    play_full(NewBoard, Size, Next, Result).

:- begin_tests(comprehensive_ai).

test(ai_vs_ai_3x3_blue_first, [nondet]) :-
    initial_board(3, Board),
    play_full(Board, 3, blue, Result),
    Result = win(_).

test(ai_vs_ai_3x3_red_first, [nondet]) :-
    initial_board(3, Board),
    play_full(Board, 3, red, Result),
    Result = win(_).

test(ai_vs_ai_5x5_blue_first, [nondet]) :-
    initial_board(5, Board),
    play_full(Board, 5, blue, Result),
    Result = win(_).

test(ai_vs_ai_5x5_red_first, [nondet]) :-
    initial_board(5, Board),
    play_full(Board, 5, red, Result),
    Result = win(_).

:- end_tests(comprehensive_ai).
