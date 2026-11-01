"""
Generates all canonical .tres data resources for Treecremental (v0.6):
- data/balance/balance_default.tres + shared curves
- data/workers/*.tres (3 worker archetypes)
- data/species/*.tres (9 tree species with HP, bark hardness, base coin value, clearance radius, synergy, and propagation curves)
- data/upgrades/*.tres (87 itemized upgrades across all 6 loops with declarative StatModifierData sub-resources)
"""
import glob
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "balance_sim"))
from sim import PARAMS as P

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
KIND = dict(
    CONSTANT=0,
    LINEAR=1,
    POLYNOMIAL=2,
    EXPONENTIAL=3,
    LOGARITHMIC=4,
    HYPERBOLIC_SOFTCAP=5,
    POWER_SOFTCAP=6,
    EXPRESSION=7,
    TABLE=8,
)
OP = dict(
    ADD=0,
    MUL_ADD=1,
    MUL_COMPOUND=2,
    OVERRIDE=3,
)
ROUND_FLOOR = 1

SPECIES = [
    # (id, biome, act, base_hp, bark_hardness, base_coin_value, clearance_r, synergy_id, proc_chance, dur_s, mag)
    ("pine", "meadow", 1, 20.0, 0, 1.00, 12.0, "pitch_sap_splatter", 0.20, 6.0, 0.25),
    ("birch", "meadow", 1, 35.0, 1, 2.20, 12.0, "silver_bark_kindling", 0.18, 6.0, 0.25),
    ("oak", "meadow", 1, 65.0, 2, 5.00, 14.0, "acorn_mast_shower", 0.15, 0.0, 0.25),
    ("sakura", "blossom_boreal", 2, 120.0, 2, 12.00, 14.0, "cherry_petal_rain", 0.15, 8.0, 0.35),
    ("canadian_maple", "blossom_boreal", 2, 220.0, 3, 28.00, 15.0, "sugarbush_sap_flow", 0.16, 8.0, 0.30),
    ("fir", "blossom_boreal", 2, 400.0, 4, 65.00, 15.0, "boreal_frost_shatter", 0.15, 6.0, 2.00),
    ("baobab", "ancient_grove", 3, 750.0, 4, 155.00, 18.0, "monsoon_reservoir_surge", 0.14, 10.0, 0.50),
    ("socotra_dragon_tree", "ancient_grove", 3, 1400.0, 5, 370.00, 17.0, "cinnabar_dragons_blood", 0.14, 8.0, 0.50),
    ("giant_sequoia", "ancient_grove", 3, 2800.0, 6, 900.00, 20.0, "seismic_timberfall", 1.00, 0.0, 0.12),
]
assert len(SPECIES) == P["tree_count"]

WORKERS = [
    {
        "id": "simple_lumberjack",
        "tier_index": 0,
        "role": "versatile_chopper_and_shared_miller",
        "footprint": (16, 16),
        "move_speed": 1.0,
        "attack_rate": 1.0,
        "base_damage": 1.0,
        "crit_chance": 0.05,
        "armor_penetration": 0,
        "ignore_all_bark_hardness": "false",
        "synergy_trigger_weight": 1.0,
        "allowed_loops": ["logging_camp", "sawmill"],
        "act_caps": [14, 24, 34],
        "hire_base": 10.0,
        "hire_growth": 1.15,
        "gear_base": 100.0,
        "gear_growth": 3.20,
    },
    {
        "id": "heavy_sawyer",
        "tier_index": 1,
        "role": "armor_piercing_durability_shredder",
        "footprint": (20, 16),
        "move_speed": 0.75,
        "attack_rate": 2.5,
        "base_damage": 1.0,
        "crit_chance": 0.05,
        "armor_penetration": 999,
        "ignore_all_bark_hardness": "true",
        "synergy_trigger_weight": 1.0,
        "allowed_loops": ["logging_camp"],
        "act_caps": [6, 12, 18],
        "hire_base": 45.0,
        "hire_growth": 1.18,
        "gear_base": 250.0,
        "gear_growth": 3.30,
    },
    {
        "id": "swift_cleaver",
        "tier_index": 2,
        "role": "high_tempo_crit_and_synergy_specialist",
        "footprint": (16, 16),
        "move_speed": 1.40,
        "attack_rate": 1.8,
        "base_damage": 0.70,
        "crit_chance": 0.25,
        "armor_penetration": 1,
        "ignore_all_bark_hardness": "false",
        "synergy_trigger_weight": 2.0,
        "allowed_loops": ["logging_camp"],
        "act_caps": [5, 10, 15],
        "hire_base": 120.0,
        "hire_growth": 1.20,
        "gear_base": 500.0,
        "gear_growth": 3.40,
    },
]


