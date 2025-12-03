# AFib Detection Demo (Flutter)

This Flutter application is designed to interface with an STM32 microcontroller running an edge AI model for Atrial Fibrillation (AFib) detection. 

**Its primary function is to imitate heart rate sensors like the Polar H9 and H10.** 

By acting as a data source, the app injects pre-recorded RR interval data (derived from ECG) into the connected device via Bluetooth Low Energy (BLE), allowing users to test the hardware's AI inference capabilities without needing a physical heart rate monitor strapped to a person during development.

## How It Works

1. **Imitation of Sensor Data:** The app contains pre-loaded datasets of RR intervals (time between heartbeats) that mimic the output of Polar H9/H10 sensors.
2. **BLE Connection:** It scans for and connects to a specific STM32 board (acting as a BLE Peripheral) that exposes a custom AI inference service.
3. **Data Injection:** The user selects a "Test Row" of data and sends it to the board.
4. **AI Result:** The board processes the data using its on-device neural network and notifies the app of the result (AFib probability), which is displayed on the dashboard.

## Features

*   **BLE Scanning & Connection:** Automatically filters and connects to the target STM32 device.
*   **Data Simulation:** Includes multiple test datasets (rows) representing both Normal Sinus Rhythm and Atrial Fibrillation patterns.
*   **Real-time Feedback:** Displays the AI classification result ("AFIB DETECTED" or "Normal Rhythm") and the confidence score returned by the device.
*   **Visual Indicators:** Clear color-coded UI (Green for Normal, Red for Warning/AFib).

## Getting Started

### Prerequisites

*   [Flutter SDK](https://flutter.dev/docs/get-started/install)
*   A compatible STM32 development board (e.g., B-L475E-IOT01A2) programmed with the corresponding AI firmware.

### Installation

1.  Clone the repository:
    ```bash
    git clone <repository_url>
    cd afib_detection_demo
    ```

2.  Install dependencies:
    ```bash
    flutter pub get
    ```

3.  Run the app:
    ```bash
    flutter run
    ```

## Usage

1.  **Power on** your STM32 board.
2.  Open the app on your mobile device.
3.  Grant the necessary **Bluetooth & Location permissions** when prompted.
4.  Wait for the **Scan Screen** to find your device and tap **Connect**.
5.  On the **Dashboard**:
    *   Select a **Test Row** (dataset) from the dropdown.
    *   Tap **Send Row**.
    *   Wait for the "AI Analysis Result" to update with the prediction from the board.

## Dependencies

*   [flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus): For Bluetooth Low Energy communication.
*   [get](https://pub.dev/packages/get): For state management and navigation.
*   [permission_handler](https://pub.dev/packages/permission_handler): For managing runtime permissions (Bluetooth/Location).