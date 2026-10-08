package mx.uam.notiuam.dto.report;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import mx.uam.notiuam.domain.ReportReason;
import mx.uam.notiuam.domain.ReportTargetType;

import java.util.UUID;

public record CreateReportRequest(
        @NotNull ReportTargetType targetType,
        @NotNull UUID targetId,
        @NotNull ReportReason reason,
        @Size(max = 500) String details
) {}