# VoiceAI Assistant

An AI-powered voice assistant Flutter app that lets users perform everyday smartphone actions using natural voice commands — including calling contacts, making UPI payments, ordering food, and reading SMS messages aloud.

---

## ✨ Features

- 🗣️ Voice Commands — powered by Groq (LLaMA 3)
- 📞 Call contacts directly using voice
- 💸 UPI Payments — opens Google Pay / PhonePe / Paytm - with amount pre-filled
- 🍔 Food Ordering — opens Swiggy or Zomato
- 📩 Read SMS aloud using Text-to-Speech
- 🔐 Session-based Authentication with PostgreSQL
- ⚡ Fast and lightweight architecture

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Backend | Node.js + Express |
| Database | PostgreSQL |
| AI / NLU | Groq API (LLaMA 3), Speech-to-Text engine, Text-to-Speech engine, |
| Authentication | Express Sessions |
| Integration | UPI deep-link protocol, Swiggy / Zomato app deep-links, Android tel: URI for calls, SMS inbox reader |

---

# 🚀 Setup

## 1. Clone the Repository

```bash
git clone https://github.com/yourusername/voiceai.git
cd voiceai
```

---

## 2. Flutter Environment Setup

Create a `.env` file in the root folder:

```env
BACKEND_URL=http://your-backend-ip:5000/api
GROQ_API_KEY=your_groq_api_key
ElevenLabs_API_KEY=your_elevenlabs_api_key
```



---

## 3. Backend Environment Setup

Create a `.env` file inside the `backend/` folder:

```env
DATABASE_URL=postgresql://user:password@localhost:5432/voiceai
SESSION_SECRET=your_long_random_secret
PORT=5000
```

---

## 4. Run Backend

```bash
cd backend
npm install
npm run dev
```

---

## 5. Run Flutter App

```bash
flutter pub get
flutter run
```

---

# 📱 Android Permissions Required

- Contacts
- Phone
- SMS
- Microphone
- Internet

---

# 💳 UPI Payment Support

The app can launch installed UPI apps such as:

- Google Pay
- PhonePe
- Paytm

Payment amount and recipient details are automatically pre-filled from voice commands.

---

# 🍔 Food Ordering Support

Voice commands can directly open:

- Swiggy
- Zomato

If the app is not installed, the browser version opens automatically.


---



# 🔮 Future Improvements

- 🌍 Multi-language support
- 🤖 Personalized AI memory
- 📅 Calendar & reminder integration
- 🎤 Wake-word detection
- 🔒 End-to-end encrypted voice actions

---

# 👨‍💻 Developer

Made by **[Gungun Agarwal]**  

---

