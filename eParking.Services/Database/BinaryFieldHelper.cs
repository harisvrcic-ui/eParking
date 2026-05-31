using System.Text;
using eParking.Model.Exceptions;

namespace eParking.Services.Database
{
    public static class BinaryFieldHelper
    {
        public static string? ToApiString(byte[]? data)
        {
            if (data == null || data.Length == 0)
                return null;

            // Legacy DB stores raw image bytes; newer seeds may store UTF-8 file names.
            if (LooksLikeText(data))
                return Encoding.UTF8.GetString(data);

            return Convert.ToBase64String(data);
        }

        public static byte[]? FromApiString(string? value)
        {
            if (string.IsNullOrWhiteSpace(value))
                return null;

            try
            {
                return Convert.FromBase64String(value);
            }
            catch (FormatException)
            {
                return Encoding.UTF8.GetBytes(value);
            }
        }

        /// <summary>
        /// Decodes a base64 image from the API and validates magic bytes (RS2 auth).
        /// </summary>
        public static byte[]? FromApiImageString(string? value)
        {
            if (string.IsNullOrWhiteSpace(value))
                return null;

            byte[] data;
            try
            {
                var raw = value.Contains(',') ? value.Split(',').Last() : value;
                data = Convert.FromBase64String(raw.Trim());
            }
            catch (FormatException)
            {
                throw new BusinessException("Invalid image format. Upload a JPEG, PNG, GIF or WebP file.");
            }

            ValidateImageMagicBytes(data);
            return data;
        }

        public static void ValidateImageMagicBytes(byte[] data)
        {
            if (data.Length < 4)
                throw new BusinessException("Image file is too small or invalid.");

            if (IsJpeg(data) || IsPng(data) || IsGif(data) || IsWebp(data))
                return;

            throw new BusinessException("Only JPEG, PNG, GIF and WebP images are allowed.");
        }

        private static bool IsJpeg(byte[] data) =>
            data.Length >= 3 && data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF;

        private static bool IsPng(byte[] data) =>
            data.Length >= 8 &&
            data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47 &&
            data[4] == 0x0D && data[5] == 0x0A && data[6] == 0x1A && data[7] == 0x0A;

        private static bool IsGif(byte[] data) =>
            data.Length >= 6 &&
            data[0] == (byte)'G' && data[1] == (byte)'I' && data[2] == (byte)'F' &&
            data[3] == (byte)'8' && (data[4] == (byte)'7' || data[4] == (byte)'9') && data[5] == (byte)'a';

        private static bool IsWebp(byte[] data) =>
            data.Length >= 12 &&
            data[0] == (byte)'R' && data[1] == (byte)'I' && data[2] == (byte)'F' && data[3] == (byte)'F' &&
            data[8] == (byte)'W' && data[9] == (byte)'E' && data[10] == (byte)'B' && data[11] == (byte)'P';

        private static bool LooksLikeText(byte[] data)
        {
            if (data.Length > 256)
                return false;

            foreach (var b in data)
            {
                if (b is < 9 or > 127)
                    return false;
            }

            return true;
        }
    }
}
