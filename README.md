# Hex Game

A Hex board game with AI opponent, built with SWI-Prolog (backend) and SvelteKit (frontend).

## Project Structure

```
backend/
  ai.pl            — AI: Minimax + Alpha-Beta, TT, Zobrist, Dijkstra heuristic
  game_logic.pl    — Board, moves, neighbors, win detection (BFS)
  game_state.pl    — Game lifecycle: create, move, AI turn
  game_store.pl    — Runtime storage of active games (dynamic facts)
  game_json.pl     — State serialization to JSON
  server.pl        — HTTP server, routing, CORS
  tests/           — plunit test suites

frontend/
  src/             — SvelteKit application
  tests/unit/      — Vitest unit tests
  tests/e2e/       — Playwright end-to-end tests
```

## Prerequisites

- [SWI-Prolog](https://www.swi-prolog.org/) (10.x+)
- [Node.js](https://nodejs.org/) (18+)

## Getting Started

### Backend

```bash
swipl backend/server.pl
?- start_server(8080).
```

The server starts on `http://localhost:8080` with 5 API endpoints:
- `POST /api/new_game` — create a new game
- `POST /api/move` — make a human move
- `POST /api/ai_move` — trigger one AI move (for AI vs AI mode)
- `GET /api/state?game_id=...` — get current game state
- `GET /api/health` — health check

### Frontend

```bash
cd frontend
npm install
npm run dev
```

Opens at `http://localhost:5173`. Requires backend running on port 8080.

## Game Modes

| Mode | Description |
|------|-------------|
| Human vs AI | Play against the AI |
| AI vs AI | Watch two AI instances play each other |
| Human vs Human | Two players on the same device |

Board sizes from 3x3 to 11x11. AI search depth is configurable (in half-moves).

Default depths per board size: 3x3 → 10, 5x5 → 5, 7x7 → 4, 11x11 → 2.

## Running Tests

### Backend (plunit)

```bash
# All tests
swipl -l backend/tests/run_tests.pl -g "run_all" -t halt

# Individual suites
swipl -l backend/tests/test_game_logic.pl -g "run_tests" -t halt
swipl -l backend/tests/test_ai.pl -g "run_tests" -t halt
swipl -l backend/tests/test_api.pl -g "run_tests" -t halt

# Comprehensive AI tests (slower — plays full games)
swipl -l backend/tests/test_comprehensive_ai.pl -g "run_tests(comprehensive_ai)" -t halt
```

### Frontend

```bash
cd frontend
npm install

# Unit tests
npx vitest run

# E2E tests (requires backend running)
npx playwright install
npx playwright test
```

## AI Algorithms

The AI uses several techniques combined via iterative deepening:

- **Minimax** with configurable depth (in half-moves)
- **Alpha-Beta pruning** — reduces search from b^d to b^(d/2) nodes under ideal ordering
- **Transposition table** with **Zobrist hashing** — avoids re-evaluating identical positions
- **Move ordering** — TT-best move first, then by Manhattan distance to center
- **Shortest path heuristic** — Dijkstra-based evaluation: cost of connecting sides for each player
- **Opening book** — center cell on empty board (instant first move)

## Use of Generative AI

Generative AI tools were used during development for:
- Writing frontend tests (Vitest unit tests, Playwright E2E scenarios)
- Code review and advice on idiomatic SWI-Prolog patterns
- Literature search for game AI optimizations (Alpha-Beta, Zobrist hashing, iterative deepening)
- Presentation preparation and structuring

All algorithmic decisions, architecture design, and Prolog game logic were implemented manually.
