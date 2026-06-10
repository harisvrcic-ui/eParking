namespace eParking.Model
{
    public static class AuthConstants
    {
        public const int MaxFailedLoginAttempts = 5;
        public const int LockoutMinutes = 15;
        public const int MinPasswordLength = 6;
        public const int UsernameMaxLength = 100;
        public const int NameMaxLength = 50;
        public const int EmailMaxLength = 100;
        public const int PhoneMaxLength = 20;
        public const int CarModelMaxLength = 100;
        public const int LicensePlateMaxLength = 20;
        public const int ReservationTypeNameMaxLength = 100;
    }
}
