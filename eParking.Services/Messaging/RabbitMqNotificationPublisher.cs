using System.Text;
using System.Text.Json;
using eParking.Model;
using eParking.Model.Messaging;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using RabbitMQ.Client;

namespace eParking.Services.Messaging
{
    public class RabbitMqNotificationPublisher : INotificationQueuePublisher, IDisposable
    {
        private readonly RabbitMqSettings _settings;
        private readonly ILogger<RabbitMqNotificationPublisher> _logger;
        private readonly object _sync = new();
        private IConnection? _connection;
        private IModel? _channel;

        public RabbitMqNotificationPublisher(IOptions<RabbitMqSettings> settings, ILogger<RabbitMqNotificationPublisher> logger)
        {
            _settings = settings.Value;
            _logger = logger;
        }

        public Task PublishNotificationAsync(NotificationDispatchMessage message, CancellationToken cancellationToken = default)
        {
            EnsureChannel();

            var json = JsonSerializer.Serialize(message);
            var body = Encoding.UTF8.GetBytes(json);

            var props = _channel!.CreateBasicProperties();
            props.ContentType = "application/json";
            props.DeliveryMode = 2;
            props.MessageId = message.MessageId.ToString();
            props.Timestamp = new AmqpTimestamp(DateTimeOffset.UtcNow.ToUnixTimeSeconds());

            _channel.BasicPublish(
                exchange: string.Empty,
                routingKey: _settings.NotificationQueue,
                basicProperties: props,
                body: body);

            _logger.LogInformation(
                "Published notification to RabbitMQ. queue={Queue} messageId={MessageId} userId={UserId} reservationId={ReservationId}",
                _settings.NotificationQueue,
                message.MessageId,
                message.UserId,
                message.ReservationId);

            return Task.CompletedTask;
        }

        private void EnsureChannel()
        {
            if (_channel is { IsOpen: true })
                return;

            lock (_sync)
            {
                if (_channel is { IsOpen: true })
                    return;

                _channel?.Dispose();
                _connection?.Dispose();

                var factory = new ConnectionFactory
                {
                    HostName = _settings.Host,
                    Port = _settings.Port,
                    UserName = _settings.Username,
                    Password = _settings.Password,
                    VirtualHost = _settings.VirtualHost,
                    AutomaticRecoveryEnabled = true
                };

                _connection = factory.CreateConnection();
                _channel = _connection.CreateModel();

                _channel.QueueDeclare(
                    queue: _settings.NotificationQueue,
                    durable: true,
                    exclusive: false,
                    autoDelete: false,
                    arguments: null);

                _logger.LogInformation(
                    "RabbitMQ publisher connected. host={Host} queue={Queue}",
                    _settings.Host,
                    _settings.NotificationQueue);
            }
        }

        public void Dispose()
        {
            _channel?.Dispose();
            _connection?.Dispose();
        }
    }
}
