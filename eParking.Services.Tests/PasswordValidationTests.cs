using eParking.Model;
using eParking.Model.Exceptions;
using eParking.Services;

namespace eParking.Services.Tests;

public class PasswordValidationTests
{
    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("12345")]
    public void EnsureValid_throws_for_short_or_empty_password(string? password)
    {
        Assert.Throws<BusinessException>(() => PasswordValidation.EnsureValid(password));
    }

    [Fact]
    public void EnsureValid_accepts_minimum_length_password()
    {
        var password = new string('a', AuthConstants.MinPasswordLength);
        PasswordValidation.EnsureValid(password);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public void NormalizeOptional_returns_null_for_blank_password(string? password)
    {
        Assert.Null(PasswordValidation.NormalizeOptional(password));
    }

    [Fact]
    public void NormalizeOptional_validates_non_blank_password()
    {
        Assert.Throws<BusinessException>(() => PasswordValidation.NormalizeOptional("12345"));
        Assert.Equal("abcdef", PasswordValidation.NormalizeOptional("  abcdef  "));
    }
}
