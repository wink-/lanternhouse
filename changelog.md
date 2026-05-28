# Changelog

All notable changes to the Lanternhouse project will be documented in this file.

## [Unreleased] - 2026-05-28

### Refactoring & Monolith Cleanups
*   **Battle Visual/Logic Decoupling**: Decoupled the massive turn-based combat script [battle.gd](file:///I:/code/lanternhouse/scripts/battle.gd) by transferring all UI styling, sprite drawing, damage number floaters, screen shakes, screen flashes, and particle/slash animations to a new dedicated [battle_renderer.gd](file:///I:/code/lanternhouse/scripts/battle_renderer.gd) component.
*   **Equipment State Refactor**: Replaced legacy parallel arrays in `GameData` with structured, nested character dictionaries representing equipment states.

### World-Building & Town Pipeline
*   **Town Layout Scaffold**: Added a town layout world-building pipeline and scaffold tool, facilitating rapid procedural grid-aligned town environment creation.
*   **Building Layout Helper**: Created a layout helper for town building placement, ensuring grid-aligned entrance thresholds and facade orientations.
*   **Workshop Interior Transitions**: Added transitions for walking in and out of the workshop interior.

### Gameplay & Systems
*   **Tradeskills & Tinkering**: Added crafted tinkering tools (such as lockpicks) and documented the tradeskill system architecture.
*   **Persistent Cave Chests**: Implemented persistent locked chests in caves that can be lockpicked using crafted tools.
*   **Beacon Lenses**: Added beacon lenses that widen the overworld map fog-of-war reveal radius when held.
*   **Cooked Meal Buffs**: Added a meal buff system where eating cooked meals grants defensive bonuses during combat for a set number of battles.
*   **Save & Load Tests**: Extended save/load system test coverage with automated smoke tests for the new systems.

### Art & Asset Pipeline
*   **Brindlewick Art Pack**: Integrated the Brindlewick town art pack featuring building facades, roofs, and environment props.
*   **Sprite Asset Registry**: Created a unified sprite asset registry (`SpriteCache`) to load characters, enemies, and props dynamically.
*   **Import Settings**: Configured pixel-perfect Godot `.import` metadata for newly added art assets to prevent automatic texture filtering.