def curve_body(kind, **kw):
    lines = [f"kind = {KIND[kind]}"]
    for k, v in kw.items():
        if isinstance(v, str):
            lines.append(f'{k} = "{v}"')
        else:
            lines.append(f"{k} = {v}")
    return "\n".join(lines)


def write(path, text):
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", newline="\n", encoding="utf-8") as f:
        f.write(text)


def clean_dir(rel_dir):
    full = os.path.join(ROOT, rel_dir)
    os.makedirs(full, exist_ok=True)
    for f in glob.glob(os.path.join(full, "*.tres")):
        try:
            os.remove(f)
        except OSError:
            pass


def curve_file(path, kind, **kw):
    write(
        path,
        '[gd_resource type="Resource" script_class="FormulaCurve" load_steps=2 format=3]\n\n'
        '[ext_resource type="Script" path="res://src/core/data/formula_curve.gd" id="1"]\n\n'
        '[resource]\nscript = ExtResource("1")\n' + curve_body(kind, **kw) + "\n",
    )


# 1. Shared curves & BalanceConfig
curve_file("data/balance/curves/hire_cost.tres", "EXPONENTIAL", base=P["hire_cost_base"], growth=P["hire_cost_growth"])
curve_file("data/balance/curves/tool_cost.tres", "EXPONENTIAL", base=P["tool_cost_base"], growth=P["tool_cost_growth"])
curve_file("data/balance/curves/sawmill_cost.tres", "EXPONENTIAL", base=P["sawmill_cost_base"], growth=P["sawmill_cost_growth"])

sap_gain_scale = P["sap_divisor"] ** (-P["sap_exponent"])
bal = f'''[gd_resource type="Resource" script_class="BalanceConfig" load_steps=5 format=3]

[ext_resource type="Script" path="res://src/core/data/balance_config.gd" id="1"]
[ext_resource type="Script" path="res://src/core/data/formula_curve.gd" id="2"]

[sub_resource type="Resource" id="eco"]
script = ExtResource("2")
{curve_body("LINEAR", base=1.0, scale=P["eco_per_tree"])}

[sub_resource type="Resource" id="sap_gain"]
script = ExtResource("2")
{curve_body("POLYNOMIAL", scale=sap_gain_scale, exponent=P["sap_exponent"], rounding=ROUND_FLOOR)}

[sub_resource type="Resource" id="sap_mult"]
script = ExtResource("2")
{curve_body("POLYNOMIAL", base=1.0, scale=P["sap_mult_scale"], exponent=P["sap_mult_exponent"])}

[resource]
script = ExtResource("1")
trees_per_act = {P["trees_per_act"]}
prop_caps = PackedInt32Array(4, 7, 10)
worker_caps = PackedInt32Array({", ".join(str(c) for c in P["worker_cap"])})
tool_caps = PackedInt32Array({", ".join(str(c) for c in P["tool_cap"])})
gear_caps = PackedInt32Array({", ".join(str(c) for c in P["tool_cap"])})
sawmill_caps = PackedInt32Array({", ".join(str(c) for c in P["sawmill_cap"])})
breakthrough_gate_coins = PackedFloat64Array({", ".join(str(g) for g in P["gate_logs"])})
breakthrough_gate_logs = PackedFloat64Array({", ".join(str(g) for g in P["gate_logs"])})
initial_max_trees_on_map = 14
maturity_hp_base = 4.0
maturity_yield_base = 4.2
chip_yield_fraction = 0.3
timberfall_yield_fraction = 0.7
milestone_counts = PackedInt32Array({", ".join(str(c) for c in P["milestone_counts"])})
milestone_multiplier = {P["milestone_mult"]}
tool_multiplier = {P["tool_mult"]}
tool_max_level = {max(P["tool_cap"])}
sawmill_gain_per_level = 0.25
sawmill_max_level = {max(P["sawmill_cap"])}
sawmill_initial_worker_slots = 2
ecosystem_per_species = SubResource("eco")
tertiary_multiplier_cap = {P["tertiary_cap"]}
tertiary_half_point_minutes = {P["tertiary_half_min"]}
sap_gain = SubResource("sap_gain")
sap_multiplier = SubResource("sap_mult")
prestige_min_sap = 5.0
'''
write("data/balance/balance_default.tres", bal)

