package mx.uam.notiuam.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record SendCodeRequest(
        @Email @NotBlank
        @Pattern(regexp = "^[a-zA-Z0-9._%+-]+@cua\\.uam\\.mx$", message = "El correo debe ser institucional (@cua.uam.mx)")
        String email
) {}
