<script lang="ts">
	import type { GameStatus as Status, GameMode, Move, Player } from '$lib/types';
	import { _ } from 'svelte-i18n';
	import GameStatus from '$lib/components/GameStatus.svelte';
	import GoalPreview from '$lib/components/GoalPreview.svelte';
	import HelpLink from '$lib/components/HelpLink.svelte';
	import MoveHistory from '$lib/components/MoveHistory.svelte';

	interface Props {
		status: Status;
		winner: Player | null;
		currentPlayer: Player | 'none';
		humanColor: Player;
		isThinking: boolean;
		mode: GameMode;
		depth: number;
		moves: Move[];
		autoPlay: boolean;
		canAdvanceAi: boolean;
		onToggleAutoPlay: (enabled: boolean) => void;
		onNextAiMove: () => void;
		onNewGame: () => void;
	}

	let {
		status,
		winner,
		currentPlayer,
		humanColor,
		isThinking,
		mode,
		depth,
		moves,
		autoPlay,
		canAdvanceAi,
		onToggleAutoPlay,
		onNextAiMove,
		onNewGame
	}: Props = $props();
</script>

<aside class="sidebar">
	<div class="status-wrap">
		<GameStatus
			{status}
			{winner}
			{currentPlayer}
			{humanColor}
			{isThinking}
			{mode}
		/>
	</div>

	<div class="player-card">
		{#if mode === 'human_vs_ai'}
			<div class="card-head">
				<div class="player-label">{$_('sidebar.youArePlaying')}</div>
				<HelpLink />
			</div>
			<div class="player-role">
				<span class:blue-text={humanColor === 'blue'} class:red-text={humanColor === 'red'}>
					{humanColor === 'blue' ? $_('colors.blue') : $_('colors.red')}
				</span>
			</div>
			<div class="goal-row">
				<span class="goal-order">{humanColor === 'blue' ? $_('dialog.blueHint') : $_('dialog.redHint')}</span>
				<GoalPreview orientation={humanColor === 'blue' ? 'vertical' : 'horizontal'} compact={true} />
			</div>
		{:else if mode === 'human_vs_human'}
			<div class="card-head">
				<div class="player-label">{$_('sidebar.mode')}</div>
				<HelpLink />
			</div>
			<div class="player-role">{$_('mode.humanVsHuman')}</div>
			<div class="sides-grid">
				<div class="side-item">
					<span class="blue-text">{$_('colors.blue')}</span>
					<GoalPreview orientation="vertical" compact={true} />
				</div>
				<div class="side-item">
					<span class="red-text">{$_('colors.red')}</span>
					<GoalPreview orientation="horizontal" compact={true} />
				</div>
			</div>
		{:else}
			<div class="card-head">
				<div class="player-label">{$_('sidebar.mode')}</div>
				<HelpLink />
			</div>
			<div class="player-role">{$_('mode.aiVsAi')}</div>
			<div class="sides-grid">
				<div class="side-item">
					<span class="blue-text">{$_('colors.blue')}</span>
					<GoalPreview orientation="vertical" compact={true} />
				</div>
				<div class="side-item">
					<span class="red-text">{$_('colors.red')}</span>
					<GoalPreview orientation="horizontal" compact={true} />
				</div>
			</div>
		{/if}

		{#if mode !== 'human_vs_human'}
			<div class="meta-row">
				<span class="player-label">{$_('sidebar.depth')}</span>
				<span class="depth-value">{depth}</span>
			</div>
		{/if}
	</div>

	{#if mode === 'ai_vs_ai'}
		<div class="controls-card">
			<div class="player-label">{$_('sidebar.controls')}</div>
			<div class="controls-actions">
				<button
					type="button"
					class="control-btn"
					onclick={() => onToggleAutoPlay(!autoPlay)}
				>
					{autoPlay ? $_('sidebar.pause') : $_('sidebar.autoPlay')}
				</button>
				<button
					type="button"
					class="control-btn"
					disabled={!canAdvanceAi || autoPlay}
					onclick={onNextAiMove}
				>
					{$_('sidebar.nextMove')}
				</button>
			</div>
		</div>
	{/if}

	<MoveHistory {moves} {humanColor} {mode} />

	<button
		class="new-game-btn"
		data-testid="new-game-btn"
		onclick={onNewGame}
	>
		{$_('sidebar.newGame')}
	</button>
</aside>

<style>
	.sidebar {
		width: 100%;
		display: flex;
		flex-direction: column;
		gap: 14px;
	}

	.status-wrap {
		width: 100%;
	}

	.player-card {
		padding: 14px 16px;
		background: var(--surface-1);
		border: 1px solid var(--border);
		border-radius: 12px;
	}

	.player-label {
		font-size: 0.86rem;
		font-weight: 600;
		color: var(--text-secondary);
	}

	.card-head {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 10px;
	}

	.player-role {
		margin-top: 8px;
		font-size: 1.2rem;
		font-weight: 700;
	}

	.meta-row {
		margin-top: 12px;
		padding-top: 12px;
		border-top: 1px solid var(--border);
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 12px;
	}

	.depth-value {
		font-family: 'JetBrains Mono', monospace;
		font-size: 0.82rem;
		font-weight: 700;
		color: var(--text-primary);
	}

	.blue-text { color: var(--blue); font-weight: 700; }
	.red-text { color: var(--red); font-weight: 700; }

	.goal-row {
		margin-top: 10px;
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 12px;
	}

	.goal-order {
		font-size: 0.74rem;
		color: var(--text-muted);
	}

	.sides-grid {
		margin-top: 12px;
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 10px;
	}

	.side-item {
		padding: 10px;
		border-radius: 10px;
		background: var(--surface-2);
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 8px;
	}

	.controls-card {
		padding: 14px 16px;
		background: var(--surface-1);
		border: 1px solid var(--border);
		border-radius: 12px;
	}

	.controls-actions {
		margin-top: 10px;
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 8px;
	}

	.control-btn {
		padding: 10px 12px;
		border: 1px solid var(--border);
		border-radius: 10px;
		background: var(--surface-2);
		color: var(--text-primary);
		font-family: 'Outfit', system-ui, sans-serif;
		font-size: 0.8rem;
		font-weight: 600;
		cursor: pointer;
		transition: background 0.12s ease, border-color 0.12s ease, opacity 0.12s ease;
	}

	.control-btn:hover {
		background: var(--surface-3);
		border-color: var(--text-secondary);
	}

	.control-btn:disabled {
		cursor: default;
		opacity: 0.45;
	}

	.new-game-btn {
		width: 100%;
		padding: 11px 18px;
		border: 1px solid var(--border);
		border-radius: 10px;
		background: var(--surface-1);
		color: var(--text-primary);
		font-family: 'Outfit', system-ui, sans-serif;
		font-size: 0.84rem;
		font-weight: 600;
		cursor: pointer;
		transition: background 0.12s ease, border-color 0.12s ease;
	}

	.new-game-btn:hover {
		background: var(--surface-2);
		border-color: var(--text-secondary);
	}
</style>
