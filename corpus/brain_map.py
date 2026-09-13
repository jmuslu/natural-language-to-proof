"""Render the fact brain as an interactive semantic-trust map (self-contained HTML).

Projects the fact embeddings to 2D (PCA via numpy SVD -- no extra deps), then draws
each claim as a point positioned by MEANING, coloured by its externally-anchored
TRUST (red distrusted / grey unchecked / green trusted), and sized by centrality.
The cross-domain bridge hypotheses are drawn as links; the exploration frontier
(unchecked-but-central) is ringed. Hover shows the claim text, domain, trust and
status. This is a faithful picture of the real brain.db -- geometry from embeddings,
trust from external checks only -- not a mock-up.

    python brain_map.py            # writes brain_map.html
"""
from __future__ import annotations

import json
from pathlib import Path

import numpy as np

from brain import Brain

HERE = Path(__file__).resolve().parent


def pca2(E: np.ndarray) -> np.ndarray:
    X = E - E.mean(axis=0, keepdims=True)
    _, _, Vt = np.linalg.svd(X, full_matrices=False)
    return X @ Vt[:2].T


def build(db_path: str, out_path: str) -> dict:
    brain = Brain.open(db_path, load_embedder=False)
    ids, E, trusts, meta = brain._all()
    coords = pca2(E)
    # normalise coords into [0,1] with a margin
    mn, mx = coords.min(axis=0), coords.max(axis=0)
    span = np.where((mx - mn) == 0, 1.0, mx - mn)
    norm = (coords - mn) / span

    # centrality (similarity mass to neighbours) for point size
    S = E @ E.T
    np.fill_diagonal(S, 0.0)
    knn = 8
    cent = np.array([np.sort(np.clip(S[i], 0, None))[-knn:].sum() for i in range(len(ids))])
    cent = (cent - cent.min()) / (float(np.ptp(cent)) or 1.0)

    frontier = {d["id"] for d in brain.explore_frontier(k=6, mode="gaps")}
    bridges = brain.bridge_hypotheses(k=6)
    cal = brain.calibrate()

    nodes = [{"id": ids[i], "x": round(float(norm[i, 0]), 4), "y": round(float(norm[i, 1]), 4),
              "trust": round(float(trusts[i]), 3), "cent": round(float(cent[i]), 3),
              "domain": meta[i]["domain"], "type": meta[i]["claim_type"],
              "text": meta[i]["text"], "frontier": ids[i] in frontier,
              "checked": bool(trusts[i] != 0.0)} for i in range(len(ids))]
    idx = {n["id"]: n for n in nodes}
    links = [{"a": b["a"], "b": b["b"], "sim": b["similarity"],
              "ad": b["a_domain"], "bd": b["b_domain"]}
             for b in bridges if b["a"] in idx and b["b"] in idx]

    data = {"nodes": nodes, "links": links,
            "meta": {"embedder": brain.embedder_id, "n": len(ids),
                     "checked": int((trusts != 0.0).sum()),
                     "licensed": cal.get("licensed"), "skill": cal.get("skill"),
                     "checked_skill": cal.get("checked_only", {}).get("skill")}}
    Path(out_path).write_text(_html(data))
    return data["meta"]


def _html(data: dict) -> str:
    return _TEMPLATE.replace("__DATA__", json.dumps(data))


