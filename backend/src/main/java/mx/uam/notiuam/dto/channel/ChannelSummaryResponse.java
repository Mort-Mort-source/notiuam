package mx.uam.notiuam.dto.channel;

import java.time.Instant;
import java.util.UUID;

public record ChannelSummaryResponse(
        UUID id,
        String name,
        String category,
        boolean publicChannel,
        String ownerDisplayName,
        String ownerRole,           // ← NUEVO
        long subscriberCount,
        Instant createdAt
) {}