package mx.uam.notiuam.repository;

import mx.uam.notiuam.domain.Report;
import mx.uam.notiuam.domain.ReportStatus;
import mx.uam.notiuam.domain.ReportTargetType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ReportRepository extends JpaRepository<Report, UUID> {
    Page<Report> findByStatusOrderByCreatedAtDesc(ReportStatus status, Pageable pageable);
    Page<Report> findAllByOrderByCreatedAtDesc(Pageable pageable);
    List<Report> findByTargetTypeAndTargetIdAndStatus(
            ReportTargetType type, UUID targetId, ReportStatus status);
    long countByStatus(ReportStatus status);
    boolean existsByTargetTypeAndTargetIdAndReporterId(
            ReportTargetType type, UUID targetId, UUID reporterId);
}