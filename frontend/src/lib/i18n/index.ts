import { browser } from '$app/environment';
import { _, addMessages, getLocaleFromNavigator, init, locale, unwrapFunctionStore } from 'svelte-i18n';
import { en, uk } from './messages';

export type AppLocale = 'en' | 'uk';

const FALLBACK_LOCALE: AppLocale = 'en';
const STORAGE_KEY = 'hex-locale';

addMessages('en', en);
addMessages('uk', uk);

init({
	fallbackLocale: FALLBACK_LOCALE,
	initialLocale: FALLBACK_LOCALE
});

export const supportedLocales: AppLocale[] = ['en', 'uk'];
export const translate = unwrapFunctionStore(_);

function normalizeLocale(value: string | null | undefined): AppLocale {
	if (!value) return FALLBACK_LOCALE;
	return value.toLowerCase().startsWith('uk') ? 'uk' : 'en';
}

function getStoredLocale(): AppLocale | null {
	if (!browser) return null;
	const stored = window.localStorage.getItem(STORAGE_KEY);
	return stored ? normalizeLocale(stored) : null;
}

export function getPreferredLocale(): AppLocale {
	const stored = getStoredLocale();
	if (stored) return stored;
	return normalizeLocale(getLocaleFromNavigator());
}

export async function initializeLocale() {
	await locale.set(getPreferredLocale());
}

export async function setAppLocale(nextLocale: AppLocale) {
	if (browser) {
		window.localStorage.setItem(STORAGE_KEY, nextLocale);
	}
	await locale.set(nextLocale);
}
