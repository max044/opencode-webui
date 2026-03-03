import adapter from '@sveltejs/adapter-static';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	kit: {
		adapter: adapter({
			out: 'build',
			fallback: 'index.html'  // SPA fallback for client-side routing
		})
	}
};

export default config;
