package mx.uam.notiuam.controller;

import jakarta.validation.Valid;
import mx.uam.notiuam.domain.ChannelCategory;
import mx.uam.notiuam.dto.channel.ChannelCreateRequest;
import mx.uam.notiuam.dto.channel.ChannelResponse;
import mx.uam.notiuam.dto.channel.ChannelSummaryResponse;
import mx.uam.notiuam.dto.channel.ChannelUpdateRequest;
import mx.uam.notiuam.dto.post.PostCreateRequest;
import mx.uam.notiuam.dto.post.PostResponse;
import mx.uam.notiuam.service.ChannelService;
import mx.uam.notiuam.service.PostService;
import mx.uam.notiuam.service.SubscriptionService;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/channels")
public class ChannelController {

    private final ChannelService channelService;
    private final SubscriptionService subscriptionService;
    private final PostService postService;

    public ChannelController(ChannelService channelService,
                             SubscriptionService subscriptionService,
                             PostService postService) {
        this.channelService = channelService;
        this.subscriptionService = subscriptionService;
        this.postService = postService;
    }

    // -------- Canales --------

    @GetMapping
    public List<ChannelSummaryResponse> list(
            @RequestParam(required = false) ChannelCategory category,
            @RequestParam(required = false, name = "q") String query) {
        return channelService.listPublic(category, query);
    }

    @GetMapping("/mine")
    public List<ChannelSummaryResponse> mine() {
        return channelService.listMine();
    }

    @GetMapping("/subscribed")
    public List<ChannelSummaryResponse> subscribed() {
        return channelService.listSubscribed();
    }

    @GetMapping("/{id}")
    public ChannelResponse get(@PathVariable UUID id) {
        return channelService.get(id);
    }

    @PostMapping
    public ResponseEntity<ChannelResponse> create(@Valid @RequestBody ChannelCreateRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED).body(channelService.create(req));
    }

    @PatchMapping("/{id}")
    public ChannelResponse update(@PathVariable UUID id,
                                  @Valid @RequestBody ChannelUpdateRequest req) {
        return channelService.update(id, req);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        channelService.delete(id);
        return ResponseEntity.noContent().build();
    }

    // -------- Suscripciones --------

    @PostMapping("/{id}/subscribe")
    public ResponseEntity<Map<String, Object>> subscribe(@PathVariable UUID id) {
        subscriptionService.subscribe(id);
        return ResponseEntity.ok(Map.of(
                "channelId", id,
                "subscribed", true,
                "subscriberCount", subscriptionService.count(id)
        ));
    }

    @DeleteMapping("/{id}/subscribe")
    public ResponseEntity<Map<String, Object>> unsubscribe(@PathVariable UUID id) {
        subscriptionService.unsubscribe(id);
        return ResponseEntity.ok(Map.of(
                "channelId", id,
                "subscribed", false,
                "subscriberCount", subscriptionService.count(id)
        ));
    }

    // -------- Publicaciones --------

    @GetMapping("/{id}/posts")
    public Page<PostResponse> listPosts(
            @PathVariable UUID id,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return postService.listByChannel(id, page, size);
    }

    @PostMapping("/{id}/posts")
    public ResponseEntity<PostResponse> createPost(@PathVariable UUID id,
                                                   @Valid @RequestBody PostCreateRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED).body(postService.create(id, req));
    }
}