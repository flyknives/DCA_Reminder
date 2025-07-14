# BTC DCA Reminder App

A modern cross-platform Bitcoin Dollar-Cost Averaging (DCA) reminder application, designed to help users make smart investments based on the Bitcoin Rainbow Chart theory. Developed with Flutter.

## App Features

### Detailed Rainbow DCA Algorithm
The core of this application is its intelligent DCA algorithm, based on the Bitcoin Rainbow Chart theory. By logarithmically regressing historical price trends, the price range is divided into different "rainbow zones," with corresponding buying multiplier suggestions for each zone. This helps users maintain rationality during market volatility, buying more when undervalued and less when overvalued.

| Rainbow Zone | Price Status | Suggested Multiplier | Investment Strategy |
|--------------|--------------|----------------------|---------------------|
| 🔵 Deep Blue | Extremely Undervalued | 3.0x | Historical buying opportunity, significantly increase investment |
| 🔵 Blue | Severely Undervalued | 2.0x | Market significantly undervalued, increase investment proportion |
| 🟢 Green | Slightly Undervalued | 1.5x | Market moderately undervalued, can increase investment |
| 🟡 Yellow | Fair Value | 1.0x | Market at fair value, follow normal DCA rhythm |
| 🟠 Orange | Slightly Overvalued | 0.75x | Market slightly overvalued, appropriately reduce investment pace |
| 🔴 Red | Significantly Overvalued | 0.5x | Market significantly overvalued, greatly reduce investment proportion |
| 🔴 Deep Red | Severely Overvalued | 0.25x | Market severely overvalued, maintain minimal investment |
| 🟣 Bubble | Bubble Phase | 0.1x | Market in irrational bubble phase, minimize investment, consider partial profit-taking |

## Installation Steps

1.  **Clone the repository**
    ```bash
    git clone https://github.com/flyknives/DCA_Reminder.git
    cd flutter_btc_dca
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run the application**
    ```bash
    # Run on a connected device (Android/iOS/Desktop)
    flutter run
    ```

### Project Structure
```
flutter_btc_dca/
├── lib/
│   ├── main.dart                 # Application entry point, initialization and routing
│   ├── models/                   # Data model definitions (e.g., BTC data, investment records)
│   │   ├── btc_data.dart
│   │   └── investment_record.dart
│   ├── services/                 # Core service layer (API interaction, notifications, data storage, Rainbow DCA calculation)
│   │   ├── api_service.dart      # Responsible for interacting with external APIs (e.g., Binance)
│   │   ├── notification_scheduler.dart # Notification scheduling service
│   │   ├── notification_service.dart # Local notification management
│   │   ├── rainbow_dca_service.dart  # Rainbow DCA algorithm implementation
│   │   ├── storage_service.dart  # Local data storage (SharedPreferences)
│   │   └── system_tray_service.dart # Desktop system tray integration
│   ├── providers/                # State management (using Provider)
│   │   ├── btc_provider.dart     # BTC data and Rainbow DCA state management
│   │   └── kline_chart_provider.dart # Kline chart data management
│   ├── screens/                  # Various pages of the application
│   │   ├── add_investment_screen.dart # Add investment record page
│   │   ├── home_screen.dart      # Home page, displaying price and Rainbow DCA info
│   │   ├── kline_chart_screen.dart # Kline chart page
│   │   └── settings_screen.dart  # Settings page
│   ├── utils/                    # Utility classes and general functions
│   │   ├── helpers.dart          # Helper functions
│   │   └── theme.dart            # Application theme and color definitions
│   └── widgets/                  # Reusable UI components
│       ├── error_widget.dart
│       ├── investment_record_card.dart
│       ├── loading_widget.dart
│       ├── price_card.dart
│       ├── rainbow_dca_card.dart
│       └── reminder_time_picker.dart
├── pubspec.yaml                  # Project dependencies and metadata configuration
├── README.md                     # Project documentation
└── ... (Other project files, such as assets, test, windows, etc.)
```

## Configuration Instructions

### Modify Base Investment Amount
You can adjust your base DCA amount in the `lib/services/rainbow_dca_service.dart` file:
```dart
// lib/services/rainbow_dca_service.dart
static const double baseAmount = 100.0; // Modify to your desired daily base DCA amount (e.g., 100.0 USDT)
```

### Adjust Rainbow Multipliers
The buying multipliers for the Rainbow DCA can be customized in `lib/services/rainbow_dca_service.dart`:
```dart
// lib/services/rainbow_dca_service.dart
static const Map<double, double> rainbowMultipliers = {
  0.45: 3.0,  // Deep Blue Zone: Historical opportunity, 3x buy
  0.60: 2.0,  // Blue Zone: Severely undervalued, 2x buy
  0.75: 1.5,  // Green Zone: Slightly undervalued, 1.5x buy
  0.90: 1.0,  // Yellow Zone: Fair value, 1x buy
  1.05: 0.75, // Orange Zone: Slightly overvalued, 0.75x buy
  1.20: 0.5,  // Red Zone: Significantly overvalued, 0.5x buy
  1.35: 0.25, // Deep Red Zone: Severely overvalued, 0.25x buy
  1.50: 0.1,  // Bubble Zone: Bubble phase, 0.1x buy
};
```

### Set Reminder Time
The daily reminder time can be configured in `lib/services/notification_scheduler.dart`. By default, it's set to 9 AM daily.
```dart
// lib/services/notification_scheduler.dart
// For example, set to remind daily at 9 AM
await flutterLocalNotificationsPlugin.zonedSchedule(
  0, // id
  'BTC DCA Reminder', // title
  'It's time for today's Bitcoin DCA!', // body
  _nextInstanceOfNineAM(), // Next reminder time
  // ... Other configurations
);

```

## Open Source License

This project is open-sourced under the [MIT License](LICENSE).

## Disclaimer

This application is for learning, research, and personal use only, and does not constitute any form of investment advice. The cryptocurrency market is highly volatile, and investments carry risks. Please make informed decisions after fully understanding the risks. The developer is not responsible for any losses incurred from using this application.

---

**Happy Investing!**