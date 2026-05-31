namespace eParking.Model.Requests
{
    public class BrandUpdateRequest
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Logo { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
