package mx.uam.notiuam.dto.report;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import mx.uam.notiuam.domain.VoteDecision;

public record VoteRequest(
        @NotNull VoteDecision decision,
        @Size(max = 500) String comment
) {}