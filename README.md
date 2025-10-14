🌙 MoodSync - Journal & Mood Tracker

A connected digital wellness experience: SwiftUI iOS App + Web App.
Log your mood, reflect on your day, and visualize emotional trends — all through a calm, minimalist interface.
Built to demonstrate full-stack mobile and web integration, deep linking, and a polished UI/UX experience.

🎥 Watch the full demo: https://youtu.be/Uqr7f90kNlY
🌐 Live Website: https://moodsync-abc123.netlify.app/dashboard

✨ Features
🧠 iOS (SwiftUI)

. Quick daily mood logging (😊 😐 ☁️)
. Journal with reflections (Create / Edit / Delete)
. Weekly mood trends powered by Swift Charts
. Profile section with live “Logged in” toast
Custom deep links
  ✅ moodsync://dashboard opens the app
  🔜 Universal Links (ready for live domain)
. Persistent local storage using UserDefaults

💻 Web

. Responsive HTML/CSS/JS interface
. Journal and new entry pages with localStorage
. Weekly mood chart built with Chart.js
. “Open in App” button
 . Tries Universal Link (future)
 . Falls back to moodsync://dashboard
. Calm pastel UI with consistent branding and design system

📸 Demo Preview
🎬 Watch the walkthrough: https://youtu.be/Uqr7f90kNlY

🚀 How to Run

🕸 Web Version
1. Navigate to the web directory:
  cd web
2. Run a local server:
  npx serve .
  or simply open index.html in your browser.

📱 iOS App
1. Open the /ios folder in Xcode.
2. Build and run the app:
  Press ⌘ + R or click Run ▶️.
3. Test deep link:
  In Safari on your Mac, type:
  moodsync://dashboard
  The app should open directly.

Platform	Technologies
iOS App	SwiftUI · Combine · Swift Charts · UserDefaults
Web App	HTML · CSS · JavaScript · Chart.js
Design	Minimalist UI · Pastel theme · Consistent branding

⚙️ Installation Summary
# Clone the repository
git clone https://github.com/VIEW-IT/moodsync.git

# For Web
cd web
npx serve .

# For iOS
open ios/MoodSync.xcodeproj
# Then run on simulator or device
