using System.Net;
using System.Net.Mail;
using eParking.Model;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace eParking.Services
{
    public class SmtpEmailSender : IEmailSender
    {
        private readonly SmtpSettings _settings;
        private readonly ILogger<SmtpEmailSender> _logger;

        public SmtpEmailSender(IOptions<SmtpSettings> settings, ILogger<SmtpEmailSender> logger)
        {
            _settings = settings.Value;
            _logger = logger;
        }

        public async Task SendAsync(string toEmail, string subject, string body)
        {
            if (string.IsNullOrWhiteSpace(_settings.Host))
            {
                _logger.LogWarning(
                    "SMTP nije konfigurisan — e-mail nije poslan. Prima={Email} Naslov={Subject} Sadržaj={Body}",
                    toEmail,
                    subject,
                    body);
                return;
            }

            var from = string.IsNullOrWhiteSpace(_settings.FromAddress)
                ? _settings.Username
                : _settings.FromAddress;

            if (string.IsNullOrWhiteSpace(from))
                throw new InvalidOperationException("SMTP FromAddress ili Username mora biti postavljen.");

            using var message = new MailMessage
            {
                From = new MailAddress(from, _settings.FromName ?? "eParking"),
                Subject = subject,
                Body = body,
                IsBodyHtml = false,
            };
            message.To.Add(toEmail);

            using var client = new SmtpClient(_settings.Host, _settings.Port)
            {
                EnableSsl = _settings.UseSsl,
                DeliveryMethod = SmtpDeliveryMethod.Network,
            };

            if (!string.IsNullOrWhiteSpace(_settings.Username))
                client.Credentials = new NetworkCredential(_settings.Username, _settings.Password);

            await client.SendMailAsync(message);
        }
    }
}
