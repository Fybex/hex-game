import type { NewGameResponse, MoveResponse, StateResponse, Player, GameMode } from './types';

const BASE_URL = '/api';
const REQUEST_TIMEOUT_MS = 120000;
const BACKEND_UNAVAILABLE = 'BACKEND_UNAVAILABLE';

function createTimeoutController(timeoutMs: number) {
	const controller = new AbortController();
	const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

	return {
		signal: controller.signal,
		cancel() {
			clearTimeout(timeoutId);
		}
	};
}

async function request<T>(path: string, options?: RequestInit): Promise<T> {
	let response: Response;
	const timeout = createTimeoutController(REQUEST_TIMEOUT_MS);

	try {
		response = await fetch(`${BASE_URL}${path}`, {
			headers: { 'Content-Type': 'application/json' },
			signal: timeout.signal,
			...options
		});
	} catch (error) {
		if (error instanceof DOMException && error.name === 'AbortError') {
			throw new Error(BACKEND_UNAVAILABLE);
		}

		if (error instanceof TypeError) {
			throw new Error(BACKEND_UNAVAILABLE);
		}

		throw error;
	} finally {
		timeout.cancel();
	}

	if (!response.ok) {
		const error = await response.json().catch(() => ({ error: 'Unknown error' }));
		throw new Error(error.error || `HTTP ${response.status}`);
	}

	return response.json();
}

export async function newGame(
	size: number = 5,
	humanColor: Player = 'blue',
	depth?: number,
	mode: GameMode = 'human_vs_ai'
): Promise<NewGameResponse> {
	const body: Record<string, unknown> = { size, human_color: humanColor, mode };
	if (depth !== undefined) body.depth = depth;
	return request<NewGameResponse>('/new_game', {
		method: 'POST',
		body: JSON.stringify(body)
	});
}

export async function makeMove(gameId: string, row: number, col: number): Promise<MoveResponse> {
	return request<MoveResponse>('/move', {
		method: 'POST',
		body: JSON.stringify({ game_id: gameId, row, col })
	});
}

export async function aiMove(gameId: string): Promise<MoveResponse> {
	return request<MoveResponse>('/ai_move', {
		method: 'POST',
		body: JSON.stringify({ game_id: gameId })
	});
}

export async function getState(gameId: string): Promise<StateResponse> {
	return request<StateResponse>(`/state?game_id=${gameId}`);
}

export async function healthCheck(): Promise<boolean> {
	try {
		await request('/health');
		return true;
	} catch {
		return false;
	}
}

export function isBackendUnavailableError(error: unknown): boolean {
	return error instanceof Error && error.message === BACKEND_UNAVAILABLE;
}
