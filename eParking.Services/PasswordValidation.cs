using eParking.Model;
using eParking.Model.Exceptions;

namespace eParking.Services
{
    public static class PasswordValidation
    {
        public static void EnsureValid(string? password)
        {
            if (string.IsNullOrWhiteSpace(password) || password.Length < AuthConstants.MinPasswordLength)
            {
                throw new BusinessException(
                    $"Password must be at least {AuthConstants.MinPasswordLength} characters.");
            }
        }

        public static string? NormalizeOptional(string? password)
        {
            var trimmed = StringNormalization.TrimOrEmpty(password);
            if (trimmed.Length == 0)
                return null;

            EnsureValid(trimmed);
            return trimmed;
        }
    }
}
