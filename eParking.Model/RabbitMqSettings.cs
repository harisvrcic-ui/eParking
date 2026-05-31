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

    }

}


