namespace eParking.Model.Requests
{
    public class NewsUpdateRequest
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Body { get; set; } = string.Empty;
        public string? Image { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
