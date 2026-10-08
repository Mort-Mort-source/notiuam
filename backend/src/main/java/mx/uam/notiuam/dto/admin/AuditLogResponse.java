package mx.uam.notiuam.dto.admin;

import java.time.Instant;
import java.util.UUID;

public record AuditLogResponse(
        UUID id,
        UUID adminId,
        String adminDisplayName,
        String action,
        String targetType,
        UUID targetId,
        String details,
        Instant createdAt
) {}
