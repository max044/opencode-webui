<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from '$lib/components/ui/card';

	let email = $state('');
	let loading = $state(false);
	let message = $state('');

	async function handleLogin() {
		loading = true;
		const { error } = await supabase.auth.signInWithOtp({
			email,
			options: {
				emailRedirectTo: window.location.origin
			}
		});
		if (error) {
			message = error.message;
		} else {
			message = 'Check your email for the magic link!';
		}
		loading = false;
	}
</script>

<div class="flex items-center justify-center min-h-screen">
	<Card class="w-full max-w-md bg-neutral-900 border-neutral-800 text-neutral-50 shadow-2xl">
		<CardHeader class="space-y-1">
			<CardTitle class="text-2xl font-bold tracking-tight">Welcome back</CardTitle>
			<CardDescription class="text-neutral-400">
				Enter your email to sign in via magic link
			</CardDescription>
		</CardHeader>
		<CardContent class="space-y-4">
			<div class="space-y-2">
				<Input
					type="email"
					placeholder="name@example.com"
					bind:value={email}
					class="bg-neutral-950 border-neutral-800 focus:ring-neutral-700"
				/>
			</div>
			{#if message}
				<p class="text-sm {message.includes('Check') ? 'text-green-400' : 'text-red-400'}">
					{message}
				</p>
			{/if}
		</CardContent>
		<CardFooter>
			<Button
				class="w-full bg-neutral-50 text-neutral-950 hover:bg-neutral-200 transition-colors"
				disabled={loading}
				onclick={handleLogin}
			>
				{loading ? 'Sending link...' : 'Send Magic Link'}
			</Button>
		</CardFooter>
	</Card>
</div>
