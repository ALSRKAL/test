require('dotenv').config();
const axios = require('axios');

// Get parameters from command line
const userId = process.argv[2];
const notificationType = process.argv[3] || 'new_booking'; // new_booking, status_update, cancellation

if (!userId) {
  console.log('❌ معاملات ناقصة!');
  console.log('\nالاستخدام:');
  console.log('  node test-booking-notification.js <userId> [type]');
  console.log('\nالأنواع المتاحة:');
  console.log('  - new_booking (افتراضي): إشعار حجز جديد');
  console.log('  - confirmed: إشعار تأكيد الحجز');
  console.log('  - completed: إشعار إكمال الحجز');
  console.log('  - cancelled: إشعار إلغاء الحجز');
  console.log('\nأمثلة:');
  console.log('  node test-booking-notification.js 690fc36b628274e7ee9861ff new_booking');
  console.log('  node test-booking-notification.js 690dc3a286f81c345a7c67a2 confirmed');
  process.exit(1);
}

const ONESIGNAL_APP_ID = process.env.ONESIGNAL_APP_ID || 'db0f9546-9d0c-411d-a59a-e331483b0d98';
const ONESIGNAL_REST_API_KEY = process.env.ONESIGNAL_REST_API_KEY || 'os_v2_app_3mhzkru5brar3jm24myuqoyntaw3t2mypk2uxxmoxk3suf345nq3ditj5reeo5gjyicog6inzvntxkx53g4cxy7vuy2i3do72kt3hni';

async function testBookingNotification() {
  console.log('🧪 اختبار إشعارات الحجوزات...\n');
  console.log(`📤 إرسال إلى المستخدم: ${userId}`);
  console.log(`📋 نوع الإشعار: ${notificationType}\n`);
  
  let payload;

  switch (notificationType) {
    case 'new_booking':
      // Notification to photographer about new booking
      payload = {
        app_id: ONESIGNAL_APP_ID,
        include_external_user_ids: [userId],
        
        headings: { 
          en: '🎉 حجز جديد!',
          ar: '🎉 حجز جديد!'
        },
        contents: { 
          en: 'لديك حجز جديد من عائشه محمد',
          ar: 'لديك حجز جديد من عائشه محمد'
        },
        
        data: {
          type: 'new_booking',
          bookingId: 'test_booking_123',
          clientName: 'عائشه محمد',
          date: 'الجمعة، 15 نوفمبر 2024',
          time: '09:00 - 11:00',
          packageName: 'باقة الأفراح',
          location: 'صنعاء، اليمن',
          price: 500,
          screen: 'bookings',
        },

        small_icon: 'ic_stat_onesignal_default',
        ios_badgeType: 'Increase',
        ios_badgeCount: 1,
        priority: 10,
        android_accent_color: 'FF9C27B0',
      };
      break;

    case 'confirmed':
      // Notification to client about booking confirmation
      payload = {
        app_id: ONESIGNAL_APP_ID,
        include_external_user_ids: [userId],
        
        headings: { 
          en: '✅ تم تأكيد الحجز',
          ar: '✅ تم تأكيد الحجز'
        },
        contents: { 
          en: 'تم تأكيد حجزك مع فاطمه',
          ar: 'تم تأكيد حجزك مع فاطمه'
        },
        
        data: {
          type: 'booking_status',
          bookingId: 'test_booking_123',
          status: 'confirmed',
          oldStatus: 'pending',
          photographerName: 'فاطمه',
          date: 'الجمعة، 15 نوفمبر 2024',
          timeSlot: '09:00 - 11:00',
          packageName: 'باقة الأفراح',
          screen: 'bookings',
        },

        small_icon: 'ic_stat_onesignal_default',
        ios_badgeType: 'Increase',
        ios_badgeCount: 1,
        priority: 10,
        android_accent_color: 'FF4CAF50',
      };
      break;

    case 'completed':
      // Notification to client about booking completion
      payload = {
        app_id: ONESIGNAL_APP_ID,
        include_external_user_ids: [userId],
        
        headings: { 
          en: '✨ تم إكمال الحجز',
          ar: '✨ تم إكمال الحجز'
        },
        contents: { 
          en: 'تم إكمال حجزك مع فاطمه. نتمنى أن تكون راضياً عن الخدمة!',
          ar: 'تم إكمال حجزك مع فاطمه. نتمنى أن تكون راضياً عن الخدمة!'
        },
        
        data: {
          type: 'booking_status',
          bookingId: 'test_booking_123',
          status: 'completed',
          oldStatus: 'confirmed',
          photographerName: 'فاطمه',
          date: 'الجمعة، 15 نوفمبر 2024',
          timeSlot: '09:00 - 11:00',
          packageName: 'باقة الأفراح',
          screen: 'bookings',
        },

        small_icon: 'ic_stat_onesignal_default',
        ios_badgeType: 'Increase',
        ios_badgeCount: 1,
        priority: 10,
        android_accent_color: 'FF9C27B0',
      };
      break;

    case 'cancelled':
      // Notification about booking cancellation
      payload = {
        app_id: ONESIGNAL_APP_ID,
        include_external_user_ids: [userId],
        
        headings: { 
          en: '❌ تم إلغاء الحجز',
          ar: '❌ تم إلغاء الحجز'
        },
        contents: { 
          en: 'قام العميل بإلغاء الحجز',
          ar: 'قام العميل بإلغاء الحجز'
        },
        
        data: {
          type: 'booking_cancelled',
          bookingId: 'test_booking_123',
          cancelledBy: 'client',
          cancellerName: 'عائشه محمد',
          date: 'الجمعة، 15 نوفمبر 2024',
          timeSlot: '09:00 - 11:00',
          packageName: 'باقة الأفراح',
          reason: 'تغيير في الخطط',
          screen: 'bookings',
        },

        small_icon: 'ic_stat_onesignal_default',
        ios_badgeType: 'Increase',
        ios_badgeCount: 1,
        priority: 10,
        android_accent_color: 'FFF44336',
      };
      break;

    default:
      console.log(`❌ نوع إشعار غير معروف: ${notificationType}`);
      process.exit(1);
  }

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

testBookingNotification();