# 2. Worker Archetypes (data/workers/*.tres)
clean_dir("data/workers")
for w in WORKERS:
    loops_str = ", ".join(f'"{lp}"' for lp in w["allowed_loops"])
    caps_str = ", ".join(str(c) for c in w["act_caps"])
    w_txt = f'''[gd_resource type="Resource" script_class="WorkerArchetypeData" load_steps=5 format=3]

[ext_resource type="Script" path="res://src/core/data/worker_archetype_data.gd" id="1"]
[ext_resource type="Script" path="res://src/core/data/formula_curve.gd" id="2"]

[sub_resource type="Resource" id="hire_curve"]
script = ExtResource("2")
{curve_body("EXPONENTIAL", base=w["hire_base"], growth=w["hire_growth"])}

[sub_resource type="Resource" id="gear_curve"]
script = ExtResource("2")
{curve_body("EXPONENTIAL", base=w["gear_base"], growth=w["gear_growth"])}

[resource]
script = ExtResource("1")
id = &"{w["id"]}"
tier_index = {w["tier_index"]}
role = &"{w["role"]}"
footprint_px = Vector2i({w["footprint"][0]}, {w["footprint"][1]})
move_speed = {w["move_speed"]}
attack_rate = {w["attack_rate"]}
base_damage = {w["base_damage"]}
crit_chance = {w["crit_chance"]}
armor_penetration = {w["armor_penetration"]}
ignore_all_bark_hardness = {w["ignore_all_bark_hardness"]}
synergy_trigger_weight = {w["synergy_trigger_weight"]}
can_chop_all_trees = true
allowed_loop_ids = PackedStringArray({loops_str})
act_roster_caps = PackedInt32Array({caps_str})
hire_cost_curve = SubResource("hire_curve")
gear_cost_curve = SubResource("gear_curve")
'''
    write(f'data/workers/{w["id"]}.tres', w_txt)

# 3. Species (data/species/*.tres)
clean_dir("data/species")
for i, (sid, biome, act, base_hp, bark_hardness, base_coin_val, clearance_r, syn_id, proc_c, dur_s, mag) in enumerate(SPECIES):
    unlock = 0.0 if i == 0 else P["unlock_cost_base"] * (P["unlock_cost_growth"] ** (i - 1))
    prop_base = 15.0 if i == 0 else round(unlock, 2)
    chop = P["chop_time_base_s"] * (P["chop_time_tier_growth"] ** i)
    weight = P["value_growth"] ** i
    txt = f'''[gd_resource type="Resource" script_class="SpeciesData" load_steps=10 format=3]

[ext_resource type="Script" path="res://src/core/data/species_data.gd" id="1"]
[ext_resource type="Script" path="res://src/core/data/formula_curve.gd" id="2"]
[ext_resource type="Resource" path="res://data/balance/curves/hire_cost.tres" id="3"]
[ext_resource type="Resource" path="res://data/balance/curves/tool_cost.tres" id="4"]
[ext_resource type="Resource" path="res://data/balance/curves/sawmill_cost.tres" id="5"]

[sub_resource type="Resource" id="unlock"]
script = ExtResource("2")
{curve_body("CONSTANT", base=round(unlock, 3))}

[sub_resource type="Resource" id="spawn_weight"]
script = ExtResource("2")
{curve_body("EXPRESSION", expression="100.0 * pow(1.35, max(0.0, x - 1.0))", base=100.0, scale=1.35)}

[sub_resource type="Resource" id="max_qty"]
script = ExtResource("2")
{curve_body("LINEAR", base=2.0, scale=1.5, rounding=ROUND_FLOOR)}

[sub_resource type="Resource" id="prop_cost"]
script = ExtResource("2")
{curve_body("EXPONENTIAL", base=prop_base, growth=1.65)}

[resource]
script = ExtResource("1")
id = &"{sid}"
tier = {i}
act_index = {act}
biome = &"{biome}"
base_hp = {base_hp}
bark_hardness = {bark_hardness}
base_coin_value = {base_coin_val}
trunk_clearance_radius = {clearance_r}
base_chop_time_s = {round(chop, 4)}
score_weight = {round(weight, 5)}
synergy_id = &"{syn_id}"
synergy_proc_chance = {proc_c}
synergy_duration_s = {dur_s}
synergy_magnitude = {mag}
spawn_weight_curve = SubResource("spawn_weight")
max_quantity_curve = SubResource("max_qty")
prop_cost_curve = SubResource("prop_cost")
unlock_cost = SubResource("unlock")
hire_cost = ExtResource("3")
tool_cost = ExtResource("4")
sawmill_cost = ExtResource("5")
'''
    write(f"data/species/{sid}.tres", txt)


# 4. All 87 Canonical Upgrades (data/upgrades/*.tres)
clean_dir("data/upgrades")


