using System.Text.RegularExpressions;
using eParking.Model;
using eParking.Model.Exceptions;
using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Services.Database;
using eParking.Services.Database.Parking;
using Microsoft.EntityFrameworkCore;

namespace eParking.Services
{
    public class AuthService : IAuthService
    {
        private readonly ParkingDbContext _context;
        private readonly IJwtTokenService _jwtTokenService;
        private readonly IEmailSender _emailSender;

        private static readonly Regex EmailRegex =
            new(@"^[\w\.\-]+@[\w\-]+\.[A-Za-z]{2,}$", RegexOptions.Compiled);

        public AuthService(
            ParkingDbContext context,
            IJwtTokenService jwtTokenService,
            IEmailSender emailSender)
        {
            _context = context;
            _jwtTokenService = jwtTokenService;
            _emailSender = emailSender;
        }

        public async Task<LoginResponse> LoginAsync(LoginRequest request, bool requireAdmin = false)
        {
            var username = request.Username.Trim();
            var user = await _context.MyAppUsers
                .FirstOrDefaultAsync(u => u.Username == username);

            if (user == null || !user.IsActive)
                throw new UnauthorizedAccessException("Invalid username or password.");

            if (user.LockoutUntil.HasValue && user.LockoutUntil > DateTime.UtcNow)
                throw new UnauthorizedAccessException("Account is temporarily locked. Try again later.");

            if (!PasswordHasher.Verify(request.Password, user.PasswordSalt, user.PasswordHash))
            {
                user.FailedLoginAttempts++;
                if (user.FailedLoginAttempts >= AuthConstants.MaxFailedLoginAttempts)
                    user.LockoutUntil = DateTime.UtcNow.AddMinutes(AuthConstants.LockoutMinutes);

                await _context.SaveChangesAsync();
                throw new UnauthorizedAccessException("Invalid username or password.");
            }

            if (requireAdmin && !user.IsAdmin)
                throw new UnauthorizedAccessException("Admin access required.");

            user.FailedLoginAttempts = 0;
            user.LockoutUntil = null;
            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return BuildLoginResponse(user);
        }

        public async Task<LoginResponse> RegisterAsync(RegisterRequest request)
        {
            var username = request.Username.Trim();
            var email = request.Email.Trim();

            if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(request.Password))
                throw new BusinessException("Username and password are required.");

            if (string.IsNullOrWhiteSpace(request.FirstName) || string.IsNullOrWhiteSpace(request.LastName))
                throw new BusinessException("First name and last name are required.");

            if (string.IsNullOrWhiteSpace(email))
                throw new BusinessException("Email is required.");

            var exists = await _context.MyAppUsers.AnyAsync(u =>
                u.Username == username || u.Email == email);
            if (exists)
                throw new BusinessException(
                    "Korisničko ime ili e-mail adresa su već u upotrebi — unesite druge vrijednosti.");

            if (request.GenderId.HasValue &&
                !await _context.Genders.AnyAsync(g => g.Id == request.GenderId.Value))
                throw new NotFoundException($"Gender with id {request.GenderId} not found.");

            if (request.CityId.HasValue &&
                !await _context.Cities.AnyAsync(c => c.Id == request.CityId.Value))
                throw new NotFoundException($"City with id {request.CityId} not found.");

            PasswordHasher.CreateHash(request.Password, out var salt, out var hash);

            var user = new MyAppUser
            {
                Username = username,
                PasswordSalt = salt,
                PasswordHash = hash,
                FirstName = request.FirstName.Trim(),
                LastName = request.LastName.Trim(),
                Email = email,
                PhoneNumber = request.PhoneNumber,
                GenderId = request.GenderId,
                CityId = request.CityId,
                IsAdmin = false,
                IsUser = true,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            _context.MyAppUsers.Add(user);
            await _context.SaveChangesAsync();

            return BuildLoginResponse(user);
        }

