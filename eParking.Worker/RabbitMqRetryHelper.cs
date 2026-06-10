using System.Text;
using RabbitMQ.Client;

namespace eParking.Worker;

internal static class RabbitMqRetryHelper
{
    public const string RetryCountHeader = "x-retry-count";
    public const string DeadLetterReasonHeader = "x-dead-letter-reason";
    public const string DeadLetteredAtHeader = "x-dead-lettered-at";

    public static int GetRetryCount(IBasicProperties? properties)
        => GetRetryCount(properties?.Headers);

    public static int GetRetryCount(IDictionary<string, object>? headers)
    {
        if (headers == null || !headers.TryGetValue(RetryCountHeader, out var value))
            return 0;

        return value switch
        {
            int i => i,
            long l => (int)l,
            byte[] bytes => int.TryParse(Encoding.UTF8.GetString(bytes), out var parsed) ? parsed : 0,
            string s => int.TryParse(s, out var parsed) ? parsed : 0,
            _ => 0
        };
    }

    public static int GetBackoffDelaySeconds(int retryCount, int[] backoffSeconds)
    {
        if (backoffSeconds.Length == 0)
            return 5;

        var index = Math.Clamp(retryCount, 0, backoffSeconds.Length - 1);
        return Math.Max(1, backoffSeconds[index]);
    }

    public static IBasicProperties ClonePropertiesForRepublish(
        IModel channel,
        IBasicProperties source,
        int retryCount)
    {
        var props = channel.CreateBasicProperties();
        props.ContentType = string.IsNullOrWhiteSpace(source.ContentType)
            ? "application/json"
            : source.ContentType;
        props.DeliveryMode = source.DeliveryMode == 0 ? (byte)2 : source.DeliveryMode;
        props.MessageId = source.MessageId;
        props.Timestamp = source.Timestamp;
        props.Type = source.Type;
        props.CorrelationId = source.CorrelationId;

        var headers = source.Headers == null
            ? new Dictionary<string, object>()
            : new Dictionary<string, object>(source.Headers);

        headers[RetryCountHeader] = retryCount;
        props.Headers = headers;
        return props;
    }

    public static IBasicProperties CreateDeadLetterProperties(
        IModel channel,
        IBasicProperties source,
        int retryCount,
        string reason)
    {
        var props = ClonePropertiesForRepublish(channel, source, retryCount);
        props.Headers![DeadLetterReasonHeader] = reason;
        props.Headers[DeadLetteredAtHeader] = DateTimeOffset.UtcNow.ToString("O");
        return props;
    }
}
