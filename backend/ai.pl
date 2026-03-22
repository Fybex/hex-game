% Hex: ШІ — Minimax з Alpha-Beta pruning
% Оптимізації: Zobrist-хешування, транспозиційна таблиця (TT),
% ітеративне поглиблення, впорядкування ходів за TT + центром
:- module(ai, [
    ai_move/5,
    ai_move/6,
    evaluate/4,
    minimax/8
]).

:- use_module(game_logic).

% Динамічні предикати

:- dynamic zobrist_key/3.      % zobrist_key(Position, Color, Key)
:- thread_local tt_entry/5.    % tt_entry(Hash, Depth, Score, Flag, BestMove)
                               % Flag: exact | lower | upper

% Константи

% inf(--Value).
% neg_inf(--Value).
% Константи для початкових меж alpha-beta.
inf(10000).
neg_inf(-10000).

% max_depth(++Size, --Depth).
% Глибина пошуку залежить від розміру дошки.
% Єдине призначення: задати Size, отримати Depth.
% Останній клауз (catch-all) гарантує результат для будь-якого Size.
max_depth(3, 10).
max_depth(5, 5).
max_depth(7, 4).
max_depth(11, 2).
max_depth(_, 3).

% is_maximizing(++Player, --IsMax).
% blue максимізує (хоче більший Score), red мінімізує.
% Єдине призначення: задати Player, отримати прапорець.
is_maximizing(blue, true).
is_maximizing(red, false).

% Zobrist-хешування
% Кожній парі (позиція, колір) відповідає випадковий ключ.
% Хеш дошки — XOR усіх ключів зайнятих клітинок.

% init_zobrist.
% Ініціалізує таблицю Zobrist-ключів (випадкові числа для кожної пари позиція-колір).
% Викликається один раз при завантаженні модуля.
init_zobrist :-
    retractall(zobrist_key(_, _, _)),
    MaxPos is 11 * 11,
    % forall/2 — успіх, якщо Goal2 виконується для кожного розв'язку Goal1.
    % random_between/3 — генерує випадкове ціле число в діапазоні (вбудований).
    forall(
        (between(1, MaxPos, Pos), member(Color, [blue, red])),
        (random_between(1, 0x3FFFFFFF, Key),
         assertz(zobrist_key(Pos, Color, Key)))
    ).

:- init_zobrist.

% board_hash(++Board, --Hash).
% Обчислює Zobrist-хеш дошки (XOR ключів зайнятих клітинок).
board_hash(Board, Hash) :-
    board_hash_(Board, 1, 0, Hash).

% board_hash_(++Cells, ++Position, ++Accumulator, --Hash).
board_hash_([], _, H, H).
board_hash_([empty|T], Pos, Acc, Hash) :- !,
    Pos1 is Pos + 1,
    board_hash_(T, Pos1, Acc, Hash).
board_hash_([Color|T], Pos, Acc, Hash) :-
    zobrist_key(Pos, Color, Key),
    Acc1 is Acc xor Key,
    Pos1 is Pos + 1,
    board_hash_(T, Pos1, Acc1, Hash).

% move_hash(++OldHash, ++Size, ++Row, ++Col, ++Color, --NewHash).
% Інкрементальне оновлення хешу при додаванні фішки.
% XOR є оборотним: одна операція і для додавання, і для видалення.
move_hash(OldHash, Size, Row, Col, Color, NewHash) :-
    rc_to_index(Size, Row, Col, Pos),
    zobrist_key(Pos, Color, Key),
    NewHash is OldHash xor Key.

% Транспозиційна таблиця
% Зберігає оцінені позиції для уникнення повторних обчислень.
% Використовує assert/retract з індексацією по Hash (перший аргумент).

% tt_clear.
% Очищує транспозиційну таблицю поточного потоку.
tt_clear :- retractall(tt_entry(_, _, _, _, _)).

