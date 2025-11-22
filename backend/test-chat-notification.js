require('dotenv').config();
const axios = require('axios');

const ONESIGNAL_APP_ID = process.env.ONESIGNAL_APP_ID || 'db0f9546-9d0c-411d-a59a-e331483b0d98';
const ONESIGNAL_REST_API_KEY = process.env.ONESIGNAL_REST_API_KEY || 'os_v2_app_3mhzkru5brar3jm24myuqoyntaw3t2mypk2uxxmoxk3suf345nq3ditj5reeo5gjyicog6inzvntxkx53g4cxy7vuy2i3do72kt3hni';

async function testChatNotification() {
  console.log('🧪 Testing Chat Notification...\n');
  
  // استبدل هذا بمعرف المستخدم الحقيقي من قاعدة البيانات
  const receiverUserId = 'USER_ID_HERE'; // ضع معرف المستخدم هنا
  
  const payload = {
    app_id: ONESIGNAL_APP_ID,
    include_external_user_ids: [receiverUserId],
    
    headings: { 
      en: 'عائشه محمد',
      ar: 'عائشه محمد'
    },
    contents: { 
      en: 'مرحباً! هذه رسالة تجريبية',
      ar: 'مرحباً! هذه رسالة تجريبية'
    },
    
    data: {
      type: 'chat_message',
      conversationId: 'test_conversation_id',
      senderId: 'test_sender_id',
      senderName: 'عائشه محمد',
      messageType: 'text',
      screen: 'chat',
    },

    small_icon: 'ic_stat_onesignal_default',
    
    ios_badgeType: 'Increase',
    ios_badgeCount: 1,
    
    priority: 10,
    android_accent_color: 'FF9C27B0',
  };

  try {
    console.log('📤 Sending notification to user:', receiverUserId);
    console.log('📦 Payload:', JSON.stringify(payload, null, 2));
    
    const response = await axios.post(
      'https://onesignal.com/api/v1/notifications',
      payload,
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
        },
      }
    );

    console.log('\n✅ Notification sent successfully!');
    console.log('📊 Response:', JSON.stringify(response.data, null, 2));
    
    if (response.data.recipients === 0) {
      console.log('\n⚠️  WARNING: No recipients found!');
      console.log('   This means the user is not registered with OneSignal.');
      console.log('   Make sure the user has logged in to the app and OneSignal.login() was called.');
    }
  } catch (error) {
    console.error('\n❌ Error sending notification:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', JSON.stringify(error.response.data, null, 2));
    } else {
      console.error(error.message);
    }
  }
}

// تشغيل الاختبار
testChatNotification();
