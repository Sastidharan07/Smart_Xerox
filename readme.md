# Smart-Xerox

Smart-Xerox is a Flutter-based mobile application designed to streamline document printing and xerox operations in college environments. The system reduces long queues, improves workflow efficiency, and provides a seamless experience for both students and shop administrators.

---

## 📌 Project Overview

Smart-Xerox addresses a common problem observed in my college xerox shop—consistent crowding and long waiting times.  
The app allows students to upload documents digitally, track order status, and avoid unnecessary waiting.  
A dedicated backend website enables shop admins to manage incoming requests efficiently.

The system also includes **automated time-slot scheduling based on the college lunch break** to ensure smooth workload distribution.

---

## 🚀 Features

### Student Mobile App (Flutter)
- Upload documents directly from the device
- Track print/xerox request status
- Receive updates for order progress
- Reduced waiting time and crowding

### Admin Backend Website
- View and manage incoming orders
- Update and track order status
- Organized workflow management

### Additional Functionalities
- Time-slot separation based on college lunch schedule
- Merged working demo video (Flutter app + admin panel)

---

## 🛠 Tech Stack

| Component            | Technology     |
|----------------------|----------------|
| Frontend (Mobile)    | Flutter        |
| Backend              | Node.js        |
| Database             | SQLite         |
| Admin Website        | Custom-built   |

---

## 📂 Project Structure
/smart-xerox-app → Flutter mobile application
/backend → Node.js server (server.js)
/admin-website → Admin management website

## 🔗 Project Links

**📱 Mobile App:**  
https://github.com/Sastidharan07/Smart_Xerox/blob/main/app-release.apk

**🌐 Backend Website:**  
https://smart-xerox-sdbv.onrender.com/

---

## 📥 Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/smart-xerox.git
cd smart-xerox
2. Flutter App Setup
bash
Copy code
cd smart-xerox-app
flutter pub get
flutter run
3. Backend Setup (Node.js)
bash
Copy code
cd backend
npm install
node server.js
4. Admin Website
Open the /admin-website folder and run/host the site on your preferred server.
```
📌 Future Improvements
Push notifications for order updates

Authentication system for users and admins

Online payment support (UPI/other)

Analytics dashboard for admin

🤝 Contributing
Contributions, ideas, and feedback are welcome.
Please open an issue or submit a pull request.
