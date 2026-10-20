package mx.uam.notiuam.controller;

import jakarta.validation.Valid;
import mx.uam.notiuam.domain.Role;
import mx.uam.notiuam.domain.User;
import mx.uam.notiuam.dto.auth.AuthResponse;
import mx.uam.notiuam.dto.auth.RegisterRequest;
import mx.uam.notiuam.repository.UserRepository;
import mx.uam.notiuam.security.JwtService;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
@Profile("dev")
public class DevAuthController {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public DevAuthController(UserRepository userRepository,
                             PasswordEncoder passwordEncoder,
                             JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @PostMapping("/register-dev")
    public ResponseEntity<AuthResponse> registerDev(@Valid @RequestBody RegisterRequest req) {
        String email = req.email().toLowerCase().trim();

        if (!email.endsWith("@cua.uam.mx")) {
            throw new IllegalArgumentException("Solo se permiten correos @cua.uam.mx");
        }

        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("El correo ya esta registrado");
        }

        User user = User.builder()
                .email(email)
                .passwordHash(passwordEncoder.encode(req.password()))
                .displayName(req.displayName())
                .role(req.role() != null ? req.role() : Role.STUDENT)
                .emailVerified(true)
                .enabled(true)
                .build();

        user = userRepository.save(user);

        String access = jwtService.generateAccessToken(user);
        String refresh = jwtService.generateRefreshToken(user);

        return ResponseEntity.status(HttpStatus.CREATED).body(new AuthResponse(
                access, refresh, "Bearer",
                jwtService.getAccessExpirationMs(),
                new AuthResponse.UserSummary(
                        user.getId().toString(),
                        user.getEmail(),
                        user.getDisplayName(),
                        user.getRole().name()
                )
        ));
    }
}