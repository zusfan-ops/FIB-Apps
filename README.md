# 🌸 FIB UNDIP · 桜言葉 (SakuraKotoba) — Japanese Literature & Academic Campus Life Ecosystem

**FIB UNDIP (桜言葉 - Sastra Jepang Fakultas Ilmu Budaya Universitas Diponegoro)** adalah ekosistem digital terpadu untuk pembelajaran bahasa & sastra Jepang sekaligus asisten produktivitas perkuliahan mahasiswa Sastra Jepang FIB Universitas Diponegoro.

Sistem ini mengintegrasikan **Backend RESTful API berbasis Laravel (Sanctum Auth)** dan **Frontend Multiplatform Flutter (Android Native APK & Web PWA)** dengan fitur unggulan: **Jadwal Kuliah Mingguan dengan Pengingat Otomatis 2 Jam Sebelum Kelas**, **Catatan Kampus & Diary Mahasiswa**, **Timeline Dokumentasi Foto Kampus (Upload Galeri/Kamera, Like, Komentar, Share WhatsApp & Pratinjau Publik Bebas Login)**, **Spaced Repetition System (SRS SuperMemo SM-2)**, **Reading Tracker Sastra dengan 1-Click Text-Clipping**, **Katalog Grammar Modern & Klasik (文語 - Bungo)**, serta **Honyaku Studio Penerjemahan Sastra**.

<p align="center">
  <img alt="FIB UNDIP" src="https://img.shields.io/badge/FIB-UNDIP-E05668?logo=undip&logoColor=white">
  <img alt="Laravel" src="https://img.shields.io/badge/Laravel-11%2F12-FF2D20?logo=laravel&logoColor=white">
  <img alt="PHP 8.2+" src="https://img.shields.io/badge/PHP-8.2+-777BB4?logo=php&logoColor=white">
  <img alt="MySQL 8" src="https://img.shields.io/badge/MySQL-8.0+-4479A1?logo=mysql&logoColor=white">
  <img alt="Flutter 3" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white">
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white">
  <img alt="Android APK" src="https://img.shields.io/badge/Android-Native_APK-3DDC84?logo=android&logoColor=white">
  <img alt="Web PWA" src="https://img.shields.io/badge/Web-PWA_Ready-5A0FC8?logo=pwa&logoColor=white">
  <img alt="Live Portal" src="https://img.shields.io/badge/Portal-fib.ordr.my.id-2A3B5C?logo=googlechrome&logoColor=white">
</p>

---

## 📥 Unduh Aplikasi Android (APK Release v1.1.0)

Aplikasi mobile **FIB UNDIP** tersedia dalam format APK mandiri yang dapat langsung dipasang di smartphone Android Anda:

