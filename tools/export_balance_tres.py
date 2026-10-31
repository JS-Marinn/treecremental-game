"""
Generates the baseline .tres files for Treecremental from the balance simulator parameters.
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
ROUND_FLOOR = 1

SPECIES = [
    ("pine", "meadow"),
    ("birch", "meadow"),
    ("oak", "meadow"),
    ("sakura", "blossom_vale"),
    ("canadian_maple", "blossom_vale"),
    ("fir", "boreal"),
    ("baobab", "savanna"),
    ("socotra_dragon_tree", "desert"),
    ("giant_sequoia", "ancient_grove"),
]
assert len(SPECIES) == P["tree_count"]


def curve_body(kind, **kw):
    lines = [f"kind = {KIND[kind]}"]
    for k, v in kw.items():
        lines.append(f"{k} = {v}")
    return "\n".join(lines)


def write(path, text):
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", newline="\n") as f:
        f.write(text)


def curve_file(path, kind, **kw):
    write(
        path,
        '[gd_resource type="Resource" script_class="FormulaCurve" load_steps=2 format=3]\n\n'
        '[ext_resource type="Script" path="res://src/core/data/formula_curve.gd" id="1"]\n\n'
        '[resource]\nscript = ExtResource("1")\n' + curve_body(kind, **kw) + "\n",
    )


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
worker_caps = PackedInt32Array({", ".join(str(c) for c in P["worker_cap"])})
tool_caps = PackedInt32Array({", ".join(str(c) for c in P["tool_cap"])})
sawmill_caps = PackedInt32Array({", ".join(str(c) for c in P["sawmill_cap"])})
breakthrough_gate_logs = PackedFloat64Array({", ".join(str(g) for g in P["gate_logs"])})
milestone_counts = PackedInt32Array({", ".join(str(c) for c in P["milestone_counts"])})
milestone_multiplier = {P["milestone_mult"]}
tool_multiplier = {P["tool_mult"]}
tool_max_level = {max(P["tool_cap"])}
sawmill_gain_per_level = {P["sawmill_gain_per_level"]}
sawmill_max_level = {max(P["sawmill_cap"])}
ecosystem_per_species = SubResource("eco")
tertiary_multiplier_cap = {P["tertiary_cap"]}
tertiary_half_point_minutes = {P["tertiary_half_min"]}
sap_gain = SubResource("sap_gain")
sap_multiplier = SubResource("sap_mult")
prestige_min_sap = 5.0
'''
write("data/balance/balance_default.tres", bal)

species_dir = os.path.join(ROOT, "data", "species")
os.makedirs(species_dir, exist_ok=True)
for f in glob.glob(os.path.join(species_dir, "*.tres")):
    try:
        os.remove(f)
    except OSError:
        pass

for i, (sid, biome) in enumerate(SPECIES):
    unlock = 0.0 if i == 0 else P["unlock_cost_base"] * (P["unlock_cost_growth"] ** (i - 1))
    chop = P["chop_time_base_s"] * (P["chop_time_tier_growth"] ** i)
    weight = P["value_growth"] ** i
    txt = f'''[gd_resource type="Resource" script_class="SpeciesData" load_steps=6 format=3]

[ext_resource type="Script" path="res://src/core/data/species_data.gd" id="1"]
[ext_resource type="Script" path="res://src/core/data/formula_curve.gd" id="2"]
[ext_resource type="Resource" path="res://data/balance/curves/hire_cost.tres" id="3"]
[ext_resource type="Resource" path="res://data/balance/curves/tool_cost.tres" id="4"]
[ext_resource type="Resource" path="res://data/balance/curves/sawmill_cost.tres" id="5"]

[sub_resource type="Resource" id="unlock"]
script = ExtResource("2")
{curve_body("CONSTANT", base=round(unlock, 3))}

[resource]
script = ExtResource("1")
id = &"{sid}"
tier = {i}
biome = &"{biome}"
base_chop_time_s = {round(chop, 4)}
score_weight = {round(weight, 5)}
unlock_cost = SubResource("unlock")
hire_cost = ExtResource("3")
tool_cost = ExtResource("4")
sawmill_cost = ExtResource("5")
'''
    write(f"data/species/{sid}.tres", txt)

print(f"Generated {len(SPECIES)} species resources and balance profile.")
