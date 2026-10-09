package mx.uam.notiuam.service;

import mx.uam.notiuam.config.CurrentUser;
import mx.uam.notiuam.domain.DeviceToken;
import mx.uam.notiuam.domain.User;
import mx.uam.notiuam.exception.NotFoundException;
import mx.uam.notiuam.repository.DeviceTokenRepository;
import mx.uam.notiuam.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class DeviceTokenService {

    private final DeviceTokenRepository repo;
    private final UserRepository userRepository;
    private final CurrentUser currentUser;

    public DeviceTokenService(DeviceTokenRepository repo,
                              UserRepository userRepository,
                              CurrentUser currentUser) {
        this.repo = repo;
        this.userRepository = userRepository;
        this.currentUser = currentUser;
    }

    @Transactional
    public void register(String token, String platform) {
        UUID userId = currentUser.requireId();

        // Si el token ya existia, actualiza el dueno (puede cambiar de usuario)
        var existing = repo.findByToken(token);
        if (existing.isPresent()) {
            DeviceToken dt = existing.get();
            dt.setUser(userRepository.getReferenceById(userId));
            dt.setPlatform(platform);
            repo.save(dt);
            return;
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Usuario no encontrado"));

        repo.save(DeviceToken.builder()
                .user(user)
                .token(token)
                .platform(platform)
                .build());
    }

    @Transactional
    public void unregister(String token) {
        repo.findByToken(token).ifPresent(dt -> {
            if (dt.getUser().getId().equals(currentUser.requireId())) {
                repo.delete(dt);
            }
        });
    }

    @Transactional(readOnly = true)
    public List<String> tokensOf(UUID userId) {
        return repo.findByUserId(userId).stream()
                .map(DeviceToken::getToken)
                .toList();
    }
}