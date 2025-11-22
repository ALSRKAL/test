const mongoose = require('mongoose');
const path = require('path');
const bcrypt = require('bcryptjs');
const User = require('../src/models/User');
const Photographer = require('../src/models/Photographer');
const Booking = require('../src/models/Booking');
const Review = require('../src/models/Review');
const { Message, Conversation } = require('../src/models/Message');

// Load .env
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

// Data arrays
const photographerNames = [
  'نورة المطيري', 'سارة العتيبي', 'فاطمة القحطاني', 'مريم الدوسري', 'هند الشمري',
  'ريم الحربي', 'لينا العنزي', 'دانة السبيعي', 'شهد الغامدي', 'جود الزهراني',
  'لمى العمري', 'غلا السلمي', 'رهف الثقفي', 'جنى البقمي', 'ملاك الجهني',
  'أسماء الخالدي', 'بشاير الرشيدي', 'منى السليماني', 'عبير الماجد', 'وعد الفيصل',
  'رنا الناصر', 'ديما الطيار', 'ريناد الشهري', 'لجين العصيمي', 'شوق البكر',
  'أريج الحمود', 'تالا الفهد', 'ياسمين الراجحي', 'نوف السديري', 'عهد العجلان',
  'أمل الدخيل', 'سلمى الفوزان', 'روان الربيعان', 'جواهر السعيد', 'لطيفة الحسن',
  'نجلاء الخليفة', 'هيا المنصور', 'بدور الصالح', 'غادة الحميد', 'إيمان الشريف'
];

const clientNames = [
  'فاطمة أحمد', 'نورة محمد', 'سارة عبدالله', 'مريم خالد', 'هند سعيد',
  'ريم عبدالعزيز', 'لينا حسن', 'دانة علي', 'شهد يوسف', 'جود إبراهيم',
  'لمى عمر', 'غلا سلطان', 'رهف ناصر', 'جنى فهد', 'ملاك عبدالرحمن',
  'أسماء طارق', 'بشاير راشد', 'منى سليمان', 'عبير ماجد', 'وعد فيصل',
  'رنا حمد', 'ديما صالح', 'ريناد عادل', 'لجين ماجد', 'شوق فارس'
];

const cities = [
  { city: 'الرياض', area: 'العليا' },
  { city: 'الرياض', area: 'النخيل' },
  { city: 'جدة', area: 'الروضة' },
  { city: 'جدة', area: 'الحمراء' },
  { city: 'الدمام', area: 'الفيصلية' },
  { city: 'مكة', area: 'العزيزية' },
  { city: 'المدينة', area: 'العيون' },
  { city: 'الطائف', area: 'الشفا' }
];

const specialties = ['weddings', 'events', 'portraits', 'children', 'products', 'fashion', 'nature', 'other'];

const bios = [
  'مصورة محترفة متخصصة في التصوير الفوتوغرافي للمناسبات الخاصة. أسعى لتوثيق أجمل اللحظات بطريقة فنية واحترافية.',
  'شغوفة بفن التصوير منذ سنوات. أقدم خدمات تصوير احترافية بأحدث المعدات وأفضل الأسعار.',
  'مصورة معتمدة مع خبرة تزيد عن 5 سنوات في تصوير المناسبات. أحب أن أجعل كل لحظة ذكرى لا تُنسى.',
  'متخصصة في التصوير الإبداعي والفني. أعمل على تقديم صور فريدة تعكس شخصية كل عميل.',
  'مصورة محترفة أؤمن بأن كل صورة تحكي قصة. دعيني أوثق قصتك بأجمل الطرق.'
];

const reviewComments = [
  'تجربة رائعة جداً! المصورة محترفة وملتزمة بالمواعيد. الصور جميلة جداً وأعجبتني كثيراً.',
  'ما شاء الله تبارك الله، صور احترافية وجودة عالية. المصورة ذوق راقي وتعاملها ممتاز.',
  'صراحة فوق التوقعات! الصور طلعت أجمل مما تخيلت. المصورة فنانة وعندها حس إبداعي عالي.',
  'تجربة ممتازة من البداية للنهاية. المصورة متعاونة جداً وصبورة. الصور جاءت بجودة عالية.',
  'أفضل مصورة تعاملت معها! محترفة وملتزمة وذوقها راقي. الصور خيالية وأسعارها معقولة.',
  'تجربة جميلة ومريحة. المصورة لطيفة وتعرف كيف تخلي الجلسة ممتعة. الصور طلعت رهيبة.',
  'ما شاء الله عليها، شغل نظيف واحترافي. الصور جودتها عالية والتعديل ممتاز.',
  'مصورة موهوبة وعندها خبرة واضحة. الصور جميلة جداً والإضاءة والزوايا كلها مدروسة.'
];

