import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import { bunny } from 'laravel-vite-plugin/fonts';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
            fonts: [bunny('Instrument Sans', { weights: [400, 500, 600] })],
        }),
        tailwindcss(),
    ],
    server: {
        hmr: { host: 'localhost' },
        watch: {
            ignored: ['**/storage/framework/views/**'],
            usePolling: process.env.VITE_USE_POLLING === 'true',
        },
    },
});
