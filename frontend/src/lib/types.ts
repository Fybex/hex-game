export type Player = 'blue' | 'red';
export type CellValue = Player | null;
export type GameStatus = 'playing' | 'finished';
export type GameMode = 'human_vs_ai' | 'ai_vs_ai' | 'human_vs_human';

export interface Move {
	player: Player;
	row: number;
	col: number;
}

export interface GameState {
	board: CellValue[][];
	size: number;
	current_player: Player | 'none';
	status: GameStatus;
	winner: Player | null;
	moves: Move[];
	human_color: Player;
	ai_color: Player;
	depth: number;
	mode: GameMode;
}

export interface NewGameResponse {
	game_id: string;
	state: GameState;
}

export interface MoveResponse {
	state: GameState;
	ai_move: { row: number; col: number } | null;
}

export interface StateResponse {
	state: GameState;
}
