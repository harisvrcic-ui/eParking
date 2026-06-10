namespace eParking.Services
{
    public static class StringNormalization
    {
        public static string TrimOrEmpty(string? value) => (value ?? string.Empty).Trim();
    }
}
