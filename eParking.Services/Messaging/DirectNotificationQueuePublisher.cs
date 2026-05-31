using eParking.Model.Messaging;
using eParking.Model.Requests;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace eParking.Services.Messaging
{
    /// <summary>
    /// When RabbitMQ is disabled, persists notifications synchronously (local dev without Worker).
    /// </summary>
    public class DirectNotificationQueuePublisher : INotificationQueuePublisher
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<DirectNotificationQueuePublisher> _logger;

        public DirectNotificationQueuePublisher(
            IServiceScopeFactory scopeFactory,
            ILogger<DirectNotificationQueuePublisher> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        public async Task PublishNotificationAsync(
            NotificationDispatchMessage message,
            CancellationToken cancellationToken = default)
        {
            using var scope = _scopeFactory.CreateScope();
            var notificationService = scope.ServiceProvider.GetRequiredService<IUserNotificationService>();

            if (message.ReservationId.HasValue)
            {
                if (await notificationService.ExistsDuplicateAsync(
                    message.UserId, message.ReservationId, message.Title))
                {
                    _logger.LogInformation(
                        "Skipping duplicate notification (direct). reservationId={ReservationId}",
                        message.ReservationId);
                    return;
                }
            }

            await notificationService.InsertAsync(new UserNotificationInsertRequest
            {
                UserId = message.UserId,
                ReservationId = message.ReservationId,
                Title = message.Title,
                Body = message.Body,
                IsRead = false
            });

            _logger.LogInformation(
                "Notification saved directly (RabbitMQ disabled). userId={UserId} title={Title}",
                message.UserId,
                message.Title);
        }
    }
}
