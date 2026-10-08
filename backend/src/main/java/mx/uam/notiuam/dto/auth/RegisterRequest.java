package mx.uam.notiuam.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import mx.uam.notiuam.domain.Role;

public record RegisterRequest(
        @Email @NotBlank String email,
        @NotBlank @Size(min = 8, max = 100) String password,
        @NotBlank @Size(max = 120) String displayName,
        Role role   // opcional; si es null, se asigna STUDENT
) {}