% tt_probe(++Hash, ++Depth, ++Alpha, ++Beta, --Alpha1, --Beta1,
%          --TTBest, --CutScore, --Cut).
% Шукає позицію в TT. Може звузити alpha/beta або повернути готовий результат.
% Єдине призначення: всі вхідні задані, завжди повертає значення (Cut = true | false).
tt_probe(Hash, Depth, Alpha, Beta, Alpha1, Beta1, TTBest, CutScore, Cut) :-
    (tt_entry(Hash, D, S, Flag, Best)
    -> TTBest = Best,
       (D >= Depth
       -> apply_tt_bounds(Flag, S, Alpha, Beta, Alpha1, Beta1, CutScore, Cut)
       ;  Alpha1 = Alpha, Beta1 = Beta, Cut = false
       )
    ;  TTBest = none, Alpha1 = Alpha, Beta1 = Beta, Cut = false
    ).

% apply_tt_bounds(++Flag, ++Score, ++Alpha, ++Beta,
%                 --Alpha1, --Beta1, --CutScore, --Cut).
% Коригує межі alpha/beta за типом запису TT (exact/lower/upper).
apply_tt_bounds(exact, S, _, _, _, _, S, true) :- !.
apply_tt_bounds(lower, S, Alpha, Beta, Alpha1, Beta1, CutScore, Cut) :- !,
    Alpha1 is max(Alpha, S),
    Beta1 = Beta,
    (Alpha1 >= Beta1 -> CutScore = S, Cut = true ; Cut = false).
apply_tt_bounds(upper, S, Alpha, Beta, Alpha1, Beta1, CutScore, Cut) :-
    Alpha1 = Alpha,
    Beta1 is min(Beta, S),
    (Alpha1 >= Beta1 -> CutScore = S, Cut = true ; Cut = false).

% tt_store(++Hash, ++Depth, ++Score, ++Flag, ++BestMove).
% Зберігає результат. Замінює старий запис якщо нова глибина >= старої.
tt_store(Hash, Depth, Score, Flag, BestMove) :-
    (tt_entry(Hash, OldD, _, _, _)
    -> (Depth >= OldD
       -> retract(tt_entry(Hash, _, _, _, _)),
          assertz(tt_entry(Hash, Depth, Score, Flag, BestMove))
       ;  true
       )
    ;  assertz(tt_entry(Hash, Depth, Score, Flag, BestMove))
    ).

% tt_store_ab(++Hash, ++Depth, ++Score, ++OrigAlpha, ++OrigBeta, ++BestMove).
% Визначає тип запису (exact/lower/upper) за alpha/beta і зберігає.
tt_store_ab(Hash, Depth, Score, OrigAlpha, OrigBeta, BestMove) :-
    (Score =< OrigAlpha -> Flag = upper
    ; Score >= OrigBeta -> Flag = lower
    ; Flag = exact
    ),
    tt_store(Hash, Depth, Score, Flag, BestMove).

% Впорядкування ходів

% order_moves(++Moves, ++Size, ++TTBest, --Ordered).
% Пріоритет: хід з TT першим, решта за відстанню до центру.
% map_list_to_pairs/3 — застосовує Goal до кожного елемента, утворюючи Key-Value пари.
% keysort/2 — сортує пари за ключем без видалення дублікатів (вбудований).
% pairs_values/2 — витягує значення з пар Key-Value (library(pairs)).
order_moves(Moves, Size, TTBest, Ordered) :-
    separate_tt(TTBest, Moves, TTMoves, Rest),
    Center is (Size + 1) / 2,
    map_list_to_pairs(move_priority(Center), Rest, Pairs),
    keysort(Pairs, Sorted),
    pairs_values(Sorted, SortedRest),
    append(TTMoves, SortedRest, Ordered).

% separate_tt(++TTBest, ++Moves, --TTMoves, --Rest).
% select/3 — видаляє перший входження елемента зі списку (вбудований).
separate_tt(none, Moves, [], Moves) :- !.
separate_tt(Best, Moves, [Best], Rest) :-
    select(Best, Moves, Rest), !.
separate_tt(_, Moves, [], Moves).

