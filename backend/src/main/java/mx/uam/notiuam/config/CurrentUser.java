package mx.uam.notiuam.config;

import mx.uam.notiuam.security.JwtAuthenticationFilter.AuthenticatedUser;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
public class CurrentUser {

    public AuthenticatedUser require() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof AuthenticatedUser u)) {
            throw new AccessDeniedException("No hay usuario autenticado");
        }
        return u;
    }

    public UUID requireId() {
        return require().id();
    }

    public boolean isAdmin() {
        try {
            return "ADMIN".equals(require().role());
        } catch (Exception e) {
            return false;
        }
    }
}