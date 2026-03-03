<p align="center">
  <img src="assets/AyanLogo.svg" alt="Ayan Logo" width="160" />
</p>

<h1 align="center">Ayan</h1>

<p align="center">
  <strong>The invisible, zero-friction time narrative for professionals.</strong>
</p>

<p align="center">
  Ayan observes your workflow silently in the background, transforming your digital activity into a structured narrative without ever requiring a start or stop button.
</p>

---

### The Problem: The "Attention Tax"
Standard time trackers demand a constant tax on your focus. You have to remember to start them, stop them, and categorize what you just did. This context-switching actively fractures the very flow state you are trying to measure. 

**Ayan was built on a different philosophy: your tools should get out of your way.**

### The Principles
*   **Zero Friction:** You should never have to tell your computer what you are doing. It already knows.
*   **Contextual Intelligence:** Time spent in an "IDE" is raw data; time spent on "Project X" is insight. Ayan reconstructs context from your window titles and directory structures.
*   **Absolute Privacy:** Your work is your business. Ayan has no cloud sync, no accounts, and no telemetry. Your data lives in a local SQLite database that never leaves your machine.

---

### Key Features

#### 🧠 Intent Engine (Project Affinity)
*   **Smart Stickiness:** A 10-minute "Project Affinity" window ensures that brief interruptions (Slack, Mail, Zoom) are correctly attributed to your active project instead of being lost to "Drift."
*   **SaaS Detection:** Deep regex parsing for **Jira**, **Figma**, and **Linear** automatically extracts project IDs and task names from your browser context.
*   **Git Root Awareness:** Intelligently recognizes project boundaries by analyzing directory structures and repository names in Terminals and IDEs.

#### 🛠 Deep Tool Integration
*   **Professional Adapters:** Native support for **VS Code**, **Xcode**, **Sublime Text**, **iTerm2**, and major browsers (**Safari**, **Chrome**, **Firefox**).
*   **Activity Tagging:** Automatically categorizes entries into professional domains: *Coding*, *Communication*, *Design*, *Planning*, and *Research*.

#### 💼 Consultant-Ready Workflow
*   **One-Click Export:** Generate professional CSV reports formatted for instant timesheet generation and client billing.
*   **High-Contrast UI:** A permanent dark-mode, zero-transparency interface designed for maximum readability over dense code and design environments.
*   **Customizable Heuristics:** Tailor the detection engine by defining your own code roots, service names, and blacklisted keywords.

---

### Screenshots

| Summary View | Projects View | Keywords View |
| :---: | :---: | :---: |
| <img src="assets/001 Summary.jpg" width="400" /> | <img src="assets/002 Projects.jpg" width="400" /> | <img src="assets/003 Keywords.jpg" width="400" /> |
| *Real-time narrative of your day.* | *Automatic project attribution.* | *Smart extraction of IDs.* |

---

### Technical Stack
- **Frontend:** SwiftUI (macOS Native)
- **Persistence:** SwiftData / SQLite
- **Engine:** Accessibility API (`AXUIElement`) & AppleScript Deep Context Extraction

---

### Installation & Deployment
Ayan requires deep system access to read window titles and document paths. To simplify the setup while ensuring you remain in control of permissions, run this automated installer in your Terminal:

```bash
curl -sL https://raw.githubusercontent.com/shoully/ayan/main/remote_install.sh | bash
```

---

### For Developers
If you wish to improve Ayan, customize the logic, or compile it yourself:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/shoully/ayan.git
   ```
2. **Open in Xcode:** Locate and open the `Package.swift` file or the project folder in Xcode.
3. **Customize & Build:** You can modify the `IntentEngine` heuristics or UI components directly. Press `Cmd + R` to build and run locally.
4. **Grant Access:** Ensure Accessibility permissions are granted in `System Settings > Privacy & Security > Accessibility` for your local build.

---

### Support
If Ayan helps you reclaim your focus and simplify your reporting, consider supporting its development:

<a href="https://buymeacoffee.com/ihabahmed" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
