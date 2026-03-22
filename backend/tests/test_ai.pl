% Тести: ШІ (minimax + alpha-beta)
:- use_module('../game_logic').
:- use_module('../ai').
:- use_module(library(plunit)).

:- begin_tests(evaluation).

test(empty_board_symmetric, [nondet, true(Score =:= 0)]) :-
    initial_board(5, Board),
    evaluate(Board, 5, blue, Score).

test(blue_advantage_positive, [nondet]) :-
    initial_board(5, B0),
    set_cell(B0, 5, 1, 3, blue, B1),
    set_cell(B1, 5, 2, 3, blue, B2),
    set_cell(B2, 5, 3, 3, blue, B3),
    evaluate(B3, 5, blue, Score),
    Score > 0.

test(red_advantage_negative, [nondet]) :-
    initial_board(5, B0),
    set_cell(B0, 5, 3, 1, red, B1),
    set_cell(B1, 5, 3, 2, red, B2),
    set_cell(B2, 5, 3, 3, red, B3),
    evaluate(B3, 5, blue, Score),
    Score < 0.

:- end_tests(evaluation).

:- begin_tests(ai_move_selection).

test(ai_returns_valid_move) :-
    initial_board(5, Board),
    ai_move(Board, 5, blue, Row, Col),
    Row >= 1, Row =< 5,
    Col >= 1, Col =< 5.

% На 3x3 дошці з двома blue підряд AI повинен завершити шлях
test(ai_finds_winning_strategy, [nondet]) :-
    initial_board(3, B0),
    set_cell(B0, 3, 1, 2, blue, B1),
    set_cell(B1, 3, 2, 2, blue, B2),
    set_cell(B2, 3, 1, 1, red, B3),
    set_cell(B3, 3, 2, 1, red, B4),
    ai_move(B4, 3, blue, Row, Col),
    valid_move(B4, 3, Row, Col),
    set_cell(B4, 3, Row, Col, blue, B5),
    wins(B5, 3, blue).

% AI має заблокувати єдиний виграшний хід суперника
% Red з'єднав col 1-4 через зигзаг, blue блокує всі альтернативи
test(ai_blocks_winning_threat, [nondet]) :-
    initial_board(3, B0),
    % 3x3 дошка: red з'єднує ліво-право
    % red: (1,1), (1,2) — потрібен (1,3) для перемоги
    set_cell(B0, 3, 1, 1, red, B1),
    set_cell(B1, 3, 1, 2, red, B2),
    % blue: (2,1), (3,1)
    set_cell(B2, 3, 2, 1, blue, B3),
    set_cell(B3, 3, 3, 1, blue, B4),
    ai_move(B4, 3, blue, Row, Col),
    % AI повинен заблокувати (1, 3) — єдине місце де red виграє одним ходом
    Row =:= 1, Col =:= 3.

:- end_tests(ai_move_selection).

:- begin_tests(ai_competitiveness).

% Тест: AI грає сам проти себе, гра повинна закінчитись перемогою
test(ai_vs_ai_completes, [nondet]) :-
    initial_board(5, Board),
    play_ai_vs_ai(Board, 5, blue, Result),
    Result = win(_).

:- end_tests(ai_competitiveness).

% --- Допоміжні предикати для тестів ---

% play_ai_vs_ai(++Board, ++Size, ++CurrentPlayer, --Result)
% AI грає за обох гравців до завершення гри
play_ai_vs_ai(Board, Size, _, Result) :-
    game_over(Board, Size, Result), !.
play_ai_vs_ai(Board, Size, Player, Result) :-
    ai_move(Board, Size, Player, Row, Col),
    set_cell(Board, Size, Row, Col, Player, NewBoard),
    opponent(Player, Next),
    play_ai_vs_ai(NewBoard, Size, Next, Result).
