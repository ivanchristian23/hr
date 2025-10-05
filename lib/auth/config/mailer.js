const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'Outlook365',
  auth: {
    user: 'iventura@proztec.com',
    pass: 'yqgnhxlpftshlzcc',
  },
});

transporter.verify((error, success) => {
  if (error) console.log('Mailer Error:', error);
  else console.log('✅ Mailer ready');
});

module.exports = transporter;
