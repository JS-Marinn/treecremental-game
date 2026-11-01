"""
Generates data/achievements/ach_*.tres resources from the canonical achievements
section of design/registry/entities.yaml. The YAML registry is the single source
of truth for achievement ids, trigger types, and thresholds; this tool only maps
them to AchievementDefinitionData resources so gameplay scripts never contain
hardcoded unlock criteria.

Usage: python tools/export_achievements_tres.py
"""
import os
import re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
REGISTRY_PATH = os.path.join(ROOT, "design", "registry", "entities.yaml")
OUT_DIR = os.path.join(ROOT, "data", "achievements")

TRIGGER = {
    "lifetime_currency": 0,
    "trees_felled_total": 1,
    "trees_felled_species": 2,
    "old_growth_felled": 3,
    "upgrades_purchased_total": 4,
    "upgrade_level": 5,
    "category_upgrades": 6,
    "worker_roster_level": 7,
    "all_worker_types": 8,
    "sawmill_assigned": 9,
    "kiln_cycles": 10,
    "boiler_pressure": 11,
    "species_unlocked": 12,
    "synergies_triggered": 13,
    "breakthrough_index": 14,
    "sap_banked": 15,
    "all_achievements": 16,
}

FIELD_MAP = {
    "currency": "currency_id",
    "species": "species_id",
    "worker": "worker_id",
    "upgrade": "upgrade_id",
    "category": "category_id",
}


def parse_registry():
    """Parses the achievements: section of entities.yaml (flow-style dict lines)."""
    lines = open(REGISTRY_PATH, encoding="utf-8").read().splitlines()
    section = None
    entries = []
    for raw in lines:
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if not raw.startswith((" ", "\t")):
            section = stripped.rstrip(":")
            continue
        if section != "achievements":
            continue
        if not stripped.startswith("- {"):
            continue
        body = stripped[2:].strip()
        if not body.endswith("}"):
            continue
        inner = body[1:-1]
        fields = {}
        for key, value in re.findall(r"(\w+):\s*([^,{}]+)", inner):
            fields[key.strip()] = value.strip()
        if "id" in fields and "trigger" in fields:
            entries.append(fields)
    return entries


def format_threshold(value):
    text = value.strip()
    if "." in text or "e" in text.lower():
        return "%g" % float(text)
    return str(int(text))


def write_tres(entry):
    ach_id = entry["id"]
    trigger = TRIGGER[entry["trigger"]]
    threshold = format_threshold(entry.get("threshold", "1"))
    extra_lines = []
    for src_key, tres_field in FIELD_MAP.items():
        if entry.get(src_key):
            extra_lines.append('%s = &"%s"' % (tres_field, entry[src_key]))
    body = "\n".join(extra_lines)
    if body:
        body += "\n"
    content = (
        '[gd_resource type="Resource" script_class="AchievementDefinitionData" '
        'load_steps=2 format=3]\n\n'
        '[ext_resource type="Script" '
        'path="res://src/core/data/achievement_definition_data.gd" id="1"]\n\n'
        "[resource]\n"
        'script = ExtResource("1")\n'
        'id = &"%s"\n'
        "trigger = %d\n"
        "threshold = %s\n"
        "%s"
        % (ach_id, trigger, threshold, body)
    )
    out_path = os.path.join(OUT_DIR, "%s.tres" % ach_id)
    with open(out_path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(content)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    entries = parse_registry()
    ids = [e["id"] for e in entries]
    assert len(ids) == len(set(ids)), "duplicate achievement ids in registry"
    for entry in entries:
        write_tres(entry)
    print("exported %d achievements to %s" % (len(entries), OUT_DIR))


if __name__ == "__main__":
    main()
