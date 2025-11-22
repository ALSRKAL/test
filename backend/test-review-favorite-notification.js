require('dotenv').config();
const axios = require('axios');

// Get parameters from command line
const userId = process.argv[2];
const notificationType = process.argv[3] || 'review'; // review, favorite
const rating = process.argv[4] || '5'; // For review notifications

if (!userId) {
  console.log('❌ معاملات ناقصة!');
  console.log('\nالاستخدام:');
  console.log('  node test-review-favorite-notification.js <userId> [type] [rating]');
  console.log('\nالأنواع المتاحة:');
  console.log('  - review (افتراضي): إشعار تقييم جديد');
  console.log('  - favorite: إشعار إعجاب جديد');
  console.log('\nالتقييمات (للتقييمات فقط):');
  console.log('  - 1 إلى 5 نجوم (افتراضي: 5)');
  console.log('\nأمثلة:');
  console.log('  node test-review-favorite-notification.js 690dc3a286f81c345a7c67a2 review 5');
  console.log('  node test-review-favorite-notification.js 690dc3a286f81c345a7c67a2 review 3');
  console.log('  node test-review-favorite-notification.js 690dc3a286f81c345a7c67a2 favorite');
  process.exit(1);
}

const ONESIGNAL_APP_ID = process.env.ONESIGNAL_APP_ID || 'db0f9546-9d0c-411d-a59a-e331483b0d98';
const ONESIGNAL_REST_API_KEY = process.env.ONESIGNAL_REST_API_KEY || 'os_v2_app_3mhzkru5brar3jm24myuqoyntaw3t2mypk2uxxmoxk3suf345nq3ditj5reeo5gjyicog6inzvntxkx53g4cxy7vuy2i3do72kt3hni';

async function testNotification() {
  console.log('🧪 اختبار إشعارات التقييمات والإعجابات...\n');
  console.log(`📤 إرسال إلى المستخدم: ${userId}`);
  console.log(`📋 نوع الإشعار: ${notificationType}\n`);
  
  let payload;

  switch (notificationType) {
    case 'review':
      const ratingNum = parseInt(rating);
      if (ratingNum < 1 || ratingNum > 5) {
        console.log('❌ التقييم يجب أن يكون بين 1 و 5');
        process.exit(1);
      }

      const stars = '⭐'.repeat(ratingNum);
      const ratingMessages = {
        5: 'ممتاز! 🌟',
        4: 'جيد جداً! 👍',
        3: 'جيد',
        2: 'يحتاج تحسين',
        1: 'ضعيف',
      };
      const ratingMessage = ratingMessages[ratingNum];

      console.log(`⭐ التقييم: ${ratingNum}/5 نجوم - ${ratingMessage}\n`);

      payload = {
        app_id: ONESIGNAL_APP_ID,
        include_external_user_ids: [userId],
        
        headings: { 
          en: `${stars} تقييم جديد ${ratingMessage}`,
          ar: `${stars} تقييم جديد ${ratingMessage}`
        },
        contents: { 
          en: `عائشه محمد قيّمك بـ ${ratingNum} نجوم`,
          ar: `عائشه محمد قيّمك بـ ${ratingNum} نجوم`
        },
        
        data: {
          type: 'new_review',
          reviewId: 'test_review_123',
          rating: ratingNum,
          comment: 'خدمة ممتازة وتصوير احترافي!',
          clientName: 'عائشه محمد',
          packageName: 'باقة الأفراح',
          date: 'الجمعة، 15 نوفمبر 2024',
          screen: 'reviews',
        },

        small_icon: 'ic_stat_onesignal_default',
        ios_badgeType: 'Increase',
        ios_badgeCount: 1,
        priority: 10,
        android_accent_color: ratingNum >= 4 ? 'FFFFC107' : 'FFFF9800',
      };
      break;

    case 'favorite':
      payload = {
        app_id: ONESIGNAL_APP_ID,
        include_external_user_ids: [userId],
        
        headings: { 
          en: '❤️ إعجاب جديد!',
          ar: '❤️ إعجاب جديد!'
        },
        contents: { 
          en: 'أعجب عائشه محمد بملفك الشخصي',
          ar: 'أعجب عائشه محمد بملفك الشخصي'
        },
        
        data: {
          type: 'new_favorite',
          clientName: 'عائشه محمد',
          screen: 'profile',
        },

        small_icon: 'ic_stat_onesignal_default',
        ios_badgeType: 'Increase',
        ios_badgeCount: 1,
        priority: 5,
        android_accent_color: 'FFE91E63',
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

testNotification();
