package mx.uam.notiuam.event;

import mx.uam.notiuam.config.KafkaConfig;
import mx.uam.notiuam.domain.Subscription;
import mx.uam.notiuam.repository.SubscriptionRepository;
import mx.uam.notiuam.service.DeviceTokenService;
import mx.uam.notiuam.service.FcmService;
import mx.uam.notiuam.service.UnreadCounterService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class PostNotificationConsumer {

    private static final Logger log = LoggerFactory.getLogger(PostNotificationConsumer.class);

    private final SubscriptionRepository subscriptionRepository;
    private final UnreadCounterService unreadCounters;
    private final DeviceTokenService deviceTokens;
    private final FcmService fcm;

    public PostNotificationConsumer(SubscriptionRepository subscriptionRepository,
                                    UnreadCounterService unreadCounters,
                                    DeviceTokenService deviceTokens,
                                    FcmService fcm) {
        this.subscriptionRepository = subscriptionRepository;
        this.unreadCounters = unreadCounters;
        this.deviceTokens = deviceTokens;
        this.fcm = fcm;
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
                continue;
            }

            unreadCounters.increment(sub.getUserId(), event.channelId());
            notified++;

            // Enviar push a todos los dispositivos del suscriptor
            List<String> tokens = deviceTokens.tokensOf(sub.getUserId());
            for (String token : tokens) {
                boolean ok = fcm.sendToToken(
                        token,
                        event.channelName(),
                        truncate(event.content()),
                        Map.of(
                                "channelId", event.channelId().toString(),
                                "postId", event.postId().toString()
                        )
                );
                if (ok) {
                    log.info("[PUSH-FCM] -> token={} user={}",
                            token.substring(0, Math.min(12, token.length())),
                            sub.getUserId());
                }
            }

            if (tokens.isEmpty()) {
                log.info("[PUSH-NO-TOKEN] user={} sin dispositivos registrados",
                        sub.getUserId());
            }
        }

        log.info("Notificaciones procesadas: {} de {} suscriptores",
                notified, subscribers.size());
    }

    private String truncate(String s) {
        if (s == null) return "";
        return s.length() <= 80 ? s : s.substring(0, 77) + "...";
    }
}