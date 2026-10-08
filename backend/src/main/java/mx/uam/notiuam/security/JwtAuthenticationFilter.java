package mx.uam.notiuam.security;

import java.io.IOException;
import java.util.List;
import java.util.UUID;

import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;

    public JwtAuthenticationFilter(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request,
                                    @NonNull HttpServletResponse response,
                                    @NonNull FilterChain filterChain)
            throws ServletException, IOException {

        String header = request.getHeader("Authorization");
        if (header == null || !header.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = header.substring(7);
        if (!jwtService.isValid(token)) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            Claims claims = jwtService.parse(token);
            if (!"access".equals(claims.get("type", String.class))) {
                filterChain.doFilter(request, response);
                return;
            }

            String userId = claims.getSubject();
            String email = claims.get("email", String.class);
            String role = claims.get("role", String.class);

            var authentication = new UsernamePasswordAuthenticationToken(
                    new AuthenticatedUser(UUID.fromString(userId), email, role),
                    null,
                    List.of(new SimpleGrantedAuthority("ROLE_" + role))
            );
            authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
            SecurityContextHolder.getContext().setAuthentication(authentication);
        } catch (Exception ignored) {
            // Si el token es inválido, dejamos la petición sin autenticación.
        }

        filterChain.doFilter(request, response);
    }

    /** Principal ligero con lo mínimo que necesitamos en los controllers. */
    public record AuthenticatedUser(UUID id, String email, String role) {}
}