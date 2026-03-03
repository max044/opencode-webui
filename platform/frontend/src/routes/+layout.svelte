<script lang="ts">
	import '../app.css';
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { page } from '$app/stores';

	let { children } = $props();

	onMount(() => {
		const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
			if (event === 'SIGNED_OUT') {
				// Handle logout logic if needed
			}
		});

		return () => subscription.unsubscribe();
	});
</script>

<div class="min-h-screen bg-neutral-950 text-neutral-50 font-sans antialiased">
	{@render children()}
</div>

<style>
	:global(body) {
		margin: 0;
		padding: 0;
		background-color: #0a0a0a;
	}
</style>
