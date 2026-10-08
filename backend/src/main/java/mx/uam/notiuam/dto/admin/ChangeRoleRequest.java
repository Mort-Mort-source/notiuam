package mx.uam.notiuam.dto.admin;

import jakarta.validation.constraints.NotNull;
import mx.uam.notiuam.domain.Role;

public record ChangeRoleRequest(
        @NotNull Role role
) {}
