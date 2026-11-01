"""
Dumps the shipped cost curve parameters (base/growth) for every upgrade .tres,
shared curve .tres, species prop/unlock/chop params, and balance knobs, so the
export_balance_tres.py generator can be verified against the shipped data.
Usage: python tools/balance_sim/dump_tres.py
"""
import glob
import os
import re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def cost_params(path):
    text = read(path)
    out = []
    for m in re.finditer(r'\[sub_resource type="Resource" id="(cost_curve|sec_cost_curve)"\]\nscript = ExtResource\("\d+"\)\n([\s\S]*?)(?=\n\n\[|\n\[resource\])', text):
        body = m.group(2)
        base = re.search(r"base = ([\d.eE+-]+)", body)
        growth = re.search(r"growth = ([\d.eE+-]+)", body)
        out.append((m.group(1), float(base.group(1)) if base else None, float(growth.group(1)) if growth else None))
    return out


def main():
    rows = []
    for path in sorted(glob.glob(os.path.join(ROOT, "data", "upgrades", "*.tres"))):
        uid = os.path.basename(path)[:-5]
        m = re.search(r'cost_currency_id = &"(\w+)"', read(path))
        cur = m.group(1) if m else "?"
        sec = re.search(r'secondary_cost_currency_id = &"(\w+)"', read(path))
        sec_cur = sec.group(1) if sec else ""
        params = cost_params(path)
        main_p = params[0] if params else (None, None, None)
        sec_p = params[1] if len(params) > 1 else (None, None, None)
        rows.append((uid, cur, main_p[1], main_p[2], sec_cur, sec_p[1], sec_p[2]))
    print("UPGRADE COSTS (id | currency | base | growth | sec_currency | sec_base | sec_growth)")
    for row in rows:
        print("%-32s %-14s %-12s %-8s %-10s %-10s %-8s" % row)

    print("\nSHARED CURVES")
    for name in ["hire_cost", "tool_cost", "sawmill_cost"]:
        path = os.path.join(ROOT, "data", "balance", "curves", "%s.tres" % name)
        params = cost_params(path)
        p = params[0] if params else (None, None, None)
        print("%-14s base=%-10s growth=%s" % (name, p[1], p[2]))

    print("\nSPECIES (id | prop_base | prop_growth | unlock_base | chop_time | clearance | hp | bark | coin)")
    for path in sorted(glob.glob(os.path.join(ROOT, "data", "species", "*.tres"))):
        sid = os.path.basename(path)[:-5]
        text = read(path)
        prop = re.search(r'\[sub_resource type="Resource" id="prop_cost"\]\nscript = ExtResource\("\d+"\)\nkind = 3\nbase = ([\d.eE+-]+)\ngrowth = ([\d.eE+-]+)', text)
        unlock = re.search(r'\[sub_resource type="Resource" id="unlock"\]\nscript = ExtResource\("\d+"\)\nkind = 0\nbase = ([\d.eE+-]+)', text)
        chop = re.search(r"base_chop_time_s = ([\d.eE+-]+)", text)
        hp = re.search(r"base_hp = ([\d.eE+-]+)", text)
        bark = re.search(r"bark_hardness = (\d+)", text)
        coin = re.search(r"base_coin_value = ([\d.eE+-]+)", text)
        clr = re.search(r"trunk_clearance_radius = ([\d.eE+-]+)", text)
        print("%-20s prop %s/%s  unlock %s  chop %s  clr %s  hp %s  bark %s  coin %s" % (
            sid,
            prop.group(1) if prop else "?", prop.group(2) if prop else "?",
            unlock.group(1) if unlock else "?", chop.group(1) if chop else "?",
            clr.group(1) if clr else "?", hp.group(1) if hp else "?",
            bark.group(1) if bark else "?", coin.group(1) if coin else "?"))

    print("\nWORKERS (id | hire_base/growth | gear_base/growth | move | atk | dmg | crit | pen | ignore | synw)")
    for path in sorted(glob.glob(os.path.join(ROOT, "data", "workers", "*.tres"))):
        wid = os.path.basename(path)[:-5]
        text = read(path)
        hire = re.search(r'id="hire_curve"\]\nscript = ExtResource\("\d+"\)\nkind = 3\nbase = ([\d.eE+-]+)\ngrowth = ([\d.eE+-]+)', text)
        gear = re.search(r'id="gear_curve"\]\nscript = ExtResource\("\d+"\)\nkind = 3\nbase = ([\d.eE+-]+)\ngrowth = ([\d.eE+-]+)', text)
        move = re.search(r"move_speed = ([\d.eE+-]+)", text)
        atk = re.search(r"attack_rate = ([\d.eE+-]+)", text)
        dmg = re.search(r"base_damage = ([\d.eE+-]+)", text)
        crit = re.search(r"crit_chance = ([\d.eE+-]+)", text)
        pen = re.search(r"armor_penetration = (\d+)", text)
        ign = re.search(r"ignore_all_bark_hardness = (\w+)", text)
        syn = re.search(r"synergy_trigger_weight = ([\d.eE+-]+)", text)
        print("%-20s hire %s/%s  gear %s/%s  move %s  atk %s  dmg %s  crit %s  pen %s  ign %s  syn %s" % (
            wid,
            hire.group(1) if hire else "?", hire.group(2) if hire else "?",
            gear.group(1) if gear else "?", gear.group(2) if gear else "?",
            move.group(1) if move else "?", atk.group(1) if atk else "?",
            dmg.group(1) if dmg else "?", crit.group(1) if crit else "?",
            pen.group(1) if pen else "?", ign.group(1) if ign else "?",
            syn.group(1) if syn else "?"))


if __name__ == "__main__":
    main()
