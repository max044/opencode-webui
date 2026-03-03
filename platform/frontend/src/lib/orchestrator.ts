import { env } from '$env/dynamic/public';
import { supabase } from './supabase';

export async function createProject(name: string) {
	const { data: { session } } = await supabase.auth.getSession();
	if (!session) throw new Error('Not authenticated');

	const response = await fetch(`${env.PUBLIC_ORCHESTRATOR_URL}/projects/create`, {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json',
			'Authorization': `Bearer ${session.access_token}`
		},
		body: JSON.stringify({
			user_id: session.user.id,
			name: name
		})
	});

	if (!response.ok) {
		const error = await response.json();
		throw new Error(error.detail || 'Failed to create project');
	}

	return await response.json();
}
