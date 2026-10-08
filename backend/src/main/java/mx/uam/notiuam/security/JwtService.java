package mx.uam.notiuam.security;

import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Map;

import javax.crypto.SecretKey;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import mx.uam.notiuam.domain.User;

@Service
public class JwtService {

    private final SecretKey signingKey;
    private final long accessExpirationMs;
    private final long refreshExpirationMs;

    public JwtService(
            @Value("${jwt.secret}") String secret,
            @Value("${jwt.expiration-ms}") long accessExpirationMs,
            @Value("${jwt.refresh-expiration-ms}") long refreshExpirationMs) {
        this.signingKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.accessExpirationMs = accessExpirationMs;
        this.refreshExpirationMs = refreshExpirationMs;
    }

    public String generateAccessToken(User user) {
        return buildToken(user, accessExpirationMs, "access");
    }

    public String generateRefreshToken(User user) {
        return buildToken(user, refreshExpirationMs, "refresh");
    }

    private String buildToken(User user, long ttlMs, String type) {
        Date now = new Date();
        Date exp = new Date(now.getTime() + ttlMs);
        return Jwts.builder()
                .subject(user.getId().toString())
                .claims(Map.of(
                        "email", user.getEmail(),
                        "role", user.getRole().name(),
                        "type", type
                ))
                .issuedAt(now)
                .expiration(exp)
                .signWith(signingKey, SignatureAlgorithm.HS256)
                .compact();
    }

    public Claims parse(String token) {
        return Jwts.parser()
                .verifyWith(signingKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public String extractUserId(String token) {
        return parse(token).getSubject();
    }

    public boolean isValid(String token) {
        try {
            parse(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public long getAccessExpirationMs() {
        return accessExpirationMs;
    }
}