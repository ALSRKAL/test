const SibApiV3Sdk = require('@sendinblue/client');
const logger = require('../utils/logger');

class EmailService {
  constructor() {
    this.apiInstance = null;
    this.isConfigured = false;
    this.initialize();
  }

  /**
   * Initialize Brevo (Sendinblue) email service
   */
  initialize() {
    try {
      const brevoApiKey = process.env.BREVO_API_KEY;

      if (!brevoApiKey) {
        logger.warn('📧 Brevo API key not configured');
        logger.warn('   1. Sign up at: https://app.brevo.com/account/register');
        logger.warn('   2. Get API key from: Settings > SMTP & API');
        logger.warn('   3. Add to .env: BREVO_API_KEY=your-key');
        return;
      }

      // Initialize Brevo API
      this.apiInstance = new SibApiV3Sdk.TransactionalEmailsApi();
      const apiKey = this.apiInstance.authentications['apiKey'];
      apiKey.apiKey = brevoApiKey;

      this.isConfigured = true;
      logger.info('✅ Brevo email service is ready');
      logger.info('   📊 Free: 300 emails/day');
    } catch (error) {
      logger.error(`Failed to initialize Brevo: ${error.message}`);
      this.isConfigured = false;
    }
  }

  /**
   * Send email using Brevo
   * @param {String} to - Recipient email
   * @param {String} subject - Email subject
   * @param {String} html - Email HTML content
   */
  async sendEmail(to, subject, html) {
    try {
      if (!this.isConfigured) {
        logger.warn('📧 Email service not configured, skipping email');
        logger.warn('   For testing: check logs for reset code');
        return false;
      }

      // استخدم البريد المحقق في Brevo
      const fromEmail = process.env.BREVO_FROM_EMAIL || 'zaqxswcde3vfr4@gmail.com';
      const fromName = process.env.EMAIL_FROM_NAME || 'Hajzy';

      const sendSmtpEmail = new SibApiV3Sdk.SendSmtpEmail();
      sendSmtpEmail.sender = { name: fromName, email: fromEmail };
      sendSmtpEmail.to = [{ email: to }];
      sendSmtpEmail.subject = subject;
      sendSmtpEmail.htmlContent = html;

      const data = await this.apiInstance.sendTransacEmail(sendSmtpEmail);
      logger.info(`✅ Email sent successfully to ${to} (ID: ${data.messageId})`);
      return true;
    } catch (error) {
      logger.error(`❌ Failed to send email to ${to}: ${error.message || error}`);
      if (error.response) {
        logger.error(`   Response: ${JSON.stringify(error.response.body)}`);
      }
      return false;
    }
  }

  /**
   * Send welcome email
   */
  async sendWelcomeEmail(user) {
    const html = `
      <h1>مرحباً ${user.name}!</h1>
      <p>شكراً لانضمامك إلى Hajzy</p>
      <p>نحن سعداء بوجودك معنا</p>
    `;

    await this.sendEmail(user.email, 'مرحباً بك في Hajzy', html);
  }

  /**
   * Send booking confirmation email
   */
  async sendBookingConfirmationEmail(user, booking) {
    const html = `
      <h1>تأكيد الحجز</h1>
      <p>مرحباً ${user.name},</p>
      <p>تم تأكيد حجزك بنجاح</p>
      <p><strong>التاريخ:</strong> ${booking.date}</p>
      <p><strong>الوقت:</strong> ${booking.time}</p>
      <p><strong>المبلغ:</strong> ${booking.payment.amount} ر.س</p>
    `;

    await this.sendEmail(user.email, 'تأكيد الحجز - Hajzy', html);
  }

  /**
   * Send booking reminder email
   */
  async sendBookingReminderEmail(user, booking, hoursUntil) {
    const html = `
      <h1>تذكير بالحجز</h1>
      <p>مرحباً ${user.name},</p>
      <p>لديك حجز بعد ${hoursUntil} ساعة</p>
      <p><strong>التاريخ:</strong> ${booking.date}</p>
      <p><strong>الوقت:</strong> ${booking.time}</p>
    `;

    await this.sendEmail(user.email, 'تذكير بالحجز - Hajzy', html);
  }

  /**
   * Send password reset email with code
   */
  async sendPasswordResetEmail(user, resetCode) {
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; direction: rtl;">
        <h1 style="color: #333; text-align: center;">إعادة تعيين كلمة المرور</h1>
        <p style="font-size: 16px; color: #555;">مرحباً ${user.name},</p>
        <p style="font-size: 16px; color: #555;">لقد طلبت إعادة تعيين كلمة المرور الخاصة بك.</p>
        <p style="font-size: 16px; color: #555;">استخدم الرمز التالي لإعادة تعيين كلمة المرور:</p>
        
        <div style="background-color: #f5f5f5; padding: 20px; text-align: center; margin: 20px 0; border-radius: 8px;">
          <h2 style="color: #6366f1; font-size: 32px; letter-spacing: 5px; margin: 0;">${resetCode}</h2>
        </div>
        
        <p style="font-size: 14px; color: #888;">الرمز صالح لمدة 10 دقائق فقط</p>
        <p style="font-size: 14px; color: #888;">إذا لم تطلب إعادة تعيين كلمة المرور، يرجى تجاهل هذا البريد</p>
        
        <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
        <p style="font-size: 12px; color: #999; text-align: center;">Hajzy - منصة حجز المصورات</p>
      </div>
    `;

    await this.sendEmail(user.email, 'إعادة تعيين كلمة المرور - Hajzy', html);
  }

  /**
   * Send verification approval email
   */
  async sendVerificationApprovalEmail(user) {
    const html = `
      <h1>تم الموافقة على حسابك</h1>
      <p>مرحباً ${user.name},</p>
      <p>تم الموافقة على حسابك كمصورة</p>
      <p>يمكنك الآن البدء في استقبال الحجوزات</p>
    `;

    await this.sendEmail(user.email, 'تم الموافقة على حسابك - Hajzy', html);
  }

  /**
   * Send verification rejection email
   */
  async sendVerificationRejectionEmail(user, reason) {
    const html = `
      <h1>تم رفض طلب التوثيق</h1>
      <p>مرحباً ${user.name},</p>
      <p>للأسف، تم رفض طلب التوثيق</p>
      <p><strong>السبب:</strong> ${reason}</p>
      <p>يمكنك إعادة التقديم بعد تصحيح المشكلة</p>
    `;

    await this.sendEmail(user.email, 'تم رفض طلب التوثيق - Hajzy', html);
  }
}

module.exports = new EmailService();
