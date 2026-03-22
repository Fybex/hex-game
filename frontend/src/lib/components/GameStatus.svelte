<script lang="ts">
	import type { Player, GameStatus, GameMode } from '$lib/types';
	import { _ } from 'svelte-i18n';

	interface Props {
		status: GameStatus;
		winner: Player | null;
		currentPlayer: Player | 'none';
		humanColor: Player;
		isThinking: boolean;
		mode: GameMode;
	}

	let { status, winner, currentPlayer, humanColor, isThinking, mode }: Props = $props();

	let messageId = $derived.by(() => {
		if (mode === 'human_vs_human') {
			if (status === 'finished') {
				if (winner === 'blue') return 'status.blueWins';
				if (winner === 'red') return 'status.redWins';
				return 'status.gameFinished';
			}
			return currentPlayer === 'red' ? 'status.redTurn' : 'status.blueTurn';
		}

		if (mode === 'ai_vs_ai') {
			if (status === 'finished') {
				if (winner === 'blue') return 'status.blueWins';
				if (winner === 'red') return 'status.redWins';
				return 'status.gameFinished';
			}
			if (isThinking) {
				return currentPlayer === 'red' ? 'status.redThinking' : 'status.blueThinking';
			}
			return currentPlayer === 'red' ? 'status.redTurn' : 'status.blueTurn';
		}

		if (status === 'finished') {
			if (winner === humanColor) return 'status.youWin';
			if (winner) return 'status.aiWins';
			return 'status.gameFinished';
		}
		if (isThinking) return 'status.aiThinking';
		if (currentPlayer === humanColor) return 'status.yourTurn';
		return 'status.aiTurn';
	});

	let subId = $derived.by(() => {
		if (mode === 'human_vs_human') {
			if (status === 'finished') {
				if (winner === 'blue') return 'status.blueConnected';
				if (winner === 'red') return 'status.redConnected';
				return null;
			}

			return currentPlayer === 'red' ? 'status.redConnected' : 'status.blueConnected';
		}

		if (mode === 'ai_vs_ai') {
			if (status === 'finished') {
				if (winner === 'blue') return 'status.blueConnected';
				if (winner === 'red') return 'status.redConnected';
				return null;
			}

			return currentPlayer === 'red' ? 'status.redConnected' : 'status.blueConnected';
		}

		if (status === 'finished') {
			if (winner === humanColor) {
				return humanColor === 'blue'
					? 'status.blueConnected'
					: 'status.redConnected';
			}
			if (winner) {
				return humanColor === 'blue'
					? 'status.redConnected'
					: 'status.blueConnected';
			}
			return null;
		}
		if (isThinking) return 'status.aiChoosing';
		if (currentPlayer === humanColor) return 'status.chooseCell';
		return 'status.waitForAi';
	});

	let colorClass = $derived(
		status === 'finished'
			? mode === 'ai_vs_ai' || mode === 'human_vs_human'
				? winner === 'blue' ? 'active' : winner === 'red' ? 'defeat' : 'thinking'
				: winner === humanColor ? 'victory' : 'defeat'
			: isThinking ? 'thinking' : 'active'
	);
</script>

<div class="status-bar {colorClass}" data-testid="game-status">
	<span class="status-msg">{$_(messageId)}</span>
	{#if subId}
		<span class="status-sub">{$_(subId)}</span>
	{/if}
</div>

<style>
	.status-bar {
		text-align: center;
		padding: 13px 16px;
		border-radius: 12px;
		background: var(--surface-1);
		border: 1px solid var(--border);
	}

	.status-msg {
		font-size: 1.02rem;
		font-weight: 700;
		letter-spacing: 0.02em;
	}

	.status-sub {
		display: block;
		font-size: 0.8rem;
		font-weight: 400;
		color: var(--text-secondary);
		margin-top: 5px;
		line-height: 1.4;
	}

	.active .status-msg { color: var(--blue); }
	.thinking .status-msg { color: var(--text-primary); }
	.victory .status-msg { color: #34d399; }
	.victory { border-color: rgba(52, 211, 153, 0.25); }
	.defeat .status-msg { color: var(--red); }
	.defeat { border-color: rgba(255, 90, 90, 0.25); }
</style>
