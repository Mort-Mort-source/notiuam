package mx.uam.notiuam.service;

import java.util.UUID;

import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import io.jsonwebtoken.Claims;
import mx.uam.notiuam.domain.Role;
import mx.uam.notiuam.domain.User;
import mx.uam.notiuam.dto.auth.AuthResponse;
import mx.uam.notiuam.dto.auth.LoginRequest;
import mx.uam.notiuam.dto.auth.RegisterRequest;
import mx.uam.notiuam.repository.UserRepository;
import mx.uam.notiuam.security.JwtService;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService,
                       AuthenticationManager authenticationManager) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.authenticationManager = authenticationManager;
    }

    @Transactional
    public AuthResponse register(RegisterRequest req) {
        if (userRepository.existsByEmail(req.email().toLowerCase())) {
            throw new IllegalArgumentException("El correo ya está registrado");
        }

        User user = User.builder()
                .email(req.email().toLowerCase())
                .passwordHash(passwordEncoder.encode(req.password()))
                .displayName(req.displayName())
                .role(req.role() != null ? req.role() : Role.STUDENT)
                .enabled(true)
                .build();

        user = userRepository.save(user);
        return buildAuthResponse(user);
    }

    public AuthResponse login(LoginRequest req) {
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            req.email().toLowerCase(),
                            req.password()));
        } catch (AuthenticationException e) {
            throw new IllegalArgumentException("Credenciales inválidas");
        }

        User user = userRepository.findByEmail(req.email().toLowerCase())
                .orElseThrow(() -> new IllegalArgumentException("Usuario no encontrado"));

        return buildAuthResponse(user);
    }

    public AuthResponse refresh(String refreshToken) {
        Claims claims;
        try {
            claims = jwtService.parse(refreshToken);
        } catch (Exception e) {
            throw new IllegalArgumentException("Refresh token inválido o expirado");
        }

        if (!"refresh".equals(claims.get("type", String.class))) {
            throw new IllegalArgumentException("El token no es de tipo refresh");
        }

        UUID userId = UUID.fromString(claims.getSubject());
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Usuario no encontrado"));

        return buildAuthResponse(user);
    }

    private AuthResponse buildAuthResponse(User user) {
        String access = jwtService.generateAccessToken(user);
        String refresh = jwtService.generateRefreshToken(user);
        return new AuthResponse(
                access,
                refresh,
                "Bearer",
                jwtService.getAccessExpirationMs(),
                new AuthResponse.UserSummary(
                        user.getId().toString(),
                        user.getEmail(),
                        user.getDisplayName(),
                        user.getRole().name()
                )
        );
    }
}