package mx.uam.notiuam.dto.channel;

import java.time.Instant;
import java.util.UUID;

public record ChannelResponse(
        UUID id,
        String name,
        String description,
        String category,
        boolean publicChannel,
        UUID ownerId,
        String ownerDisplayName,
        String ownerRole,           // ← NUEVO
        long subscriberCount,
        boolean subscribedByMe,
        Instant createdAt
) {}