def write_upgrade(
    uid,
    loop_id,
    category,
    cost_currency,
    cost_kind,
    cost_kw,
    act_caps,
    max_level,
    resets_on_breakthrough,
    modifiers,
    target_entity_id="",
    initial_level=0,
    sec_currency="",
    sec_kind="EXPONENTIAL",
    sec_kw=None,
):
    """
    modifiers: list of dicts:
      {"id": str, "domain": str, "key": str, "op": str, "kind": str, "kw": dict}
    """
    has_sec = bool(sec_currency)
    load_steps = 4 + (1 if has_sec else 0) + len(modifiers) * 2
    sub_lines = []
    sub_lines.append(
        f'[sub_resource type="Resource" id="cost_curve"]\n'
        f'script = ExtResource("2")\n'
        f'{curve_body(cost_kind, **cost_kw)}\n'
    )
    if has_sec:
        sub_lines.append(
            f'[sub_resource type="Resource" id="sec_cost_curve"]\n'
            f'script = ExtResource("2")\n'
            f'{curve_body(sec_kind, **(sec_kw or {}))}\n'
        )
    mod_refs = []
    for idx, m in enumerate(modifiers):
        cid = f"mod_curve_{idx}"
        mid = f"mod_{idx}"
        sub_lines.append(
            f'[sub_resource type="Resource" id="{cid}"]\n'
            f'script = ExtResource("2")\n'
            f'{curve_body(m["kind"], **m["kw"])}\n'
        )
        sub_lines.append(
            f'[sub_resource type="Resource" id="{mid}"]\n'
            f'script = ExtResource("3")\n'
            f'modifier_id = &"{m["id"]}"\n'
            f'target_domain = &"{m["domain"]}"\n'
            f'stat_key = &"{m["key"]}"\n'
            f'operation = {OP[m["op"]]}\n'
            f'curve = SubResource("{cid}")\n'
        )
        mod_refs.append(f'SubResource("{mid}")')

    caps_str = ", ".join(str(c) for c in act_caps)
    mods_str = ", ".join(mod_refs)
    sec_line = f'secondary_cost_currency_id = &"{sec_currency}"\nsecondary_cost_curve = SubResource("sec_cost_curve")\n' if has_sec else ""
    resets_str = "true" if resets_on_breakthrough else "false"

    content = (
        f'[gd_resource type="Resource" script_class="UpgradeDefinitionData" load_steps={load_steps} format=3]\n\n'
        f'[ext_resource type="Script" path="res://src/core/data/upgrade_definition_data.gd" id="1"]\n'
        f'[ext_resource type="Script" path="res://src/core/data/formula_curve.gd" id="2"]\n'
        f'[ext_resource type="Script" path="res://src/core/data/stat_modifier_data.gd" id="3"]\n\n'
        + "\n".join(sub_lines)
        + "\n[resource]\n"
        f'script = ExtResource("1")\n'
        f'id = &"{uid}"\n'
        f'loop_id = &"{loop_id}"\n'
        f'category = &"{category}"\n'
        f'target_entity_id = &"{target_entity_id}"\n'
        f'cost_currency_id = &"{cost_currency}"\n'
        f'{sec_line}'
        f'cost_curve = SubResource("cost_curve")\n'
        f'act_level_caps = PackedInt32Array({caps_str})\n'
        f'max_level = {max_level}\n'
        f'initial_level = {initial_level}\n'
        f'resets_on_breakthrough = {resets_str}\n'
        f'modifiers = Array[StatModifierData]([{mods_str}])\n'
    )
    write(f"data/upgrades/{uid}.tres", content)


# 4A. 9 Species Propagation Upgrades (prop_<species>)
for i, (sid, *_rest) in enumerate(SPECIES):
    base_cost = 15.0 if i == 0 else round(150.0 * (2.2 ** (i - 1)), 2)
    write_upgrade(
        uid=f"prop_{sid}",
        loop_id="logging_camp",
        category="species_propagation",
        target_entity_id=sid,
        cost_currency="coins",
        cost_kind="EXPONENTIAL",
        cost_kw=dict(base=base_cost, growth=1.65),
        act_caps=[4, 7, 10],
        max_level=10,
        initial_level=1 if i == 0 else 0,
        resets_on_breakthrough=True,
        modifiers=[
            dict(
                id="spawn_weight",
                domain="species_spawn_weight",
                key=sid,
                op="ADD",
                kind="EXPRESSION",
                kw=dict(expression="100.0 * pow(1.35, max(0.0, x - 1.0))", base=100.0, scale=1.35),
            ),
            dict(
                id="max_quantity",
                domain="species_max_quantity",
                key=sid,
                op="ADD",
                kind="LINEAR",
                kw=dict(base=2.0, scale=1.5, rounding=ROUND_FLOOR),
            ),
        ],
    )