% move_priority(++Center, ++Move, --Priority).
% Менше значення = ближче до центру = вищий пріоритет.
move_priority(Center, R-C, Priority) :-
    Priority is abs(R - Center) + abs(C - Center).

% Головний предикат

% ai_move(++Board, ++Size, ++Player, --Row, --Col)
% Єдине призначення: задати стан дошки і гравця, отримати координати ходу.
% Обирає хід через ітеративне поглиблення + alpha-beta + TT.

% Дебют: на порожній дошці центр завжди оптимальний
ai_move(Board, Size, _, Row, Col) :-
    \+ (member(X, Board), X \= empty), !,
    Row is (Size + 1) // 2,
    Col = Row.

% Основний пошук (глибина за замовчуванням)
ai_move(Board, Size, Player, Row, Col) :-
    (max_depth(Size, MaxD) -> true ; MaxD = 3),
    ai_move(Board, Size, Player, MaxD, Row, Col).

% ai_move(++Board, ++Size, ++Player, ++Depth, --Row, --Col)
% Версія з явною глибиною пошуку
ai_move(_Board, Size, _, Depth, Row, Col) :-
    Depth =:= 0, !,
    Row is (Size + 1) // 2,
    Col = Row.
ai_move(Board, Size, _, _, Row, Col) :-
    \+ (member(X, Board), X \= empty), !,
    Row is (Size + 1) // 2,
    Col = Row.
ai_move(Board, Size, Player, Depth, Row, Col) :-
    tt_clear,
    board_hash(Board, Hash),
    is_maximizing(Player, IsMax),
    id_search(Board, Size, Player, Hash, IsMax, 1, Depth, Row-Col).

% id_search(++Board, ++Size, ++Player, ++Hash, ++IsMax,
%           ++CurrentDepth, ++MaxDepth, --BestMove)
% Ітеративне поглиблення: пошук від глибини 1 до MaxDepth.
% Кожна ітерація заповнює TT кращими ходами для наступної.
id_search(Board, Size, Player, Hash, IsMax, D, MaxD, BestMove) :-
    neg_inf(Alpha), inf(Beta),
    search_root(Board, Size, Player, Hash, IsMax, D, Alpha, Beta, Move),
    (D >= MaxD
    -> BestMove = Move
    ;  D1 is D + 1,
       id_search(Board, Size, Player, Hash, IsMax, D1, MaxD, BestMove)
    ).

% search_root(++Board, ++Size, ++Player, ++Hash, ++IsMax,
%             ++Depth, ++Alpha, ++Beta, --BestMove)
% Пошук кращого ходу на кореневому рівні
search_root(Board, Size, Player, Hash, IsMax, Depth, Alpha, Beta, BestMove) :-
    all_valid_moves(Board, Size, Moves),
    (tt_entry(Hash, _, _, _, TTBest) -> true ; TTBest = none),
    order_moves(Moves, Size, TTBest, OrderedMoves),
    OrigAlpha = Alpha,
    (IsMax = true
    -> neg_inf(Init),
       root_max(OrderedMoves, Board, Size, Player, Depth, Alpha, Beta,
                Hash, Init, none, BestMove, Score)
    ;  inf(Init),
       root_min(OrderedMoves, Board, Size, Player, Depth, Alpha, Beta,
                Hash, Init, none, BestMove, Score)
    ),
    tt_store_ab(Hash, Depth, Score, OrigAlpha, Beta, BestMove).

