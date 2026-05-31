namespace eParking.Model.Messaging
{
    /// <summary>
    /// Async notification job sent from API to Worker via RabbitMQ.
    /// </summary>
    public class NotificationDispatchMessage
    {
        public Guid MessageId { get; set; } = Guid.NewGuid();
        public int UserId { get; set; }
        public int? ReservationId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Body { get; set; } = string.Empty;
        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    }
}
