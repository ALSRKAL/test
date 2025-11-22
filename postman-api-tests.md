# Hajzy Backend API - Postman Tests

**Base URL:** `https://jennifer-practical-den-fighting.trycloudflare.com`

---

## 1. Health Check

### Check Server Health
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/health
```

### Check API Health
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/health
```

---

## 2. Admin Authentication

### Admin Login
```
POST https://jennifer-practical-den-fighting.trycloudflare.com/api/admin/login
Content-Type: application/json

{
  "email": "admin@hajzy.com",
  "password": "Admin@Hajzy2025!"
}
```
**Response:** احفظ الـ `token` من الرد

---

## 3. User Authentication

### Register User
```
POST https://jennifer-practical-den-fighting.trycloudflare.com/api/auth/register
Content-Type: application/json

{
  "name": "Test User",
  "email": "testuser@example.com",
  "password": "Test@123456",
  "phone": "+966501234567",
  "role": "user"
}
```

### Register Photographer
```
POST https://jennifer-practical-den-fighting.trycloudflare.com/api/auth/register
Content-Type: application/json

{
  "name": "Test Photographer",
  "email": "photographer@example.com",
  "password": "Photo@123456",
  "phone": "+966509876543",
  "role": "photographer"
}
```

### User Login
```
POST https://jennifer-practical-den-fighting.trycloudflare.com/api/auth/login
Content-Type: application/json

{
  "email": "testuser@example.com",
  "password": "Test@123456"
}
```

### Refresh Token
```
POST https://jennifer-practical-den-fighting.trycloudflare.com/api/auth/refresh-token
Content-Type: application/json

{
  "refreshToken": "YOUR_REFRESH_TOKEN"
}
```

### Logout
```
POST https://jennifer-practical-den-fighting.trycloudflare.com/api/auth/logout
Authorization: Bearer YOUR_TOKEN
```

---

## 4. User Profile

### Get Profile
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/users/profile
Authorization: Bearer YOUR_TOKEN
```

### Update Profile
```
PUT https://jennifer-practical-den-fighting.trycloudflare.com/api/users/profile
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "name": "Updated Name",
  "phone": "+966501234567",
  "bio": "My bio"
}
```

### Get User Statistics
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/users/statistics
Authorization: Bearer YOUR_TOKEN
```

---

## 5. Photographers

### Get All Photographers
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/photographers
```

### Search Photographers
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/photographers/search?query=test&city=Riyadh
```

### Get Featured Photographers
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/photographers/featured
```

### Get Photographer Details
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/photographers/PHOTOGRAPHER_ID
```

### Get My Photographer Profile
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/photographers/me/profile
Authorization: Bearer PHOTOGRAPHER_TOKEN
```

### Update Photographer Profile
```
PUT https://jennifer-practical-den-fighting.trycloudflare.com/api/photographers/me/profile
Authorization: Bearer PHOTOGRAPHER_TOKEN
Content-Type: application/json

{
  "bio": "Professional photographer",
  "specialties": ["wedding", "portrait"],
  "city": "Riyadh",
  "priceRange": {
    "min": 500,
    "max": 2000
  }
}
```

---

## 6. Bookings

### Create Booking
```
POST https://jennifer-practical-den-fighting.trycloudflare.com/api/bookings
Authorization: Bearer USER_TOKEN
Content-Type: application/json

{
  "photographerId": "PHOTOGRAPHER_ID",
  "packageId": "PACKAGE_ID",
  "date": "2025-12-01",
  "time": "14:00",
  "location": "Riyadh",
  "notes": "Wedding photography"
}
```

### Get My Bookings
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/bookings
Authorization: Bearer YOUR_TOKEN
```

### Get Booking Details
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/bookings/BOOKING_ID
Authorization: Bearer YOUR_TOKEN
```

### Update Booking Status
```
PUT https://jennifer-practical-den-fighting.trycloudflare.com/api/bookings/BOOKING_ID/status
Authorization: Bearer PHOTOGRAPHER_TOKEN
Content-Type: application/json

{
  "status": "confirmed"
}
```
**Status options:** pending, confirmed, completed, cancelled

### Cancel Booking
```
PUT https://jennifer-practical-den-fighting.trycloudflare.com/api/bookings/BOOKING_ID/cancel
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "reason": "Change of plans"
}
```

---

## 7. Reviews

### Create Review
```
POST https://jennifer-practical-den-fighting.trycloudflare.com/api/reviews
Authorization: Bearer USER_TOKEN
Content-Type: application/json

{
  "photographerId": "PHOTOGRAPHER_ID",
  "bookingId": "BOOKING_ID",
  "rating": 5,
  "comment": "Excellent service!"
}
```

### Get Photographer Reviews
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/photographers/PHOTOGRAPHER_ID/reviews
```