# 4B. 6 Worker Roster & Gear Upgrades (hire_<worker>, gear_<worker>)
for w in WORKERS:
    wid = w["id"]
    write_upgrade(
        uid=f"hire_{wid}",
        loop_id="logging_camp",
        category="worker_roster_and_gear",
        target_entity_id=wid,
        cost_currency="coins",
        cost_kind="EXPONENTIAL",
        cost_kw=dict(base=w["hire_base"], growth=w["hire_growth"]),
        act_caps=w["act_caps"],
        max_level=w["act_caps"][-1],
        initial_level=1 if wid == "simple_lumberjack" else 0,
        resets_on_breakthrough=True,
        modifiers=[
            dict(
                id="roster_count",
                domain="worker_roster_count",
                key=wid,
                op="ADD",
                kind="LINEAR",
                kw=dict(base=0.0, scale=1.0),
            )
        ],
    )
    write_upgrade(
        uid=f"gear_{wid}",
        loop_id="logging_camp",
        category="worker_roster_and_gear",
        target_entity_id=wid,
        cost_currency="coins",
        cost_kind="EXPONENTIAL",
        cost_kw=dict(base=w["gear_base"], growth=w["gear_growth"]),
        act_caps=[3, 5, 6],
        max_level=6,
        resets_on_breakthrough=True,
        modifiers=[
            dict(
                id="gear_chop_mult",
                domain="worker_chop_power",
                key=wid,
                op="MUL_COMPOUND",
                kind="EXPONENTIAL",
                kw=dict(base=1.0, growth=2.0),
            )
        ],
    )

# 4C. 15 Compound & Synergy Upgrades (camp_*)
CAMP_UPGRADES = [
    ("camp_plot_expansion", 40.0, 1.55, [4, 7, 10], 10, "clearing_max_trees", "all", "ADD", "LINEAR", dict(base=0.0, scale=2.0)),
    ("camp_old_growth_stewardship", 180.0, 2.80, [1, 2, 4], 4, "old_growth_max_rank", "all", "ADD", "LINEAR", dict(base=0.0, scale=1.0)),
    ("camp_synergy_resonator", 120.0, 1.75, [2, 4, 5], 5, "synergy_proc_chance", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.05)),
    ("camp_whetstone_bench", 55.0, 1.50, [2, 4, 5], 5, "worker_chop_power", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.15)),
    ("camp_hickory_hafts", 70.0, 1.55, [2, 4, 5], 5, "worker_attack_rate", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.10)),
    ("camp_felling_wedges", 160.0, 1.85, [1, 2, 3], 3, "bark_penetration", "all", "ADD", "LINEAR", dict(base=0.0, scale=1.0)),
    ("camp_skid_road", 90.0, 1.50, [2, 4, 5], 5, "worker_move_speed", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.12)),
    ("camp_kerf_softening", 240.0, 1.80, [2, 4, 5], 5, "sawyer_armor_shred", "heavy_sawyer", "ADD", "LINEAR", dict(base=0.0, scale=0.08)),
    ("camp_cleaver_flurry", 280.0, 1.85, [2, 4, 5], 5, "worker_crit_damage", "swift_cleaver", "ADD", "LINEAR", dict(base=0.0, scale=0.15)),
    ("camp_silk_cordage", 850.0, 1.75, [0, 3, 5], 5, "synergy_duration", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.20)),
    ("camp_sap_lubrication", 1200.0, 1.80, [0, 3, 5], 5, "worker_attack_rate", "heavy_sawyer", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.18)),
    ("camp_highland_crampons", 1600.0, 1.80, [0, 3, 5], 5, "worker_move_speed", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.15)),
    ("camp_block_and_tackle", 4500.0, 1.90, [0, 2, 5], 5, "timberfall_jackpot_bonus", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.20)),
    ("camp_crimson_varnish", 18000.0, 2.00, [0, 0, 5], 5, "worker_crit_chance", "all", "ADD", "LINEAR", dict(base=0.0, scale=0.03)),
    ("camp_skyline_yarder", 65000.0, 2.20, [0, 0, 5], 5, "global_coin_multiplier", "all", "MUL_COMPOUND", "LINEAR", dict(base=1.0, scale=0.25)),
]
for uid, base_c, growth_c, caps, max_lv, dom, skey, op, ckind, ckw in CAMP_UPGRADES:
    write_upgrade(
        uid=uid,
        loop_id="logging_camp",
        category="compound_and_synergy",
        cost_currency="coins",
        cost_kind="EXPONENTIAL",
        cost_kw=dict(base=base_c, growth=growth_c),
        act_caps=caps,
        max_level=max_lv,
        resets_on_breakthrough=True,
        modifiers=[dict(id=uid, domain=dom, key=skey, op=op, kind=ckind, kw=ckw)],
    )

