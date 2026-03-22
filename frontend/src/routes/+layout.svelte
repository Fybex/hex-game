<script lang="ts">
	import '../app.css';
	import { onMount } from 'svelte';
	import { locale } from 'svelte-i18n';
	import { initializeLocale } from '$lib/i18n';

	let { children } = $props();

	onMount(() => {
		void initializeLocale();

		const unsubscribe = locale.subscribe((value) => {
			document.documentElement.lang = value?.startsWith('uk') ? 'uk' : 'en';
		});

		return unsubscribe;
	});
</script>

{@render children()}
