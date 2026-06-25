# Design System Specification: Neon Fluidic Editorial

## 1. Overview & Creative North Star
**The Creative North Star: "The Luminescent Pulse"**

This design system rejects the clinical, static nature of traditional healthcare apps in favor of a living, breathing digital organism. We are moving away from the "Dashboard of Charts" and toward a "Curated Health Narrative." 

The aesthetic is driven by **intentional asymmetry** and **tonal depth**. By placing hyper-vibrant neon accents against a void-like charcoal background, we create a sense of infinite space. Elements should never feel "pasted on"; they should feel as though they are floating in a pressurized, fluid environment. We break the grid by allowing organic, fluid shapes to bleed off-canvas, suggesting a system that is too expansive to be contained by a screen.

---

2. Colors & Surface Architecture

The palette is built on extreme contrast: the "Void" (deep blacks) vs. "The Pulse" (electric neons). 

### The Palette
- **Background (`#0e0e0e`):** The foundation of the entire experience.
- **Primary / Electric Lime (`#f3ffca`):** Use for high-priority health data and "Positive" states.
- **Secondary / Cyber Blue (`#00eefc`):** Use for AI-driven insights and technical data visualizations.
- **Tertiary / Hot Pink (`#ff6b9b`):** Use for critical alerts, biological markers, or "Action Required" states.

### The "No-Line" Rule
Traditional 1px solid borders are strictly prohibited for sectioning. Use background shifts instead. A `surface-container-low` section sitting on a `surface` background creates a sophisticated boundary that feels architectural rather than "templated."

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers of frosted glass.
*   **Layer 0 (Background):** Base layer (`surface`).
*   **Layer 1 (Main Content):** Large sections use `surface-container-low`.
*   **Layer 2 (Interactive Cards):** Components use `surface-container-high` with 40% opacity and a `backdrop-filter: blur(20px)`.

### Signature Textures: The Fluid Gradient
For main CTAs or Hero backgrounds, use a **Fluidic Gradient**: A linear-gradient (135deg) transitioning from `primary` (`#f3ffca`) to `primary_container` (`#cafd00`). This adds "soul" and a sense of liquid energy to the interface.

---

## 3. Typography
We utilize a pairing of **Space Grotesk** (Display/Headlines) and **Manrope** (Body/Labels) to balance high-tech precision with human readability.

- **Display & Headlines (Space Grotesk):** These are your "Editorial Statements." Use `display-lg` (3.5rem) with tight letter-spacing (-0.02em) to create a bold, authoritative voice. 
- **Body & Labels (Manrope):** Designed for maximum legibility of complex health data. 
- **The Hierarchy Strategy:** Use extreme scale contrast. A `display-md` headline should be paired with a `body-sm` description to create a sophisticated, high-end editorial look that feels like a premium health journal.

---

## 4. Elevation & Depth

### The Layering Principle
Depth is achieved through **Tonal Layering**. To create lift, stack `surface-container-highest` on top of `surface-container-low`. The 2-tone shift provides enough contrast for the eye without requiring a heavy-handed shadow.

### Ambient Shadows & Neon Glows
Shadows are not grey; they are light. 
*   **Floating Elements:** Use a shadow with a 40px blur at 6% opacity, using the `secondary` (`#00eefc`) color as the shadow tint. This mimics a neon light reflecting off a dark surface.
*   **The "Ghost Border":** If a container requires a border for accessibility, use the `outline_variant` token at **15% opacity**. This creates a "hairline" effect that appears and disappears as the user scrolls.

### Glassmorphism Specs
All cards must implement:
- `background`: `rgba(26, 25, 25, 0.6)` (Surface Container)
- `backdrop-filter`: `blur(16px)`
- `border`: `1px solid rgba(255, 255, 255, 0.1)`
- `box-shadow`: `0 8px 32px 0 rgba(0, 0, 0, 0.8)`

---

## 5. Components

### Buttons
*   **Primary:** `primary_container` background with `on_primary_container` text. Apply a `xl` (3rem) corner radius. Add a subtle outer glow using the `primary_dim` color.
*   **Secondary:** Ghost style. Transparent background with a `secondary` ghost border (20% opacity) and `secondary` text.

### Fluid Progress Bars
Progress bars should never be rectangular. Use `full` (9999px) roundedness. The track should be `surface_container_highest`, and the indicator should be a gradient from `secondary` to `primary`.

### Data Visualizations
*   **The "Pulse" Chart:** Use thin, 2px lines with an outer glow.
*   **Data Points:** Use `tertiary` (Hot Pink) for outliers or errors to immediately draw the eye against the neon greens and blues.

### Cards & Lists
**Forbid dividers.** Use vertical white space from the Spacing Scale (specifically `8` (2.75rem) or `10` (3.5rem)) to separate list items. Content should be grouped by "logical islands" of space, not lines.

### Additional AI Component: "The Insight Orb"
A floating, organic SVG shape that slowly morphs (using CSS animation). This represents the Health AI's "thinking" state. Use a mesh gradient of `primary`, `secondary`, and `tertiary`.

---

## 6. Do's and Don'ts

### Do:
- **Use Intentional Asymmetry:** Align a headline to the left and the supporting data to the far right to create a sophisticated, non-linear flow.
- **Embrace the Glow:** Use subtle neon glows on icons (`thin-line` weight) to make them feel like light-emitting diodes.
- **Apply Large Radius:** Use `xl` (3rem) and `lg` (2rem) for containers to maintain the "fluidic" and organic feel.

### Don't:
- **Don't use 100% White:** For body text, use `on_surface_variant` (`#adaaaa`) to reduce eye strain against the black background. Reserve pure white (`#ffffff`) for headlines only.
- **Don't use "Drop Shadows":** Never use a standard black `(0,0,0, 0.5)` shadow. It muddies the deep charcoal surfaces. Always use tinted, low-opacity ambient glows.
- **Don't Overcrowd:** This design system relies on "The Void." If a screen feels busy, increase the spacing tokens (e.g., move from `6` to `12`).