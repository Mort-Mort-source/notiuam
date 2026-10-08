package mx.uam.notiuam.controller;

import jakarta.validation.Valid;
import mx.uam.notiuam.dto.report.CreateReportRequest;
import mx.uam.notiuam.dto.report.ReportResponse;
import mx.uam.notiuam.service.ReportService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/reports")
public class ReportController {

    private final ReportService reportService;

    public ReportController(ReportService reportService) {
        this.reportService = reportService;
    }

    @PostMapping
    public ResponseEntity<ReportResponse> create(
            @Valid @RequestBody CreateReportRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED).body(reportService.create(req));
    }
}
