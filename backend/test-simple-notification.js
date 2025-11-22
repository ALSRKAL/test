require('dotenv').config();
const axios = require('axios');

// احصل على معرف المستخدم من سطر الأوامر
const userId = process.argv[2];

if (!userId) {
  console.log('❌ يرجى تحديد معرف المستخدم!');
  console.log('الاستخدام: node test-simple-notification.js <userId>');
  console.log('مثال: node test-simple-notification.js 673e8f9a1234567890abcdef');
  process.exit(1);
}

const ONESIGNAL_APP_ID = process.env.ONESIGNAL_APP_ID || 'db0f9546-9d0c-411d-a59a-e331483b0d98';
const ONESIGNAL_REST_API_KEY = process.env.ONESIGNAL_REST_API_KEY || 'os_v2_app_3mhzkru5brar3jm24myuqoyntaw3t2mypk2uxxmoxk3suf345nq3ditj5reeo5gjyicog6inzvntxkx53g4cxy7vuy2i3do72kt3hni';

async function testNotification() {
  console.log('🧪 اختبار إرسال إشعار...\n');
  console.log(`📤 إرسال إلى المستخدم: ${userId}\n`);
  
  const payload = {
    app_id: ONESIGNAL_APP_ID,
    include_external_user_ids: [userId],
    
    headings: { 
      en: 'رسالة جديدة',
      ar: 'رسالة جديدة'
    },
    contents: { 
      en: 'مرحباً! هذه رسالة تجريبية من نظام الإشعارات',
      ar: 'مرحباً! هذه رسالة تجريبية من نظام الإشعارات'
    },
    
    data: {
      type: 'chat_message',
      screen: 'chat',
      test: true,
    },

    // Don't specify channel, let OneSignal use default
    small_icon: 'ic_stat_onesignal_default',
    
    ios_badgeType: 'Increase',
    ios_badgeCount: 1,
    
    priority: 10,
  };

  try {
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

    console.log('✅ تم إرسال الإشعار بنجاح!\n');
    console.log('📊 النتيجة:');
    console.log(`   - عدد المستلمين: ${response.data.recipients || 'غير محدد'}`);
    console.log(`   - معرف الإشعار: ${response.data.id}`);
    console.log(`   - الأخطاء: ${response.data.errors || 'لا يوجد'}`);
    
    if (response.data.recipients === 0 || response.data.recipients === undefined) {
      console.log('\n⚠️  تحذير: لم يتم العثور على مستلمين!');
      console.log('   هذا يعني أن المستخدم غير مسجل في OneSignal.');
      console.log('\n💡 الحلول:');
      console.log('   1. تأكد من أن المستخدم سجل دخول في التطبيق');
      console.log('   2. تأكد من أن OneSignal.login(userId) تم استدعاؤه');
      console.log('   3. تحقق من السجلات: [NotificationService] OneSignal user ID set');
      console.log('   4. جرب إعادة تسجيل الدخول في التطبيق');
    } else {
      console.log('\n🎉 الإشعار تم إرساله بنجاح!');
      console.log('   تحقق من جهاز المستخدم الآن.');
    }
  } catch (error) {
    console.error('\n❌ خطأ في إرسال الإشعار:');
    if (error.response) {
      console.error(`   - الحالة: ${error.response.status}`);
      console.error(`   - الخطأ: ${JSON.stringify(error.response.data, null, 2)}`);
      
      if (error.response.data.errors) {
        console.log('\n💡 الأخطاء:');
        error.response.data.errors.forEach(err => {
          console.log(`   - ${err}`);
        });
      }
    } else {
      console.error(`   - ${error.message}`);
    }
  }
}

testNotification();
