namespace eParking.Model.Responses
{
    public class ForgotPasswordResponse
    {
        public string Message { get; set; } = string.Empty;

        /// <summary>Samo u Development okruženju — za testiranje bez SMTP-a.</summary>
        public string? DevResetCode { get; set; }
    }
}
