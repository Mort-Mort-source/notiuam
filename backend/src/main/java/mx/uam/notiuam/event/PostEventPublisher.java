package mx.uam.notiuam.event;

import mx.uam.notiuam.config.KafkaConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
public class PostEventPublisher {

    private static final Logger log = LoggerFactory.getLogger(PostEventPublisher.class);

    private final KafkaTemplate<String, Object> kafkaTemplate;

    public PostEventPublisher(KafkaTemplate<String, Object> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    public void publishPostCreated(PostCreatedEvent event) {
        kafkaTemplate.send(KafkaConfig.POSTS_TOPIC, event.channelId().toString(), event)
                .whenComplete((result, ex) -> {
                    if (ex != null) {
                        log.error("Error publicando evento de post {}: {}",
                                event.postId(), ex.getMessage());
                    } else {
                        log.info("Evento publicado: post={} canal={} partition={} offset={}",
                                event.postId(),
                                event.channelId(),
                                result.getRecordMetadata().partition(),
                                result.getRecordMetadata().offset());
                    }
                });
    }
}