# 4D. 9 Sawmill Per-Species Value & Slot Upgrades (mill_<species>)
for i, (sid, *_rest) in enumerate(SPECIES):
    mill_base = round(25.0 * (1.85 ** i), 2)
    write_upgrade(
        uid=f"mill_{sid}",
        loop_id="sawmill",
        category="sawmill_per_species_value_and_slots",
        target_entity_id=sid,
        cost_currency="processed_logs",
        cost_kind="EXPONENTIAL",
        cost_kw=dict(base=mill_base, growth=1.55),
        act_caps=[4, 7, 10],
        max_level=10,
        resets_on_breakthrough=True,
        modifiers=[
            dict(
                id="species_coin_mult",
                domain="species_coin_value",
                key=sid,
                op="MUL_ADD",
                kind="LINEAR",
                kw=dict(base=0.0, scale=0.25),
            ),
            dict(
                id="species_mill_slots",
                domain="sawmill_station_slots",
                key=sid,
                op="ADD",
                kind="EXPRESSION",
                kw=dict(expression="floor(x / 3.0)", base=0.0, scale=1.0),
            ),
        ],
    )

# 4E. 8 Sawmill Capacity & Working Speed Upgrades
MILL_SPEED_UPGRADES = [
    ("mill_crew_quarters", 30.0, 1.50, [4, 7, 10], 10, "sawmill_max_workers", "all", "ADD", "LINEAR", dict(base=0.0, scale=1.0)),
    ("mill_undershot_wheel", 45.0, 1.60, [2, 4, 5], 5, "sawmill_work_speed", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.20)),
    ("mill_kerf_thinning", 80.0, 1.65, [2, 4, 5], 5, "sawmill_value_rate", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.18)),
    ("mill_roller_conveyor", 140.0, 1.70, [2, 4, 5], 5, "sawmill_logs_yield", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.15)),
    ("mill_gang_saw", 420.0, 1.80, [0, 3, 5], 5, "sawmill_work_speed", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.25)),
    ("mill_flywheel_governor", 950.0, 1.85, [0, 3, 5], 5, "sawmill_idle_baseline", "all", "ADD", "LINEAR", dict(base=0.0, scale=0.05)),
    ("mill_hydraulic_carriage", 3200.0, 1.95, [0, 0, 5], 5, "sawmill_work_speed", "all", "MUL_COMPOUND", "LINEAR", dict(base=1.0, scale=0.20)),
    ("mill_sawdust_briquetter", 7500.0, 2.05, [0, 0, 5], 5, "kiln_cycle_speed", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.15)),
]
for uid, base_c, growth_c, caps, max_lv, dom, skey, op, ckind, ckw in MILL_SPEED_UPGRADES:
    write_upgrade(
        uid=uid,
        loop_id="sawmill",
        category="sawmill_capacity_and_speed",
        cost_currency="processed_logs",
        cost_kind="EXPONENTIAL",
        cost_kw=dict(base=base_c, growth=growth_c),
        act_caps=caps,
        max_level=max_lv,
        resets_on_breakthrough=True,
        modifiers=[dict(id=uid, domain=dom, key=skey, op=op, kind=ckind, kw=ckw)],
    )

