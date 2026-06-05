---
name: visualize
description: >-
  Always use this skill when the user asks to visualize, diagram, draw,
  sketch, illustrate, or chart anything — architecture, data flow, pipelines,
  state machines, class/ER relationships, algorithms, sequences, or "show me
  how X works" as a picture. Trigger on "visualize xxx", "draw a diagram of",
  "make a diagram", "diagram this", "create a flowchart/graph/chart".
allowed-tools:
  - Write
  - Edit
  - Read
  - Bash
---

# Visualize Skill

Two core principles:

1. **Less text** — a diagram is shapes first, words second.
2. **Use drawio** — produce a `.drawio` file (mxGraph XML). Always this
   format, never ASCII art, Mermaid, SVG, or images unless the user overrides.

## Process

1. **Pick a layout** — flow direction (top→down or left→right) and the 3–6
   nodes that matter. Drop everything non-essential.
2. **Write** the `.drawio` file where it belongs (e.g. `docs/`).
3. **Summarize** in chat: one short line per stage, no more.

## Text Discipline (hard rule)

- Node label = a short name, ideally one line. No sentences inside nodes.
- At most one short caption per stage, in a muted `fontColor=#555555` note.
- No legend unless colors are non-obvious. No decorative text.
- Use ellipsis cells (`…`, `⋮`) instead of drawing every element.

## drawio File Skeleton

```xml
<mxfile host="app.diagrams.net" type="device">
  <diagram name="NAME" id="NAME">
    <mxGraphModel dx="1200" dy="800" grid="1" gridSize="10" pageWidth="1200" pageHeight="900">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        <!-- nodes + edges below, parent="1" -->
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

Node: `<mxCell id="n1" value="label" style="..." vertex="1" parent="1"><mxGeometry x=".." y=".." width=".." height=".." as="geometry"/></mxCell>`

Edge: `<mxCell id="e1" value="" style="endArrow=block;html=1;" edge="1" parent="1" source="n1" target="n2"><mxGeometry relative="1" as="geometry"/></mxCell>`

## Style Cheatsheet

- Box: `rounded=0;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;`
- Rounded: add `rounded=1;`
- 3D box: `shape=cube;backgroundOutline=1;fillColor=#dae8fc;strokeColor=#6c8ebf;`
- Cylinder/DB: `shape=cylinder3;`  Decision: `rhombus;`
- Title/caption: `text;html=1;align=left;` (no fill, no stroke)
- Arrow: `endArrow=block;html=1;`  Dashed: add `dashed=1;`
- Newline in a label = `&#10;`

Color families (fill / stroke): blue `#dae8fc/#6c8ebf`, green `#d5e8d4/#82b366`,
orange `#ffe6cc/#d79b00`, gray `#f5f5f5/#666666`. Use one family per stage so
stages read at a glance.

## Reminders

- Offer one concrete follow-up.
- Open hint: diagrams.net, the VS Code Draw.io extension, or `app.diagrams.net`.
