namespace eParking.Services.Database
{
    /// <summary>
    /// Resolves seed image file names from wwwroot (same layout as legacy HasData seed).
    /// </summary>
    public static class SeedAssetHelper
    {
        public static string? TryGetAssetFileName(string wwwrootFolder, string fileName)
        {
            if (string.IsNullOrWhiteSpace(fileName))
                return null;

            var baseDir = ResolveWwwRoot(wwwrootFolder);
            if (baseDir == null)
                return fileName;

            var fullPath = Path.Combine(baseDir, fileName);
            return File.Exists(fullPath) ? fileName : fileName;
        }

        private static string? ResolveWwwRoot(string wwwrootFolder)
        {
            var candidates = new[]
            {
                Path.Combine(Directory.GetCurrentDirectory(), wwwrootFolder),
                Path.Combine(AppContext.BaseDirectory, wwwrootFolder),
                Path.Combine(AppContext.BaseDirectory, "..", "..", "..", wwwrootFolder),
            };

            foreach (var path in candidates)
            {
                var full = Path.GetFullPath(path);
                if (Directory.Exists(full))
                    return full;
            }

            return null;
        }
    }
}
