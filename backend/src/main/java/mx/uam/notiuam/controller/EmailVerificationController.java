package mx.uam.notiuam.controller;

import jakarta.validation.Valid;
import mx.uam.notiuam.dto.auth.SendCodeRequest;
import mx.uam.notiuam.dto.auth.VerifyCodeRequest;
import mx.uam.notiuam.repository.UserRepository;
import mx.uam.notiuam.service.EmailService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class EmailVerificationController {

    private final EmailService emailService;
    private final UserRepository userRepository;

    public EmailVerificationController(EmailService emailService, UserRepository userRepository) {
        this.emailService = emailService;
        this.userRepository = userRepository;
    }

    @PostMapping("/send-verification")
    public ResponseEntity<Map<String, String>> send(@Valid @RequestBody SendCodeRequest req) {
        String email = req.email().toLowerCase().trim();

        if (userRepository.existsByEmail(email)) {
            return ResponseEntity.badRequest().body(Map.of("message", "El correo ya esta registrado"));
        }

        emailService.sendVerificationCode(email);
        return ResponseEntity.ok(Map.of("message", "Codigo enviado"));
    }

    @PostMapping("/verify-email")
    public ResponseEntity<Map<String, Object>> verify(@Valid @RequestBody VerifyCodeRequest req) {
        String email = req.email().toLowerCase().trim();
        boolean ok = emailService.verifyCode(email, req.code());

        if (!ok) {
            return ResponseEntity.badRequest().body(Map.of("verified", false, "message", "Codigo incorrecto o expirado"));
        }

        return ResponseEntity.ok(Map.of("verified", true));
    }
}
