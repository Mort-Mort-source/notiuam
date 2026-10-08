package mx.uam.notiuam.repository;

import mx.uam.notiuam.domain.ReportVote;
import mx.uam.notiuam.domain.VoteDecision;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ReportVoteRepository extends JpaRepository<ReportVote, UUID> {
    List<ReportVote> findByReportId(UUID reportId);
    Optional<ReportVote> findByReportIdAndAdminId(UUID reportId, UUID adminId);
    long countByReportIdAndDecision(UUID reportId, VoteDecision decision);
    long countByReportId(UUID reportId);
}