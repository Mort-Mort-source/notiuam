package mx.uam.notiuam.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record VerifyCodeRequest(
        @Email @NotBlank
        @Pattern(regexp = "^[a-zA-Z0-9._%+-]+@cua\\.uam\\.mx$")
        String email,

        @NotBlank
        @Pattern(regexp = "^\\d{6}$", message = "El codigo debe tener 6 digitos")
        String code
) {}
