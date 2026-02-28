# Ayan

Ayan is a continuous narrative of your work.

There are no start buttons. There are no stop buttons. You don't have to remember to track your time or log your activities. 

Ayan sits silently in your menu bar and observes your active windows. It reads the titles, document names, and paths of the applications you use. By recognizing patterns, it automatically groups your activities into meaningful projects.

When you finish your day, your timeline is already written. 

---

### How it works
1. **Auto-Discovery:** It finds your projects automatically based on keywords, code directory names, or SaaS platforms you use.
2. **Contextual Grouping:** It ignores noise and combines rapid window switching within the same app into clean, continuous entries.
3. **Your Data:** Everything is stored locally on your machine in an SQLite database. It never leaves your computer.

---

### Installation & Compilation
*Why is there no pre-built app?* Because Ayan requires deep system access to read window titles (via Accessibility APIs) and document paths (via AppleScript), it fundamentally conflicts with the strict App Sandbox rules required by macOS for pre-packaged distribution. 

To use Ayan, you must compile it yourself to grant it these necessary permissions on your own machine:
1. Clone this repository.
2. Open the project in **Xcode**.
3. Build and Run.
4. When prompted, grant Ayan permission in `System Settings > Privacy & Security > Accessibility`.

---

### Support
If you find Ayan helpful, consider supporting the development:

<a href="https://buymeacoffee.com/ihabahmed" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
