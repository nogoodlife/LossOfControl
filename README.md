# Loss of Control

![Loss of Control Preview](https://github.com/user-attachments/assets/136f150e-c85c-495e-bb9a-995ee2331551)
<!-- Badges Block -->
<p align="left">
  <!-- WoW Version -->
  <a href="https://github.com/s0h2x/LossOfControl/releases">
    <img src="https://img.shields.io/badge/WoW-3.3.5a-0070dd.svg?style=flat-square&logo=worldofwarcraft" alt="WoW Version">
  </a>
  <!-- License -->
  <a href="LICENSE">
    <img src="https://img.shields.io/github/license/s0h2x/LossOfControl?style=flat-square&color=2ecc71" alt="License">
  </a>
  <!-- Latest Version -->
  <a href="https://github.com/s0h2x/LossOfControl/releases/latest">
    <img src="https://img.shields.io/github/v/release/s0h2x/LossOfControl?style=flat-square&color=f39c12&label=ver" alt="Latest Version">
  </a>
  <!-- Total Downloads -->
  <a href="https://github.com/s0h2x/LossOfControl/releases">
    <img src="https://img.shields.io/github/downloads/s0h2x/LossOfControl/total?style=flat-square&color=9b59b6&label=downloads" alt="Downloads">
  </a>
</p>
<details>
  <summary>More screenshots</summary>
  <img src="https://user-images.githubusercontent.com/33549022/204646710-3ec5da44-fb66-4edf-b9b8-c07233ff9aae.png" alt="Old Version">
</details>

**Loss of Control** is a standalone backport of the modern WoW Loss of Control indicator for legacy clients.

It displays crowd control (CC) effects (Stun, Fear, Silence, Disarm, etc.) with an icon, remaining duration, and a cooldown spiral.

## ✨ Features

*   **Retail Experience:** Faithful recreation of visuals and animations.
*   **Accurate Timers:** Handles interrupt lockouts (Kick, Counterspell) correctly.
*   **Customization:**
    *   Unlock and move the frame (`/loc move`)
    *   Scale the frame (`/loc scale`)
    *   Toggle sound alerts (`/loc sound`)
    *   Toggle animations and pulse (`/loc anim`, `/loc pulse`)
    *   Toggle UI elements (`/loc bg`, `/loc lines`)
    *   Add your own custom spells (`/loc add`)
*   **Localized:** `enUS`, `ruRU`, `deDE`, `frFR`, `esES`, `zhCN`, `zhTW`, `koKR`.

## 📂 Installation

1.  Download the **[Latest Release](https://github.com/s0h2x/LossOfControl/releases/latest)** (zip file).
2.  Extract `LossOfControl` into `Interface\AddOns\`.
3.  Restart WoW.

## ⚙️ Commands

Settings available via `/loc` or `/los`.

| Command | Action |
| :--- | :--- |
| `/loc move` | **Unlock frame** to move it |
| `/loc scale <n>` | Set size (0.5 to 3.0) |
| `/loc sound` | Toggle alert sound |
| `/loc add <id> <type>` | Add custom spell override |
| `/loc list` | View custom spells |
| `/loc status` | Show current settings |

---
Copyright (c) 2026 s0h2x. Licensed under [GPLv3](LICENSE).
<!--
# Loss Of Control (standalone)
<h1 align="left">
  <a href="https://github.com/s0h2x/pw_lossofcontrol"><img src="https://user-images.githubusercontent.com/33549022/204646710-3ec5da44-fb66-4edf-b9b8-c07233ff9aae.png" alt="pw_lossofcontrol"></a>
</h1>

<h4 align="left">Loss of Control (Alerter)</h4>
<p align="left">
    <a href="https://github.com/s0h2x/pw_lossofcontrol/releases/latest">
    <a href="https://github.com/s0h2x/pw_lossofcontrol/releases/download/v1.0/pw_lossofcontrol.zip">
    <img src="https://img.shields.io/github/downloads/s0h2x/pw_lossofcontrol/total?label=Download%40latest&style=flat-square&logo=github&logoColor=white"
         alt="Latest">
    <a href="https://wowwiki-archive.fandom.com/wiki/Patch_3.3.5">
    <img src="https://img.shields.io/badge/WoWPatch-3.3.5-blue?style=flat-square"
         alt="WoW version dependency">
</p>

## About
- Makes it easy to see the duration of crowd control spells by displaying them on screen.

## Install
- **[Download](https://github.com/s0h2x/pw_lossofcontrol/releases/download/v1.0/pw_lossofcontrol.zip)** latest version
- Extract zip file
- Move sub folder to AddOns
- Remove the word ***-master*** from folder name
- Enjoy!

## Settings
- /loc - For setup frame. **Drag to move, scroll to resize**.
- /locreset - Reset position to default.
-->
