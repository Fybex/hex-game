<script lang="ts">
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { game } from '$lib/stores/game.svelte';
	import { _ } from 'svelte-i18n';
	import AppHeader from '$lib/components/AppHeader.svelte';
	import GameSidebar from '$lib/components/GameSidebar.svelte';
	import HexBoard from '$lib/components/HexBoard.svelte';

	onMount(() => {
		if (!game.state) {
			void goto('/');
		}
	});

	function handleCellClick(row: number, col: number) {
		game.makeMove(row, col);
	}

	function handleNewGame() {
		game.stopAutoPlay();
		void goto('/');
	}
</script>

<svelte:head>
	<title>{$_('app.title')}</title>
</svelte:head>

<div class="page">
	<AppHeader subtitle={game.state ? $_('app.boardSize', { values: { size: game.size } }) : null} />

	{#if game.state}
		<div class="game-layout">
			<div class="board-area">
				<HexBoard
					board={game.board}
					size={game.size}
					disabled={!game.canPlayCell}
					humanColor={game.humanColor}
					winner={game.winner}
					status={game.status}
					onCellClick={handleCellClick}
				/>
			</div>

			<GameSidebar
				status={game.status}
				winner={game.winner}
				currentPlayer={game.currentPlayer}
				humanColor={game.humanColor}
				isThinking={game.isThinking}
				mode={game.mode}
				depth={game.depth}
				moves={game.moves}
				autoPlay={game.autoPlay}
				canAdvanceAi={game.canAdvanceAi}
				onToggleAutoPlay={(enabled) => game.setAutoPlay(enabled)}
				onNextAiMove={() => void game.aiStep()}
				onNewGame={handleNewGame}
			/>
		</div>

		{#if game.error}
			<div class="error-toast" data-testid="error-message">{game.error}</div>
		{/if}
	{/if}
</div>

<style>
	.page {
		min-height: 100vh;
		display: flex;
		flex-direction: column;
		padding: 16px 16px 24px;
	}

	.game-layout {
		width: min(100%, 1240px);
		margin: 0 auto;
		display: grid;
		grid-template-columns: minmax(0, 1fr) 280px;
		align-items: start;
		gap: 28px;
		padding-top: 8px;
	}

	.board-area {
		width: min(100%, 940px);
		display: flex;
		justify-content: center;
		align-items: center;
		min-width: 0;
	}

	.error-toast {
		position: fixed;
		bottom: 24px;
		left: 50%;
		transform: translateX(-50%);
		background: rgba(255, 90, 90, 0.12);
		border: 1px solid rgba(255, 90, 90, 0.25);
		color: var(--red);
		padding: 8px 16px;
		border-radius: 8px;
		font-size: 0.8rem;
	}

	@media (max-width: 960px) {
		:global(.sidebar) {
			max-width: 420px;
		}

		.game-layout {
			grid-template-columns: 1fr;
			justify-items: center;
		}
	}

	@media (max-width: 640px) {
		.page {
			padding-inline: 12px;
		}
	}
</style>
