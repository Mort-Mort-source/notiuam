package mx.uam.notiuam.controller;

import mx.uam.notiuam.config.CurrentUser;
import mx.uam.notiuam.dto.admin.AuditLogResponse;
import mx.uam.notiuam.service.AdminLogService;
import org.springframework.data.domain.Page;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/audit")
@PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
public class AdminAuditController {

    private final AdminLogService adminLogService;
    private final CurrentUser currentUser;

    public AdminAuditController(AdminLogService adminLogService, CurrentUser currentUser) {
        this.adminLogService = adminLogService;
        this.currentUser = currentUser;
    }

    @GetMapping
    public Page<AuditLogResponse> list(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {

        var me = currentUser.require();
        boolean isSuper = "SUPERADMIN".equals(me.role());

        return isSuper
                ? adminLogService.listAllDto(page, size)
                : adminLogService.listByAdminDto(me.id(), page, size);
    }
}