namespace eParking.Model.Requests
{
    public class ColorUpdateRequest
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? HexCode { get; set; }
    }
}
