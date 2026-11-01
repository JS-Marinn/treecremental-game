class_name LocaleResolver
extends RefCounted
## Translates Steamworks API language codes into Godot locale identifiers and loads
## res://i18n/game_text.csv into TranslationServer so KEY_* strings resolve in all environments.

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
const DEFAULT_CSV_PATH: String = "res://i18n/game_text.csv"

static var _loaded: bool = false


static func ensure_loaded(csv_path: String = DEFAULT_CSV_PATH) -> void:
	if _loaded:
		return
	load_csv_translations(csv_path)


static func load_csv_translations(csv_path: String = DEFAULT_CSV_PATH) -> void:
	if not FileAccess.file_exists(csv_path):
		push_warning("LocaleResolver: CSV file missing at %s" % csv_path)
		return
	var file: FileAccess = FileAccess.open(csv_path, FileAccess.READ)
	if file == null:
		return
	var header: PackedStringArray = file.get_csv_line()
	if header.size() < 2:
		return
	var translations: Dictionary = {}
	for col_idx in range(1, header.size()):
		var loc_code: String = header[col_idx].strip_edges()
		if loc_code != "":
			var tr_obj := Translation.new()
			tr_obj.locale = loc_code
			translations[col_idx] = tr_obj

	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() < 2:
			continue
		var key: String = row[0].strip_edges()
		if key == "" or key.begins_with("#"):
			continue
		for col_idx in translations.keys():
			if col_idx < row.size():
				var tr_obj: Translation = translations[col_idx]
				tr_obj.add_message(StringName(key), row[col_idx])

	for col_idx in translations.keys():
		var tr_obj: Translation = translations[col_idx]
		TranslationServer.add_translation(tr_obj)
	_loaded = true
	if TranslationServer.get_locale() == "" or not SUPPORTED_LOCALES.has(TranslationServer.get_locale()):
		TranslationServer.set_locale(DEFAULT_LOCALE)


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

	if loc.begins_with("es_") or loc == "es":
		if loc == "es_ES":
			return "es_ES"
		return "es_419"

	return DEFAULT_LOCALE


## Applies the resolved locale to Godot's TranslationServer.
static func apply_locale(target_locale: String) -> void:
	ensure_loaded()
	var sanitized := sanitize_locale(target_locale)
	TranslationServer.set_locale(sanitized)
