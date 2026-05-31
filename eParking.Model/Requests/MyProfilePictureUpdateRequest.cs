namespace eParking.Model.Requests
{
    public class MyProfilePictureUpdateRequest
    {
        /// <summary>Base64 slika (JPEG/PNG/GIF/WebP) ili prazno za uklanjanje.</summary>
        public string? Picture { get; set; }
    }
}
