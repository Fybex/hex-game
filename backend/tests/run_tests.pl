% Запуск всіх тестів бекенду
% Використання: swipl -l run_tests.pl -g "run_all" -t halt

:- use_module(library(plunit)).

tests_dir(Dir) :-
    source_file(with_tests_dir(_), Path),
    file_directory_name(Path, Dir).

with_tests_dir(Goal) :-
    tests_dir(Dir),
    setup_call_cleanup(
        working_directory(PrevDir, Dir),
        Goal,
        working_directory(_, PrevDir)
    ).

run_all :-
    with_tests_dir((
        load_files([test_game_logic, test_ai, test_api], []),
        run_tests
    )),
    halt(0).

run_all :- halt(1).

% Окремо API тести (потребують сервера)
run_api_tests :-
    with_tests_dir((
        load_files([test_api], []),
        run_tests
    )),
    halt(0).

run_api_tests :- halt(1).

run_comprehensive_ai_tests :-
    with_tests_dir((
        load_files([test_comprehensive_ai], []),
        run_tests(comprehensive_ai)
    )),
    halt(0).

run_comprehensive_ai_tests :- halt(1).
