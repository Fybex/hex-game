<script lang="ts">
	import { _ } from 'svelte-i18n';

	const href = 'https://en.wikipedia.org/wiki/Hex_(board_game)';
</script>

<a
	class="help-link"
	href={href}
	target="_blank"
	rel="noreferrer"
	title={$_('help.learnMore')}
	aria-label={$_('help.learnMore')}
>
	?
</a>

<style>
	.help-link {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 22px;
		height: 22px;
		border-radius: 999px;
		border: 1px solid var(--border);
		background: var(--surface-2);
		color: var(--text-secondary);
		font-size: 0.78rem;
		font-weight: 700;
		text-decoration: none;
		transition: background 0.12s ease, color 0.12s ease, border-color 0.12s ease;
	}

	.help-link:hover {
		background: var(--surface-3);
		border-color: var(--text-secondary);
		color: var(--text-primary);
	}
</style>
