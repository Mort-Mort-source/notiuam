package mx.uam.notiuam.controller;

import jakarta.validation.Valid;
import mx.uam.notiuam.dto.admin.ChangeRoleRequest;
import mx.uam.notiuam.dto.admin.ToggleUserStatusRequest;
import mx.uam.notiuam.dto.admin.UserSummaryResponse;
import mx.uam.notiuam.service.AdminUserService;
import org.springframework.data.domain.Page;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/admin/users")
@PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")  // lectura + cambio de rol
public class AdminUserController {

    private final AdminUserService adminUserService;

    public AdminUserController(AdminUserService adminUserService) {
        this.adminUserService = adminUserService;
    }

    // -------- Lectura (ADMIN y SUPERADMIN) --------

    @GetMapping
    public Page<UserSummaryResponse> list(
            @RequestParam(required = false) String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return adminUserService.list(q, page, size);
    }

    @GetMapping("/{id}")
    public UserSummaryResponse get(@PathVariable UUID id) {
        return adminUserService.getById(id);
    }

    // -------- Cambio de rol (ADMIN y SUPERADMIN, reglas en service) --------

    @PatchMapping("/{id}/role")
    public UserSummaryResponse changeRole(@PathVariable UUID id,
                                          @Valid @RequestBody ChangeRoleRequest req) {
        return adminUserService.changeRole(id, req.role());
    }

    // -------- Banear (solo SUPERADMIN) --------

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasRole('SUPERADMIN')")
    public UserSummaryResponse toggleStatus(@PathVariable UUID id,
                                            @Valid @RequestBody ToggleUserStatusRequest req) {
        return adminUserService.toggleStatus(id, req.enabled());
    }
}