# Ayan

We spend too much of our day managing how we manage our day.

Every time tracker demands a tax on your attention. You have to remember to start it. You have to remember to stop it. You have to categorize what you just did. This constant context-switching fractures your flow state. The tool meant to measure your productivity actively disrupts it.

Ayan was built on a different philosophy: **your tools should get out of your way.** 

There are no start buttons. There are no stop buttons. You don't log activities. Ayan sits invisibly in the background and simply observes your active windows—the code directories you open, the web services you use, the documents you write. 

By recognizing these patterns, it automatically pieces together the narrative of your day. When you are ready to review your work, your timeline is already written. 

---

### The Principles
1. **Zero Friction:** You should never have to tell your computer what you are doing on your computer. It already knows. 
2. **Context, Not Just Time:** Knowing you spent two hours in "Xcode" is useless. Ayan captures the actual project folders and document names to provide meaningful context.
3. **Absolute Privacy:** Your activity is your business. Ayan has no cloud sync, no accounts, and no telemetry. Everything is written to a local SQLite database that never leaves your machine.

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
If Ayan helps you reclaim your focus, consider supporting its development:

<a href="https://buymeacoffee.com/ihabahmed" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
