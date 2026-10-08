package mx.uam.notiuam.controller;

import jakarta.validation.Valid;
import mx.uam.notiuam.domain.ReportStatus;
import mx.uam.notiuam.dto.report.ReportResponse;
import mx.uam.notiuam.dto.report.ReportSummaryResponse;
import mx.uam.notiuam.dto.report.VoteRequest;
import mx.uam.notiuam.service.ReportService;
import org.springframework.data.domain.Page;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/admin/reports")
@PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
public class AdminReportController {

    private final ReportService reportService;

    public AdminReportController(ReportService reportService) {
        this.reportService = reportService;
    }

    @GetMapping
    public Page<ReportSummaryResponse> list(
            @RequestParam(required = false) ReportStatus status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return reportService.listForAdmin(status, page, size);
    }

    @GetMapping("/{id}")
    public ReportResponse get(@PathVariable UUID id) {
        return reportService.getById(id);
    }

    @PostMapping("/{id}/vote")
    public ReportResponse vote(@PathVariable UUID id,
                               @Valid @RequestBody VoteRequest req) {
        return reportService.vote(id, req);
    }
}