const photographerReplies = [
  'شكراً جزيلاً على كلماتك الجميلة! سعيدة جداً بإعجابك بالصور. دائماً في خدمتك 💕',
  'الله يسعدك ويحفظك! شكراً على ثقتك وتعاملك الراقي. أتمنى أشوفك قريب 🌸',
  'ما شاء الله عليك! كلماتك أسعدتني كثير. شكراً على التعاون والذوق الراقي ✨',
  'شكراً حبيبتي على التقييم الجميل! سعيدة إني قدرت أحقق توقعاتك 💖',
  'الله يخليك ويسعدك! شكراً على كلماتك اللطيفة. كان شرف لي التعامل معك 🌹'
];

const messageTexts = [
  'السلام عليكم، أريد الاستفسار عن أسعار التصوير',
  'مرحباً، هل أنتِ متاحة يوم الجمعة القادمة؟',
  'شكراً على الرد السريع، متى يمكنني استلام الصور؟',
  'الصور جميلة جداً، شكراً لك 💕',
  'هل يمكن إضافة تعديلات إضافية على الصور؟'
];

// Connect to MongoDB
const connectDB = async () => {
  try {
    const mongoUri = process.env.MONGODB_URI || process.env.MONGO_URI;
    if (!mongoUri) {
      console.error('❌ MONGODB_URI not found in .env file');
      process.exit(1);
    }
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(mongoUri);
    console.log('✅ MongoDB connected\n');
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  }
};

// Helper functions
const randomItem = (arr) => arr[Math.floor(Math.random() * arr.length)];
const randomNumber = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const randomDate = (daysAgo) => new Date(Date.now() - Math.random() * daysAgo * 24 * 60 * 60 * 1000);

