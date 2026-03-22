<script lang="ts">
	import type { CellValue } from '$lib/types';
	import { _ } from 'svelte-i18n';

	interface Props {
		row: number;
		col: number;
		cx: number;
		cy: number;
		size: number;
		value: CellValue;
		disabled: boolean;
		onclick: (row: number, col: number) => void;
	}

	let { row, col, cx, cy, size, value, disabled, onclick }: Props = $props();

	function hexPoints(r: number, centerY = cy): string {
		const pts = [];
		for (let i = 0; i < 6; i++) {
			const angle = (Math.PI / 3) * i - Math.PI / 6;
			pts.push(`${cx + r * Math.cos(angle)},${centerY + r * Math.sin(angle)}`);
		}
		return pts.join(' ');
	}

	let isClickable = $derived(!disabled && value === null);
	let cellId = $derived(`cell-${row}-${col}`);
</script>

<g
	class="hex-cell"
	class:clickable={isClickable}
	class:blue={value === 'blue'}
	class:red={value === 'red'}
	class:empty={value === null}
	role="button"
	tabindex={isClickable ? 0 : -1}
	aria-label={$_('accessibility.cell', { values: { row, col } })}
	onclick={() => isClickable && onclick(row, col)}
	onkeydown={(e) => e.key === 'Enter' && isClickable && onclick(row, col)}
>
	<!-- Shadow layer -->
	<polygon points={hexPoints(size, cy + 2)} class="hex-shadow" />
	<!-- Base hex -->
	<polygon points={hexPoints(size)} class="hex-base" />
	<!-- Top face -->
	<polygon points={hexPoints(size * 0.78)} class="hex-face" />
	<!-- Highlight -->
	<polygon points={hexPoints(size * 0.5)} class="hex-highlight" />
</g>

<style>
	.hex-cell {
		outline: none;
	}

	/* --- Empty --- */
	.hex-cell.empty .hex-shadow { fill: #080c14; }
	.hex-cell.empty .hex-base { fill: #1a2236; stroke: #2a3650; stroke-width: 1.5; }
	.hex-cell.empty .hex-face { fill: #26324a; }
	.hex-cell.empty .hex-highlight { fill: #31415f; opacity: 0.45; }

	/* --- Blue --- */
	.hex-cell.blue .hex-shadow { fill: #0c2d6b; }
	.hex-cell.blue .hex-base { fill: #1a56db; stroke: #2b6feb; stroke-width: 1; }
	.hex-cell.blue .hex-face { fill: #5ea7ff; }
	.hex-cell.blue .hex-highlight { fill: #84bdff; opacity: 0.55; }

	/* --- Red --- */
	.hex-cell.red .hex-shadow { fill: #5c0f0f; }
	.hex-cell.red .hex-base { fill: #c62828; stroke: #e53935; stroke-width: 1; }
	.hex-cell.red .hex-face { fill: #ff6c6c; }
	.hex-cell.red .hex-highlight { fill: #ff9d9d; opacity: 0.55; }

	/* --- Hover --- */
	.hex-cell.clickable { cursor: pointer; }

	.hex-cell.clickable:hover .hex-base {
		fill: #1e3a5f;
		stroke: #4d9fff;
		stroke-width: 2;
	}
	.hex-cell.clickable:hover .hex-face { fill: #2d4a6f; }
	.hex-cell.clickable:hover .hex-highlight { fill: #3d5a7f; opacity: 0.8; }

	/* --- Transitions --- */
	.hex-shadow, .hex-base, .hex-face, .hex-highlight {
		transition: all 0.12s ease-out;
	}
</style>
