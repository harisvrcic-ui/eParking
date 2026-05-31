using eParking.Model.Messaging;

namespace eParking.Services.Messaging
{
    public interface INotificationQueuePublisher
    {
        Task PublishNotificationAsync(NotificationDispatchMessage message, CancellationToken cancellationToken = default);
    }
}
