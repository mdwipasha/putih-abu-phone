# Putih-Abu Phone Framework 📱

A modern, highly-detailed iPhone 5 roleplay framework for Roblox. Built with Luau and managed via [Rojo](https://github.com/rojo-rbx/rojo), this framework provides a realistic smartphone experience including a 3D physical model, smooth UI animations, and modular apps.

## ✨ Features

- **3D Physical Phone & Animations:** Players physically hold the phone in their hands with customized arm animations. The 3D model features a complete iPhone 5 design (screen, camera, flash, home button).
- **Home Screen & Lock Screen:** Dynamic lock screen with a working time display, notification support, and an interactive music widget.
- **Settings App:** Customize phone wallpapers using any Roblox Image Asset ID.
- **Music App (iTunes/Apple Music):** Fully functional music player. Plays 3D spatial audio that replicates across the server. Includes playback scrubbing, volume control, repeat, and shuffle.
- **Camera App:** Take photos in-game! Includes UI effects like flash and shutter animations, and physically saves the pictures to the phone's gallery.
- **Gallery App:** View, manage, and browse photos you've taken using the Camera app.
- **Modular App System:** Easily create and register your own custom apps without touching the core framework.

---

## 🚀 Installation Guide

You can either test the phone in a fresh place, or install it into your existing Roblox game.

### Method 1: Fresh Place (Testing)
To build a brand new place from scratch containing only the phone framework:
1. Clone this repository.
2. Run the following command in your terminal to build the `.rbxlx` file:
   ```bash
   rojo build -o "putih-abu-phone.rbxlx"
   ```
3. Open `putih-abu-phone.rbxlx` in Roblox Studio.

### Method 2: Installing into an Existing Game
If you want to add this phone to an existing game, you must sync the scripts into the correct services using Rojo:

1. Clone this repository.
2. Start the Rojo server in your terminal:
   ```bash
   rojo serve
   ```
3. Open your existing game in Roblox Studio and connect the Rojo plugin.
4. Rojo will automatically sync the folders into these specific locations based on `default.project.json`:
   - `src/shared` ➔ `ReplicatedStorage.Shared`
   - `src/server` ➔ `ServerScriptService.Server`
   - `src/client` ➔ `StarterPlayer.StarterPlayerScripts.Client`
5. *Note: If you don't use Rojo for your main game, you can build the `.rbxlx` file (Method 1), open it, and manually copy those three folders into your game's corresponding services.*

---

## 💻 Client Usage API

To interact with the phone programmatically from any LocalScript, you can require the core framework:

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhoneFramework = require(ReplicatedStorage.Shared.PhoneFramework)

-- Start and initialize the phone
local Phone = PhoneFramework.Start()

-- API Methods
Phone:Open()                             -- Pulls the phone up
Phone:Close()                            -- Puts the phone away
Phone:Lock()                             -- Locks the phone (shows Lock Screen)
Phone:Unlock()                           -- Unlocks the phone (shows Home Screen)
Phone:OpenApp("music")                   -- Opens a specific app by its ID
Phone:CloseCurrentApp()                  -- Returns to the Home Screen
Phone:SendNotification({                 -- Sends a push notification
    Title = "Messages", 
    Body = "Hey, where are you?" 
})
```

---

## 🛠️ Creating Custom Apps

The framework is strictly modular. To create a new app, simply create a new `ModuleScript` inside `src/shared/PhoneFramework/Apps`. 

The framework automatically scans this folder and mounts the app. Your module must return a table with the following structure:

```luau
local App = {
    Id = "myapp",                -- Unique identifier
    Name = "My App",             -- Name displayed on the Home Screen
    Order = 10,                  -- Determines position on the Home Screen
    Icon = {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Image = "rbxassetid://123456789", -- Roblox Image Asset ID
    }
}

function App.Create(context)
    -- context provides:
    -- context.Root (Frame): The parent frame where your app's UI goes
    -- context.CloseCurrentApp (Function): Call this to exit the app
    
    local label = Instance.new("TextLabel")
    label.Text = "Hello World"
    label.Size = UDim2.fromScale(1, 1)
    label.Parent = context.Root
end

return App
```

> **Note on Icons:** You must use a valid Roblox Asset ID (`rbxassetid://...`) for the `Icon.Image`. Local files (`.png` or `.ico`) cannot be loaded dynamically by Roblox UI at runtime; they must be uploaded to Roblox first.

---

## Bank App Integration

The Bank app is a presentation-only client for the standalone Economy Framework. It never reads DataStores, economy cache modules, or internal economy services directly.

### Folder Structure

- `src/shared/PhoneFramework/Apps/Bank.luau` - mobile banking UI, local `BankState`, page navigation, dialogs, transfer form, transaction list, and transaction details.
- `src/shared/PhoneFramework/Services/EconomyAdapter.luau` - client adapter used by the Bank UI. It wraps remote calls in protected calls, normalizes responses, and returns placeholders when the economy service is unavailable.
- `src/server/EconomyNetwork.server.luau` - server bridge from remotes to the public `EconomyFramework.API.Economy` module.
- `src/server/EconomyFramework/API/Economy.luau` - public Economy Framework API surface.

### Public Interfaces

The Bank UI calls only `EconomyAdapter`:

```luau
EconomyAdapter.GetPlayerData()
EconomyAdapter.GetBalance()
EconomyAdapter.GetPhoneNumber()
EconomyAdapter.GetTransactionHistory()
EconomyAdapter.Transfer(phoneNumber, amount, description)
EconomyAdapter.OnBalanceChanged(callback)
EconomyAdapter.OnTransactionCreated(callback)
EconomyAdapter.OnPlayerDataLoaded(callback)
```

The server bridge calls only public Economy APIs such as `Economy.GetBalance`, `Economy.GetPhoneNumber`, `Economy.GetTransactionHistory`, `Economy.TransferByPhone`, and `Economy.GetPlayerData`.

### State Management

`Bank.luau` renders from a local `BankState` containing balance, phone number, player name, transactions, loading state, loaded state, error state, current page, and selected transaction. Economy values are refreshed through the adapter; the UI does not modify balances or manufacture transaction history.

### Event Usage

The server bridge forwards public economy events to the owning client:

- `BalanceChanged` refreshes balance and account data.
- `TransactionCreated` refreshes transaction history.
- `PlayerDataLoaded` refreshes the full UI.

The app does not continuously poll. While offline or waiting for remotes/data, it opens immediately with placeholders: balance `0`, phone number `-`, player name `Unknown`, and an empty transaction list.

### Extension Points

Future banking features such as ATM, savings, loans, bills, taxes, marketplace purchases, or multiple accounts should add UI pages and adapter methods first. Keep business rules in the Economy Framework and expose them through public economy APIs before wiring them into the Bank app.
