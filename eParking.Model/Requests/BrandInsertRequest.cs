namespace eParking.Model.Requests
{
    public class BrandInsertRequest
    {
        public string Name { get; set; } = string.Empty;
        public string? Logo { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
