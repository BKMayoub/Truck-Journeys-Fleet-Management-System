# Firebase Database Setup Instructions

## 1. Go to Firebase Console
https://console.firebase.google.com/

## 2. Select your project: bouksim-trans-app

## 3. Go to Firestore Database → Create Database (if not exists)

## 4. Create Collections Manually:

### Collection: admin_users
- Add document: admin@bouksim.com
```json
{
  "email": "admin@bouksim.com",
  "password": "admin123",
  "role": "super_admin", 
  "isActive": true,
  "createdAt": January 20, 2024 at 3:30:00 PM UTC+1,
  "lastLogin": January 20, 2024 at 3:30:00 PM UTC+1
}