_TEMPLATE = r"""<!doctype html><html><head><meta charset="utf-8">
<title>Fact brain — semantic-trust map</title>
<style>
  :root{--bg:#0f1117;--fg:#e6e6e6;--muted:#8a90a0;--grid:#1c2030;
        --neg:#e5484d;--zero:#6b7280;--pos:#30a46c;--bridge:#8b5cf6;--ring:#f5a623;}
  *{box-sizing:border-box} body{margin:0;background:var(--bg);color:var(--fg);
    font:14px/1.5 -apple-system,Segoe UI,Roboto,sans-serif}
  .wrap{max-width:1000px;margin:0 auto;padding:18px}
  h1{font-size:18px;margin:0 0 2px} .sub{color:var(--muted);font-size:12.5px;margin-bottom:12px}
  .legend{display:flex;gap:14px;flex-wrap:wrap;align-items:center;font-size:12px;color:var(--muted);margin:8px 0}
  .dot{display:inline-block;width:10px;height:10px;border-radius:50%;margin-right:5px;vertical-align:-1px}
  svg{width:100%;height:auto;background:
    linear-gradient(var(--grid) 1px,transparent 1px) 0 0/40px 40px,
    linear-gradient(90deg,var(--grid) 1px,transparent 1px) 0 0/40px 40px,var(--bg);
    border:1px solid var(--grid);border-radius:10px}
  .node{cursor:pointer;stroke:#0b0d13;stroke-width:.6}
  .node:hover{stroke:#fff;stroke-width:1.4}
  .link{stroke:var(--bridge);stroke-opacity:.5;stroke-dasharray:3 3}
  .ring{fill:none;stroke:var(--ring);stroke-width:1.6;stroke-opacity:.9}
  #tip{position:fixed;pointer-events:none;max-width:320px;background:#171b26;
    border:1px solid #2a3040;border-radius:8px;padding:9px 11px;font-size:12.5px;
    opacity:0;transition:opacity .08s;box-shadow:0 6px 24px #0008;z-index:9}
  #tip .t{color:var(--fg);margin-bottom:5px} #tip .m{color:var(--muted);font-size:11.5px}
  .pill{display:inline-block;padding:1px 6px;border-radius:20px;font-size:11px;margin-right:5px}
</style></head><body><div class="wrap">
  <h1>Fact brain — semantic-trust map</h1>
  <div class="sub" id="cap"></div>
  <div class="legend">
    <span><span class="dot" style="background:var(--pos)"></span>trusted (external check &gt; 0)</span>
    <span><span class="dot" style="background:var(--zero)"></span>unchecked (trust = 0)</span>
    <span><span class="dot" style="background:var(--neg)"></span>distrusted (&lt; 0)</span>
    <span><span class="dot" style="background:var(--ring);border-radius:2px"></span>exploration frontier</span>
    <span><span style="color:var(--bridge)">— —</span> cross-domain bridge</span>
    <span>size = centrality</span>
  </div>
  <svg id="svg" viewBox="0 0 960 620" preserveAspectRatio="xMidYMid meet"></svg>
  <div class="sub" style="margin-top:10px">Position = meaning (PCA of embeddings). Colour = trust,
    which comes only from external checks — the brain never invents it. Everything here is a
    view of the real data; the frontier and bridges are <b>proposals for the next external check</b>.</div>
</div><div id="tip"></div>
<script>
const DATA = __DATA__;
const svg = document.getElementById('svg'), NS='http://www.w3.org/2000/svg';
const W=960,H=620,P=44;
const X = v => P + v*(W-2*P), Y = v => (H-P) - v*(H-2*P);
function color(t){ if(t>0) return `rgba(48,163,108,${.45+.55*Math.min(1,t)})`;
  if(t<0) return `rgba(229,72,77,${.45+.55*Math.min(1,-t)})`; return '#6b7280'; }
const m=DATA.meta;
document.getElementById('cap').textContent =
  `${m.n} facts · ${m.checked} externally checked · embedder ${m.embedder} · `
  +`trust-imputation licensed: ${m.licensed} (skill ${m.skill}; checked-only ${m.checked_skill})`;
const byId={}; DATA.nodes.forEach(n=>byId[n.id]=n);
// bridge links first (under nodes)
DATA.links.forEach(l=>{const a=byId[l.a],b=byId[l.b];
  const ln=document.createElementNS(NS,'line'); ln.setAttribute('class','link');
  ln.setAttribute('x1',X(a.x));ln.setAttribute('y1',Y(a.y));
  ln.setAttribute('x2',X(b.x));ln.setAttribute('y2',Y(b.y)); svg.appendChild(ln);});
// nodes
const tip=document.getElementById('tip');
DATA.nodes.forEach(n=>{
  const r=4+9*n.cent;
  if(n.frontier){const rg=document.createElementNS(NS,'circle');rg.setAttribute('class','ring');
    rg.setAttribute('cx',X(n.x));rg.setAttribute('cy',Y(n.y));rg.setAttribute('r',r+4);svg.appendChild(rg);}
  const c=document.createElementNS(NS,'circle'); c.setAttribute('class','node');
  c.setAttribute('cx',X(n.x));c.setAttribute('cy',Y(n.y));c.setAttribute('r',r);
  c.setAttribute('fill',color(n.trust));
  c.addEventListener('mousemove',e=>{tip.style.opacity=1;
    tip.style.left=Math.min(e.clientX+14,innerWidth-336)+'px';tip.style.top=(e.clientY+14)+'px';
    const st=n.checked?(n.trust>0?'trusted':'distrusted'):'unchecked';
    tip.innerHTML=`<div class="t">${n.text}</div><div class="m">`
      +`<span class="pill" style="background:${color(n.trust)}22;color:${color(n.trust)}">${st} · trust ${n.trust}</span>`
      +`<span class="pill" style="background:#222a">${n.domain}</span>${n.id}`
      +(n.frontier?` · <span style="color:var(--ring)">frontier: check next</span>`:'')+`</div>`;});
  c.addEventListener('mouseleave',()=>tip.style.opacity=0);
  svg.appendChild(c);});
</script></body></html>"""


if __name__ == "__main__":
    meta = build(str(HERE / "brain.db"), str(HERE / "brain_map.html"))
    print(f"[brain_map] wrote brain_map.html — {meta}")
