<script lang="ts">
	import { goto } from '$app/navigation';
	import { game } from '$lib/stores/game.svelte';
	import type { GameMode, Player } from '$lib/types';
	import { _ } from 'svelte-i18n';
	import AppHeader from '$lib/components/AppHeader.svelte';
	import StartGamePanel from '$lib/components/StartGamePanel.svelte';

	async function handleStart(
		size: number,
		color: Player,
		depth: number | undefined,
		mode: GameMode
	) {
		await game.newGame(size, color, depth, mode);

		if (game.state) {
			await goto('/game');
		}
	}
</script>

<svelte:head>
	<title>{$_('app.title')}</title>
</svelte:head>

<div class="page">
	<AppHeader />

	<main class="menu-layout">
		<StartGamePanel error={game.error} onStart={handleStart} />
	</main>
</div>

<style>
	.page {
		min-height: 100vh;
		display: flex;
		flex-direction: column;
		padding: 16px 16px 32px;
	}

	.menu-layout {
		width: min(100%, 1100px);
		margin: 0 auto;
		padding-top: 44px;
		display: flex;
		justify-content: center;
	}

	@media (max-width: 640px) {
		.page {
			padding-inline: 12px;
		}

		.menu-layout {
			padding-top: 28px;
		}
	}
</style>
