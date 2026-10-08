package mx.uam.notiuam.dto.report;

import java.time.Instant;
import java.util.UUID;

public record ReportVoteResponse(
        UUID adminId,
        String adminDisplayName,
        String decision,
        String comment,
        Instant votedAt
) {}