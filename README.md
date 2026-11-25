# WinDisplayHelper Portable (`v1.2.0`)

![Platform](https://img.shields.io/badge/platform-Windows-0078D6?logo=windows&logoColor=white)
![AutoHotkey](https://img.shields.io/badge/AutoHotkey-v2.0-blue?logo=autohotkey)
![Release](https://img.shields.io/badge/release-v1.0.0-green)
[![Downloads](https://img.shields.io/github/downloads/kbenin/WinDisplayHelper-Portable/total?style=flat-square&color=brightgreen)]
![License](https://img.shields.io/badge/license-MIT-yellow)

A lightweight, discreet, zero-install Windows 11 utility that automatically hides a selected application's window and bottom taskbar icon—and optionally mutes its audio—whenever you switch to another window, while keeping the program running smoothly in the background.

<img width="382" height="355" alt="setup" src="https://github.com/user-attachments/assets/c0fa4a2f-e478-4f08-972d-f2713def9f90" />

---

## 📦 Folder Structure

Keep these files together inside your **`WinDisplayHelper-Portable`** folder (works from any directory, cloud folder, or USB drive):

```text
WinDisplayHelper-Portable/
├── StartHelper.bat          # 1-click portable launcher
├── AutoHotkey64.exe         # Digitally signed AutoHotkey v2 runtime engine
├── WinDisplayHelper.ahk     # Core window, taskbar & audio management script
└── README.md                # Documentation & usage guide
```

---

## ✨ Key Features
* **Zero-Blink Window & Taskbar Hiding:** Minimizes the target window (`SW_FORCEMINIMIZE`) before applying `WS_EX_TOOLWINDOW` and hiding (`SW_HIDE`)—preventing ghost taskbar placeholders and stopping background apps from peeking behind smaller floating windows.
* **Per-App Core Audio Auto-Mute:** Uses Windows Core Audio (`ISimpleAudioVolume`) to automatically mute **only** your target `.exe` in the Windows Volume Mixer while hidden, without affecting your browser, music, or voice chat.
* **Sub-Millisecond Event Hook (`0%` Idle CPU):** Uses Windows' native `SetWinEventHook` (`EVENT_SYSTEM_FOREGROUND`) rather than heavy background polling timers for instant focus detection.
* **Interactive Startup Setup GUI:** Launches a compact setup window with a live dropdown of currently open applications (prioritizing `RDR2.exe` when running), a **Refresh** button, an **Auto-mute** toggle, and a **Custom Show/Restore Hotkey** picker.
* **Discreet Background Operation & Auto-Exit:** Runs with zero system tray icons (`#NoTrayIcon`) while active and automatically shuts itself down within 1.5 seconds if you close your target app.
* **Cursor-Safe Cleanup (`OnExit`):** Restores your app's taskbar icon in a minimized, non-activating state (`SW_SHOWMINNOACTIVE`), unmutes audio, and releases cursor locks (`ClipCursor`) upon exit so 3D games never trap your mouse pointer.
* **Smart App Control Friendly:** Runs on the officially signed `AutoHotkey64.exe` runtime rather than an unsigned compiled binary, avoiding Windows 11 Smart App Control blocks.

---

## 🚀 How to Use (Step-by-Step Instructions)

### 1. Launch Your Target Application First
* Open the game or software you want to hide (for example, *Red Dead Redemption 2* or any desktop application).
* *Tip for Games:* Set your game's display mode to **Windowed Borderless** rather than Exclusive Fullscreen for instant, flicker-free switching.

### 2. Run `StartHelper.bat`
1. Double-click **`StartHelper.bat`**.
   * *Note for Elevated / Admin Games:* If your target game or software runs **As Administrator** (such as `RDR2.exe`) and does not hide automatically, exit the helper (`Ctrl + Shift + Backspace`), then right-click **`StartHelper.bat`** and select **Run as administrator**.
2. In the **Display Helper Setup** popup:
   * Select your running app from the dropdown list (click **Refresh** if you opened the app after launching the helper, or type the `.exe` name manually).
   * Leave **Auto-mute app audio while hidden** checked (or uncheck if you want background audio to keep playing).
   * *(Optional)* Click the **Show/Restore Hotkey** box to assign a custom shortcut, or leave it at the default **`Ctrl + Shift + \`**.
   * Click **Start** (or press **Enter**).
3. The setup dialog closes, no tray icon appears, and your selected app's window, taskbar icon, and audio immediately hide while the program continues running normally.

### 3. Hotkeys Reference

| Hotkey | Action |
| :--- | :--- |
| **`Ctrl + Shift + \` (Backslash)** *(or Custom Hotkey)* | **Show / Restore App:** Unhides your target application, restores its bottom taskbar icon, unmutes its audio, and brings it to the front. Switching away to another window automatically hides it again. |
| **`Ctrl + Shift + M`** | **Background Mute Toggle:** Mutes or unmutes your hidden app's audio in the background without bringing its window onto your screen (displays a brief confirmation tooltip). |
| **`Ctrl + Shift + Backspace`** | **Exit & Cleanup:** Safely unhooks the focus listener, restores your app's taskbar icon in a minimized state without locking your mouse cursor, unmutes audio, and closes the helper cleanly. |

---

## ⚖️ Pros & Cons

| Pros | Cons |
| :--- | :--- |
| **Zero Installation & 100% Portable:** Runs straight from any folder or USB drive on Windows 10/11 without installing AutoHotkey. | **Excluded from Native `Alt + Tab`:** Windows ties `Alt + Tab` visibility to taskbar styles; hidden apps must be restored via your **Show/Restore Hotkey**. |
| **Smart App Control Safe:** Relies on Microsoft-trusted `AutoHotkey64.exe` instead of unsigned `.exe` wrappers. | **Single-App Per Session:** Tracks one `.exe` at a time (by design, to avoid multi-window focus conflicts). |
| **Isolated Per-App Audio Control:** Mutes only your chosen `.exe` without touching system volume or other apps. | **Session-Only Settings:** Selected `.exe` and custom hotkeys are held in memory per session and reset on exit. |
| **Self-Cleaning Lifecycle:** Auto-exits when your target app closes and restores icons/audio on any shutdown. | **Privilege Matching Required:** Elevated targets require running `StartHelper.bat` as Administrator. |

---

## 🎯 Scope & Limitations

* **Supported OS:** Windows 11 and Windows 10 (64-bit).
* **Supported Applications:** Standard Win32/Win64 desktop software and games running in **Windowed** or **Windowed Borderless** mode.
* **UWP / Microsoft Store Apps:** Modern Store apps hosted inside `ApplicationFrameHost.exe` (such as Windows Settings or Calculator) manage their own frame windows and may ignore external taskbar style changes.
* **System Helper Filtering:** Automatically ignores invisible Windows text/input helper windows (`Default IME` and `MSCTFIME UI`).

---

## 🛠️ Troubleshooting
* **App remains hidden after force-closing via Task Manager:** Always exit using **`Ctrl + Shift + Backspace`** (or close the target app normally) so the `OnExit` cleanup routine restores your app's taskbar button and audio. If terminated forcibly, simply run `StartHelper.bat` again, pick the same `.exe`, and press **`Ctrl + Shift + Backspace`**.
* **Black-screen flicker when switching back to a game:** Open your game's graphics settings and change **Screen Type** from **Fullscreen** to **Windowed Borderless**.
* **Optional Desktop Shortcut (No Command Prompt Flash):** Right-click `StartHelper.bat` > **Show more options** > **Create shortcut**, move the shortcut to your Desktop, open **Properties**, and set **Run** to **Minimized**.

---

## 📝 Changelog

### `v1.2.0` (Current Release)
* Added **Auto-Exit** watcher (`WatchTargetAlive`) to close the helper automatically when the target app exits.
* Added **`Ctrl + Shift + M`** hotkey to toggle background audio mute/unmute without unhiding the window.
* Added customizable **Show/Restore Hotkey** control inside the startup setup GUI.
* Added strict process-running validation before starting.

### `v1.1.0`
* Added Windows Core Audio (`ISimpleAudioVolume`) per-process auto-mute engine and setup checkbox.
* Guaranteed automatic unmute on restore and exit (`OnExit`).

### `v1.0.0`
* Packaged `WinDisplayHelper.ahk` with signed `AutoHotkey64.exe` and relative-path `StartHelper.bat` launcher.
* Implemented zero-blink hiding (`SW_FORCEMINIMIZE` + `WS_EX_TOOLWINDOW` + `SW_HIDE`), event-driven foreground hook (`SetWinEventHook`), and cursor-safe exit cleanup (`SW_SHOWMINNOACTIVE` + `ClipCursor`).
