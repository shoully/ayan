# Ayan: Ambient Flow-State Monitor

Ayan is a privacy-first, context-aware productivity companion for macOS. It replaces the traditional "stopwatch" time tracker with an **Ambient Intelligence** engine that observes your environment and reflects your focus back to you.

## 🧠 The Philosophy

### 1. The OS is the Project
Ayan treats your entire operating system as a dynamic workspace. It doesn't see "apps"; it recognizes "States." Whether you are in iTerm2, Firefox, or Pages, Ayan understands the **Intent** behind your tools.

### 2. Intentional Flow over Manual Tracking
Stopwatches are a cognitive burden. Ayan uses **Contextual Fingerprinting** to detect when you are working on a specific project (e.g., via local domains like `mizan.local` or terminal paths) and only nudges you to confirm its assumptions.

### 3. Calm Technology
Ayan follows the principles of Calm Technology. It lives in the periphery—your menu bar or a subtle floating "nudge"—rather than demanding your center of attention.

### 4. The Personal Black Box
Your data is yours. Ayan is local-only, using SwiftData to store your "Narrative" securely on your machine. No cloud, no tracking, just reflection.

---

## 🛠 Development Roadmap

### Phase 1: The Senses (Context Observation)
*   **App Observation:** Detect active application switches via `NSWorkspace`.
*   **Deep Inspection:** Use Accessibility APIs (`AXUIElement`) to read window titles.
*   **Browser Intelligence:** Use AppleScript to extract active URLs from Firefox for `.local` or `.dev` domain detection.

### Phase 2: The Brain (Intent Engine)
*   **Fingerprinting Models:** Define `Project` rules (e.g., "If URL contains X or Terminal path is Y").
*   **State Machine:** Manage transitions between `Flow`, `Uncertain`, and `Drift`.
*   **Persistence:** Local SwiftData store for projects and time entries.

### Phase 3: The Nudge (Ambient Interaction)
*   **Floating Toast:** A non-intrusive SwiftUI "pill" for one-tap context confirmation.
*   **Menu Bar Glow:** A color-coded menu bar presence that reflects the active project state.

### Phase 4: The Narrative (Reflection)
*   **Timeline View:** A text-based, chronological "Narrative" of your day.
*   **Manual Correction:** Simple UI to bridge gaps or correct misidentified drift.

---

## 🔒 Permissions Required
To function as an autonomous observer, Ayan requires:
1. **Accessibility Permissions:** To read window titles and UI elements.
2. **Automation Permissions:** To query browser URLs via AppleScript.
