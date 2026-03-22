<script lang="ts">
	import type { CellValue, Player, GameStatus } from '$lib/types';
	import HexCell from './HexCell.svelte';

	type Point = {
		x: number;
		y: number;
	};

	interface Props {
		board: CellValue[][];
		size: number;
		disabled: boolean;
		humanColor: Player;
		winner: Player | null;
		status: GameStatus;
		onCellClick: (row: number, col: number) => void;
	}

	let { board, size, disabled, humanColor, winner, status, onCellClick }: Props = $props();

	// Pointy-top hex geometry
	const HEX_R = 34;
	const HEX_W = Math.sqrt(3) * HEX_R;
	const GAP = 0;
	const COL_STEP = HEX_W + GAP;
	const ROW_STEP = (HEX_R * 3) / 2 + GAP;
	const ROW_OFFSET = COL_STEP / 2;
	const BORDER_STROKE = 7;
	const LABEL_GAP = 18;
	const PAD = BORDER_STROKE + LABEL_GAP + 18;
	const HEX_VERTICES: Point[] = [
		{ x: HEX_W / 2, y: -HEX_R / 2 },
		{ x: HEX_W / 2, y: HEX_R / 2 },
		{ x: 0, y: HEX_R },
		{ x: -HEX_W / 2, y: HEX_R / 2 },
		{ x: -HEX_W / 2, y: -HEX_R / 2 },
		{ x: 0, y: -HEX_R }
	];

	const LETTERS = 'ABCDEFGHIJKLMNOP';

	function cellX(r: number, c: number) {
		return PAD + c * COL_STEP + r * ROW_OFFSET + HEX_W / 2;
	}
	function cellY(r: number, _c: number) {
		return PAD + r * ROW_STEP + HEX_R;
	}

	function cellVertex(r: number, c: number, vertexIdx: number): Point {
		const vertex = HEX_VERTICES[vertexIdx];
		return {
			x: cellX(r, c) + vertex.x,
			y: cellY(r, c) + vertex.y
		};
	}

	function pathFromPoints(points: Point[]): string {
		return points.map(({ x, y }, index) => `${index === 0 ? 'M' : 'L'} ${x} ${y}`).join(' ');
	}

	let svgW = $derived(cellX(size - 1, size - 1) + HEX_W / 2 + PAD);
	let svgH = $derived(cellY(size - 1, 0) + HEX_R + PAD);

	let topEdge = $derived.by(() => {
		const points = [cellVertex(0, 0, 4)];
		for (let col = 0; col < size; col++) {
			points.push(cellVertex(0, col, 5), cellVertex(0, col, 0));
		}
		return points;
	});

	let bottomEdge = $derived.by(() => {
		const row = size - 1;
		const points = [cellVertex(row, 0, 3)];
		for (let col = 0; col < size; col++) {
			points.push(cellVertex(row, col, 2), cellVertex(row, col, 1));
		}
		return points;
	});

	let leftEdge = $derived.by(() => {
		const points = [cellVertex(0, 0, 4)];
		for (let row = 0; row < size; row++) {
			points.push(cellVertex(row, 0, 3), cellVertex(row, 0, 2));
		}
		return points;
	});

	let rightEdge = $derived.by(() => {
		const lastCol = size - 1;
		const points = [cellVertex(0, lastCol, 0)];
		for (let row = 0; row < size; row++) {
			points.push(cellVertex(row, lastCol, 1));
			if (row < size - 1) {
				points.push(cellVertex(row + 1, lastCol, 0));
			}
		}
		return points;
	});

	let topBorder = $derived(pathFromPoints(topEdge));
	let bottomBorder = $derived(pathFromPoints(bottomEdge));
	let leftBorder = $derived(pathFromPoints(leftEdge));
	let rightBorder = $derived(pathFromPoints(rightEdge));

	let topLabelY = $derived(cellY(0, 0) - HEX_R - LABEL_GAP);
	let bottomLabelY = $derived(cellY(size - 1, 0) + HEX_R + LABEL_GAP);
	let leftLabelX = $derived.by(() => {
		const start = leftEdge[0];
		const end = leftEdge[leftEdge.length - 1];
		const dx = end.x - start.x;
		const dy = end.y - start.y;
		const len = Math.sqrt(dx * dx + dy * dy);
		return (-dy / len) * LABEL_GAP;
	});
	let leftLabelY = $derived.by(() => {
		const start = leftEdge[0];
		const end = leftEdge[leftEdge.length - 1];
		const dx = end.x - start.x;
		const dy = end.y - start.y;
		const len = Math.sqrt(dx * dx + dy * dy);
		return (dx / len) * LABEL_GAP;
	});

	// Winning path BFS
	function hexNeighbors(r: number, c: number): [number, number][] {
		const dirs: [number, number][] = [[-1, 0], [-1, 1], [0, -1], [0, 1], [1, -1], [1, 0]];
		return dirs
			.map(([dr, dc]) => [r + dr, c + dc] as [number, number])
			.filter(([nr, nc]) => nr >= 0 && nr < size && nc >= 0 && nc < size);
	}

	function findWinningPath(b: CellValue[][], w: Player): [number, number][] {
		const seeds: [number, number][] = [];
		const isTarget = w === 'blue'
			? (r: number, _c: number) => r === size - 1
			: (_r: number, c: number) => c === size - 1;

		if (w === 'blue') {
			for (let c = 0; c < size; c++) if (b[0][c] === w) seeds.push([0, c]);
		} else {
			for (let r = 0; r < size; r++) if (b[r][0] === w) seeds.push([r, 0]);
		}

		const visited = new Set<string>();
		const parent = new Map<string, string | null>();
		const queue: [number, number][] = [];

		for (const [r, c] of seeds) {
			const key = `${r},${c}`;
			visited.add(key);
			parent.set(key, null);
			queue.push([r, c]);
		}

		while (queue.length > 0) {
			const [r, c] = queue.shift()!;
			if (isTarget(r, c)) {
				const path: [number, number][] = [];
				let key: string | null | undefined = `${r},${c}`;
				while (key != null) {
					const [pr, pc] = key.split(',').map(Number);
					path.unshift([pr, pc]);
					key = parent.get(key);
				}
				return path;
			}
			for (const [nr, nc] of hexNeighbors(r, c)) {
				const nkey = `${nr},${nc}`;
				if (!visited.has(nkey) && b[nr][nc] === w) {
					visited.add(nkey);
					parent.set(nkey, `${r},${c}`);
					queue.push([nr, nc]);
				}
			}
		}
		return [];
	}

	let winPath = $derived.by(() => {
		if (status !== 'finished' || !winner) return [];
		return findWinningPath(board, winner);
	});

	let winPathD = $derived.by(() => {
		if (winPath.length === 0) return '';
		return winPath
			.map(([r, c], i) => `${i === 0 ? 'M' : 'L'} ${cellX(r, c)} ${cellY(r, c)}`)
			.join(' ');
	});

	let winColor = $derived(winner === 'blue' ? '#4d9fff' : '#ff5a5a');
