class_name LocaleResolver
extends RefCounted
## Translates Steamworks API language codes into Godot locale identifiers.
## Ensures seamless alignment between Steam store / client settings and Godot's TranslationServer.

const STEAM_TO_GODOT_LOCALE: Dictionary = {
	"english": "en",
	"latam": "es_419",
	"spanish": "es_ES",
	"french": "fr",
	"german": "de",
	"italian": "it",
	"japanese": "ja",
	"koreana": "ko",
	"brazilian": "pt_BR",
	"portuguese": "pt_PT",
	"russian": "ru",
	"schinese": "zh_CN",
	"tchinese": "zh_TW",
	"polish": "pl",
	"turkish": "tr",
	"ukrainian": "uk",
}

const SUPPORTED_LOCALES: PackedStringArray = ["en", "es_419", "es_ES"]
const DEFAULT_LOCALE: String = "en"


## Converts a Steamworks API language string (e.g. "latam" or "spanish") to a Godot locale.
static func from_steam(steam_lang: String) -> String:
	var clean := steam_lang.to_lower().strip_edges()
	var mapped: String = STEAM_TO_GODOT_LOCALE.get(clean, DEFAULT_LOCALE)
	return sanitize_locale(mapped)


## Validates against supported locales with fallback chain (e.g. es_AR -> es_419 -> es -> en).
static func sanitize_locale(raw_locale: String) -> String:
	var loc := raw_locale.strip_edges()
	if SUPPORTED_LOCALES.has(loc):
		return loc

	# Fallbacks for regional spanish variants
	if loc.begins_with("es_") or loc == "es":
		# European Spain
		if loc == "es_ES":
			return "es_ES"
		# All Latin American variants default to es_419
		return "es_419"

	return DEFAULT_LOCALE


## Applies the resolved locale to Godot's TranslationServer.
static func apply_locale(target_locale: String) -> void:
	var sanitized := sanitize_locale(target_locale)
	TranslationServer.set_locale(sanitized)
