<script lang="ts">
	import type { GameMode, Player } from '$lib/types';
	import { _ } from 'svelte-i18n';
	import GoalPreview from '$lib/components/GoalPreview.svelte';
	import HelpLink from '$lib/components/HelpLink.svelte';

	interface Props {
		error?: string | null;
		onStart: (size: number, color: Player, depth: number | undefined, mode: GameMode) => void | Promise<void>;
	}

	let { error = null, onStart }: Props = $props();

	const boardSizes = [3, 5, 7, 11];
	const DEPTH_MIN = 1;
	const DEPTH_MAX = 12;
	let size = $state(5);
	let mode = $state<GameMode>('human_vs_ai');
	let color = $state<Player>('blue');
	let depth = $state(5);
	let previousSize = 5;

	const defaultDepths: Record<number, number> = { 3: 10, 5: 5, 7: 4, 11: 2 };

	function getDefaultDepth(s: number) {
		return defaultDepths[s] ?? 3;
	}

	$effect(() => {
		if (size !== previousSize) {
			depth = getDefaultDepth(size);
			previousSize = size;
			return;
		}

		if (depth > DEPTH_MAX) depth = DEPTH_MAX;
		if (depth < DEPTH_MIN) depth = DEPTH_MIN;
	});
</script>

<section class="panel" data-testid="start-game-panel">
	<div class="panel-header">
		<div class="panel-title">
			<div class="hex-icon">⬡</div>
			<h2>{$_('dialog.newGame')}</h2>
		</div>
		<HelpLink />
	</div>

	<div class="panel-body">
		<fieldset class="field">
			<legend class="field-label">{$_('dialog.gameMode')}</legend>
			<div class="mode-options">
				<button
					type="button"
					class="mode-btn"
					class:active={mode === 'human_vs_ai'}
					onclick={() => (mode = 'human_vs_ai')}
				>
					{$_('mode.humanVsAi')}
				</button>
				<button
					type="button"
					class="mode-btn"
					class:active={mode === 'human_vs_human'}
					onclick={() => (mode = 'human_vs_human')}
				>
					{$_('mode.humanVsHuman')}
				</button>
				<button
					type="button"
					class="mode-btn"
					class:active={mode === 'ai_vs_ai'}
					onclick={() => (mode = 'ai_vs_ai')}
				>
					{$_('mode.aiVsAi')}
				</button>
			</div>
		</fieldset>

		<fieldset class="field">
			<legend class="field-label">{$_('dialog.boardSize')}</legend>
			<div class="size-options">
				{#each boardSizes as s}
					<button
						type="button"
						class="size-btn"
						class:active={size === s}
						onclick={() => (size = s)}
					>
						{s}x{s}
					</button>
				{/each}
			</div>
		</fieldset>

		{#if mode === 'human_vs_ai'}
			<fieldset class="field">
				<legend class="field-label">{$_('dialog.playAs')}</legend>
				<div class="color-options">
					<button
						type="button"
						class="color-btn blue-opt"
						class:active={color === 'blue'}
						onclick={() => (color = 'blue')}
					>
						<span class="color-dot blue-dot"></span>
						<div class="color-copy">
							<span class="color-name">{$_('colors.blue')}</span>
							<span class="color-hint">{$_('dialog.blueHint')}</span>
						</div>
						<GoalPreview orientation="vertical" compact={true} />
					</button>
					<button
						type="button"
						class="color-btn red-opt"
						class:active={color === 'red'}
						onclick={() => (color = 'red')}
					>
						<span class="color-dot red-dot"></span>
						<div class="color-copy">
							<span class="color-name">{$_('colors.red')}</span>
							<span class="color-hint">{$_('dialog.redHint')}</span>
						</div>
						<GoalPreview orientation="horizontal" compact={true} />
					</button>
				</div>
			</fieldset>
		{:else}
			<div class="field">
				<div class="field-label">
					{mode === 'ai_vs_ai' ? $_('dialog.aiSides') : $_('dialog.humanSides')}
				</div>
				<div class="ai-sides">
					<div class="ai-side-card">
						<span class="color-name">{$_('colors.blue')}</span>
						<GoalPreview orientation="vertical" compact={true} />
					</div>
					<div class="ai-side-card">
						<span class="color-name">{$_('colors.red')}</span>
						<GoalPreview orientation="horizontal" compact={true} />
					</div>
				</div>
			</div>
		{/if}

		{#if mode !== 'human_vs_human'}
			<div class="field">
				<label class="field-label" for="ai-depth">{$_('dialog.aiDepth')}</label>
				<div class="depth-meta">
					<span>{$_('dialog.recommendedDepth', { values: { size, depth: getDefaultDepth(size) } })}</span>
				</div>
				<div class="depth-slider">
					<input
						id="ai-depth"
						type="range"
						min={DEPTH_MIN}
						max={DEPTH_MAX}
						bind:value={depth}
					/>
					<span class="depth-value">{depth}</span>
				</div>
			</div>
		{/if}

		{#if error}
			<div class="error-message" data-testid="error-message">{error}</div>
		{/if}

		<button
			class="start-btn"
			data-testid="start-game-btn"
			onclick={() => onStart(
				size,
				color,
				mode === 'human_vs_human' || depth === getDefaultDepth(size) ? undefined : depth,
				mode
			)}
		>
			{$_('dialog.start')}
		</button>
	</div>
</section>

<style>
	.panel {
		background: var(--surface-1);
		border: 1px solid var(--border);
		border-radius: 16px;
		width: min(100%, 420px);
		overflow: hidden;
		box-shadow: 0 28px 70px rgba(0, 0, 0, 0.35);
	}

	.panel-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 10px;
		padding: 20px 24px 12px;
	}

	.panel-title {
		display: flex;
		align-items: center;
		gap: 10px;
	}

	.hex-icon {
		font-size: 1.5rem;
		color: var(--blue);
		line-height: 1;
	}

	.panel-header h2 {
		font-size: 1.3rem;
		font-weight: 700;
		margin: 0;
		letter-spacing: 0.02em;
	}

	.panel-body {
		padding: 8px 24px 24px;
		display: flex;
		flex-direction: column;
		gap: 18px;
	}

	.field-label {
		display: block;
		font-size: 0.86rem;
		font-weight: 600;
		color: var(--text-secondary);
		margin-bottom: 8px;
	}

	.field {
		border: 0;
		padding: 0;
		margin: 0;
		min-width: 0;
	}

	.size-options {
		display: flex;
		gap: 6px;
	}

	.mode-options {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 6px;
	}

	.mode-btn {
		padding: 9px 10px;
		border: 1px solid var(--border);
		border-radius: 10px;
		background: var(--surface-2);
		color: var(--text-secondary);
		font-family: 'Outfit', system-ui, sans-serif;
		font-size: 0.84rem;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.12s ease;
	}

	.mode-btn:hover {
		background: var(--surface-3);
		color: var(--text-primary);
	}

	.mode-btn.active {
		background: var(--surface-3);
		border-color: var(--blue);
		color: var(--text-primary);
		box-shadow: 0 0 0 1px var(--blue);
	}

	.size-btn {
		flex: 1;
		padding: 8px;
		border: 1px solid var(--border);
		border-radius: 8px;
		background: var(--surface-2);
		color: var(--text-secondary);
		font-family: 'Outfit', system-ui, sans-serif;
		font-size: 0.85rem;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.12s ease;
	}

	.size-btn:hover {
		background: var(--surface-3);
		color: var(--text-primary);
	}

	.size-btn.active {
		background: var(--surface-3);
		border-color: var(--blue);
		color: var(--text-primary);
		box-shadow: 0 0 0 1px var(--blue);
	}

	.color-options {
		display: flex;
		flex-direction: column;
		gap: 6px;
	}

	.color-btn {
		display: flex;
		align-items: center;
		gap: 10px;
		padding: 10px 14px;
		border: 1px solid var(--border);
		border-radius: 10px;
		background: var(--surface-2);
		color: var(--text-secondary);
		font-family: 'Outfit', system-ui, sans-serif;
		font-size: 0.9rem;
		font-weight: 500;
		cursor: pointer;
		text-align: left;
		transition: all 0.12s ease;
	}

	.color-btn:hover {
		background: var(--surface-3);
	}

	.color-btn.active {
		border-color: currentColor;
	}

	.blue-opt.active {
		border-color: var(--blue);
		color: var(--blue);
	}

	.red-opt.active {
		border-color: var(--red);
		color: var(--red);
	}

	.color-dot {
		width: 14px;
		height: 14px;
		border-radius: 50%;
		flex-shrink: 0;
	}

	.color-copy {
		display: flex;
		flex-direction: column;
		gap: 2px;
		min-width: 0;
		flex: 1;
	}

	.color-name {
		font-size: 0.9rem;
		font-weight: 600;
	}

	.blue-dot {
		background: var(--blue);
	}

	.red-dot {
		background: var(--red);
	}

	.color-hint {
		font-size: 0.68rem;
		color: var(--text-muted);
		letter-spacing: 0.03em;
	}

	.ai-sides {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 8px;
	}

	.ai-side-card {
		padding: 10px;
		border: 1px solid var(--border);
		border-radius: 10px;
		background: var(--surface-2);
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 8px;
	}

	.depth-meta {
		display: flex;
		align-items: center;
		gap: 10px;
		margin-bottom: 8px;
		font-size: 0.76rem;
		color: var(--text-muted);
	}

	.depth-slider {
		display: flex;
		align-items: center;
		gap: 10px;
	}

	.depth-slider input[type='range'] {
		flex: 1;
		accent-color: var(--blue);
	}

	.depth-value {
		font-family: 'JetBrains Mono', monospace;
		font-size: 0.9rem;
		font-weight: 600;
		color: var(--blue);
		min-width: 20px;
		text-align: center;
	}

	.error-message {
		border: 1px solid rgba(255, 90, 90, 0.25);
		background: rgba(255, 90, 90, 0.1);
		color: var(--red);
		padding: 10px 12px;
		border-radius: 10px;
		font-size: 0.82rem;
	}

	.start-btn {
		padding: 12px;
		border: none;
		border-radius: 10px;
		background: linear-gradient(135deg, var(--blue-deep), var(--blue));
		color: white;
		font-family: 'Outfit', system-ui, sans-serif;
		font-size: 1rem;
		font-weight: 700;
		letter-spacing: 0.06em;
		cursor: pointer;
		transition: all 0.15s ease;
	}

	.start-btn:hover {
		filter: brightness(1.1);
		transform: translateY(-1px);
	}

	.start-btn:active {
		transform: translateY(0);
	}

	@media (max-width: 640px) {
		.panel {
			width: 100%;
		}

		.panel-body,
		.panel-header {
			padding-inline: 18px;
		}
	}
</style>
