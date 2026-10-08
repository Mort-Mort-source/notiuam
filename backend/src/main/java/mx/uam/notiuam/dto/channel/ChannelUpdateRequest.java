package mx.uam.notiuam.dto.channel;

import jakarta.validation.constraints.Size;
import mx.uam.notiuam.domain.ChannelCategory;

public record ChannelUpdateRequest(
        @Size(max = 120) String name,
        @Size(max = 500) String description,
        ChannelCategory category,
        Boolean publicChannel
) {}