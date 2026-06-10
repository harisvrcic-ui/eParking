using eParking.Services;

namespace eParking.Services.Tests;

public class StringNormalizationTests
{
    [Theory]
    [InlineData(null, "")]
    [InlineData("", "")]
    [InlineData("  test  ", "test")]
    public void TrimOrEmpty_handles_null_and_whitespace(string? input, string expected)
    {
        Assert.Equal(expected, StringNormalization.TrimOrEmpty(input));
    }
}
