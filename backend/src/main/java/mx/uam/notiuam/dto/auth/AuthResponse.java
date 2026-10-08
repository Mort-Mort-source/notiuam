package mx.uam.notiuam.dto.auth;

public record AuthResponse(
        String accessToken,
        String refreshToken,
        String tokenType,
        long expiresInMs,
        UserSummary user
) {
    public record UserSummary(String id, String email, String displayName, String role) {}
}