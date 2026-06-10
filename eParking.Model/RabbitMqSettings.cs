namespace eParking.Model

{

    public class RabbitMqSettings

    {

        public bool Enabled { get; set; }

        public string Host { get; set; } = string.Empty;

        public int Port { get; set; }

        public string Username { get; set; } = string.Empty;

        public string Password { get; set; } = string.Empty;

        public string VirtualHost { get; set; } = string.Empty;

        public string NotificationQueue { get; set; } = string.Empty;

        public string? NotificationDeadLetterQueue { get; set; }

        public int MaxRetryAttempts { get; set; } = 3;

        public int[] RetryBackoffSeconds { get; set; } = [5, 30, 120];

        public string ResolveDeadLetterQueue()
        {
            if (!string.IsNullOrWhiteSpace(NotificationDeadLetterQueue))
                return NotificationDeadLetterQueue;

            return string.IsNullOrWhiteSpace(NotificationQueue)
                ? "eparking.notifications.dlq"
                : $"{NotificationQueue}.dlq";
        }

    }

}


