"""
Treecremental balance simulator (design-time pacing verification tool).

Models the 3-Act Plateau-Curve progression across 9 tree species:
- Climb phase: purchasing workers, tools, sawmills, and loop upgrades up to the Act cap.
- Plateau phase: production stabilizes at the Act cap while accumulating logs toward the Breakthrough gate.
- Breakthrough phase: Heartwood Ascension resets run currencies, banks permanent Sap, and unlocks the next Act.
"""
import copy
import json
import math
import sys

PARAMS = dict(
    tree_count=9,
    trees_per_act=3,
    chop_time_base_s=2.0,
    chop_time_tier_growth=1.55,
    hire_cost_base=10.0,
    hire_cost_growth=1.15,
    tool_cost_base=120.0,
    tool_cost_growth=9.0,
    tool_mult=2.0,
    sawmill_cost_base=200.0,
    sawmill_cost_growth=3.2,
    sawmill_gain_per_level=0.20,
    unlock_cost_base=150.0,
    unlock_cost_growth=2.2,
    worker_cap=[30, 50, 70],
    tool_cap=[3, 5, 6],
    sawmill_cap=[4, 7, 10],
    milestone_counts=[10, 25, 50],
    milestone_mult=1.5,
    gate_logs=[247000.0, 7160000.0, 46200000.0],
    eco_per_tree=0.05,
    tertiary_cap=1.0,
    tertiary_half_min=90.0,
    value_growth=1.9,
    sap_divisor=2000.0,
    sap_exponent=0.5,
    sap_mult_scale=0.6,
    sap_mult_exponent=0.5,
    worker_attack_scale=0.8,
    bot_efficiency=1.0,
    post_game_min=0,
    max_hours=8,
    trace=False,
)