# 4F. 8 Charcoal Kiln Upgrades (kiln_*)
KILN_UPGRADES = [
    ("kiln_clay_lining", "coins", 200.0, 1.60, "", [2, 4, 5], 5, "kiln_charcoal_yield", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.20)),
    ("kiln_draft_vents", "charcoal", 15.0, 1.55, "", [2, 4, 5], 5, "kiln_cycle_speed", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.15)),
    ("kiln_boiler_manifold", "charcoal", 25.0, 1.65, "", [2, 4, 5], 5, "global_work_speed", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.10)),
    ("kiln_hardwood_retort", "charcoal", 60.0, 1.70, "", [0, 3, 5], 5, "kiln_ash_yield", "all", "ADD", "LINEAR", dict(base=0.0, scale=1.0)),
    ("kiln_auto_stoker", "charcoal", 120.0, 1.75, "", [0, 3, 5], 5, "kiln_boiler_retention", "all", "ADD", "LINEAR", dict(base=0.0, scale=0.20)),
    ("kiln_ash_sifter", "charcoal", 200.0, 1.75, "ash", [0, 3, 5], 5, "kiln_ash_purity", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.25)),
    ("kiln_bellows_turbine", "charcoal", 500.0, 1.85, "", [0, 0, 5], 5, "worker_chop_power", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.15)),
    ("kiln_white_charcoal", "charcoal", 1200.0, 2.00, "ash", [0, 0, 5], 5, "global_coin_multiplier", "all", "MUL_COMPOUND", "LINEAR", dict(base=1.0, scale=0.20)),
]
for uid, curr, base_c, growth_c, sec_c, caps, max_lv, dom, skey, op, ckind, ckw in KILN_UPGRADES:
    write_upgrade(
        uid=uid,
        loop_id="charcoal_kilns",
        category="charcoal_kilns",
        cost_currency=curr,
        cost_kind="EXPONENTIAL",
        cost_kw=dict(base=base_c, growth=growth_c),
        sec_currency=sec_c,
        sec_kind="EXPONENTIAL",
        sec_kw=dict(base=10.0, growth=1.50) if sec_c else None,
        act_caps=caps,
        max_level=max_lv,
        resets_on_breakthrough=True,
        modifiers=[dict(id=uid, domain=dom, key=skey, op=op, kind=ckind, kw=ckw)],
    )

# 4G. 8 Canopy Aviary Upgrades (aviary_*)
AVIARY_UPGRADES = [
    ("aviary_bird_woodpecker", "birdseed", 15.0, 1.50, [2, 4, 5], 5, "bark_penetration", "all", "ADD", "LINEAR", dict(base=0.0, scale=1.0)),
    ("aviary_bird_waxwing", "birdseed", 30.0, 1.55, [2, 4, 5], 5, "synergy_proc_chance", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.04)),
    ("aviary_bird_falcon", "birdseed", 65.0, 1.60, [0, 3, 5], 5, "worker_crit_chance", "all", "ADD", "LINEAR", dict(base=0.0, scale=0.03)),
    ("aviary_bird_songbird", "birdseed", 140.0, 1.65, [0, 3, 5], 5, "sawmill_work_speed", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.10)),
    ("aviary_bird_phoenix", "birdseed", 350.0, 1.75, [0, 0, 5], 5, "kiln_cycle_speed", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.15)),
    ("aviary_seed_hopper", "coins", 350.0, 1.60, [2, 4, 5], 5, "birdseed_generation", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.25)),
    ("aviary_suet_cakes", "birdseed", 45.0, 1.55, [2, 4, 5], 5, "aviary_buff_potency", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.20)),
    ("aviary_gilded_weathervane", "birdseed", 180.0, 1.70, [0, 3, 5], 5, "global_coin_multiplier", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.12)),
]
for uid, curr, base_c, growth_c, caps, max_lv, dom, skey, op, ckind, ckw in AVIARY_UPGRADES:
    write_upgrade(
        uid=uid,
        loop_id="canopy_aviary",
        category="canopy_aviary",
        cost_currency=curr,
        cost_kind="EXPONENTIAL",
        cost_kw=dict(base=base_c, growth=growth_c),
        act_caps=caps,
        max_level=max_lv,
        resets_on_breakthrough=False,
        modifiers=[dict(id=uid, domain=dom, key=skey, op=op, kind=ckind, kw=ckw)],
    )

# 4H. 8 Mycelium Network Upgrades (myc_*)
MYC_UPGRADES = [
    ("myc_phosphorus_exchange", "spores", 15.0, 1.50, "", [2, 4, 5], 5, "species_coin_value", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.10)),
    ("myc_spore_bloom", "spores", 30.0, 1.55, "ash", [2, 4, 5], 5, "spores_generation", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.25)),
    ("myc_saprophyte_enzymes", "spores", 60.0, 1.60, "", [2, 4, 5], 5, "chip_yield_bonus", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.12)),
    ("myc_rhizomorph_conduit", "spores", 120.0, 1.65, "", [0, 3, 5], 5, "sawmill_value_rate", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.15)),
    ("myc_truffle_symbiosis", "spores", 250.0, 1.70, "", [0, 3, 5], 5, "timberfall_jackpot_bonus", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.18)),
    ("myc_alkaline_mulch", "spores", 480.0, 1.75, "ash", [0, 3, 5], 5, "species_spawn_weight", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.15)),
    ("myc_fairy_ring_pulse", "spores", 950.0, 1.85, "", [0, 0, 5], 5, "synergy_proc_chance", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.08)),
    ("myc_mother_tree_nexus", "spores", 2200.0, 2.00, "", [0, 0, 5], 5, "global_coin_multiplier", "all", "MUL_COMPOUND", "LINEAR", dict(base=1.0, scale=0.18)),
]
for uid, curr, base_c, growth_c, sec_c, caps, max_lv, dom, skey, op, ckind, ckw in MYC_UPGRADES:
    write_upgrade(
        uid=uid,
        loop_id="mycelium_network",
        category="mycelium_network",
        cost_currency=curr,
        cost_kind="EXPONENTIAL",
        cost_kw=dict(base=base_c, growth=growth_c),
        sec_currency=sec_c,
        sec_kind="EXPONENTIAL",
        sec_kw=dict(base=8.0, growth=1.45) if sec_c else None,
        act_caps=caps,
        max_level=max_lv,
        resets_on_breakthrough=False,
        modifiers=[dict(id=uid, domain=dom, key=skey, op=op, kind=ckind, kw=ckw)],
    )

