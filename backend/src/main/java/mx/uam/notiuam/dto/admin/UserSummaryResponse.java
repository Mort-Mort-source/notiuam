package mx.uam.notiuam.dto.admin;

import java.time.Instant;
import java.util.UUID;

public record UserSummaryResponse(
        UUID id,
        String email,
        String displayName,
        String role,
        boolean enabled,
        Instant createdAt
) {}
