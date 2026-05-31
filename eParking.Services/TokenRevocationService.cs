using System.Collections.Concurrent;

namespace eParking.Services
{
    public interface ITokenRevocationService
    {
        void Revoke(string jti, DateTime expiresAtUtc);
        bool IsRevoked(string jti);
    }

    public sealed class TokenRevocationService : ITokenRevocationService
    {
        private readonly ConcurrentDictionary<string, DateTime> _revoked = new();

        public void Revoke(string jti, DateTime expiresAtUtc)
        {
            if (string.IsNullOrWhiteSpace(jti))
                return;

            _revoked[jti] = expiresAtUtc;
            PurgeExpired();
        }

        public bool IsRevoked(string jti)
        {
            if (string.IsNullOrWhiteSpace(jti))
                return false;

            if (!_revoked.TryGetValue(jti, out var expiresAt))
                return false;

            if (expiresAt <= DateTime.UtcNow)
            {
                _revoked.TryRemove(jti, out _);
                return false;
            }

            return true;
        }

        private void PurgeExpired()
        {
            var now = DateTime.UtcNow;
            foreach (var entry in _revoked)
            {
                if (entry.Value <= now)
                    _revoked.TryRemove(entry.Key, out _);
            }
        }
    }
}
