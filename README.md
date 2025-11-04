# Java Version Switcher

A lightweight PowerShell CLI tool for quickly switching between multiple Java versions on Windows.

This tool allows you to define a root directory (`JAVA_ROOT`) containing your various Java installations and interactively choose which one to activate.
The selected version is automatically set as your `JAVA_HOME`, and your environment variables (including `Path`) are updated accordingly.
No manual edits, reboots, or configuration hassles.

<img width="704" height="438" alt="switch-java" src="https://github.com/user-attachments/assets/e085b793-dd97-49e5-b272-71e77db0dad2" />

## ▶️ Usage

No setup or configuration is required.

Simply download all the necessary files and run the main script (**`switch-java.ps1`**) in PowerShell, and follow the interactive prompts to select your desired Java version.
Everything happens directly within the tool.

Additionally, you can run this tool by launching its standalone version (**`switch-java-single.ps1`**), which already includes all the required dependencies.

## ⚙️ Administrator Privileges

Running the script as an administrator is **strongly recommended**.

Without admin privileges, it can only modify **user-level** environment variables.
If a **system-level** Java path already exists, those changes will be ignored.

To ensure the switch works properly, either:

- Remove any Java entries from your system-level `Path`, **or**
- Run the tool with **administrator rights**.

## ⚠️ Alpha Version Notice

This is an early (alpha) release and has not yet been thoroughly tested.

Because it modifies environment variables, including your `Path`, please **back up your current Path** before use.
If anything unexpected happens, you can restore your environment and report an issue directly in this repository.

While the tool *should* behave safely, caution is advised.
You’ve been warned 🙂