def simulate(P):
    n = P["tree_count"]
    per = P["trees_per_act"]
    chop_t = [P["chop_time_base_s"] * P["chop_time_tier_growth"] ** i for i in range(n)]
    V = [P["value_growth"] ** i for i in range(n)]
    sap_total = 0.0
    act = 0

    def fresh():
        s = dict(
            logs=[0.0] * n,
            total=[0.0] * n,
            workers=[0] * n,
            tool=[0] * n,
            saw=[0] * n,
            unlocked=per * act + 1,
        )
        for i in range(s["unlocked"]):
            s["workers"][i] = 1
        return s

    s = fresh()
    t = 0.0
    events = []
    run_start = 0.0
    curve = []
    life = [0.0] * n

    def milestone(w):
        m = 1.0
        for c in P["milestone_counts"]:
            if w >= c:
                m *= P["milestone_mult"]
        return m

    def tert():
        p = t / 60.0
        return 1.0 + P["tertiary_cap"] * p / (p + P["tertiary_half_min"])

    def rate(i):
        w = s["workers"][i]
        if w == 0:
            return 0.0
        eco = 1.0 + P["eco_per_tree"] * (s["unlocked"] - 1)
        msap = 1.0 + P["sap_mult_scale"] * (sap_total ** P["sap_mult_exponent"])
        return (
            (w / chop_t[i])
            * (P["tool_mult"] ** s["tool"][i])
            * milestone(w)
            * (1.0 + P["sawmill_gain_per_level"] * s["saw"][i])
            * eco
            * msap
            * tert()
            * P["worker_attack_scale"]
            * P["bot_efficiency"]
        )

    def hire_cost(i):
        return P["hire_cost_base"] * (P["hire_cost_growth"] ** s["workers"][i])

    def tool_cost(i):
        return P["tool_cost_base"] * (P["tool_cost_growth"] ** s["tool"][i])

    def saw_cost(i):
        return P["sawmill_cost_base"] * (P["sawmill_cost_growth"] ** s["saw"][i])

    def unlock_cost(j):
        return P["unlock_cost_base"] * (P["unlock_cost_growth"] ** (j - 1))

    finished_at = None
    end_post = None
    gates = list(P["gate_logs"])
    capped_flag = False
    capped_info = {}

    while t < P["max_hours"] * 3600:
        top = per * (act + 1)
        for i in range(s["unlocked"]):
            r = rate(i)
            s["logs"][i] += r
            s["total"][i] += r
            life[i] += r
        t += 1.0

        for _ in range(60):
            best = None
            for i in range(s["unlocked"]):
                r0 = rate(i)
                opts = []
                if s["workers"][i] < P["worker_cap"][act]:
                    opts.append(("hire", hire_cost(i)))
                if s["tool"][i] < P["tool_cap"][act]:
                    opts.append(("tool", tool_cost(i)))
                if s["saw"][i] < P["sawmill_cap"][act]:
                    opts.append(("saw", saw_cost(i)))
                for kind, c in opts:
                    if s["logs"][i] < c:
                        continue
                    key = {"hire": "workers", "tool": "tool", "saw": "saw"}[kind]
                    s[key][i] += 1
                    d = rate(i) - r0
                    s[key][i] -= 1
                    pb = c / max(d, 1e-12)
                    if best is None or pb < best[0]:
                        best = (pb, kind, i, c)
            if s["unlocked"] < top:
                j = s["unlocked"]
                c = unlock_cost(j)
                if s["logs"][j - 1] >= c:
                    s["logs"][j - 1] -= c
                    s["unlocked"] += 1
                    s["workers"][j] = 1
                    events.append((t, act, f"unlock tree {j + 1}"))
                    continue
            if best is None:
                break
            _, kind, i, c = best
            s["logs"][i] -= c
            s[{"hire": "workers", "tool": "tool", "saw": "saw"}[kind]][i] += 1

        if s["unlocked"] == top and not capped_flag:
            if all(
                s["workers"][i] >= P["worker_cap"][act]
                and s["tool"][i] >= P["tool_cap"][act]
                and s["saw"][i] >= P["sawmill_cap"][act]
                for i in range(top)
            ):
                capped_flag = True
                events.append((t, act, "CAPPED"))
                capped_info[act] = (t, s["total"][top - 1], rate(top - 1))
                if P.get("stop_on_capped_act") == act:
                    break

        if int(t) % 30 == 0:
            curve.append((t, act, sum(rate(i) * V[i] for i in range(s["unlocked"]))))

        last = per * (act + 1) - 1
        if s["unlocked"] > last and s["total"][last] >= gates[act]:
            if act == len(gates) - 1:
                if finished_at is None:
                    finished_at = t
                    events.append((t, act, "FINALE: Great Felling"))
                    if P["post_game_min"] <= 0:
                        break
                    end_post = t + P["post_game_min"] * 60
                    gates[act] = float("inf")
            else:
                score = sum(s["total"][i] * V[i] for i in range(n))
                gain = math.floor((score / P["sap_divisor"]) ** P["sap_exponent"])
                sap_total += gain
                events.append(
                    (
                        t,
                        act,
                        f"BREAKTHROUGH {act + 1}->{act + 2}: +{gain} Sap (total {sap_total:.0f}), run {(t - run_start) / 60:.1f} min",
                    )
                )
                act += 1
                s = fresh()
                run_start = t
                capped_flag = False
        if end_post and t >= end_post:
            break

    return dict(
        finished=finished_at,
        events=events,
        curve=curve,
        sap=sap_total,
        life=life,
        t=t,
        capped=capped_info,
    )


def phases(curve, events):
    out = []
    for a in range(3):
        starts = [e[0] for e in events if e[1] == a - 1 and "BREAKTHROUGH" in e[2]]
        start_t = 0 if a == 0 else (starts[0] if starts else None)
        capped = [e[0] for e in events if e[1] == a and e[2] == "CAPPED"]
        ends = [e[0] for e in events if e[1] == a and ("BREAKTHROUGH" in e[2] or "FINALE" in e[2])]
        if start_t is None or not capped or not ends:
            continue
        out.append((a + 1, start_t / 60, (capped[0] - start_t) / 60, (ends[0] - capped[0]) / 60))
    return out


if __name__ == "__main__":
    P = copy.deepcopy(PARAMS)
    for a in sys.argv[1:]:
        k, v = a.split("=", 1)
        P[k] = json.loads(v)
    r = simulate(P)
    for e in r["events"]:
        if "unlock" not in e[2] or P["trace"]:
            print(f"{e[0] / 60:7.1f} min  {e[2]}")
    print("FINISHED:", "no" if r["finished"] is None else f"{r['finished'] / 3600:.2f} h", f"sap={r['sap']:.0f}")
    if r["finished"]:
        for a, st, climb, plat in phases(r["curve"], r["events"]):
            print(f"  Act {a}: starts {st:5.1f} min | CLIMB {climb:5.1f} min | PLATEAU {plat:5.1f} min")
