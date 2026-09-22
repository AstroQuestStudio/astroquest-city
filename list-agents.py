import sys, json
d = json.load(sys.stdin)
for k, v in d["agents"].items():
    oc = v.get("opencodeAgent", "-")
    print(f"  {k}: role={v['role']} -> primary={v['models']['primary']}, opencodeAgent={oc}")