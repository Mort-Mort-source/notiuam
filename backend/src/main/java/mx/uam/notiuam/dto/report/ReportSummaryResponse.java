package mx.uam.notiuam.dto.report;

import java.time.Instant;
import java.util.UUID;

public record ReportSummaryResponse(
        UUID id,
        String targetType,
        UUID targetId,
        String targetPreview,
        String reporterDisplayName,
        String reason,
        String status,
        long voteCount,
        long keepVotes,
        long deleteVotes,
        boolean votedByMe,
        Instant createdAt
) {}