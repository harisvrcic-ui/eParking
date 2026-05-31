using System.Security.Cryptography;
using System.Text;

namespace eParking.Services
{
    /// <summary>
    /// PBKDF2 (RFC 2898) password hashing. Legacy SHA256 hashes remain verifiable for migration.
    /// </summary>
    public static class PasswordHasher
    {
        private const int SaltSize = 16;
        private const int KeySize = 32;
        private const int Iterations = 100_000;
        private const string Pbkdf2Prefix = "pbkdf2:";

        public static void CreateHash(string password, out string salt, out string hash)
        {
            var saltBytes = RandomNumberGenerator.GetBytes(SaltSize);
            salt = Convert.ToBase64String(saltBytes);
            hash = Pbkdf2Prefix + HashPasswordPbkdf2(password, saltBytes);
        }

        public static bool Verify(string password, string salt, string hash)
        {
            if (string.IsNullOrEmpty(password) || string.IsNullOrEmpty(salt) || string.IsNullOrEmpty(hash))
                return false;

            if (hash.StartsWith(Pbkdf2Prefix, StringComparison.Ordinal))
            {
                var stored = hash[Pbkdf2Prefix.Length..];
                return VerifyPbkdf2(password, salt, stored);
            }

            return VerifyLegacySha256(password, salt, hash);
        }

        public static bool IsLegacyHash(string hash)
            => !hash.StartsWith(Pbkdf2Prefix, StringComparison.Ordinal);

        /// <summary>Deterministic salt/hash for database seed data.</summary>
        public static (string Salt, string Hash) CreateSeedHash(string password, string saltKey)
        {
            var saltBytes = SHA256.HashData(Encoding.UTF8.GetBytes("eParking-seed:" + saltKey))[..SaltSize];
            var salt = Convert.ToBase64String(saltBytes);
            var hash = Pbkdf2Prefix + HashPasswordPbkdf2(password, saltBytes);
            return (salt, hash);
        }

        /// <summary>6-digit reset code using cryptographically secure RNG (RS2 A.3).</summary>
        public static string GenerateResetCode()
            => RandomNumberGenerator.GetInt32(100_000, 1_000_000).ToString();

        public static void HashResetCode(string code, out string salt, out string hash)
            => CreateHash(code, out salt, out hash);

        public static bool VerifyResetCode(string code, string salt, string hash)
            => Verify(code, salt, hash);

        private static string HashPasswordPbkdf2(string password, byte[] saltBytes)
        {
            var hashBytes = Rfc2898DeriveBytes.Pbkdf2(
                password,
                saltBytes,
                Iterations,
                HashAlgorithmName.SHA256,
                KeySize);
            return Convert.ToBase64String(hashBytes);
        }

        private static bool VerifyPbkdf2(string password, string salt, string storedHashBase64)
        {
            byte[] saltBytes;
            byte[] expectedHash;
            try
            {
                saltBytes = Convert.FromBase64String(salt);
                expectedHash = Convert.FromBase64String(storedHashBase64);
            }
            catch (FormatException)
            {
                return false;
            }

            var actualHash = Rfc2898DeriveBytes.Pbkdf2(
                password,
                saltBytes,
                Iterations,
                HashAlgorithmName.SHA256,
                expectedHash.Length);

            return CryptographicOperations.FixedTimeEquals(actualHash, expectedHash);
        }

        private static bool VerifyLegacySha256(string password, string salt, string hash)
        {
            var computed = ComputeLegacySha256Hash(password, salt);
            return CryptographicOperations.FixedTimeEquals(
                Encoding.UTF8.GetBytes(computed),
                Encoding.UTF8.GetBytes(hash));
        }

        private static string ComputeLegacySha256Hash(string password, string salt)
        {
            var bytes = Encoding.UTF8.GetBytes(password + salt);
            var hashBytes = SHA256.HashData(bytes);
            return Convert.ToBase64String(hashBytes);
        }
    }
}
