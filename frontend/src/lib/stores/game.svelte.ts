import type { GameState, Player, Move, GameMode } from '$lib/types';
import * as api from '$lib/api';
import { translate } from '$lib/i18n';

class GameStore {
	gameId = $state<string | null>(null);
	state = $state<GameState | null>(null);
	isThinking = $state(false);
	error = $state<string | null>(null);
	autoPlay = $state(false);
	private autoPlayTimer: ReturnType<typeof setTimeout> | null = null;

	get board() {
		return this.state?.board ?? [];
	}

	get size() {
		return this.state?.size ?? 5;
	}

	get depth() {
		return this.state?.depth ?? 5;
	}

	get currentPlayer() {
		return this.state?.current_player ?? 'blue';
	}

	get status() {
		return this.state?.status ?? 'playing';
	}

	get winner() {
		return this.state?.winner ?? null;
	}

	get moves(): Move[] {
		return this.state?.moves ?? [];
	}

	get humanColor(): Player {
		return this.state?.human_color ?? 'blue';
	}

	get aiColor(): Player {
		return this.state?.ai_color ?? 'red';
	}

	get mode(): GameMode {
		return this.state?.mode ?? 'human_vs_ai';
	}

	get isHumanTurn() {
		if (this.mode !== 'human_vs_ai') return false;
		return this.status === 'playing' && this.currentPlayer === this.humanColor && !this.isThinking;
	}

	get canPlayCell() {
		if (!this.state || this.status !== 'playing' || this.isThinking) return false;
		if (this.mode === 'human_vs_ai') return this.currentPlayer === this.humanColor;
		return this.mode === 'human_vs_human';
	}

	get canAdvanceAi() {
		return this.mode === 'ai_vs_ai' && this.status === 'playing' && !this.isThinking && !!this.gameId;
	}

	private cloneState(state: GameState): GameState {
		return {
			...state,
			board: state.board.map((row) => [...row]),
			moves: state.moves.map((move) => ({ ...move }))
		};
	}

	private opponent(player: Player): Player {
		return player === 'blue' ? 'red' : 'blue';
	}

	private applyOptimisticMove(state: GameState, row: number, col: number): GameState {
		const nextState = this.cloneState(state);
		const currentPlayer = state.current_player === 'red' ? 'red' : 'blue';
		const movePlayer = this.mode === 'human_vs_human' ? currentPlayer : this.humanColor;

		nextState.board[row][col] = movePlayer;
		nextState.moves = [
			...nextState.moves,
			{ player: movePlayer, row, col }
		];
		nextState.current_player = this.opponent(movePlayer);

		return nextState;
	}

	private clearAutoPlayTimer() {
		if (this.autoPlayTimer !== null) {
			clearTimeout(this.autoPlayTimer);
			this.autoPlayTimer = null;
		}
	}

	private scheduleAutoPlay() {
		this.clearAutoPlayTimer();

		if (!(this.autoPlay && this.canAdvanceAi)) return;

		this.autoPlayTimer = setTimeout(() => {
			void this.aiStep();
		}, 500);
	}

	private getErrorMessage(error: unknown, fallbackKey: string) {
		if (api.isBackendUnavailableError(error)) {
			return translate('errors.backendUnavailable');
		}

		return error instanceof Error ? error.message : translate(fallbackKey);
	}

	setAutoPlay(enabled: boolean) {
		this.autoPlay = enabled && this.mode === 'ai_vs_ai';
		if (!this.autoPlay) {
			this.clearAutoPlayTimer();
			return;
		}
		this.scheduleAutoPlay();
	}

	stopAutoPlay() {
		this.autoPlay = false;
		this.clearAutoPlayTimer();
	}

	async newGame(
		size: number = 5,
		humanColor: Player = 'blue',
		depth?: number,
		mode: GameMode = 'human_vs_ai'
	) {
		this.error = null;
		this.isThinking = false;
		this.autoPlay = false;
		this.clearAutoPlayTimer();
		try {
			const response = await api.newGame(size, humanColor, depth, mode);
			this.gameId = response.game_id;
			this.state = response.state;
		} catch (e) {
			this.error = this.getErrorMessage(e, 'errors.failedCreateGame');
		}
	}

	async makeMove(row: number, col: number) {
		if (!this.gameId || !this.canPlayCell || !this.state) return;

		this.error = null;
		const previousState = this.cloneState(this.state);
		this.state = this.applyOptimisticMove(this.state, row, col);
		this.isThinking = true;

		try {
			// Frontend uses 0-based indices, backend uses 1-based
			const response = await api.makeMove(this.gameId, row + 1, col + 1);
			this.state = response.state;
		} catch (e) {
			this.state = previousState;
			this.error = this.getErrorMessage(e, 'errors.invalidMove');
		} finally {
			this.isThinking = false;
		}
	}

	async aiStep() {
		if (!this.gameId || !this.canAdvanceAi) return;

		this.error = null;
		this.isThinking = true;

		try {
			const response = await api.aiMove(this.gameId);
			this.state = response.state;
		} catch (e) {
			this.error = this.getErrorMessage(e, 'errors.failedAiMove');
			this.autoPlay = false;
		} finally {
			this.isThinking = false;
			this.scheduleAutoPlay();
		}
	}
}

export const game = new GameStore();