        public async Task<ForgotPasswordResponse> ForgotPasswordAsync(
            ForgotPasswordRequest request,
            bool includeDevCode)
        {
            var email = request.Email?.Trim() ?? string.Empty;
            if (string.IsNullOrWhiteSpace(email))
                throw new BusinessException("E-mail adresa je obavezna — unesite format korisnik@domena.com.");

            if (!EmailRegex.IsMatch(email))
                throw new BusinessException("Unesite ispravnu e-mail adresu u formatu korisnik@domena.com.");

            const string successMessage =
                "Ako postoji račun s tom e-mail adresom, poslali smo vam kod za reset lozinke.";

            var user = await _context.MyAppUsers
                .FirstOrDefaultAsync(u => u.Email == email && u.IsActive);

            string? devCode = null;
            if (user != null)
            {
                var code = PasswordHasher.GenerateResetCode();
                PasswordHasher.HashResetCode(code, out var codeSalt, out var codeHash);
                var oldTokens = await _context.PasswordResetTokens
                    .Where(t => t.UserId == user.Id && !t.IsUsed)
                    .ToListAsync();
                foreach (var token in oldTokens)
                    token.IsUsed = true;

                _context.PasswordResetTokens.Add(new PasswordResetToken
                {
                    UserId = user.Id,
                    CodeSalt = codeSalt,
                    CodeHash = codeHash,
                    ExpiresAt = DateTime.UtcNow.AddMinutes(15),
                    CreatedAt = DateTime.UtcNow,
                });
                await _context.SaveChangesAsync();

                await _emailSender.SendAsync(
                    user.Email,
                    "eParking — reset lozinke",
                    $"Vaš kod za reset lozinke je: {code}\nKod vrijedi 15 minuta.");

                if (includeDevCode)
                    devCode = code;
            }

            return new ForgotPasswordResponse
            {
                Message = successMessage,
                DevResetCode = devCode,
            };
        }

        public async Task ResetPasswordAsync(ResetPasswordRequest request)
        {
            var email = request.Email?.Trim() ?? string.Empty;
            var code = request.Code?.Trim() ?? string.Empty;

            if (string.IsNullOrWhiteSpace(email))
                throw new BusinessException("E-mail adresa je obavezna — unesite format korisnik@domena.com.");

            if (!EmailRegex.IsMatch(email))
                throw new BusinessException("Unesite ispravnu e-mail adresu u formatu korisnik@domena.com.");

            if (string.IsNullOrWhiteSpace(code))
                throw new BusinessException("Kod za reset je obavezan — unesite 6-cifreni kod iz e-maila.");

            if (!Regex.IsMatch(code, @"^\d{6}$"))
                throw new BusinessException("Kod mora imati tačno 6 cifara (npr. 123456).");

            if (string.IsNullOrWhiteSpace(request.NewPassword) || request.NewPassword.Length < 6)
                throw new BusinessException("Nova lozinka mora imati najmanje 6 znakova.");

            if (request.NewPassword != request.ConfirmPassword)
                throw new BusinessException("Nova lozinka i potvrda se ne podudaraju — unesite istu lozinku u oba polja.");

            var user = await _context.MyAppUsers
                .FirstOrDefaultAsync(u => u.Email == email && u.IsActive);
            if (user == null)
                throw new BusinessException("Kod nije ispravan ili je istekao — zatražite novi kod.");

            var token = await _context.PasswordResetTokens
                .Where(t => t.UserId == user.Id && !t.IsUsed && t.ExpiresAt > DateTime.UtcNow)
                .OrderByDescending(t => t.CreatedAt)
                .ToListAsync();

            var matched = token.FirstOrDefault(t =>
                PasswordHasher.VerifyResetCode(code, t.CodeSalt, t.CodeHash));

            if (matched == null)
                throw new BusinessException("Kod nije ispravan ili je istekao — zatražite novi kod.");

            PasswordHasher.CreateHash(request.NewPassword, out var salt, out var hash);
            user.PasswordSalt = salt;
            user.PasswordHash = hash;
            user.FailedLoginAttempts = 0;
            user.LockoutUntil = null;
            user.UpdatedAt = DateTime.UtcNow;
            matched.IsUsed = true;

            await _context.SaveChangesAsync();
        }

        private LoginResponse BuildLoginResponse(MyAppUser user)
        {
            var (token, expiresAt) = _jwtTokenService.CreateToken(user);

            return new LoginResponse
            {
                Id = user.Id,
                Username = user.Username,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Email = user.Email,
                IsAdmin = user.IsAdmin,
                IsUser = user.IsUser,
                Token = token,
                ExpiresAt = expiresAt,
                Picture = BinaryFieldHelper.ToApiString(user.Picture),
            };
        }
    }
}
