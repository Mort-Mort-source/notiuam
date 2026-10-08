package mx.uam.notiuam.service;

import mx.uam.notiuam.config.CurrentUser;
import mx.uam.notiuam.domain.*;
import mx.uam.notiuam.dto.report.*;
import mx.uam.notiuam.exception.ForbiddenException;
import mx.uam.notiuam.exception.NotFoundException;
import mx.uam.notiuam.repository.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class ReportService {

    public static final int VOTES_REQUIRED = 3;

    private final ReportRepository reportRepository;
    private final ReportVoteRepository voteRepository;
    private final PostRepository postRepository;
    private final ChannelRepository channelRepository;
    private final UserRepository userRepository;
    private final CurrentUser currentUser;
    private final AdminLogService adminLog;

    public ReportService(ReportRepository reportRepository,
                         ReportVoteRepository voteRepository,
                         PostRepository postRepository,
                         ChannelRepository channelRepository,
                         UserRepository userRepository,
                         CurrentUser currentUser,
                         AdminLogService adminLog) {
        this.reportRepository = reportRepository;
        this.voteRepository = voteRepository;
        this.postRepository = postRepository;
        this.channelRepository = channelRepository;
        this.userRepository = userRepository;
        this.currentUser = currentUser;
        this.adminLog = adminLog;
    }

    // ============ Usuario normal ============

    @Transactional
    public ReportResponse create(CreateReportRequest req) {
        UUID reporterId = currentUser.requireId();

        // Verificar que el target existe
        validateTargetExists(req.targetType(), req.targetId());

        // Evitar reportes duplicados del mismo usuario sobre el mismo contenido
        if (reportRepository.existsByTargetTypeAndTargetIdAndReporterId(
                req.targetType(), req.targetId(), reporterId)) {
            throw new IllegalArgumentException("Ya reportaste este contenido");
        }

        User reporter = userRepository.findById(reporterId)
                .orElseThrow(() -> new NotFoundException("Usuario no encontrado"));

        Report report = Report.builder()
                .targetType(req.targetType())
                .targetId(req.targetId())
                .reporter(reporter)
                .reason(req.reason())
                .details(req.details())
                .status(ReportStatus.PENDING)
                .build();

        report = reportRepository.save(report);
        return toResponse(report, reporterId);
    }

    // ============ Admin ============

    @Transactional(readOnly = true)
    public Page<ReportSummaryResponse> listForAdmin(ReportStatus status, int page, int size) {
        Pageable p = PageRequest.of(Math.max(0, page), Math.min(Math.max(1, size), 50));
        UUID me = currentUser.requireId();

        Page<Report> reports = (status == null)
                ? reportRepository.findAllByOrderByCreatedAtDesc(p)
                : reportRepository.findByStatusOrderByCreatedAtDesc(status, p);

        return reports.map(r -> toSummary(r, me));
    }

    @Transactional(readOnly = true)
    public ReportResponse getById(UUID id) {
        Report r = reportRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Reporte no encontrado"));
        return toResponse(r, currentUser.requireId());
    }

    @Transactional
    public ReportResponse vote(UUID reportId, VoteRequest req) {
        var me = currentUser.require();
        UUID adminId = me.id();

        Report report = reportRepository.findById(reportId)
                .orElseThrow(() -> new NotFoundException("Reporte no encontrado"));

        if (report.getStatus() != ReportStatus.PENDING) {
            throw new IllegalStateException("Este reporte ya fue resuelto");
        }

        // Un admin no puede votar en un reporte que él mismo creó
        if (report.getReporter().getId().equals(adminId)) {
            throw new ForbiddenException("No puedes votar en un reporte que tú creaste");
        }

        // Un admin solo puede votar una vez por reporte
        if (voteRepository.findByReportIdAndAdminId(reportId, adminId).isPresent()) {
            throw new IllegalArgumentException("Ya votaste en este reporte");
        }

        User admin = userRepository.findById(adminId)
                .orElseThrow(() -> new NotFoundException("Usuario no encontrado"));

        ReportVote vote = ReportVote.builder()
                .report(report)
                .admin(admin)
                .decision(req.decision())
                .comment(req.comment())
                .build();
        voteRepository.save(vote);

        adminLog.log(admin, "VOTE_" + req.decision(),
                report.getTargetType(), report.getTargetId(),
                "Reporte " + reportId);

        // Verificar si ya se puede resolver
        resolveIfComplete(report);

        return toResponse(reportRepository.findById(reportId).orElseThrow(), adminId);
    }

    // ============ Lógica interna ============

    private void validateTargetExists(ReportTargetType type, UUID targetId) {
        boolean exists = switch (type) {
            case POST -> postRepository.existsById(targetId);
            case CHANNEL -> channelRepository.existsById(targetId);
        };
        if (!exists) {
            throw new NotFoundException("El contenido reportado no existe");
        }
    }

    private void resolveIfComplete(Report report) {
        long totalVotes = voteRepository.countByReportId(report.getId());
        if (totalVotes < VOTES_REQUIRED) return;

        long deleteVotes = voteRepository.countByReportIdAndDecision(
                report.getId(), VoteDecision.DELETE);
        long keepVotes = voteRepository.countByReportIdAndDecision(
                report.getId(), VoteDecision.KEEP);

        ReportStatus newStatus;
        if (deleteVotes > keepVotes) {
            newStatus = ReportStatus.RESOLVED_DELETE;
            applyDeletion(report);
        } else {
            newStatus = ReportStatus.RESOLVED_KEEP;
        }

        report.setStatus(newStatus);
        report.setResolvedAt(Instant.now());
        // resolvedBy: sin autor único (voto colegiado). Se deja null a propósito.
        reportRepository.save(report);
    }

    private void applyDeletion(Report report) {
        switch (report.getTargetType()) {
            case POST -> postRepository.deleteById(report.getTargetId());
            case CHANNEL -> channelRepository.deleteById(report.getTargetId());
        }
    }

    private ReportSummaryResponse toSummary(Report r, UUID meId) {
        long total = voteRepository.countByReportId(r.getId());
        long keep = voteRepository.countByReportIdAndDecision(r.getId(), VoteDecision.KEEP);
        long del = voteRepository.countByReportIdAndDecision(r.getId(), VoteDecision.DELETE);
        boolean voted = voteRepository.findByReportIdAndAdminId(r.getId(), meId).isPresent();

        return new ReportSummaryResponse(
                r.getId(),
                r.getTargetType().name(),
                r.getTargetId(),
                buildTargetPreview(r.getTargetType(), r.getTargetId()),
                r.getReporter().getDisplayName(),
                r.getReason().name(),
                r.getStatus().name(),
                total, keep, del,
                voted,
                r.getCreatedAt()
        );
    }

    private ReportResponse toResponse(Report r, UUID meId) {
        var votes = voteRepository.findByReportId(r.getId()).stream()
                .map(v -> new ReportVoteResponse(
                        v.getAdmin().getId(),
                        v.getAdmin().getDisplayName(),
                        v.getDecision().name(),
                        v.getComment(),
                        v.getVotedAt()))
                .toList();

        long keep = votes.stream().filter(v -> "KEEP".equals(v.decision())).count();
        long del = votes.stream().filter(v -> "DELETE".equals(v.decision())).count();

        String myVote = votes.stream()
                .filter(v -> v.adminId().equals(meId))
                .map(ReportVoteResponse::decision)
                .findFirst()
                .orElse(null);

        var preview = buildTargetPreviewWithDetails(r.getTargetType(), r.getTargetId());

        return new ReportResponse(
                r.getId(),
                r.getTargetType().name(),
                r.getTargetId(),
                preview.preview(),
                preview.details(),
                r.getReporter().getDisplayName(),
                r.getReason().name(),
                r.getDetails(),
                r.getStatus().name(),
                votes.size(), keep, del,
                myVote != null,
                myVote,
                votes,
                r.getCreatedAt(),
                r.getResolvedAt(),
                r.getResolvedBy() != null ? r.getResolvedBy().getDisplayName() : null
        );
    }

    private String buildTargetPreview(ReportTargetType type, UUID id) {
        return buildTargetPreviewWithDetails(type, id).preview();
    }

    private record TargetPreview(String preview, String details) {}

    private TargetPreview buildTargetPreviewWithDetails(ReportTargetType type, UUID id) {
        if (type == ReportTargetType.POST) {
            return postRepository.findById(id)
                    .map(p -> {
                        String c = p.getContent();
                        String preview = c.length() > 80 ? c.substring(0, 77) + "..." : c;
                        return new TargetPreview(preview,
                                "Post en canal: " + p.getChannel().getName()
                                + " · por " + p.getAuthor().getDisplayName());
                    })
                    .orElse(new TargetPreview("(Publicación eliminada)", ""));
        } else {
            return channelRepository.findById(id)
                    .map(c -> new TargetPreview(
                            c.getName(),
                            "Canal · por " + c.getOwner().getDisplayName()))
                    .orElse(new TargetPreview("(Canal eliminado)", ""));
        }
    }
}