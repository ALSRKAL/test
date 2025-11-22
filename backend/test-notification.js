/**
 * اختبار سريع لإرسال إشعار OneSignal
 * 
 * الاستخدام:
 * node test-notification.js <userId> <senderName> <message>
 * 
 * مثال:
 * node test-notification.js 673e8f9a1234567890abcdef "أحمد" "مرحباً! هذه رسالة اختبار"
 */

require('dotenv').config();
const axios = require('axios');

const ONESIGNAL_APP_ID = process.env.ONESIGNAL_APP_ID || 'db0f9546-9d0c-411d-a59a-e331483b0d98';
const ONESIGNAL_REST_API_KEY = process.env.ONESIGNAL_REST_API_KEY || 'os_v2_app_3mhzkru5brar3jm24myuqoyntaw3t2mypk2uxxmoxk3suf345nq3ditj5reeo5gjyicog6inzvntxkx53g4cxy7vuy2i3do72kt3hni';

async function sendTestNotification(userId, senderName, message) {
  try {
    console.log('📤 إرسال إشعار اختبار...');
    console.log('   User ID:', userId);
    console.log('   Sender:', senderName);
    console.log('   Message:', message);
    console.log('');

    const payload = {
      app_id: ONESIGNAL_APP_ID,
      include_external_user_ids: [userId],
      
      headings: { 
        en: senderName,
        ar: senderName
      },
      contents: { 
        en: message,
        ar: message
      },
      
      data: {
        type: 'chat_message',
        conversationId: 'test-conversation-123',
        senderId: 'test-sender-456',
        senderName: senderName,
        senderAvatar: '',
        messageType: 'text',
        screen: 'chat',
      },

      android_channel_id: 'chat_channel',
      android_sound: 'notification_sound',
      small_icon: 'ic_notification',
      
      ios_sound: 'notification_sound.wav',
      ios_badgeType: 'Increase',
      ios_badgeCount: 1,
      
      priority: 10,
      android_accent_color: 'FF9C27B0',
    };

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

    console.log('✅ تم إرسال الإشعار بنجاح!');
    console.log('   Response ID:', response.data.id);
    console.log('   Recipients:', response.data.recipients);
    console.log('');
    console.log('📊 التفاصيل الكاملة:');
    console.log(JSON.stringify(response.data, null, 2));

  } catch (error) {
    console.error('❌ فشل إرسال الإشعار:');
    if (error.response) {
      console.error('   Status:', error.response.status);
      console.error('   Data:', JSON.stringify(error.response.data, null, 2));
    } else {
      console.error('   Error:', error.message);
    }
    process.exit(1);
  }
}

// قراءة المعاملات من سطر الأوامر
const args = process.argv.slice(2);

if (args.length < 3) {
  console.log('❌ معاملات ناقصة!');
  console.log('');
  console.log('الاستخدام:');
  console.log('  node test-notification.js <userId> <senderName> <message>');
  console.log('');
  console.log('مثال:');
  console.log('  node test-notification.js 673e8f9a1234567890abcdef "أحمد" "مرحباً! هذه رسالة اختبار"');
  console.log('');
  console.log('ملاحظة: userId هو معرف المستخدم في قاعدة البيانات (MongoDB ObjectId)');
  process.exit(1);
}

const [userId, senderName, message] = args;

// إرسال الإشعار
sendTestNotification(userId, senderName, message);
