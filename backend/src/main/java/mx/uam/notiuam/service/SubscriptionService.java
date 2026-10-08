package mx.uam.notiuam.service;

import mx.uam.notiuam.config.CurrentUser;
import mx.uam.notiuam.domain.Channel;
import mx.uam.notiuam.domain.Subscription;
import mx.uam.notiuam.domain.User;
import mx.uam.notiuam.exception.NotFoundException;
import mx.uam.notiuam.repository.ChannelRepository;
import mx.uam.notiuam.repository.SubscriptionRepository;
import mx.uam.notiuam.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class SubscriptionService {

    private final SubscriptionRepository subscriptionRepository;
    private final ChannelRepository channelRepository;
    private final UserRepository userRepository;
    private final CurrentUser currentUser;

    public SubscriptionService(SubscriptionRepository subscriptionRepository,
                               ChannelRepository channelRepository,
                               UserRepository userRepository,
                               CurrentUser currentUser) {
        this.subscriptionRepository = subscriptionRepository;
        this.channelRepository = channelRepository;
        this.userRepository = userRepository;
        this.currentUser = currentUser;
    }

    @Transactional
    public void subscribe(UUID channelId) {
        UUID me = currentUser.requireId();
        Channel c = channelRepository.findById(channelId)
                .orElseThrow(() -> new NotFoundException("Canal no encontrado"));
        if (!c.isPublicChannel()) {
            throw new NotFoundException("El canal no existe o no es público");
        }
        if (subscriptionRepository.existsByUserIdAndChannelId(me, channelId)) {
            return; // idempotente
        }
        User user = userRepository.findById(me)
                .orElseThrow(() -> new NotFoundException("Usuario no encontrado"));

        Subscription s = Subscription.builder()
                .userId(me)
                .channelId(channelId)
                .user(user)
                .channel(c)
                .build();
        subscriptionRepository.save(s);
    }

    @Transactional
    public void unsubscribe(UUID channelId) {
        UUID me = currentUser.requireId();
        var id = new mx.uam.notiuam.domain.SubscriptionId(me, channelId);
        if (subscriptionRepository.existsById(id)) {
            subscriptionRepository.deleteById(id);
        }
    }

    @Transactional(readOnly = true)
    public long count(UUID channelId) {
        return subscriptionRepository.countByChannelId(channelId);
    }
}