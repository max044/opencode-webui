<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { supabase } from '$lib/supabase';

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (session) {
			goto('/dashboard');
		} else {
			goto('/login');
		}
	});
</script>

<div class="flex items-center justify-center min-h-screen bg-neutral-950">
	<div class="animate-pulse text-neutral-500">Loading...</div>
</div>
