package mx.uam.notiuam.service;

import mx.uam.notiuam.domain.AdminActionLog;
import mx.uam.notiuam.domain.ReportTargetType;
import mx.uam.notiuam.domain.User;
import mx.uam.notiuam.dto.admin.AuditLogResponse;
import mx.uam.notiuam.repository.AdminActionLogRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class AdminLogService {

    private final AdminActionLogRepository repo;

    public AdminLogService(AdminActionLogRepository repo) {
        this.repo = repo;
    }

    @Transactional
    public void log(User admin, String action, ReportTargetType targetType,
                    UUID targetId, String details) {
        repo.save(AdminActionLog.builder()
                .admin(admin)
                .action(action)
                .targetType(targetType)
                .targetId(targetId)
                .details(details)
                .build());
    }

    // ---------- Métodos que devuelven DTOs (mapeo dentro de la transacción) ----------

    @Transactional(readOnly = true)
    public Page<AuditLogResponse> listAllDto(int page, int size) {
        Pageable p = PageRequest.of(Math.max(0, page), Math.min(Math.max(1, size), 100));
        return repo.findAllByOrderByCreatedAtDesc(p).map(this::toDto);
    }

    @Transactional(readOnly = true)
    public Page<AuditLogResponse> listByAdminDto(UUID adminId, int page, int size) {
        Pageable p = PageRequest.of(Math.max(0, page), Math.min(Math.max(1, size), 100));
        return repo.findByAdminIdOrderByCreatedAtDesc(adminId, p).map(this::toDto);
    }

    private AuditLogResponse toDto(AdminActionLog l) {
        return new AuditLogResponse(
                l.getId(),
                l.getAdmin().getId(),
                l.getAdmin().getDisplayName(),
                l.getAction(),
                l.getTargetType() != null ? l.getTargetType().name() : null,
                l.getTargetId(),
                l.getDetails(),
                l.getCreatedAt()
        );
    }
}