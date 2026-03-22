% Hex: сховище станів гри
% Ізолює runtime-зберігання ігор від доменної логіки
:- module(game_store, [
    store_game/2,
    replace_game/2,
    lookup_game/2,
    delete_game/1
]).

% dynamic game(GameId, State) — зберігає поточний стан кожної гри
:- dynamic game/2.

% store_game(++GameId, ++State)
% Єдине призначення: зберегти нову гру в пам'яті.
% assertz/1 — додає dynamic fact в кінець бази (вбудований).
store_game(GameId, State) :-
    assertz(game(GameId, State)).

% replace_game(++GameId, ++State)
% Єдине призначення: замінити стан існуючої гри.
% retractall/1 — видаляє всі факти, що збігаються з шаблоном (вбудований).
replace_game(GameId, State) :-
    retractall(game(GameId, _)),
    assertz(game(GameId, State)).

% lookup_game(++GameId, --State)
% Єдине призначення: знайти гру за ідентифікатором.
% Може бути невдалим (fail), якщо гри з таким GameId не існує.
lookup_game(GameId, State) :-
    game(GameId, State).

% delete_game(++GameId)
% Єдине призначення: видалити гру зі сховища.
delete_game(GameId) :-
    retractall(game(GameId, _)).
