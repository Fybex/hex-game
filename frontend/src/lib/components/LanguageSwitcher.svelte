<script lang="ts">
	import { _, locale } from 'svelte-i18n';
	import type { AppLocale } from '$lib/i18n';
	import { setAppLocale } from '$lib/i18n';

	const options: { value: AppLocale; label: string; ariaKey: string }[] = [
		{ value: 'en', label: 'EN', ariaKey: 'accessibility.languageEnglish' },
		{ value: 'uk', label: 'UA', ariaKey: 'accessibility.languageUkrainian' }
	];
</script>

<div class="switcher">
	<span class="switcher-label">{$_('app.language')}</span>
	<div class="switcher-controls">
		{#each options as option}
			<button
				type="button"
				class="switcher-btn"
				class:active={$locale === option.value}
				aria-label={$_(option.ariaKey)}
				onclick={() => setAppLocale(option.value)}
			>
				{option.label}
			</button>
		{/each}
	</div>
</div>

<style>
	.switcher {
		display: inline-flex;
		align-items: center;
		gap: 10px;
		justify-content: center;
	}

	.switcher-label {
		font-size: 0.78rem;
		color: var(--text-secondary);
	}

	.switcher-controls {
		display: inline-flex;
		padding: 3px;
		border: 1px solid var(--border);
		border-radius: 999px;
		background: var(--surface-1);
	}

	.switcher-btn {
		border: none;
		background: transparent;
		color: var(--text-secondary);
		padding: 6px 10px;
		border-radius: 999px;
		font-family: 'JetBrains Mono', monospace;
		font-size: 0.74rem;
		font-weight: 700;
		cursor: pointer;
		transition: background 0.12s ease, color 0.12s ease;
	}

	.switcher-btn.active {
		background: var(--surface-3);
		color: var(--text-primary);
	}
</style>
