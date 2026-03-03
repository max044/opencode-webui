<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { Button } from '$lib/components/ui/button';
	import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '$lib/components/ui/card';
	import { createProject } from '$lib/orchestrator';
	import { Plus, Layout, ExternalLink, Settings, LogOut, Loader2 } from 'lucide-svelte';
	import { goto } from '$app/navigation';

	let session = $state<any>(null);
	let projects = $state<any[]>([]);
	let loading = $state(true);
	let creating = $state(false);

	onMount(async () => {
		const { data: { session: currentSession } } = await supabase.auth.getSession();
		if (!currentSession) {
			goto('/login');
			return;
		}
		session = currentSession;
		await fetchProjects();
		loading = false;
	});

	async function fetchProjects() {
		const { data, error } = await supabase
			.from('projects')
			.select('*')
			.order('created_at', { ascending: false });
		
		if (!error) {
			projects = data;
		}
	}

	async function handleLogout() {
		await supabase.auth.signOut();
		goto('/login');
	}

	async function handleCreateProject() {
		const name = prompt('Project Name:');
		if (!name) return;

		creating = true;
		try {
			await createProject(name);
			await fetchProjects();
		} catch (e: any) {
			alert(e.message);
		} finally {
			creating = false;
		}
	}
</script>

<div class="min-h-screen bg-neutral-950 text-neutral-50 px-6 py-12 lg:px-24">
	<header class="flex items-center justify-between mb-12">
		<div class="flex items-center gap-2">
			<div class="w-8 h-8 bg-neutral-50 rounded-md flex items-center justify-center">
				<Layout class="w-5 h-5 text-neutral-950" />
			</div>
			<h1 class="text-xl font-bold tracking-tight">OpenCode.</h1>
		</div>
		<div class="flex items-center gap-4">
			<span class="text-sm text-neutral-400 hidden sm:inline">{session?.user?.email}</span>
			<Button variant="ghost" size="icon" class="text-neutral-400 hover:text-neutral-50" onclick={handleLogout}>
				<LogOut class="w-5 h-5" />
			</Button>
		</div>
	</header>

	<main>
		<div class="flex items-center justify-between mb-8">
			<div>
				<h2 class="text-3xl font-bold tracking-tight mb-1">Projects</h2>
				<p class="text-neutral-400 text-sm">Manage and monitor your AI-powered applications</p>
			</div>
			<Button 
				class="bg-neutral-50 text-neutral-950 hover:bg-neutral-200" 
				onclick={handleCreateProject}
				disabled={creating}
			>
				{#if creating}
					<Loader2 class="w-4 h-4 mr-2 animate-spin" />
					Creating...
				{:else}
					<Plus class="w-4 h-4 mr-2" />
					New Project
				{/if}
			</Button>
		</div>

		{#if loading}
			<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
				{#each Array(3) as _}
					<div class="h-48 rounded-xl bg-neutral-900 animate-pulse border border-neutral-800"></div>
				{/each}
			</div>
		{:else if projects.length === 0}
			<div class="flex flex-col items-center justify-center py-24 px-4 text-center border border-dashed border-neutral-800 rounded-2xl bg-neutral-900/30">
				<div class="w-16 h-16 bg-neutral-900 rounded-full flex items-center justify-center mb-6">
					<Layout class="w-8 h-8 text-neutral-500" />
				</div>
				<h3 class="text-lg font-semibold mb-2">No projects yet</h3>
				<p class="text-neutral-400 mb-8 max-w-xs">
					Start by creating your first AI-powered application. It only takes a minute.
				</p>
				<Button 
					class="bg-neutral-50 text-neutral-950 hover:bg-neutral-200" 
					onclick={handleCreateProject}
					disabled={creating}
				>
					{#if creating}
						<Loader2 class="w-4 h-4 mr-2 animate-spin" />
						Creating...
					{:else}
						Create your first project
					{/if}
				</Button>
			</div>
		{:else}
			<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
				{#each projects as project}
					<Card class="bg-neutral-900 border-neutral-800 hover:border-neutral-700 transition-all cursor-pointer group">
						<CardHeader>
							<div class="flex items-start justify-between">
								<div>
									<CardTitle class="text-lg font-bold group-hover:text-neutral-50 transition-colors">
										{project.name}
									</CardTitle>
									<CardDescription class="text-neutral-400 line-clamp-1">
										{project.description || 'No description provided'}
									</CardDescription>
								</div>
								<div class="w-10 h-10 rounded-lg bg-neutral-950 flex items-center justify-center border border-neutral-800 group-hover:border-neutral-700">
									<Layout class="w-5 h-5 text-neutral-400 group-hover:text-neutral-50" />
								</div>
							</div>
						</CardHeader>
						<CardContent class="mt-4 flex items-center gap-3">
							<Button variant="secondary" size="sm" class="flex-1 bg-neutral-800 border-neutral-700 hover:bg-neutral-700">
								<Settings class="w-4 h-4 mr-2" />
								Manage
							</Button>
							<Button variant="secondary" size="sm" class="bg-neutral-800 border-neutral-700 hover:bg-neutral-700">
								<ExternalLink class="w-4 h-4" />
							</Button>
						</CardContent>
					</Card>
				{/each}
			</div>
		{/if}
	</main>
</div>
