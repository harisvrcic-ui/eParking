namespace eParking.Model.Responses
{
    public class UserNotificationResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int? ReservationId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Body { get; set; } = string.Empty;
        public bool IsRead { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}

