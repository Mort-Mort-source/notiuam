package mx.uam.notiuam.service;

import mx.uam.notiuam.config.CurrentUser;
import mx.uam.notiuam.domain.Role;
import mx.uam.notiuam.domain.User;
import mx.uam.notiuam.dto.admin.UserSummaryResponse;
import mx.uam.notiuam.exception.ForbiddenException;
import mx.uam.notiuam.exception.NotFoundException;
import mx.uam.notiuam.repository.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class AdminUserService {

    private final UserRepository userRepository;
    private final CurrentUser currentUser;
    private final AdminLogService adminLog;

    public AdminUserService(UserRepository userRepository,
                            CurrentUser currentUser,
                            AdminLogService adminLog) {
        this.userRepository = userRepository;
        this.currentUser = currentUser;
        this.adminLog = adminLog;
    }

    // ============================================================
    // Lectura (ADMIN y SUPERADMIN)
    // ============================================================

    @Transactional(readOnly = true)
    public Page<UserSummaryResponse> list(String query, int page, int size) {
        Pageable p = PageRequest.of(
                Math.max(0, page),
                Math.min(Math.max(1, size), 100),
                Sort.by(Sort.Direction.ASC, "email"));

        if (query != null && !query.isBlank()) {
            return userRepository.findByEmailContainingIgnoreCase(query, p)
                    .map(this::toResponse);
        }
        return userRepository.findAll(p).map(this::toResponse);
    }

    @Transactional(readOnly = true)
    public UserSummaryResponse getById(UUID id) {
        User u = userRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Usuario no encontrado"));
        return toResponse(u);
    }

    // ============================================================
    // Cambio de rol
    //
    // Reglas:
    // 1. Nadie puede cambiarse su propio rol.
    // 2. Nunca se puede quitar el rol SUPERADMIN.
    // 3. Solo SUPERADMIN puede nombrar a otro SUPERADMIN.
    // 4. ADMIN solo puede promover STUDENT → PROFESSOR | ADMIN.
    // 5. Solo SUPERADMIN puede degradar.
    // ============================================================

    @Transactional
    public UserSummaryResponse changeRole(UUID targetUserId, Role newRole) {
        var me = currentUser.require();
        UUID myId = me.id();
        Role myRole = Role.valueOf(me.role());

        // Regla 1
        if (myId.equals(targetUserId)) {
            throw new ForbiddenException("No puedes cambiar tu propio rol");
        }

        User target = userRepository.findById(targetUserId)
                .orElseThrow(() -> new NotFoundException("Usuario no encontrado"));

        Role currentRole = target.getRole();

        if (currentRole == newRole) {
            throw new IllegalArgumentException("El usuario ya tiene ese rol");
        }

        // Regla 2
        if (currentRole == Role.SUPERADMIN && newRole != Role.SUPERADMIN) {
            throw new ForbiddenException("No se puede degradar a un SUPERADMIN");
        }

        // Regla 3
        if (newRole == Role.SUPERADMIN && myRole != Role.SUPERADMIN) {
            throw new ForbiddenException("Solo un SUPERADMIN puede nombrar a otro SUPERADMIN");
        }

        // Regla 4
        if (myRole == Role.ADMIN) {
            if (currentRole != Role.STUDENT) {
                throw new ForbiddenException(
                        "Como ADMIN solo puedes promover estudiantes");
            }
            if (newRole != Role.PROFESSOR && newRole != Role.ADMIN) {
                throw new ForbiddenException(
                        "Como ADMIN solo puedes promover a PROFESSOR o ADMIN");
            }
        }

        // Regla 5
        if (myRole != Role.SUPERADMIN && level(newRole) < level(currentRole)) {
            throw new ForbiddenException("Solo un SUPERADMIN puede degradar usuarios");
        }

        target.setRole(newRole);
        userRepository.save(target);

        User admin = userRepository.findById(myId).orElseThrow();
        adminLog.log(
                admin,
                "CHANGE_ROLE",
                null,
                target.getId(),
                "De " + currentRole + " a " + newRole + " para " + target.getEmail()
        );

        return toResponse(target);
    }

    // ============================================================
    // Banear / desbanear (solo SUPERADMIN)
    //
    // Reglas:
    // 1. Solo SUPERADMIN.
    // 2. Nadie puede banearse a sí mismo.
    // 3. No se puede banear a un SUPERADMIN.
    // ============================================================

    @Transactional
    public UserSummaryResponse toggleStatus(UUID targetUserId, boolean enabled) {
        var me = currentUser.require();
        UUID myId = me.id();

        if (myId.equals(targetUserId)) {
            throw new ForbiddenException("No puedes cambiar tu propio estado");
        }

        User target = userRepository.findById(targetUserId)
                .orElseThrow(() -> new NotFoundException("Usuario no encontrado"));

        if (target.getRole() == Role.SUPERADMIN) {
            throw new ForbiddenException("No se puede banear a un SUPERADMIN");
        }

        if (target.isEnabled() == enabled) {
            throw new IllegalArgumentException(
                    "El usuario ya está " + (enabled ? "activo" : "baneado"));
        }

        target.setEnabled(enabled);
        userRepository.save(target);

        User admin = userRepository.findById(myId).orElseThrow();
        adminLog.log(
                admin,
                enabled ? "UNBAN_USER" : "BAN_USER",
                null,
                target.getId(),
                "Usuario " + target.getEmail() + (enabled ? " reactivado" : " baneado")
        );

        return toResponse(target);
    }

    // ============================================================
    // Helpers
    // ============================================================

    private int level(Role r) {
        return switch (r) {
            case STUDENT -> 0;
            case PROFESSOR -> 1;
            case ADMIN -> 2;
            case SUPERADMIN -> 3;
        };
    }

    private UserSummaryResponse toResponse(User u) {
        return new UserSummaryResponse(
                u.getId(),
                u.getEmail(),
                u.getDisplayName(),
                u.getRole().name(),
                u.isEnabled(),
                u.getCreatedAt()
        );
    }
}