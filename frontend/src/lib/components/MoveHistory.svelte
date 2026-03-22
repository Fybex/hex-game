<script lang="ts">
	import type { Move, Player, GameMode } from '$lib/types';
	import { _ } from 'svelte-i18n';

	interface Props {
		moves: Move[];
		humanColor: Player;
		mode: GameMode;
	}

	let { moves, humanColor, mode }: Props = $props();

	const LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

	function formatCoord(row: number, col: number) {
		return `${LETTERS[col] ?? '?'}${row + 1}`;
	}
</script>

<div class="history">
	<div class="history-header">
		<span>{$_('moves.title')}</span>
		<span class="history-count">{moves.length}</span>
	</div>
	{#if moves.length === 0}
		<p class="empty-msg">{$_('moves.empty')}</p>
	{:else}
		<div class="move-list" data-testid="move-history">
			{#each moves as move, idx}
				<div class="move-row" class:is-you={mode === 'human_vs_ai' && move.player === humanColor}>
					<span class="move-num">{idx + 1}</span>
					<span class="move-dot" class:blue={move.player === 'blue'} class:red={move.player === 'red'}></span>
					<span class="move-coord">{formatCoord(move.row, move.col)}</span>
					<span class="move-who">
						{#if mode === 'human_vs_ai'}
							{move.player === humanColor ? $_('moves.you') : $_('moves.ai')}
						{:else}
							{move.player === 'blue' ? $_('colors.blue') : $_('colors.red')}
						{/if}
					</span>
				</div>
			{/each}
		</div>
	{/if}
</div>

<style>
	.history {
		background: var(--surface-1);
		border: 1px solid var(--border);
		border-radius: 12px;
		overflow: hidden;
		width: 100%;
	}

	.history-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		font-size: 0.86rem;
		font-weight: 600;
		color: var(--text-secondary);
		padding: 12px 14px 8px;
	}

	.history-count {
		font-family: 'JetBrains Mono', monospace;
		font-size: 0.72rem;
	}

	.empty-msg {
		font-size: 0.8rem;
		color: var(--text-muted);
		padding: 2px 14px 14px;
	}

	.move-list {
		max-height: 260px;
		overflow-y: auto;
		padding: 0 0 8px;
	}

	.move-row {
		display: flex;
		align-items: center;
		gap: 8px;
		padding: 6px 14px;
		font-size: 0.8rem;
		font-family: 'JetBrains Mono', monospace;
	}

	.move-row.is-you { background: rgba(77, 159, 255, 0.03); }

	.move-num {
		color: var(--text-muted);
		width: 20px;
		text-align: right;
		font-size: 0.7rem;
	}

	.move-dot {
		width: 8px;
		height: 8px;
		border-radius: 50%;
		flex-shrink: 0;
	}

	.move-dot.blue { background: var(--blue); }
	.move-dot.red { background: var(--red); }

	.move-coord {
		color: var(--text-primary);
		flex: 1;
	}

	.move-who {
		color: var(--text-muted);
		font-size: 0.65rem;
		letter-spacing: 0.03em;
	}
</style>
