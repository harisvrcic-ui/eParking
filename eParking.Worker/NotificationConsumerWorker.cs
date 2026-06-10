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

        var deadLetterQueue = _settings.ResolveDeadLetterQueue();

        channel.QueueDeclare(
            queue: _settings.NotificationQueue,
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: null);

        channel.QueueDeclare(
            queue: deadLetterQueue,
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: null);

        channel.BasicQos(prefetchSize: 0, prefetchCount: 1, global: false);

        _logger.LogInformation(
            "Worker listening on RabbitMQ. host={Host} queue={Queue} deadLetterQueue={DeadLetterQueue} maxRetryAttempts={MaxRetryAttempts}",
            _settings.Host,
            _settings.NotificationQueue,
            deadLetterQueue,
            _settings.MaxRetryAttempts);

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
            var retryCount = RabbitMqRetryHelper.GetRetryCount(ea.BasicProperties);
            NotificationDispatchMessage? message = null;
            string? json = null;

            try
            {
                json = Encoding.UTF8.GetString(ea.Body.ToArray());
                message = JsonSerializer.Deserialize<NotificationDispatchMessage>(json);

                if (message == null)
                {
                    _logger.LogWarning(
                        "Received empty or invalid notification message. deliveryTag={DeliveryTag}",
                        deliveryTag);
                    channel.BasicAck(deliveryTag, multiple: false);
                    return;
                }

                await ProcessNotificationAsync(message, stoppingToken);
                channel.BasicAck(deliveryTag, multiple: false);

                _logger.LogInformation(
                    "Processed notification. messageId={MessageId} userId={UserId} reservationId={ReservationId} retryCount={RetryCount}",
                    message.MessageId,
                    message.UserId,
                    message.ReservationId,
                    retryCount);
            }
            catch (Exception ex)
            {
                var ids = ResolveMessageIds(message, json);
                await HandleProcessingFailureAsync(
                    channel,
                    ea,
                    deadLetterQueue,
                    retryCount,
                    ids.MessageId,
                    ids.UserId,
                    ids.ReservationId,
                    ex,
                    stoppingToken);
            }
        };

        channel.BasicConsume(
            queue: _settings.NotificationQueue,
            autoAck: false,
            consumer: consumer);

        stoppingToken.Register(() => tcs.TrySetResult());
        await tcs.Task;
    }

    private async Task HandleProcessingFailureAsync(
        IModel channel,
        BasicDeliverEventArgs delivery,
        string deadLetterQueue,
        int retryCount,
        Guid? messageId,
        int? userId,
        int? reservationId,
        Exception exception,
        CancellationToken stoppingToken)
    {
        if (retryCount >= _settings.MaxRetryAttempts)
        {
            PublishToDeadLetterQueue(channel, delivery, deadLetterQueue, retryCount, exception.Message);

            channel.BasicAck(delivery.DeliveryTag, multiple: false);

            _logger.LogError(
                exception,
                "Notification moved to dead-letter queue after max retries. messageId={MessageId} userId={UserId} reservationId={ReservationId} retryCount={RetryCount} deadLetterQueue={DeadLetterQueue}",
                messageId,
                userId,
                reservationId,
                retryCount,
                deadLetterQueue);
            return;
        }

        var nextRetryCount = retryCount + 1;
        var backoffSeconds = RabbitMqRetryHelper.GetBackoffDelaySeconds(
            retryCount,
            _settings.RetryBackoffSeconds);

        _logger.LogWarning(
            exception,
            "Notification processing failed. Scheduling retry in {BackoffSeconds}s. messageId={MessageId} userId={UserId} reservationId={ReservationId} retryCount={RetryCount} nextRetryCount={NextRetryCount}",
            backoffSeconds,
            messageId,
            userId,
            reservationId,
            retryCount,
            nextRetryCount);

        await Task.Delay(TimeSpan.FromSeconds(backoffSeconds), stoppingToken);

        var props = RabbitMqRetryHelper.ClonePropertiesForRepublish(
            channel,
            delivery.BasicProperties,
            nextRetryCount);

        channel.BasicPublish(
            exchange: string.Empty,
            routingKey: _settings.NotificationQueue,
            basicProperties: props,
            body: delivery.Body);

        channel.BasicAck(delivery.DeliveryTag, multiple: false);
    }

    private void PublishToDeadLetterQueue(
        IModel channel,
        BasicDeliverEventArgs delivery,
        string deadLetterQueue,
        int retryCount,
        string reason)
    {
        var props = RabbitMqRetryHelper.CreateDeadLetterProperties(
            channel,
            delivery.BasicProperties,
            retryCount,
            reason);

        channel.BasicPublish(
            exchange: string.Empty,
            routingKey: deadLetterQueue,
            basicProperties: props,
            body: delivery.Body);
    }

    private static (Guid? MessageId, int? UserId, int? ReservationId) ResolveMessageIds(
        NotificationDispatchMessage? message,
        string? json)
    {
        if (message != null)
            return (message.MessageId, message.UserId, message.ReservationId);

        if (string.IsNullOrWhiteSpace(json))
            return (null, null, null);

        try
        {
            var parsed = JsonSerializer.Deserialize<NotificationDispatchMessage>(json);
            if (parsed == null)
                return (null, null, null);

            return (parsed.MessageId, parsed.UserId, parsed.ReservationId);
        }
        catch
        {
            return (null, null, null);
        }
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