### Reply to Review
```
POST https://jennifer-practical-den-fighting.trycloudflare.com/api/reviews/REVIEW_ID/reply
Authorization: Bearer PHOTOGRAPHER_TOKEN
Content-Type: application/json

{
  "reply": "Thank you for your feedback!"
}
```

---

## 8. Chat

### Get Conversations
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/chat/conversations
Authorization: Bearer YOUR_TOKEN
```

### Create Conversation
```
POST https://jennifer-practical-den-fighting.trycloudflare.com/api/chat/conversations
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "participantId": "USER_OR_PHOTOGRAPHER_ID"
}
```

### Get Conversation Messages
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/chat/conversations/CONVERSATION_ID/messages
Authorization: Bearer YOUR_TOKEN
```

### Send Message
```
POST https://jennifer-practical-den-fighting.trycloudflare.com/api/chat/messages
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "conversationId": "CONVERSATION_ID",
  "content": "Hello!",
  "type": "text"
}
```

### Get Unread Count
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/chat/unread-count
Authorization: Bearer YOUR_TOKEN
```

---

## 9. Notifications

### Get Notifications
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/notifications
Authorization: Bearer YOUR_TOKEN
```

### Get Unread Count
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/notifications/unread-count
Authorization: Bearer YOUR_TOKEN
```

### Mark as Read
```
PUT https://jennifer-practical-den-fighting.trycloudflare.com/api/notifications/NOTIFICATION_ID/read
Authorization: Bearer YOUR_TOKEN
```

### Mark All as Read
```
PUT https://jennifer-practical-den-fighting.trycloudflare.com/api/notifications/read-all
Authorization: Bearer YOUR_TOKEN
```

---

## 10. Media Upload

### Upload Image
```
POST https://jennifer-practical-den-fighting.trycloudflare.com/api/media/upload/image
Authorization: Bearer YOUR_TOKEN
Content-Type: multipart/form-data

file: [SELECT IMAGE FILE]
```

### Upload Video
```
POST https://jennifer-practical-den-fighting.trycloudflare.com/api/media/upload/video
Authorization: Bearer YOUR_TOKEN
Content-Type: multipart/form-data

file: [SELECT VIDEO FILE]
```

### Upload Multiple Images
```
POST https://jennifer-practical-den-fighting.trycloudflare.com/api/media/upload/images
Authorization: Bearer YOUR_TOKEN
Content-Type: multipart/form-data

files: [SELECT MULTIPLE IMAGE FILES]
```

---

## 11. Admin Operations

### Get All Users
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/admin/users
Authorization: Bearer ADMIN_TOKEN
```

### Get All Photographers
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/admin/photographers
Authorization: Bearer ADMIN_TOKEN
```

### Get All Bookings
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/admin/bookings
Authorization: Bearer ADMIN_TOKEN
```

### Get Dashboard Statistics
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/admin/statistics
Authorization: Bearer ADMIN_TOKEN
```

### Block User
```
PUT https://jennifer-practical-den-fighting.trycloudflare.com/api/admin/users/USER_ID/block
Authorization: Bearer ADMIN_TOKEN
Content-Type: application/json

{
  "reason": "Violation of terms"
}
```

### Unblock User
```
PUT https://jennifer-practical-den-fighting.trycloudflare.com/api/admin/users/USER_ID/unblock
Authorization: Bearer ADMIN_TOKEN
```

---

## 12. Subscriptions

### Get Plans
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/subscriptions/plans
```

### Subscribe
```
POST https://jennifer-practical-den-fighting.trycloudflare.com/api/subscriptions/subscribe
Authorization: Bearer PHOTOGRAPHER_TOKEN
Content-Type: application/json

{
  "planId": "PLAN_ID",
  "paymentMethod": "credit_card"
}
```

### Get My Subscription
```
GET https://jennifer-practical-den-fighting.trycloudflare.com/api/subscriptions/my-subscription
Authorization: Bearer PHOTOGRAPHER_TOKEN
```

---

## ملاحظات مهمة:

1. **استبدل YOUR_TOKEN** بالـ token الذي تحصل عليه من Login
2. **استبدل IDs** مثل PHOTOGRAPHER_ID, BOOKING_ID بالـ IDs الحقيقية
3. **Admin Credentials:**
   - Email: `admin@hajzy.com`
   - Password: `Admin@Hajzy2025!`
4. **لرفع الملفات** استخدم `form-data` في Postman
5. **جميع الطلبات المحمية** تحتاج `Authorization: Bearer TOKEN`
