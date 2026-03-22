<script lang="ts">
	import { _ } from 'svelte-i18n';
	import LanguageSwitcher from '$lib/components/LanguageSwitcher.svelte';

	interface Props {
		subtitle?: string | null;
	}

	let { subtitle = null }: Props = $props();
</script>

<header class="page-header">
	<h1>{$_('app.title')}</h1>
	{#if subtitle}
		<p class="subtitle">{subtitle}</p>
	{/if}
	<div class="header-tools">
		<LanguageSwitcher />
	</div>
</header>

<style>
	.page-header {
		position: sticky;
		top: 0;
		z-index: 120;
		text-align: center;
		padding: 8px 0 18px;
		background: linear-gradient(
			to bottom,
			color-mix(in srgb, var(--surface-0) 96%, transparent),
			color-mix(in srgb, var(--surface-0) 88%, transparent),
			transparent
		);
		backdrop-filter: blur(8px);
	}

	.header-tools {
		margin-top: 12px;
	}

	h1 {
		margin: 0;
		font-size: 1.7rem;
		font-weight: 700;
		letter-spacing: 0.04em;
	}

	.subtitle {
		margin: 8px 0 0;
		font-family: 'JetBrains Mono', monospace;
		font-size: 0.78rem;
		letter-spacing: 0.03em;
		color: var(--text-muted);
	}

	@media (max-width: 640px) {
		h1 {
			font-size: 1.5rem;
		}
	}
</style>