// Seed database
const seedDatabase = async () => {
  try {
    console.log('🌱 Starting database seeding...\n');

    // Check if test data already exists
    const existingTestUsers = await User.countDocuments({ email: { $regex: /@test\.com$/ } });
    if (existingTestUsers > 0) {
      console.log(`⚠️  Found ${existingTestUsers} existing test users`);
      console.log('💡 Please run clean-database.js first to remove old data\n');
      console.log('   Run: node scripts/clean-database.js\n');
      return;
    }

    // Create clients
    console.log('👥 Creating 25 clients...');
    const clients = [];
    for (let i = 0; i < 25; i++) {
      const client = await User.create({
        name: clientNames[i],
        email: `client${i + 1}@test.com`,
        password: await bcrypt.hash('password123', 10),
        phone: `+96650${String(i).padStart(7, '0')}`,
        role: 'client',
      });
      clients.push(client);
    }
    console.log(`✅ Created ${clients.length} clients\n`);

    // Create 40 photographers
    console.log('📸 Creating 40 photographers...');
    const photographers = [];
    
    for (let i = 0; i < 40; i++) {
      // Create user
      const user = await User.create({
        name: photographerNames[i],
        email: `photographer${i + 1}@test.com`,
        password: await bcrypt.hash('password123', 10),
        phone: `+96655${String(i).padStart(7, '0')}`,
        role: 'photographer',
      });

      // Create photographer profile
      const location = randomItem(cities);
      const photographer = await Photographer.create({
        user: user._id,
        bio: randomItem(bios),
        location: {
          city: location.city,
          area: location.area
        },
        specialties: [randomItem(specialties), randomItem(specialties)],
        
        // Portfolio
        portfolio: {
          images: [
            'https://images.unsplash.com/photo-1519741497674-611481863552',
            'https://images.unsplash.com/photo-1606216794074-735e91aa2c92',
            'https://images.unsplash.com/photo-1511285560929-80b456fea0bc'
          ].map(url => ({ url, caption: 'عمل سابق' })),
          videos: []
        },

        // Packages
        packages: [
          {
            name: 'الباقة الأساسية',
            price: randomNumber(500, 800),
            duration: '2 hours',
            features: ['50 صورة معدلة', 'تسليم خلال 7 أيام', 'ألبوم رقمي']
          },
          {
            name: 'الباقة الذهبية',
            price: randomNumber(1000, 1500),
            duration: '4 hours',
            features: ['100 صورة معدلة', 'تسليم خلال 5 أيام', 'ألبوم رقمي', 'فيديو قصير']
          }
        ],

        // Subscription
        subscription: {
          plan: i < 10 ? 'premium' : i < 25 ? 'pro' : 'basic',
          startDate: randomDate(90),
          endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
        }
      });

      photographers.push(photographer);
      
      if ((i + 1) % 10 === 0) {
        console.log(`   Created ${i + 1}/40 photographers...`);
      }
    }
    console.log(`✅ Created ${photographers.length} photographers\n`);

    // Create bookings and reviews
    console.log('📅 Creating bookings and reviews...');
    let totalBookings = 0;
    let totalReviews = 0;

    for (const photographer of photographers) {
      const numBookings = randomNumber(3, 8);
      
      for (let i = 0; i < numBookings; i++) {
        const client = randomItem(clients);
        const pkg = randomItem(photographer.packages);
        const bookingDate = randomDate(60);
        
        const booking = await Booking.create({
          client: client._id,
          photographer: photographer._id,
          package: pkg._id,
          date: bookingDate,
          timeSlot: randomItem(['09:00 - 11:00', '11:00 - 13:00', '15:00 - 17:00', '17:00 - 19:00']),
          location: randomItem(cities).city,
          status: randomItem(['completed', 'completed', 'completed', 'confirmed', 'pending']),
          payment: {
            amount: pkg.price,
            status: 'paid'
          }
        });

        totalBookings++;

        // Create review for completed bookings (80% chance)
        if (booking.status === 'completed' && Math.random() > 0.2) {
          const rating = Math.random() > 0.7 ? 5 : Math.random() > 0.4 ? 4 : 3;
          
          const review = await Review.create({
            booking: booking._id,
            client: client._id,
            photographer: photographer._id,
            rating: rating,
            comment: randomItem(reviewComments),
            createdAt: new Date(bookingDate.getTime() + randomNumber(1, 5) * 24 * 60 * 60 * 1000)
          });

          // Add photographer reply (85% chance)
          if (Math.random() > 0.15) {
            review.photographerReply = {
              comment: randomItem(photographerReplies),
              createdAt: new Date(review.createdAt.getTime() + randomNumber(1, 3) * 24 * 60 * 60 * 1000)
            };
            await review.save();
          }

          totalReviews++;
        }
      }

      // Update photographer rating
      const reviews = await Review.find({ photographer: photographer._id });
      if (reviews.length > 0) {
        const totalRating = reviews.reduce((sum, r) => sum + r.rating, 0);
        photographer.rating = {
          average: totalRating / reviews.length,
          count: reviews.length
        };
        photographer.stats.completedBookings = reviews.length;
        await photographer.save();
      }
    }
    console.log(`✅ Created ${totalBookings} bookings`);
    console.log(`✅ Created ${totalReviews} reviews\n`);

    // Create conversations and messages
    console.log('💬 Creating conversations and messages...');
    let totalConversations = 0;
    let totalMessages = 0;

    for (let i = 0; i < 30; i++) {
      const client = randomItem(clients);
      const photographer = randomItem(photographers);
      
      const conversation = await Conversation.create({
        participants: [client._id, photographer.user],
        lastMessage: null,
        lastMessageTime: randomDate(30)
      });

      const numMessages = randomNumber(2, 6);
      for (let j = 0; j < numMessages; j++) {
        const isFromClient = j % 2 === 0;
        const message = await Message.create({
          conversation: conversation._id,
          sender: isFromClient ? client._id : photographer.user,
          receiver: isFromClient ? photographer.user : client._id,
          content: randomItem(messageTexts),
          type: 'text',
          isRead: Math.random() > 0.3,
          createdAt: new Date(conversation.lastMessageTime.getTime() + j * 60 * 60 * 1000)
        });
        totalMessages++;
      }

      totalConversations++;
    }
    console.log(`✅ Created ${totalConversations} conversations`);
    console.log(`✅ Created ${totalMessages} messages\n`);

    // Summary
    console.log('═══════════════════════════════════════');
    console.log('🎉 Database seeding completed!');
    console.log('═══════════════════════════════════════');
    console.log(`📸 Photographers: ${photographers.length}`);
    console.log(`👥 Clients: ${clients.length}`);
    console.log(`📅 Bookings: ${totalBookings}`);
    console.log(`⭐ Reviews: ${totalReviews}`);
    console.log(`💬 Conversations: ${totalConversations}`);
    console.log(`📨 Messages: ${totalMessages}`);
    console.log('═══════════════════════════════════════\n');

  } catch (error) {
    console.error('❌ Error seeding database:', error);
    throw error;
  }
};

// Run
const run = async () => {
  await connectDB();
  await seedDatabase();
  await mongoose.connection.close();
  console.log('👋 Database connection closed');
  process.exit(0);
};

run();
