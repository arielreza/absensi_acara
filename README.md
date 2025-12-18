# Sie.Acara – Aplikasi Absensi & Manajemen Acara

Sie.Acara adalah aplikasi mobile berbasis Flutter yang digunakan untuk membantu proses **manajemen acara dan absensi peserta** secara digital.  
Aplikasi ini dikembangkan sebagai bagian dari **Project Based Learning (PBL)**.

---

## 🎯 Deskripsi Aplikasi
Aplikasi Sie.Acara dirancang untuk mempermudah panitia dalam mengelola data acara, peserta, serta mencatat kehadiran menggunakan **QR Code**.  
Dengan sistem ini, proses absensi menjadi lebih cepat, aman, dan terstruktur dibandingkan metode manual.

---

## 👥 Role Pengguna

### Admin
- Melihat dashboard dan statistik acara  
- Menambahkan dan mengelola event  
- Melihat daftar peserta setiap event  
- Melakukan scan QR Code untuk absensi  
- Melihat riwayat absensi  

### Peserta
- Melihat daftar event yang tersedia  
- Melihat detail event  
- Mendaftar ke event  
- Mendapatkan QR Code sebagai bukti kehadiran  
  *(QR Code hanya dapat dipindai oleh Admin)*

---

## ⭐ Fitur Utama
- Manajemen Event  
- Sistem Absensi berbasis QR Code  
- Scan QR oleh Admin  
- Riwayat Absensi  
- Pembagian Role (Admin & Peserta)  
- Antarmuka mobile yang sederhana dan mudah digunakan  

---

## 🛠 Teknologi yang Digunakan
- Flutter  
- Firebase Authentication  
- Firebase Realtime Database  
- QR Code Scanner  
- Provider (State Management)

---

## ⚙️ Cara Instalasi

### 1. Clone Repository
```bash
git clone https://github.com/arielreza/absensi_acara.git
cd absensi_acara
```

### 2. Install Dependency
```bash
flutter pub get
```

### 3. Konfigurasi Firebase
- Buat project Firebase
- Aktifkan Authentication dan Realtime Database
- Tambahkan file konfigurasi Firebase:
  - `google-services.json` (Android)
  - `GoogleService-Info.plist` (iOS)

### 4. Jalankan Aplikasi
```bash
flutter run
```

---

## 📱 Demo Aplikasi
Video demo aplikasi tersedia melalui link YouTube (Unlisted) atau Google Drive (Public) sesuai ketentuan penilaian.

---

## 👨‍💻 Tim Pengembang
Proyek ini dikembangkan oleh kelompok PBL sebagai bagian dari tugas perkuliahan.
- Lavina 2341760062 / 9
- M.M. Arielreza H  2341760049 / 13
- Nova Diana R 2341760104 / 19
- Pandya Cahya 2341760053 / 20
- Titania Aurellia Putri D 2341760112 / 27

---

## 📄 Lisensi
Proyek ini dibuat untuk keperluan akademik dan pembelajaran.