% root_max(++Moves, ++Board, ++Size, ++Player, ++Depth, ++Alpha, ++Beta,
%          ++Hash, ++Best, ++AccBM, --FinalBM, --FinalScore)
% Кореневий рівень для максимізуючого гравця (blue).
% Перебирає ходи, оцінює кожен через minimax_, зберігає найкращий.
root_max([], _, _, _, _, _, _, _, Best, BestM, BestM, Best) :- BestM \= none.
root_max([R-C|Rest], Board, Size, Player, Depth, Alpha, Beta,
         Hash, Best, AccBM, FinalBM, FinalScore) :-
    set_cell(Board, Size, R, C, Player, NB),
    opponent(Player, Opp),
    D1 is Depth - 1,
    move_hash(Hash, Size, R, C, Player, NH),
    minimax_(NB, Size, Opp, D1, Alpha, Beta, false, NH, MS),
    (AccBM = none -> Best1 = MS, BM1 = R-C
    ; MS > Best   -> Best1 = MS, BM1 = R-C
    ;                Best1 = Best, BM1 = AccBM
    ),
    Alpha1 is max(Alpha, Best1),
    (Alpha1 >= Beta
    -> FinalBM = BM1, FinalScore = Best1
    ;  root_max(Rest, Board, Size, Player, Depth, Alpha1, Beta,
               Hash, Best1, BM1, FinalBM, FinalScore)
    ).

% root_min(++Moves, ++Board, ++Size, ++Player, ++Depth, ++Alpha, ++Beta,
%          ++Hash, ++Best, ++AccBM, --FinalBM, --FinalScore)
% Кореневий рівень для мінімізуючого гравця (red).
% Симетричний до root_max, але обирає мінімальну оцінку.
root_min([], _, _, _, _, _, _, _, Best, BestM, BestM, Best) :- BestM \= none.
root_min([R-C|Rest], Board, Size, Player, Depth, Alpha, Beta,
         Hash, Best, AccBM, FinalBM, FinalScore) :-
    set_cell(Board, Size, R, C, Player, NB),
    opponent(Player, Opp),
    D1 is Depth - 1,
    move_hash(Hash, Size, R, C, Player, NH),
    minimax_(NB, Size, Opp, D1, Alpha, Beta, true, NH, MS),
    (AccBM = none -> Best1 = MS, BM1 = R-C
    ; MS < Best   -> Best1 = MS, BM1 = R-C
    ;                Best1 = Best, BM1 = AccBM
    ),
    Beta1 is min(Beta, Best1),
    (Alpha >= Beta1
    -> FinalBM = BM1, FinalScore = Best1
    ;  root_min(Rest, Board, Size, Player, Depth, Alpha, Beta1,
               Hash, Best1, BM1, FinalBM, FinalScore)
    ).

% Minimax з Alpha-Beta і TT

% minimax(++Board, ++Size, ++Player, ++Depth, ++Alpha, ++Beta,
%         ++IsMaximizing, --Score)
% Exported wrapper для зворотної сумісності з тестами
minimax(Board, Size, Player, Depth, Alpha, Beta, IsMax, Score) :-
    board_hash(Board, Hash),
    minimax_(Board, Size, Player, Depth, Alpha, Beta, IsMax, Hash, Score).

% minimax_(++Board, ++Size, ++Player, ++Depth, ++Alpha, ++Beta,
%          ++IsMaximizing, ++Hash, --Score)

% Термінальний стан: перевіряємо лише гравця, який щойно ходив.
% Player — гравець, який ходить наступним, отже щойно ходив opponent(Player).
minimax_(Board, Size, Player, _, _, _, _, _, Score) :-
    opponent(Player, LastMover),
    wins(Board, Size, LastMover), !,
    (LastMover = blue -> inf(Score) ; neg_inf(Score)).

% TT hit — перевіряємо TT перед оцінкою (кешує і листові вузли)
minimax_(_, _, _, Depth, Alpha, Beta, _, Hash, Score) :-
    tt_entry(Hash, D, S, Flag, _),
    D >= Depth,
    apply_tt_bounds(Flag, S, Alpha, Beta, _, _, CutScore, true), !,
    Score = CutScore.

% Глибина 0: евристична оцінка (з кешуванням в TT)
minimax_(Board, Size, _, 0, _, _, _, Hash, Score) :- !,
    evaluate(Board, Size, blue, Score),
    tt_store(Hash, 0, Score, exact, none).

% Немає вільних клітинок
minimax_(Board, Size, _, _, _, _, _, _, Score) :-
    all_valid_moves(Board, Size, []), !,
    evaluate(Board, Size, blue, Score).

