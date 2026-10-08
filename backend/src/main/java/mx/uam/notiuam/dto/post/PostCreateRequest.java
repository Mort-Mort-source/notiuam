package mx.uam.notiuam.dto.post;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record PostCreateRequest(
        @NotBlank @Size(max = 2000) String content
) {}