const mongoose = require('mongoose');
require('dotenv').config();

const Photographer = require('./src/models/Photographer');

async function listPhotographers() {
  try {
    console.log('🔌 جاري الاتصال بقاعدة البيانات...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ تم الاتصال بنجاح\n');

    console.log('📸 جاري جلب المصورات...');
    const photographers = await Photographer.find().lean();

    console.log(`\n📊 عدد المصورات الكلي: ${photographers.length}\n`);
    console.log('═══════════════════════════════════════════════════\n');

    if (photographers.length === 0) {
      console.log('⚠️  لا توجد مصورات في قاعدة البيانات!');
      console.log('\n💡 لإضافة مصورة:');
      console.log('   1. سجل دخول كمصورة في التطبيق');
      console.log('   2. أكمل الملف الشخصي');
      console.log('   3. أضف باقات وصور\n');
    } else {
      // Get all user IDs to fetch user data
      const User = require('./src/models/User');
      const userIds = photographers.map(p => p.user).filter(Boolean);
      const users = await User.find({ _id: { $in: userIds } }).lean();
      const userMap = {};
      users.forEach(u => { userMap[u._id.toString()] = u; });
      
      photographers.forEach((photographer, index) => {
        const user = userMap[photographer.user?.toString()] || {};
        
        console.log(`${index + 1}. 📷 ${user.name || photographer.name || 'بدون اسم'}`);
        console.log(`   ├─ ID: ${photographer._id}`);
        console.log(`   ├─ User ID: ${photographer.user || 'N/A'}`);
        console.log(`   ├─ Email: ${user.email || photographer.email || 'N/A'}`);
        console.log(`   ├─ Phone: ${user.phone || 'N/A'}`);
        console.log(`   ├─ Bio: ${photographer.bio || 'لا يوجد'}`);
        console.log(`   ├─ التخصصات: ${photographer.specialties?.join(', ') || 'لا يوجد'}`);
        console.log(`   ├─ المدينة: ${photographer.location?.city || 'غير محدد'}`);
        console.log(`   ├─ المنطقة: ${photographer.location?.area || 'غير محدد'}`);
        console.log(`   ├─ التقييم: ${photographer.rating?.average?.toFixed(1) || '0.0'} (${photographer.rating?.count || 0} تقييم)`);
        console.log(`   ├─ الباقات: ${photographer.packages?.length || 0}`);
        
        if (photographer.packages && photographer.packages.length > 0) {
          photographer.packages.forEach((pkg, i) => {
            console.log(`   │  ${i + 1}. ${pkg.name}: ${pkg.price} ريال`);
          });
        }
        
        console.log(`   ├─ الصور: ${photographer.portfolio?.images?.length || 0}`);
        console.log(`   ├─ الفيديو: ${photographer.portfolio?.video ? 'نعم' : 'لا'}`);
        console.log(`   ├─ مميزة: ${photographer.featured?.isActive ? '⭐ نعم' : 'لا'}`);
        console.log(`   ├─ موثقة: ${photographer.verification?.isVerified ? '✓ نعم' : 'لا'}`);
        console.log(`   └─ تاريخ الإنشاء: ${new Date(photographer.createdAt).toLocaleDateString('ar-SA')}`);
        console.log('');
      });
    }

    console.log('═══════════════════════════════════════════════════');
    
    // إحصائيات إضافية
    const withPackages = photographers.filter(p => p.packages && p.packages.length > 0).length;
    const withImages = photographers.filter(p => p.portfolio?.images && p.portfolio.images.length > 0).length;
    const featured = photographers.filter(p => p.featured?.isActive).length;
    const verified = photographers.filter(p => p.verification?.isVerified).length;
    
    console.log('\n📈 إحصائيات:');
    console.log(`   ├─ مصورات لديها باقات: ${withPackages}/${photographers.length}`);
    console.log(`   ├─ مصورات لديها صور: ${withImages}/${photographers.length}`);
    console.log(`   ├─ مصورات مميزة: ${featured}/${photographers.length}`);
    console.log(`   └─ مصورات موثقة: ${verified}/${photographers.length}`);
    
    console.log('\n✅ تم بنجاح!\n');
    
  } catch (error) {
    console.error('\n❌ خطأ:', error.message);
    console.error('Stack:', error.stack);
  } finally {
    await mongoose.disconnect();
    process.exit(0);
  }
}

listPhotographers();
