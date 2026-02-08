# Gym Timer

A totally free and open-sourced gym timer app for iPhone and Apple Watch. Available on the [App Store](https://apps.apple.com/app/gym-timer).

## Features

### iPhone App
- **Prepare / Train / Rest** phases with customizable durations
- **Sets** configuration (1–50 sets)
- **Rest Only Mode** — ideal for strength training (tap when ready for rest countdown)
- **Background notifications** — alerts when each phase completes
- **Audio feedback** — sound cues for phase transitions
- **Multi-language support** — English and Traditional Chinese
- **Dark/Light/System theme** options
- **Portrait lock** — screen stays in portrait

### Apple Watch App
- Full timer with **Prepare / Train / Rest / Tap** phases
- **Settings accessible during session** — use Digital Crown to scroll to settings while timer runs
- **Progress ring** with phase indicator inside
- **Background notifications** — get alerted when phases complete
- **HealthKit workout session** — keeps screen active during workout (on supported devices)
- **Watch complications** — quick access from watch face

## Requirements

- **iPhone**: iOS 17.0+
- **Apple Watch**: watchOS 11.0+
- Xcode 16.0+ (for development)

## Installation

### From Source
1. Clone the repository:
   ```bash
   git clone https://github.com/Gary0302/Gym-timer.git
   cd Gym-timer
   ```
2. Open `Gym-timer.xcodeproj` in Xcode
3. Select your development team under Signing & Capabilities
4. Add **HealthKit** capability to the Watch App target (required for workout session)
5. Build and run on your device or simulator

## Project Structure

```
Gym-timer/
├── Gym-timer/                    # iPhone app
│   ├── TimerView.swift
│   ├── TimerManager.swift
│   ├── SettingsView.swift
│   ├── NotificationManager.swift
│   ├── AudioManager.swift
│   ├── LanguageManager.swift
│   └── ...
├── Gym-timer-watch Watch App/    # Apple Watch app
│   ├── WatchContentView.swift
│   ├── WatchTimerManager.swift
│   ├── WatchNotificationManager.swift
│   └── WatchWorkoutManager.swift
└── Gym-timer.xcodeproj
```

## License

This project is open source. Feel free to use, modify, and distribute.

## Contributing

Issues and pull requests are welcome at [https://github.com/Gary0302/Gym-timer](https://github.com/Gary0302/Gym-timer).

## Contact

- GitHub: [@Gary0302](https://github.com/Gary0302)
- Email: yanggary2388@gmail.com
