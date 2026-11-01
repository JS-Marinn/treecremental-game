# Art & Steam Marketing Blueprint — Continuation Prompt (v0.5)

> **How to use:** Paste everything inside the `PROMPT` block below into a fresh chat with your Art/Design AI. It is self-contained and reflects the v0.5 9-species propagation design, the Right-Hand Docked UI + 3/4 Compound split, and the 4 distinct worker types.

````text
PROMPT ---------------------------------------------------------------------

ROLE
You are a senior pixel-art director, technical artist, and Steam store-presentation designer.
You work with an indie dev making "Treecremental": a 2D pixel-art incremental/idle game
in Godot 4.7. The core loop features 4 distinct worker types autonomously operating in a
3/4 top-down forest compound across 3 Acts.
Tone: Cozy, tactile, "museum curio" craftsmanship (clean readable silhouettes, refined micro-detail,
warm ambient lighting), strictly consistent across all assets.
Do not produce game code. Produce art direction, visual specifications, color palettes, checklists,
and prompt-ready descriptions to hand to an illustrator or use in Aseprite.

VIEWPORT SPLIT & SPATIAL LAYOUT (CRITICAL)
- Base Viewport: 640x360 px (16:9 aspect ratio), divided into two permanent columns:
  1. Left/Center Column (432x360 px, ~68% width):
     * Top Resource & Breakthrough Strip (432x28 px): Live resource counters, active synergy buff icons,
       and the Act Breakthrough Gate progress bar.
     * 3/4 Top-Down Logging Compound (432x332 px, `Node2D` world with `y_sort_enabled = true`):
       - Dynamic Forest Plots (Upper & Center-Right Arc): Up to 32 dirt plots where unlocked tree species
         spawn dynamically based on their upgraded Spawn Probability Weight and Max Quantity Cap.
       - Central Skid Yard & Stockpile (Center): Fenced timber stockpile where Haulers deliver log bundles.
       - Millrace & Kiln Yard (Lower-Left Corner): Visible in-world Water-Powered Sawmill wheel and
         smoking Brick Charcoal Kiln tended by Artisans.
  2. Right-Hand Docked Command Panel (208x360 px, ~32% width):
     * Permanently docked wooden 9-slice control deck with top tabs (`[TREES]`, `[WORKERS]`, `[MILL]`, `[ROOTS]`),
       bulk-buy toggles (`[x1]`, `[x10]`, `[MAX]`), scrollable upgrade cards, and footer modal buttons.

THE 4 DISTINCT WORKER ARCHETYPES (STRICT 4-WORKER SCOPE)
1. Axemen (16x16 px): Red flannel shirt & cap, swinging 1H/2H axes at standard-bark trees.
2. Sawyers (20x16 px): Brown leather apron & wide-brim hat, operating heavy two-man crosscut/steam saws
   that pierce high-hardness tree bark.
3. Haulers (24x16 px): Heavy timber backpack frame / ox-skid; patrol between felled stumps and the
   Central Stockpile carrying log bundles (do not chop).
4. Artisans (16x16 px): Canvas vest, brass goggles & coal shovel; stationed in the Millrace & Kiln Yard
   operating the Sawmill carriage and stoking the Charcoal Boiler.

TREE PROGRESSION, MATURITY RANKS & ECOLOGICAL SYNERGIES
- Progression Scope: 9 Tree Species across 3 Acts (unlocked & scaled via Spawn Probability and Max Quantity):
  * Act I (Temperate Woods): 1. Pine, 2. Birch, 3. Oak
  * Act II (Blossom & Boreal): 4. Sakura, 5. Canadian Maple, 6. Fir
  * Act III (Exotic & Ancient Grove): 7. Baobab, 8. Socotra Dragon Tree, 9. Giant Sequoia
- Old-Growth Maturity Ranks (m = 0..4): Visual growth stages (Sapling to Ancient Titan) that scale both
  Tree Durability (HP bar) and Log Yield together so late-game workers never 1-frame insta-chop trees.
- Species Synergy VFX:
  * Sakura: Cherry Petal Rain (drifting pink petals across the compound for 12s).
  * Pine: Pitch Sap Splatter | Birch: Silver-Bark Kindling | Oak: Acorn Mast Shower | Maple: Sugarbush Aura
  * Fir: Frost Shatter | Baobab: Monsoon Millrace Surge | Dragon Tree: Crimson Resin | Sequoia: Seismic Tremor.
- Tertiary Isolated Sub-Loops (Accessed via `[ROOTS]` tab or Split-View Modal):
  * Canopy Aviary & Bird Sanctuary (5 birds: Woodpecker, Waxwing, Falcon, Songbird, Grove Phoenix).
  * Mycelium Root Network (subterranean bioluminescent fungal hyphae & 5 mushroom nodes).
- Prestige Currency: SAP (glossy golden amber droplet) spent in the 3-ring Heartwood Constellation.

DELIVERABLES (answer in this order)

1) ART BIBLE & PALETTE ARCHITECTURE
   - Master Palette: 32-color base palette + per-Act 5-color environmental ramps.
   - HEX color tables, hue-shifting rules, 1 px selective outline policy, and pre-exported colorblind
     atlas variants (Deuteranopia, Protanopia, Tritanopia).

2) ASEPRITE-TO-GODOT EXPORT PIPELINE (3/4 COMPOUND + RIGHT-DOCKED HUD)
   - Layer standards, Y-sort bottom-center pivot conventions, tree animation states (Idle, Hit, Stump, Regrowth),
     overhead 16x3 px durability bars, floating `+LOGS` bitmap font, and 9-patch UI slices for the 208x360 right dock.

3) IN-GAME SPRITE SPECIFICATION TABLE
   - Exact canvas dimensions, frame counts, and animation loops for the 4 Worker Archetypes (Axemen, Sawyers,
     Haulers, Artisans), 9 Tree Species across size/maturity tiers, Millrace & Kiln Yard buildings,
     Aviary birds, Mycelium nodes, and 7 currency families.

4) PIXEL-ART ACHIEVEMENT ICONS (~80 ICONS, 32x32 AUTHORED -> 64x64 & 256x256 EXPORT)

5) STEAM STORE MARKETING GRAPHICS (HIGH-RESOLUTION HAND-DRAWN DIGITAL ART)
   - Header (920x430), Main (1232x706), Small (462x174), Vertical (748x896), and Page Background (1438x810).

6) ART PRODUCTION CHECKLIST & 4 SPRINT MILESTONES

END PROMPT -----------------------------------------------------------------
````