# 4I. 16 Heartwood Ascension Prestige Upgrades (sap_*)
SAP_UPGRADES = [
    ("sap_heartwood_resonance_1", 5.0, 1.50, 5, "global_coin_multiplier", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.25)),
    ("sap_pioneer_charter", 8.0, 1.60, 3, "starting_coins", "all", "ADD", "EXPONENTIAL", dict(base=250.0, growth=4.0)),
    ("sap_amber_distillation", 10.0, 1.65, 5, "synergy_proc_chance", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.05)),
    ("sap_seasoned_joinery", 12.0, 1.65, 5, "sawmill_value_rate", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.25)),
    ("sap_eternal_embers", 15.0, 1.70, 3, "kiln_boiler_floor", "all", "ADD", "LINEAR", dict(base=0.0, scale=0.15)),
    ("sap_canopy_sanctuary_bond", 20.0, 1.00, 1, "aviary_persist_breakthrough", "all", "ADD", "CONSTANT", dict(base=1.0)),
    ("sap_heartwood_resonance_2", 35.0, 1.75, 5, "global_coin_multiplier", "all", "MUL_COMPOUND", "LINEAR", dict(base=1.0, scale=0.35)),
    ("sap_guild_headquarters", 45.0, 1.80, 3, "starting_simple_lumberjacks", "simple_lumberjack", "ADD", "LINEAR", dict(base=0.0, scale=2.0)),
    ("sap_bulk_contracting", 30.0, 1.00, 1, "unlock_max_buy_mode", "all", "ADD", "CONSTANT", dict(base=1.0)),
    ("sap_cambium_overflow", 55.0, 1.80, 5, "old_growth_spawn_chance", "all", "ADD", "LINEAR", dict(base=0.0, scale=0.06)),
    ("sap_mycorrhizal_awakening", 65.0, 1.85, 3, "spores_generation", "all", "MUL_COMPOUND", "LINEAR", dict(base=1.0, scale=0.50)),
    ("sap_crucible_steel", 80.0, 1.90, 5, "worker_chop_power", "all", "MUL_COMPOUND", "LINEAR", dict(base=1.0, scale=0.30)),
    ("sap_titan_feller", 120.0, 2.00, 3, "act3_tree_damage", "all", "MUL_COMPOUND", "LINEAR", dict(base=1.0, scale=0.50)),
    ("sap_golden_bough", 160.0, 2.10, 3, "timberfall_jackpot_bonus", "all", "MUL_COMPOUND", "LINEAR", dict(base=1.0, scale=0.40)),
    ("sap_ancient_harmony", 220.0, 2.20, 3, "achievement_coin_bonus", "all", "MUL_ADD", "LINEAR", dict(base=0.0, scale=0.02)),
    ("sap_world_tree_crown", 500.0, 1.00, 1, "global_coin_multiplier", "all", "MUL_COMPOUND", "CONSTANT", dict(base=3.0)),
]
for uid, base_c, growth_c, max_lv, dom, skey, op, ckind, ckw in SAP_UPGRADES:
    write_upgrade(
        uid=uid,
        loop_id="heartwood_ascension",
        category="heartwood_prestige",
        cost_currency="sap",
        cost_kind="EXPONENTIAL",
        cost_kw=dict(base=base_c, growth=growth_c),
        act_caps=[max_lv, max_lv, max_lv],
        max_level=max_lv,
        resets_on_breakthrough=False,
        modifiers=[dict(id=uid, domain=dom, key=skey, op=op, kind=ckind, kw=ckw)],
    )

total_upgrades = len(glob.glob(os.path.join(ROOT, "data", "upgrades", "*.tres")))
print(f"Generated {len(WORKERS)} workers, {len(SPECIES)} species, {total_upgrades} upgrades, and balance profile.")
