"""Calibrate the breakthrough gates so each Act's PLATEAU hits a target length.
Method: income is flat once an Act is CAPPED, so
    gate = (last-tree logs at CAPPED) + (last-tree rate at CAPPED) * target_plateau_seconds
One sim run per Act (sequential, because later Acts depend on earlier gates), then a full verification run.
Usage: python calibrate.py [key=json ...]   (same overrides as sim.py)"""
import sys, json, copy
from sim import PARAMS, simulate, phases

TARGET_PLATEAU_MIN = [14.0, 16.0, 16.0]


def calibrate(P, targets=TARGET_PLATEAU_MIN):
    P = copy.deepcopy(P)
    P["gate_logs"] = [float("inf")] * 3
    P["max_hours"] = 14
    for act in range(3):
        Q = copy.deepcopy(P)
        Q["stop_on_capped_act"] = act
        r = simulate(Q)
        if act not in r["capped"]:
            raise SystemExit(f"Act {act+1} never capped within max_hours; relax costs/caps")
        _, total_last, rate_last = r["capped"][act]
        P["gate_logs"][act] = float(f"{total_last + rate_last * targets[act] * 60:.3g}")
    return P


def report(C):
    C = copy.deepcopy(C); C["max_hours"] = 14
    r = simulate(C)
    for e in r["events"]:
        if "unlock" not in e[2]:
            print(f"{e[0]/60:7.1f} min  {e[2]}")
    fin = None if r["finished"] is None else r["finished"] / 3600
    print("FINISHED:", None if fin is None else round(fin, 2), "h  gate_logs =", C["gate_logs"])
    for a, st, climb, plat in phases(r["curve"], r["events"]):
        print(f"  Act {a}: starts {st:5.1f} | CLIMB {climb:5.1f} | PLATEAU {plat:5.1f} min")
    return fin


if __name__ == "__main__":
    P = copy.deepcopy(PARAMS)
    for a in sys.argv[1:]:
        k, v = a.split("=", 1)
        P[k] = json.loads(v)
    report(calibrate(P))
