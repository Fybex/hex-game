<script lang="ts">
	import { _ } from 'svelte-i18n';

	interface Props {
		orientation: 'vertical' | 'horizontal';
		compact?: boolean;
	}

	let { orientation, compact = false }: Props = $props();
</script>

<div
	class="goal-preview"
	class:vertical={orientation === 'vertical'}
	class:horizontal={orientation === 'horizontal'}
	class:compact
	role="img"
	aria-label={orientation === 'vertical'
		? $_('accessibility.goalVertical')
		: $_('accessibility.goalHorizontal')}
>
	<div class="mini-board">
		<span class="edge top"></span>
		<span class="edge right"></span>
		<span class="edge bottom"></span>
		<span class="edge left"></span>
		<span class="mini-hex"></span>
	</div>
</div>

<style>
	.goal-preview {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		--preview-width: 32px;
		--preview-height: 28px;
	}

	.goal-preview.compact {
		--preview-width: 28px;
		--preview-height: 24px;
	}

	.mini-board {
		position: relative;
		width: var(--preview-width);
		height: var(--preview-height);
	}

	.edge {
		position: absolute;
		background: var(--border);
		opacity: 0.95;
	}

	.top,
	.bottom {
		left: 6px;
		right: 6px;
		height: 3px;
		border-radius: 999px;
	}

	.left,
	.right {
		top: 5px;
		bottom: 5px;
		width: 3px;
		border-radius: 999px;
	}

	.top { top: 0; }
	.bottom { bottom: 0; }
	.left { left: 0; }
	.right { right: 0; }

	.vertical .top,
	.vertical .bottom {
		background: var(--blue);
	}

	.horizontal .left,
	.horizontal .right {
		background: var(--red);
	}

	.mini-hex {
		position: absolute;
		inset: 4px 5px;
		background: color-mix(in srgb, var(--surface-3) 78%, transparent);
		border: 1px solid color-mix(in srgb, var(--border) 85%, transparent);
		clip-path: polygon(25% 0%, 75% 0%, 100% 50%, 75% 100%, 25% 100%, 0% 50%);
	}
</style>