</script>

<div class="board-container">
	<svg
		viewBox="0 0 {svgW} {svgH}"
		data-testid="hex-board"
		class="board-svg"
	>
		<defs>
			<filter id="win-glow">
				<feGaussianBlur in="SourceGraphic" stdDeviation="6" />
			</filter>
		</defs>

		<!-- Border lines -->
		<path d={topBorder} fill="none" stroke="#4d9fff" stroke-width={BORDER_STROKE} stroke-linecap="round" stroke-linejoin="round" />
		<path d={bottomBorder} fill="none" stroke="#4d9fff" stroke-width={BORDER_STROKE} stroke-linecap="round" stroke-linejoin="round" />
		<path d={leftBorder} fill="none" stroke="#ff5a5a" stroke-width={BORDER_STROKE} stroke-linecap="round" stroke-linejoin="round" />
		<path d={rightBorder} fill="none" stroke="#ff5a5a" stroke-width={BORDER_STROKE} stroke-linecap="round" stroke-linejoin="round" />

		<!-- Column labels -->
		{#each Array(size) as _, c}
			<text
				x={cellX(0, c)}
				y={topLabelY}
				text-anchor="middle"
				dominant-baseline="central"
				class="board-label"
				fill="white"
			>{LETTERS[c]}</text>
		{/each}

		<!-- Column labels (letters) in bottom border -->
		{#each Array(size) as _, c}
			<text
				x={cellX(size - 1, c)}
				y={bottomLabelY}
				text-anchor="middle"
				dominant-baseline="central"
				class="board-label"
				fill="white"
			>{LETTERS[c]}</text>
		{/each}

		<!-- Row labels -->
		{#each Array(size) as _, r}
			<text
				x={cellX(r, 0) - HEX_W / 2 + leftLabelX}
				y={cellY(r, 0) + leftLabelY}
				text-anchor="middle"
				dominant-baseline="central"
				class="board-label"
				fill="white"
			>{r + 1}</text>
		{/each}

		<!-- Row labels (numbers) in right border -->
		{#each Array(size) as _, r}
			<text
				x={cellX(r, size - 1) + HEX_W / 2 - leftLabelX}
				y={cellY(r, size - 1) - leftLabelY}
				text-anchor="middle"
				dominant-baseline="central"
				class="board-label"
				fill="white"
			>{r + 1}</text>
		{/each}

		<!-- Hex cells (drawn on top of borders) -->
		{#each board as rowCells, rowIdx}
			{#each rowCells as cell, colIdx}
				<HexCell
					row={rowIdx}
					col={colIdx}
					cx={cellX(rowIdx, colIdx)}
					cy={cellY(rowIdx, colIdx)}
					size={HEX_R}
					value={cell}
					{disabled}
					onclick={onCellClick}
				/>
			{/each}
		{/each}

		<!-- Winning path -->
		{#if winPathD}
			<path
				d={winPathD}
				stroke="white"
				stroke-width="10"
				stroke-linecap="round"
				stroke-linejoin="round"
				fill="none"
				opacity="0.15"
				filter="url(#win-glow)"
			/>
			<path
				d={winPathD}
				stroke={winColor}
				stroke-width="8"
				stroke-linecap="round"
				stroke-linejoin="round"
				fill="none"
				opacity="0.5"
			/>
			<path
				d={winPathD}
				stroke="white"
				stroke-width="4"
				stroke-linecap="round"
				stroke-linejoin="round"
				fill="none"
				opacity="0.6"
			/>
		{/if}
	</svg>
</div>

<style>
	.board-container {
		display: flex;
		justify-content: center;
		align-items: center;
		flex: 1;
		width: 100%;
	}

	.board-svg {
		width: 100%;
		height: auto;
		max-height: min(78vh, 900px);
	}

	.board-label {
		font-family: 'Outfit', system-ui, sans-serif;
		font-size: 11px;
		font-weight: 700;
		letter-spacing: 0.05em;
		pointer-events: none;
		user-select: none;
	}
</style>