% Основний пошук з TT
minimax_(Board, Size, Player, Depth, Alpha, Beta, IsMax, Hash, Score) :-
    OrigAlpha = Alpha,
    OrigBeta = Beta,
    tt_probe(Hash, Depth, Alpha, Beta, Alpha1, Beta1, TTBest, CutScore, Cut),
    (Cut = true
    -> Score = CutScore
    ;  all_valid_moves(Board, Size, Moves),
       order_moves(Moves, Size, TTBest, OrderedMoves),
       (IsMax = true
       -> neg_inf(Init),
          ab_max(OrderedMoves, Board, Size, Player, Depth, Alpha1, Beta1,
                 Hash, Init, none, Score, BestMove)
       ;  inf(Init),
          ab_min(OrderedMoves, Board, Size, Player, Depth, Alpha1, Beta1,
                 Hash, Init, none, Score, BestMove)
       ),
       tt_store_ab(Hash, Depth, Score, OrigAlpha, OrigBeta, BestMove)
    ).

% ab_max(++Moves, ++Board, ++Size, ++Player, ++Depth, ++Alpha, ++Beta,
%        ++Hash, ++Best, ++AccBM, --FinalScore, --FinalBM)
% Обхід ходів для максимізуючого гравця з alpha-beta відсіканням.
ab_max([], _, _, _, _, _, _, _, Best, BestM, Best, BestM).
ab_max([R-C|Rest], Board, Size, Player, Depth, Alpha, Beta,
       Hash, Best, AccBM, FinalScore, FinalBM) :-
    set_cell(Board, Size, R, C, Player, NB),
    opponent(Player, Opp),
    D1 is Depth - 1,
    move_hash(Hash, Size, R, C, Player, NH),
    minimax_(NB, Size, Opp, D1, Alpha, Beta, false, NH, MS),
    (AccBM = none -> Best1 = MS, BM1 = R-C
    ; MS > Best   -> Best1 = MS, BM1 = R-C
    ;                Best1 = Best, BM1 = AccBM
    ),
    Alpha1 is max(Alpha, Best1),
    (Alpha1 >= Beta
    -> FinalScore = Best1, FinalBM = BM1
    ;  ab_max(Rest, Board, Size, Player, Depth, Alpha1, Beta,
             Hash, Best1, BM1, FinalScore, FinalBM)
    ).

% ab_min(++Moves, ++Board, ++Size, ++Player, ++Depth, ++Alpha, ++Beta,
%        ++Hash, ++Best, ++AccBM, --FinalScore, --FinalBM)
% Обхід ходів для мінімізуючого гравця з alpha-beta відсіканням.
ab_min([], _, _, _, _, _, _, _, Best, BestM, Best, BestM).
ab_min([R-C|Rest], Board, Size, Player, Depth, Alpha, Beta,
       Hash, Best, AccBM, FinalScore, FinalBM) :-
    set_cell(Board, Size, R, C, Player, NB),
    opponent(Player, Opp),
    D1 is Depth - 1,
    move_hash(Hash, Size, R, C, Player, NH),
    minimax_(NB, Size, Opp, D1, Alpha, Beta, true, NH, MS),
    (AccBM = none -> Best1 = MS, BM1 = R-C
    ; MS < Best   -> Best1 = MS, BM1 = R-C
    ;                Best1 = Best, BM1 = AccBM
    ),
    Beta1 is min(Beta, Best1),
    (Alpha >= Beta1
    -> FinalScore = Best1, FinalBM = BM1
    ;  ab_min(Rest, Board, Size, Player, Depth, Alpha, Beta1,
             Hash, Best1, BM1, FinalScore, FinalBM)
    ).

% Евристична оцінка

% evaluate(++Board, ++Size, ++Player, --Score)
% Єдине призначення: оцінити позицію для Player = blue.
% Виклик evaluate(B, S, red, X) не підтримується — клаузи немає.
% Score = відстань red до з'єднання - відстань blue до з'єднання.
% Більше значення = краще для blue, менше = краще для red.
evaluate(Board, Size, blue, Score) :-
    shortest_path(Board, Size, blue, BlueDist),
    shortest_path(Board, Size, red, RedDist),
    Score is RedDist - BlueDist.

