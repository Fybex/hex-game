import { describe, it, expect, vi, beforeEach } from 'vitest';
import { newGame, makeMove, getState, healthCheck, aiMove, isBackendUnavailableError } from '$lib/api';

const mockFetch = vi.fn();
vi.stubGlobal('fetch', mockFetch);

function jsonResponse(data: unknown, status = 200) {
	return new Response(JSON.stringify(data), {
		status,
		headers: { 'Content-Type': 'application/json' }
	});
}

beforeEach(() => {
	mockFetch.mockReset();
});

describe('API client', () => {
	it('newGame sends correct request', async () => {
		const mockState = {
			game_id: 'test-123',
			state: { board: [], size: 5, status: 'playing' }
		};
		mockFetch.mockResolvedValueOnce(jsonResponse(mockState));

		const result = await newGame(5, 'blue');

		expect(mockFetch).toHaveBeenCalledWith('/api/new_game', expect.objectContaining({
			method: 'POST',
			body: JSON.stringify({ size: 5, human_color: 'blue', mode: 'human_vs_ai' })
		}));
		expect(result.game_id).toBe('test-123');
	});

	it('makeMove sends correct request', async () => {
		const mockResponse = {
			state: { board: [], status: 'playing' },
			ai_move: { row: 2, col: 3 }
		};
		mockFetch.mockResolvedValueOnce(jsonResponse(mockResponse));

		const result = await makeMove('game-1', 1, 1);

		expect(mockFetch).toHaveBeenCalledWith('/api/move', expect.objectContaining({
			method: 'POST',
			body: JSON.stringify({ game_id: 'game-1', row: 1, col: 1 })
		}));
		expect(result.ai_move).toEqual({ row: 2, col: 3 });
	});

	it('aiMove sends correct request', async () => {
		const mockResponse = {
			state: { board: [], status: 'playing' },
			ai_move: { row: 3, col: 3 }
		};
		mockFetch.mockResolvedValueOnce(jsonResponse(mockResponse));

		const result = await aiMove('game-1');

		expect(mockFetch).toHaveBeenCalledWith('/api/ai_move', expect.objectContaining({
			method: 'POST',
			body: JSON.stringify({ game_id: 'game-1' })
		}));
		expect(result.ai_move).toEqual({ row: 3, col: 3 });
	});

	it('getState fetches game state', async () => {
		const mockResponse = { state: { board: [], size: 5 } };
		mockFetch.mockResolvedValueOnce(jsonResponse(mockResponse));

		const result = await getState('game-1');

		expect(mockFetch).toHaveBeenCalledWith(
			'/api/state?game_id=game-1',
			expect.objectContaining({ headers: { 'Content-Type': 'application/json' } })
		);
		expect(result.state.size).toBe(5);
	});

	it('healthCheck returns true on success', async () => {
		mockFetch.mockResolvedValueOnce(jsonResponse({ status: 'ok' }));
		expect(await healthCheck()).toBe(true);
	});

	it('healthCheck returns false on error', async () => {
		mockFetch.mockRejectedValueOnce(new Error('Network error'));
		expect(await healthCheck()).toBe(false);
	});

	it('throws on non-200 response', async () => {
		mockFetch.mockResolvedValueOnce(jsonResponse({ error: 'Invalid move' }, 400));

		await expect(makeMove('game-1', 1, 1)).rejects.toThrow('Invalid move');
	});

	it('maps network failures to backend unavailable errors', async () => {
		mockFetch.mockRejectedValueOnce(new TypeError('fetch failed'));

		try {
			await newGame(5, 'blue');
			throw new Error('Expected newGame to fail');
		} catch (error) {
			expect(isBackendUnavailableError(error)).toBe(true);
		}
	});

	it('maps request timeouts to backend unavailable errors', async () => {
		mockFetch.mockRejectedValueOnce(new DOMException('The operation was aborted.', 'AbortError'));

		try {
			await aiMove('game-1');
			throw new Error('Expected aiMove to fail');
		} catch (error) {
			expect(isBackendUnavailableError(error)).toBe(true);
		}
	});
});
