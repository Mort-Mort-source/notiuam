package mx.uam.notiuam.dto.channel;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import mx.uam.notiuam.domain.ChannelCategory;

public record ChannelCreateRequest(
        @NotBlank @Size(max = 120) String name,
        @Size(max = 500) String description,
        @NotNull ChannelCategory category,
        Boolean publicChannel   // null => true
) {}