% Найкоротший шлях (Dijkstra)
% Обчислює мінімальну кількість порожніх клітинок для з'єднання сторін.
% Клітинки гравця: вартість 0, порожні: 1, суперника: непрохідні.

% shortest_path(++Board, ++Size, ++Player, --Distance)
shortest_path(Board, Size, Player, Distance) :-
    start_queue(Board, Size, Player, Queue),
    inf(Inf),
    sp_dijkstra(Board, Size, Player, Queue, [], Inf, Distance).

% start_queue(++Board, ++Size, ++Player, --Queue)
% blue починає з рядка 1, red — зі стовпця 1
start_queue(Board, Size, blue, Queue) :-
    findall(Cost-1-Col,
            (between(1, Size, Col),
             cell_at(Board, Size, 1, Col, Cell),
             cell_cost(Cell, blue, Cost),
             Cost < 10000),
            Queue0),
    msort(Queue0, Queue).
start_queue(Board, Size, red, Queue) :-
    findall(Cost-Row-1,
            (between(1, Size, Row),
             cell_at(Board, Size, Row, 1, Cell),
             cell_cost(Cell, red, Cost),
             Cost < 10000),
            Queue0),
    msort(Queue0, Queue).

% sp_dijkstra(++Board, ++Size, ++Player, ++Queue, ++Visited, ++BestSoFar, --Distance)
% BFS з пріоритетною чергою (Dijkstra-подібний).
% msort/2 — сортує список без видалення дублікатів (вбудований)
sp_dijkstra(_, _, _, [], _, Best, Best).
sp_dijkstra(Board, Size, Player, [Cost-Row-Col|Rest], Visited, Best, Distance) :-
    (member(Row-Col, Visited)
    -> sp_dijkstra(Board, Size, Player, Rest, Visited, Best, Distance)
    ;  (is_target(Player, Size, Row, Col)
       -> Distance is min(Best, Cost)
       ;  neighbors(Size, Row, Col, Nbrs),
          expand_nbrs(Board, Size, Player, Nbrs, Cost, Visited, NewEntries),
          append(Rest, NewEntries, Queue1),
          msort(Queue1, Queue2),
          sp_dijkstra(Board, Size, Player, Queue2, [Row-Col|Visited], Best, Distance)
       )
    ).

% is_target(++Player, ++Size, ++Row, ++Col)
% blue: рядок Size (низ), red: стовпець Size (право)
is_target(blue, Size, Size, _).
is_target(red, Size, _, Size).

% expand_nbrs(++Board, ++Size, ++Player, ++Neighbors, ++CurrentCost,
%             ++Visited, --NewEntries)
expand_nbrs(_, _, _, [], _, _, []).
expand_nbrs(Board, Size, Player, [NR-NC|Rest], CurrentCost, Visited, Entries) :-
    (member(NR-NC, Visited)
    -> expand_nbrs(Board, Size, Player, Rest, CurrentCost, Visited, Entries)
    ;  cell_at(Board, Size, NR, NC, Cell),
       cell_cost(Cell, Player, StepCost),
       (StepCost >= 10000
       -> expand_nbrs(Board, Size, Player, Rest, CurrentCost, Visited, Entries)
       ;  NewCost is CurrentCost + StepCost,
          expand_nbrs(Board, Size, Player, Rest, CurrentCost, Visited, RestEntries),
          Entries = [NewCost-NR-NC | RestEntries]
       )
    ).

% cell_cost(++Cell, ++Player, --Cost)
% Єдине призначення: задати Cell і Player, отримати Cost.
% Зворотній напрямок (Cost → Cell) не має сенсу: кілька Cell
% можуть мати однакову вартість.
% Клітинка гравця: 0, порожня: 1, суперника: 10000 (непрохідна).
cell_cost(Player, Player, 0) :- !.
cell_cost(empty, _, 1) :- !.
cell_cost(_, _, 10000).
