package mx.uam.notiuam.dto.report;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record ReportResponse(
        UUID id,
        String targetType,
        UUID targetId,
        String targetPreview,
        String targetDetails,
        String reporterDisplayName,
        String reason,
        String details,
        String status,
        long voteCount,
        long keepVotes,
        long deleteVotes,
        boolean votedByMe,
        String myVote,
        List<ReportVoteResponse> votes,
        Instant createdAt,
        Instant resolvedAt,
        String resolvedByDisplayName
) {}