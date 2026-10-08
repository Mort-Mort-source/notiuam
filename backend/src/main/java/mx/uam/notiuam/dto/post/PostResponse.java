package mx.uam.notiuam.dto.post;

import java.time.Instant;
import java.util.UUID;

public record PostResponse(
        UUID id,
        UUID channelId,
        String channelName,
        UUID authorId,
        String authorDisplayName,
        String content,
        Instant createdAt
) {}