package mx.uam.notiuam.event;

import java.time.Instant;
import java.util.UUID;

public record PostCreatedEvent(
        UUID postId,
        UUID channelId,
        String channelName,
        UUID authorId,
        String authorDisplayName,
        String content,
        Instant createdAt
) {}