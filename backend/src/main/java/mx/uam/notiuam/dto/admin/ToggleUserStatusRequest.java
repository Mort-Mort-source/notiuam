package mx.uam.notiuam.dto.admin;

import jakarta.validation.constraints.NotNull;

public record ToggleUserStatusRequest(
        @NotNull Boolean enabled
) {}