* 🚀 **Download APK Resmi Langsung:**  
  👉 **[Download app-arm64-v8a-release.apk (v1.1.0)](https://github.com/zusfan-ops/FIB-Backend/releases/download/v1.1.0/app-arm64-v8a-release.apk)** *(18.6 MB — Rekomendasi Utama)*  
  👉 **[Web App / PWA (Browser)](https://fib.undip.test/app/)**  
  👉 **[GitHub Releases FIB-Backend](https://github.com/zusfan-ops/FIB-Backend/releases)**
* 💻 **Akses Web App (PWA):**  
  👉 **[https://fib.ordr.my.id/app/](https://fib.ordr.my.id/app/)**

### 📱 Varian File APK yang Tersedia

| File APK | Arsitektur CPU | Rekomendasi Penggunaan | Ukuran |
|---|---|---|---|
| **`app-arm64-v8a-release.apk`** | **ARM 64-bit** | ⭐ **Sangat Direkomendasikan** untuk hampir semua smartphone Android modern (Samsung, Xiaomi, Oppo, Vivo, Realme, Infinix, Pixel, dll). Ringan dan kencang. | **~18.6 MB** |
| **`app-armeabi-v7a-release.apk`** | **ARM 32-bit** | Untuk smartphone Android tipe lama atau entry-level 32-bit. | **~16.3 MB** |
| **`app-x86_64-release.apk`** | **x86 64-bit** | Untuk emulator Android di PC / Mac (Android Studio, LDPlayer, NoxPlayer). | **~20.1 MB** |
| **`app-release.apk`** | **Universal** | Berisi bundle seluruh arsitektur prosesor Android. | **~53.0 MB** |

---

## ✨ Fitur-Fitur Unggulan Terbaru

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                   FIB UNDIP · SAKURAKOTOBA                                      │
├─────────────────────┬─────────────────────┬─────────────────────┬───────────────────────────────┤
│  📅 JADWAL KULIAH   │  📖 CATATAN KAMPUS  │  📸 TIMELINE FOTO   │  🎴 AKADEMIK SASTRA JEPANG    │
│  & REMINDER 2 JAM   │     & DIARY         │  & INTERAKSI SOSIAL │     (SRS, READING, BUNGO)     │
├─────────────────────┼─────────────────────┼─────────────────────┼───────────────────────────────┤
│ • Senin–Sabtu Tabs  │ • Mood Mahasiswa    │ • Upload Galeri/Cam │ • SRS Flashcard (SM-2 Algo)   │
│ • Pengingat 2 Jam   │ • Kategori Kegiatan │ • Like & Komentar   │ • Reading Tracker + Clips     │
│ • Ruang Gedung FIB  │ • Pin Catatan Utama │ • Share ke WhatsApp │ • Grammar Modern & Bungo (文語)│
│ • Dosen & Bobot SKS │ • Refleksi Kuliah   │ • Link Tamu No-Auth │ • Honyaku Studio Penerjemahan │
└─────────────────────┴─────────────────────┴─────────────────────┴───────────────────────────────┘
```

---

### 📅 1. Jadwal Kuliah FIB UNDIP & Pengingat 2 Jam Sebelum Kelas
*Dirancang khusus untuk manajemen jadwal perkuliahan mingguan mahasiswa Sastra Jepang FIB Universitas Diponegoro.*
- **Tab Hari Terorganisir (Senin – Sabtu):** Mengelompokkan mata kuliah berdasarkan hari perkuliahan secara rapi.
- **Data Perkuliahan Lengkap:** Nama mata kuliah (Choukai, Dokkai, Bunpo, Honyaku, Nihonshi, Nihon Bungaku), dosen pengampu, ruang kelas (Gedung A, B, D FIB UNDIP), bobot SKS, dan rentang jam mulai/selesai.
- **⏰ Fitur Pengingat Otomatis 2 Jam:** Setiap mata kuliah dapat diaktifkan toggle alarm pengingat yang otomatis memberi notifikasi pengingat 2 jam sebelum jam masuk kelas.
- **Card Preview di Dashboard:** Menampilkan kuliah hari ini secara langsung di beranda utama aplikasi.
- **Kalkulator Total SKS:** Menghitung total beban SKS aktif semester berjalan secara otomatis.

---

### 📖 2. Catatan Kampus & Diary Mahasiswa
*Buku harian digital mahasiswa untuk mencatat dinamika perkuliahan dan bimbingan akademik.*
- **Jurnal Refleksi Perkuliahan:** Mencatat rangkuman materi dosen, progres skripsi/tugas akhir, dan persiapan seminar.
- **Mood Tracker Visual:** Rekam suasana hati harian (*Semangat*, *Fokus*, *Santai*, *Produktif*, *Lelah*) lengkap dengan ikon ekspresi.
- **Kategori Kegiatan:** Pengelompokan catatan (*Kuliah*, *Bimbingan Dosen*, *Organisasi/Himpunan*, *Belajar Mandiri*, *Refleksi Pribadi*).
- **📌 Pin to Top:** Sematkan catatan penting agar selalu tampil di urutan teratas.
- **Fitur Pencarian & Filter Cepat:** Temukan catatan masa lalu berdasarkan judul atau filter kategori dalam 1 klik.

---

### 📸 3. Timeline Dokumentasi Foto & Interaksi Sosial Kampus
*Media dokumentasi kebersamaan dan momen kegiatan mahasiswa Sastra Jepang FIB UNDIP.*
- **🖼️ Upload Langsung dari Galeri HP / Kamera:** Mahasiswa dapat langsung memilih foto dari galeri HP atau mengambil foto langsung dari kamera tanpa perlu memasukkan link URL manual.
- **✨ Tampilan Foto Utuh (SmartImageView):** Menggunakan *engine* penampil gambar cerdas beresolusi penuh yang mendukung URL web, CDN, maupun Base64 Data URI tanpa gambar terpotong (*no-crop*).
- **❤️ Sistem Like Real-Time:** Berikan apresiasi pada momen kegiatan teman dengan tombol like interaktif.
- **💬 Komentar Antar Mahasiswa:** Kolom diskusi dan komentar terintegrasi untuk saling berbagi tanggapan di setiap foto kegiatan.
- **📲 Share ke WhatsApp Otomatis:** Tombol bagikan langsung membuka aplikasi WhatsApp dengan pesan dan link publik yang rapi.
- **🌐 Akses Publik Tamu Tanpa Login (`/p/{id}` & `/foto/{id}`):**
  - Tautan foto yang dibagikan dapat dibuka langsung oleh siapa saja di browser **tanpa harus mendaftar atau login akun**.
  - Dilengkapi *OpenGraph Meta Tags* sehingga muncul *preview banner* foto dan judul kegiatan saat link dikirim di WhatsApp.

---

### 🧭 4. Navigasi Global Persisten (`GlobalBottomNavBar`)
*Navigasi antarmuka mulus yang selalu tersedia di seluruh halaman.*
- **Bottom Navigation Bar di Setiap Halaman:** Navigasi bawah selalu aktif di halaman Honyaku, Grammar, Jadwal Kuliah, Catatan Diary, Timeline Foto, Detail Buku, Flashcard SRS, hingga Profil Mahasiswa.
- **Perpindahan Tab Instan:** Berpindah antar modul utama (*Beranda, Review, Baca, Agenda, Lainnya*) dari layar mana pun tanpa perlu menekan tombol panah kembali (*back*) berulang kali.

---

### 🎴 5. Spaced Repetition System (SRS SM-2) Kanji & Kosakata
*Sistem flashcard berbasis interval memori SuperMemo SM-2 untuk persiapan ujian JLPT N5 hingga N1.*
- **Kalkulasi Ease Factor ($EF$) & Interval Adaptif:** Menjadwalkan repetisi kartu berdasarkan daya ingat mahasiswa (Rating: *Lagi*, *Sulit*, *Bagus*, *Mudah*).
- **Struktur Kartu Autentik:** Kanji, On'yomi, Kun'yomi, makna bahasa Indonesia, dan contoh kalimat (*rei-bun*).
- **Multi-Deck Management & Bulk Import:** Kelompokkan kartu berdasarkan buku ajar atau level JLPT.

---

### 📖 6. Reading Tracker & Smart Text-Clipping Sastra
*Lacak progres membaca novel dan cerpen sastra Jepang autentik.*
- **Katalog Karya Sastra:** Dokumentasikan karya sastra (*Natsume Soseki, Dazai Osamu, Akutagawa Ryunosuke, dll*).
- **✂️ 1-Click Klip ke Flashcard:** Potongan kata sulit yang disorot pada buku dapat langsung dikonversi menjadi kartu SRS baru beserta contoh kalimat aslinya.

---

### 📜 7. Grammar Reference & Tata Bahasa Klasik Bungo (文語)
- **Katalog Tata Bahasa Lengkap:** Pola kalimat JLPT N5–N1 dan tata bahasa sastra klasik era Heian/Edo (*Bungo / Kobun* seperti *nari, beshi, keri, ramu, tari, zo/namu musubi*).
- **Formasi & Nuansa Makna:** Rumus konjugasi kata kerja (*mizenkei, ren'youkei, shuushikei*) dan contoh kalimat bertingkat.

---

### ✍️ 8. Honyaku Studio — Latihan Menerjemahkan Sastra (翻訳)
- **Workbench Penerjemahan:** Terjemahkan teks sastra Jepang ke Bahasa Indonesia dengan tampilan berdampingan (*Side-by-Side*).
- **Sistem Revisi Bertahap:** Simpan versi draf terjemahan mulai dari draf kasar hingga hasil akhir (*Final Polish*).

---

## 🏛️ Desain Halaman Landing Page (Washi Paper Aesthetic)

Halaman utama portal [https://fib.ordr.my.id/](https://fib.ordr.my.id/) mengusung estetika **Kertas Washi Jepang Autentik**:
* 🎨 **Palet Warna Alami:** Latar Washi Cream (`#FAF7F2`), Tinta Sumi Charcoal (`#231F20`), Sakura Coral (`#E05668`), dan Indigo Deep (`#2A3B5C`).
* 🪷 **Tipografi Jepang:** Font berkarakter *Shippori Mincho* dan *Noto Serif JP*.
* ⚡ **1-Click Demo Login & Register:** Coba portal secara langsung dengan akun demo atau daftarkan akun baru.
* 📦 **Tombol Download APK & PWA:** Akses langsung ke installer Android v1.1.0 dan Web App.

---

## 🏗️ Struktur Direktori Proyek

```
jepang/
├── backend/                      # Laravel RESTful API (Sanctum Auth) & Web Blade
│   ├── app/
│   │   ├── Http/Controllers/Api/ # Controller (ClassSchedule, CampusDiary, CampusPhoto, SRS, Reading, dll)
│   │   ├── Models/               # Eloquent Models (CampusPhoto, CampusPhotoLike, CampusPhotoComment, dll)
│   │   └── Services/             # Logika Bisnis (Sm2Service - Spaced Repetition)
│   ├── database/migrations/      # Skema Database (Jadwal, Diary, Timeline Foto, Interaksi Like/Komen)
│   ├── resources/views/          # Blade Template (Landing Page Washi & Public Photo Share)
│   ├── routes/
│   │   ├── api.php               # Rute Endpoint RESTful API v1
│   │   └── web.php               # Rute Landing Page & Public Share Link (/p/{id})
│   └── public/                   # Entry point Laravel, /app/ (Flutter Web), dan /uploads/
│
├── apps/flutter/                 # Client Multiplatform Flutter (Android & Web PWA)
│   ├── lib/
│   │   ├── models/               # Data Model Dart (ClassSchedule, CampusDiary, CampusPhoto, dll)
│   │   ├── screens/              # Layar Aplikasi (Campus, Dashboard, SRS, Reading, Translation, More)
│   │   ├── services/             # ApiClient (Multipart & JSON), Session, TabSwitcher
│   │   ├── widgets/              # GlobalBottomNavBar, SmartImageView, Reusable Components
│   │   └── main.dart             # Root Runner & Router Navigasi
│   ├── android/                  # Konfigurasi Native Android (Label: FIB UNDIP, Strings.xml, AppIcon)
│   └── pubspec.yaml              # Dependensi Flutter (image_picker, url_launcher, http)
```

---

## 🚀 Panduan Menjalankan di Server & Lokal

### 1. Prasyarat Sistem
* **PHP:** $\ge$ 8.2 (Ekstensi: `pdo_mysql`, `mbstring`, `fileinfo`, `openssl`)
* **Database:** MySQL $\ge$ 8.0 / MariaDB
* **Flutter SDK:** $\ge$ 3.12+ & Dart $\ge$ 3.0+
* **Web Server:** Nginx / Apache / Laragon

### 2. Update & Jalankan Server (Laravel)
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --force
php artisan storage:link
php artisan route:clear
php artisan view:clear
php artisan config:clear
```

> 🔑 **Akun Demo Bawaan:**  
> - **Email:** `demo@nihon.test`  
> - **Password:** `password`

### 3. Kompilasi Flutter Web & Android APK
```bash
cd apps/flutter
flutter pub get

# 1. Build Web App Production
flutter build web --release --base-href=/app/

# 2. Build APK Android Release
flutter build apk --split-per-abi --release
```

---

## 🌐 Ringkasan Endpoint RESTful API Utama

Semua endpoint privat memerlukan header `Authorization: Bearer <TOKEN>`.

| Modul | Method | Endpoint | Deskripsi |
|---|---|---|---|
| **Auth** | `POST` | `/api/v1/auth/login` | Masuk akun & menerima Sanctum Bearer Token |
| **Auth** | `POST` | `/api/v1/auth/register` | Mendaftarkan akun mahasiswa baru |
| **Jadwal** | `GET` | `/api/v1/class-schedules` | Mengambil jadwal kuliah mingguan & kuliah hari ini |
| **Jadwal** | `POST` | `/api/v1/class-schedules` | Menambah jadwal kuliah baru (pengingat 2 jam) |
| **Diary** | `GET` | `/api/v1/campus-diaries` | Mengambil catatan kampus & mood tracker |
| **Diary** | `POST` | `/api/v1/campus-diaries` | Menulis catatan diary baru |
| **Timeline** | `GET` | `/api/v1/campus-photos` | Feed dokumentasi foto kegiatan kampus |
| **Timeline** | `POST` | `/api/v1/campus-photos` | Upload foto baru (Multipart / Base64 Data URI) |
| **Timeline** | `POST` | `/api/v1/campus-photos/{id}/like` | Toggle Like / Batal Suka pada foto |
| **Timeline** | `POST` | `/api/v1/campus-photos/{id}/comments` | Mengirim komentar mahasiswa pada foto |
| **Publik** | `GET` | `/p/{id}` & `/foto/{id}` | Halaman web publik foto untuk WhatsApp share (No Login) |
| **SRS** | `GET` | `/api/v1/review/due` | Mengambil kartu flashcard yang jatuh tempo review |
| **SRS** | `POST` | `/api/v1/review/{card}` | Mengirim skor rating review untuk algoritma SM-2 |
| **Reading**| `POST` | `/api/v1/clips/{id}/to-card` | Konversi klip teks buku sastra menjadi kartu flashcard |
| **Grammar**| `GET` | `/api/v1/grammar` | Katalog tata bahasa modern & klasik Bungo |
| **Honyaku**| `POST` | `/api/v1/translations` | Membuat lembar kerja latihan penerjemahan |

---

## 👨‍💻 Profil Pengembang

<table>
  <tr>
    <td width="140" valign="top">
      <img src="https://zusfan.hallosemarang.com/DSC00218.jpg" alt="Zusfan Mashuri" width="120" style="border-radius: 50%;">
    </td>
    <td valign="top">
      <h3>Zusfan Mashuri</h3>
      <p>
        <strong>Marketing Strategist · IT Builder · Public Service Innovator</strong>
      </p>
      <p>
        Founder & Marketing IT Director di <a href="https://hallosemarang.com" target="_blank">Hallo Semarang</a>. 
        Pengembang arsitektur sistem digital dengan spesialisasi platform edukasi modern, 
        infrastruktur smart city, strategi pemasaran digital, dan transformasi teknologi tepat guna.
      </p>
      <p>
        <a href="https://wa.me/628998813000" target="_blank">
          <img alt="WhatsApp" src="https://img.shields.io/badge/WhatsApp-+62_899_8813_000-25D366?logo=whatsapp&logoColor=white">
        </a>
        <a href="https://zusfan.hallosemarang.com/" target="_blank">
          <img alt="Digital Card" src="https://img.shields.io/badge/Digital_Card-zusfan.hallosemarang.com-2D5A27?logo=internetexplorer&logoColor=white">
        </a>
        <a href="https://hallosemarang.com" target="_blank">
          <img alt="Website" src="https://img.shields.io/badge/Website-hallosemarang.com-0AA956?logo=googlechrome&logoColor=white">
        </a>
        <a href="https://zusfan.hallosemarang.com/resume.html" target="_blank">
          <img alt="Resume" src="https://img.shields.io/badge/Resume-CV-4F46E5?logo=readme&logoColor=white">
        </a>
      </p>
    </td>
  </tr>
</table>

---

## 📄 Lisensi

Perangkat lunak **FIB UNDIP · 桜言葉 (SakuraKotoba)** dikembangkan untuk mendukung kegiatan akademis, perkuliahan sastra Jepang, dan inovasi pendidikan di lingkungan Fakultas Ilmu Budaya Universitas Diponegoro.

<p align="center"><sub>🌸 FIB UNDIP · 桜言葉 (SakuraKotoba) — Program Studi Sastra Jepang Fakultas Ilmu Budaya Universitas Diponegoro · Developed by Zusfan Mashuri</sub></p>
