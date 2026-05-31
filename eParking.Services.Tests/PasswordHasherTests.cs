using eParking.Services;

namespace eParking.Services.Tests;

public class PasswordHasherTests
{
    [Fact]
    public void CreateHash_and_Verify_succeed_for_correct_password()
    {
        PasswordHasher.CreateHash("TestPassword123", out var salt, out var hash);

        Assert.StartsWith("pbkdf2:", hash);
        Assert.True(PasswordHasher.Verify("TestPassword123", salt, hash));
        Assert.False(PasswordHasher.Verify("WrongPassword", salt, hash));
    }

    [Fact]
    public void CreateSeedHash_is_deterministic_for_same_username()
    {
        var first = PasswordHasher.CreateSeedHash("test", "mobile");
        var second = PasswordHasher.CreateSeedHash("test", "mobile");

        Assert.Equal(first.Salt, second.Salt);
        Assert.Equal(first.Hash, second.Hash);
        Assert.True(PasswordHasher.Verify("test", first.Salt, first.Hash));
    }

    [Fact]
    public void GenerateResetCode_returns_six_digits()
    {
        var code = PasswordHasher.GenerateResetCode();

        Assert.Equal(6, code.Length);
        Assert.True(int.TryParse(code, out var value));
        Assert.InRange(value, 100_000, 999_999);
    }

    [Fact]
    public void HashResetCode_does_not_store_plain_text_equivalent()
    {
        var code = PasswordHasher.GenerateResetCode();
        PasswordHasher.HashResetCode(code, out var salt, out var hash);

        Assert.NotEqual(code, hash);
        Assert.True(PasswordHasher.VerifyResetCode(code, salt, hash));
        Assert.False(PasswordHasher.VerifyResetCode("000000", salt, hash));
    }

    [Fact]
    public void Verify_accepts_legacy_sha256_hashes()
    {
        const string password = "admin";
        var saltBytes = System.Security.Cryptography.SHA256.HashData(
            System.Text.Encoding.UTF8.GetBytes("eParking-seed:admin"))[..16];
        var salt = Convert.ToBase64String(saltBytes);
        var bytes = System.Text.Encoding.UTF8.GetBytes(password + salt);
        var legacyHash = Convert.ToBase64String(System.Security.Cryptography.SHA256.HashData(bytes));

        Assert.True(PasswordHasher.IsLegacyHash(legacyHash));
        Assert.True(PasswordHasher.Verify(password, salt, legacyHash));
    }
}
