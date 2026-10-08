package mx.uam.notiuam.event;

import mx.uam.notiuam.config.KafkaConfig;
import mx.uam.notiuam.domain.Subscription;
import mx.uam.notiuam.repository.SubscriptionRepository;
import mx.uam.notiuam.service.UnreadCounterService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PostNotificationConsumer {

    private static final Logger log = LoggerFactory.getLogger(PostNotificationConsumer.class);

    private final SubscriptionRepository subscriptionRepository;
    private final UnreadCounterService unreadCounters;

    public PostNotificationConsumer(SubscriptionRepository subscriptionRepository,
                                    UnreadCounterService unreadCounters) {
        this.subscriptionRepository = subscriptionRepository;
        this.unreadCounters = unreadCounters;
    }

    @KafkaListener(
            topics = KafkaConfig.POSTS_TOPIC,
            groupId = "notiuam-notifications",
            containerFactory = "kafkaListenerContainerFactory"
    )
    public void onPostCreated(PostCreatedEvent event) {
        log.info("Kafka event recibido: post={} canal={}",
                event.postId(), event.channelName());

        List<Subscription> subscribers = subscriptionRepository.findByChannelId(event.channelId());

        int notified = 0;
        for (Subscription sub : subscribers) {
            if (sub.getUserId().equals(event.authorId())) {
                continue; // no notificar al propio autor
            }

            unreadCounters.increment(sub.getUserId(), event.channelId());
            notified++;

            // Simulación de push (FCM real en Sesión 7)
            log.info("[PUSH-SIMULADO] -> user={} | {} | \"{}\"",
                    sub.getUserId(),
                    event.channelName(),
                    truncate(event.content()));
        }

        log.info("Notificaciones procesadas: {} de {} suscriptores", notified, subscribers.size());
    }

    private String truncate(String s) {
        if (s == null) return "";
        return s.length() <= 80 ? s : s.substring(0, 77) + "...";
    }
}