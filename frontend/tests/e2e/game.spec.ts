import { test, expect, type Page } from '@playwright/test';
import type { CellValue, GameMode, GameState } from '$lib/types';

function createState(size: number, mode: GameMode = 'human_vs_ai'): GameState {
	const board: CellValue[][] = Array.from({ length: size }, () =>
		Array.from({ length: size }, () => null as CellValue)
	);

	return {
		board,
		size,
		current_player: 'blue',
		status: 'playing',
		winner: null,
		moves: [],
		human_color: 'blue',
		ai_color: 'red',
		depth: size === 3 ? 10 : 5,
		mode
	};
}

async function mockNewGame(page: Page, size = 3, mode: GameMode = 'human_vs_ai') {
	await page.route('**/api/new_game', async (route) => {
		await route.fulfill({
			status: 200,
			contentType: 'application/json',
			body: JSON.stringify({
				game_id: 'game-1',
				state: createState(size, mode)
			})
		});
	});
}

test.describe('Hex Game E2E', () => {
	test('shows start screen on load', async ({ page }) => {
		await page.goto('/');

		const menu = page.getByTestId('start-game-panel');
		await expect(menu).toBeVisible();
		await expect(menu.getByText('New Game')).toBeVisible();
		await expect(page.getByTestId('hex-board')).toHaveCount(0);
	});

	test('starts a new game and shows board', async ({ page }) => {
		await mockNewGame(page, 3);
		await page.goto('/');

		// Select 3x3 by clicking the size button
		await page.getByRole('button', { name: '3x3' }).click();
		await page.getByTestId('start-game-btn').click();

		// Board should appear
		const board = page.getByTestId('hex-board');
		await expect(board).toBeVisible({ timeout: 10000 });

		// Status should show player turn
		const status = page.getByTestId('game-status');
		await expect(status).toContainText('Your turn');
		await expect(page).toHaveURL(/\/game$/);
	});

	test('clicking a cell places a stone and AI responds', async ({ page }) => {
		await mockNewGame(page, 3);
		await page.route('**/api/move', async (route) => {
			const state = createState(3);
			state.board[0][0] = 'blue';
			state.board[1][1] = 'red';
			state.moves = [
				{ player: 'blue', row: 0, col: 0 },
				{ player: 'red', row: 1, col: 1 }
			];

			await route.fulfill({
				status: 200,
				contentType: 'application/json',
				body: JSON.stringify({
					state,
					ai_move: { row: 2, col: 2 }
				})
			});
		});

		await page.goto('/');

		await page.getByRole('button', { name: '3x3' }).click();
		await page.getByTestId('start-game-btn').click();

		const board = page.getByTestId('hex-board');
		await expect(board).toBeVisible({ timeout: 10000 });

		// Click a hex cell
		const cell = page.getByLabel('Cell 0,0');
		await expect(cell).toBeVisible();
		await cell.click();

		// Wait for AI to respond
		const status = page.getByTestId('game-status');
		await expect(status).toContainText(/(Your turn|You win|AI wins)/, { timeout: 30000 });
	});

	test('can return to the start screen after a game begins', async ({ page }) => {
		await mockNewGame(page, 5);
		await page.goto('/');

		// Start first game (default 5x5)
		await page.getByTestId('start-game-btn').click();
		await expect(page.getByTestId('hex-board')).toBeVisible({ timeout: 10000 });

		// Return to menu
		await page.getByTestId('new-game-btn').click();
		await expect(page).toHaveURL('/');
		await expect(page.getByTestId('start-game-panel')).toBeVisible();
		await expect(page.getByTestId('hex-board')).toHaveCount(0);
	});

	test('supports two-player mode without an AI reply', async ({ page }) => {
		await mockNewGame(page, 3, 'human_vs_human');
		await page.route('**/api/move', async (route) => {
			const state = createState(3, 'human_vs_human');
			state.board[0][0] = 'blue';
			state.moves = [{ player: 'blue', row: 0, col: 0 }];
			state.current_player = 'red';

			await route.fulfill({
				status: 200,
				contentType: 'application/json',
				body: JSON.stringify({
					state,
					ai_move: null
				})
			});
		});

		await page.goto('/');
		await page.getByRole('button', { name: 'Two players' }).click();
		await page.getByRole('button', { name: '3x3' }).click();
		await page.getByTestId('start-game-btn').click();

		await expect(page.getByTestId('hex-board')).toBeVisible({ timeout: 10000 });
		await expect(page.getByTestId('game-status')).toContainText('Blue to move');

		await page.getByLabel('Cell 0,0').click();
		await expect(page.getByTestId('game-status')).toContainText('Red to move');
	});

	test('shows an error when backend does not respond', async ({ page }) => {
		await page.route('**/api/new_game', async (route) => {
			await route.abort('failed');
		});

		await page.goto('/');
		await page.getByTestId('start-game-btn').click();

		await expect(page.getByTestId('error-message')).toContainText(/backend is not responding/i);
	});
});
