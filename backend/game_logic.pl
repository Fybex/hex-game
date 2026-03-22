% Hex: ігрова логіка — дошка, ходи, перевірка перемоги (BFS)
:- module(game_logic, [
    initial_board/2,
    board_size/2,
    cell_at/5,
    set_cell/6,
    valid_move/4,
    all_valid_moves/3,
    neighbors/4,
    wins/3,
    game_over/3,
    opponent/2,
    index_to_rc/4,
    rc_to_index/4
]).

% Гравці

% opponent(?Player, ?Opponent)
% opponent(+Player, -Opponent) — визначити суперника
% opponent(-Player, +Opponent) — зворотній напрямок
% opponent(-Player, -Opponent) — перебрати всі пари (2 розв'язки)
opponent(blue, red).
opponent(red, blue).

% Дошка
% Дошка - плоский список Size*Size елементів.
% Кожна клітинка: empty, blue або red.
% Індексація: (Row, Col) починаючи з 1.

% initial_board(++Size, --Board).
% Створює порожню дошку Size x Size.
% Єдине призначення: задати Size, отримати Board.
% maplist/2 — застосовує Goal до кожного елемента списку (вбудований).
initial_board(Size, Board) :- Total is Size * Size,
                              length(Board, Total),
                              maplist(=(empty), Board).

% board_size(++Board, --Size).
% Визначає розмір дошки за довжиною списку.
% Єдине призначення: задати Board, отримати Size.
board_size(Board, Size) :- length(Board, Total),
                           Size is round(sqrt(Total)).

% Конвертація координат

% rc_to_index(++Size, ++Row, ++Col, --Index).
% Перетворює (Row, Col) в 1-based індекс плоского списку.
% Зворотній напрямок (Index → Row, Col) — окремий предикат index_to_rc/4.
rc_to_index(Size, Row, Col, Index) :- Index is (Row - 1) * Size + Col.

% index_to_rc(++Size, ++Index, --Row, --Col).
% Перетворює 1-based індекс назад у (Row, Col).
% Зворотній напрямок — rc_to_index/4.
index_to_rc(Size, Index, Row, Col) :- Row is (Index - 1) // Size + 1,
                                      Col is (Index - 1) mod Size + 1.

% Доступ до клітинок

% cell_at(++Board, ++Size, ++Row, ++Col, ?Value)
% cell_at(+Board, +Size, +Row, +Col, -Value) — отримати значення клітинки
% cell_at(+Board, +Size, +Row, +Col, +Value) — перевірити значення клітинки
% Генерація координат за Value не підтримується — nth1/3 потребує індекс.
% nth1/3 — доступ до N-го елемента списку (1-based, вбудований).
cell_at(Board, Size, Row, Col, Value) :- rc_to_index(Size, Row, Col, Index),
                                         nth1(Index, Board, Value).

% set_cell(++Board, ++Size, ++Row, ++Col, ++Player, --NewBoard).
% Ставить фішку Player на позицію (Row, Col).
% Єдине призначення: всі вхідні задані, отримати оновлену дошку.
set_cell(Board, Size, Row, Col, Player, NewBoard) :-
    rc_to_index(Size, Row, Col, Index),
    replace_nth(Board, Index, Player, NewBoard).

% replace_nth(++List, ++N, ++Elem, --Result).
% Замінює N-й елемент (1-based) списку на Elem.
% Єдине призначення: всі вхідні задані, отримати Result.
replace_nth([_|T], 1, Elem, [Elem|T]).
replace_nth([H|T], N, Elem, [H|R]) :- N > 1,
                                       N1 is N - 1,
                                       replace_nth(T, N1, Elem, R).

% Валідація ходів

% valid_move(++Board, ++Size, ?Row, ?Col)
% valid_move(+Board, +Size, +Row, +Col) — перевірка конкретної клітинки
% valid_move(+Board, +Size, -Row, -Col) — генерація всіх вільних клітинок
% Часткова конкретизація (лише Row або Col) працює, але не використовується.
% between/3 — генерує або перевіряє цілі числа в діапазоні (вбудований).
valid_move(Board, Size, Row, Col) :- between(1, Size, Row),
                                     between(1, Size, Col),
                                     cell_at(Board, Size, Row, Col, empty).

% all_valid_moves(++Board, ++Size, --Moves).
% Збирає всі допустимі ходи як список Row-Col.
% findall/3 — збирає всі розв'язки Goal у список (вбудований).
all_valid_moves(Board, Size, Moves) :-
    findall(Row-Col, valid_move(Board, Size, Row, Col), Moves).

% Сусіди

% neighbors(++Size, ++Row, ++Col, --Neighbors).
% Повертає список сусідів Row-Col у межах дошки.
% Шестикутник має до 6 сусідів: N, NE, E, S, SW, W
% (у координатах offset: (-1,0), (-1,+1), (0,+1), (+1,0), (+1,-1), (0,-1)).
% Єдине призначення: задати координати, отримати список.
neighbors(Size, Row, Col, Neighbors) :-
    Deltas = [(-1, 0), (-1, 1), (0, 1), (1, 0), (1, -1), (0, -1)],
    findall(NR-NC,
            (member((DR, DC), Deltas),
             NR is Row + DR,
             NC is Col + DC,
             NR >= 1, NR =< Size,
             NC >= 1, NC =< Size),
            Neighbors).

% Перевірка перемоги (BFS)
% blue з'єднує верх (Row=1) з низом (Row=Size)
% red з'єднує ліво (Col=1) з право (Col=Size)

% wins(++Board, ++Size, ++Player).
% Перевіряє чи Player з'єднав свої сторони.
% Єдине призначення: перевірка для конкретного гравця.
% Генерація переможця — через game_over/3.
wins(Board, Size, blue) :- !,
                           findall(1-Col,
                                   (between(1, Size, Col),
                                    cell_at(Board, Size, 1, Col, blue)),
                                   Seeds),
                           bfs_reaches_target(Board, Size, blue, Seeds, [],
                                              row, Size).
wins(Board, Size, red) :- findall(Row-1,
                                  (between(1, Size, Row),
                                   cell_at(Board, Size, Row, 1, red)),
                                  Seeds),
                          bfs_reaches_target(Board, Size, red, Seeds, [],
                                             col, Size).

% bfs_reaches_target(++Board, ++Size, ++Player, ++Queue, ++Visited,
%                    ++TargetType, ++TargetVal).
% BFS по клітинках Player. Перевіряє чи досягнуто цільовий рядок/стовпець.
% TargetType = row: перевіряємо Row == TargetVal
% TargetType = col: перевіряємо Col == TargetVal.
% Єдине призначення: всі аргументи вхідні, успіх або невдача.
bfs_reaches_target(_, _, _, [], _, _, _) :- fail.
bfs_reaches_target(_, _, _, [Row-_Col|_], _, row, Target) :- Row =:= Target, !.
bfs_reaches_target(_, _, _, [_Row-Col|_], _, col, Target) :- Col =:= Target, !.
bfs_reaches_target(Board, Size, Player, [Row-Col|Rest], Visited, TType, TVal) :-
    neighbors(Size, Row, Col, Nbrs),
    % include/3 — фільтрує список, залишаючи елементи що задовольняють Goal.
    include(bfs_can_visit(Board, Size, Player, Visited), Nbrs, NewNbrs),
    append(Visited, [Row-Col], Visited1),
    append(Rest, NewNbrs, Queue1),
    bfs_reaches_target(Board, Size, Player, Queue1, Visited1, TType, TVal).

% bfs_can_visit(++Board, ++Size, ++Player, ++Visited, ++Cell).
% Перевіряє чи клітинку можна відвідати: належить Player і ще не відвідана.
bfs_can_visit(Board, Size, Player, Visited, Row-Col) :-
    \+ member(Row-Col, Visited),
    cell_at(Board, Size, Row, Col, Player).

% Кінець гри

% game_over(++Board, ++Size, -Result)
% game_over(+Board, +Size, -Result) — визначити результат гри
% Result = win(Player) | draw.
% Єдине призначення: Board завжди конкретизована.
% Нічия в Hex математично неможлива (Gale, 1979), клауза для draw — для повноти.
game_over(Board, Size, win(blue)) :- wins(Board, Size, blue), !.
game_over(Board, Size, win(red))  :- wins(Board, Size, red), !.
game_over(Board, Size, draw)      :- all_valid_moves(Board, Size, []).
