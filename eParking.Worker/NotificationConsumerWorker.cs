using System.Text;
using System.Text.Json;
using eParking.Model;
using eParking.Model.Messaging;
using eParking.Model.Requests;
using eParking.Services;
using Microsoft.Extensions.Options;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace eParking.Worker;

/// <summary>
/// RS2 pomoćni mikroservis: prima poruke iz RabbitMQ i upisuje korisnička obavještenja u bazu.
/// </summary>
public class NotificationConsumerWorker : BackgroundService
{
    private readonly IServiceProvider _services;
    private readonly RabbitMqSettings _settings;
    private readonly ILogger<NotificationConsumerWorker> _logger;

    public NotificationConsumerWorker(
        IServiceProvider services,
        IOptions<RabbitMqSettings> settings,
        ILogger<NotificationConsumerWorker> logger)
    {
        _services = services;
        _settings = settings.Value;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await RunConsumerLoopAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Notification consumer failed. Retrying in 5 seconds...");
                await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
            }
        }
    }

    private async Task RunConsumerLoopAsync(CancellationToken stoppingToken)
    {
        var factory = new ConnectionFactory
        {
            HostName = _settings.Host,
            Port = _settings.Port,
            UserName = _settings.Username,
            Password = _settings.Password,
            VirtualHost = _settings.VirtualHost,
            AutomaticRecoveryEnabled = true,
            DispatchConsumersAsync = true
        };

        using var connection = factory.CreateConnection();
        using var channel = connection.CreateModel();

        channel.QueueDeclare(
            queue: _settings.NotificationQueue,
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: null);

        channel.BasicQos(prefetchSize: 0, prefetchCount: 1, global: false);

        _logger.LogInformation(
            "Worker listening on RabbitMQ. host={Host} queue={Queue}",
            _settings.Host,
            _settings.NotificationQueue);

        var tcs = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);

        var consumer = new AsyncEventingBasicConsumer(channel);
        consumer.Received += async (_, ea) =>
        {
            if (stoppingToken.IsCancellationRequested)
            {
                tcs.TrySetResult();
                return;
            }

            var deliveryTag = ea.DeliveryTag;
            try
            {
                var json = Encoding.UTF8.GetString(ea.Body.ToArray());
                var message = JsonSerializer.Deserialize<NotificationDispatchMessage>(json);

                if (message == null)
                {
                    _logger.LogWarning("Received empty or invalid notification message. deliveryTag={DeliveryTag}", deliveryTag);
                    channel.BasicAck(deliveryTag, multiple: false);
                    return;
                }

                await ProcessNotificationAsync(message, stoppingToken);
                channel.BasicAck(deliveryTag, multiple: false);

                _logger.LogInformation(
                    "Processed notification. messageId={MessageId} userId={UserId} reservationId={ReservationId}",
                    message.MessageId,
                    message.UserId,
                    message.ReservationId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to process notification message. deliveryTag={DeliveryTag}", deliveryTag);
                channel.BasicNack(deliveryTag, multiple: false, requeue: true);
            }
        };

        channel.BasicConsume(
            queue: _settings.NotificationQueue,
            autoAck: false,
            consumer: consumer);

        stoppingToken.Register(() => tcs.TrySetResult());
        await tcs.Task;
    }

    private async Task ProcessNotificationAsync(NotificationDispatchMessage message, CancellationToken cancellationToken)
    {
        using var scope = _services.CreateScope();
        var notificationService = scope.ServiceProvider.GetRequiredService<IUserNotificationService>();

        var exists = false;
        if (message.ReservationId.HasValue)
        {
            exists = await notificationService.ExistsDuplicateAsync(
                message.UserId, message.ReservationId, message.Title);
        }

        if (exists)
        {
            _logger.LogInformation(
                "Skipping duplicate notification. messageId={MessageId} reservationId={ReservationId}",
                message.MessageId,
                message.ReservationId);
            return;
        }

        await notificationService.InsertAsync(new UserNotificationInsertRequest
        {
            UserId = message.UserId,
            ReservationId = message.ReservationId,
            Title = message.Title,
            Body = message.Body,
            IsRead = false
        });
    }
}
