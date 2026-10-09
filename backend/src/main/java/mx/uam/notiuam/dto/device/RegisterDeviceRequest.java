package mx.uam.notiuam.dto.device;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record RegisterDeviceRequest(
        @NotBlank String token,
        @NotBlank @Pattern(regexp = "ANDROID|IOS|WEB") String platform
) {}