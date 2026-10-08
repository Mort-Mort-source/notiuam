package mx.uam.notiuam.service;

import mx.uam.notiuam.config.CurrentUser;
import mx.uam.notiuam.domain.Channel;
import mx.uam.notiuam.domain.ChannelCategory;
import mx.uam.notiuam.domain.User;
import mx.uam.notiuam.dto.channel.ChannelCreateRequest;
import mx.uam.notiuam.dto.channel.ChannelResponse;
import mx.uam.notiuam.dto.channel.ChannelSummaryResponse;
import mx.uam.notiuam.dto.channel.ChannelUpdateRequest;
import mx.uam.notiuam.exception.ForbiddenException;
import mx.uam.notiuam.exception.NotFoundException;
import mx.uam.notiuam.repository.ChannelRepository;
import mx.uam.notiuam.repository.SubscriptionRepository;
import mx.uam.notiuam.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class ChannelService {

    private final ChannelRepository channelRepository;
    private final UserRepository userRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final CurrentUser currentUser;

    public ChannelService(ChannelRepository channelRepository,
                          UserRepository userRepository,
                          SubscriptionRepository subscriptionRepository,
                          CurrentUser currentUser) {
        this.channelRepository = channelRepository;
        this.userRepository = userRepository;
        this.subscriptionRepository = subscriptionRepository;
        this.currentUser = currentUser;
    }

    @Transactional(readOnly = true)
    public List<ChannelSummaryResponse> listPublic(ChannelCategory category, String q) {
        List<Channel> channels;
        if (category != null) {
            channels = channelRepository.findByCategoryAndPublicChannelTrue(category);
        } else if (q != null && !q.isBlank()) {
            channels = channelRepository.findByNameContainingIgnoreCaseAndPublicChannelTrue(q);
        } else {
            channels = channelRepository.findByPublicChannelTrueOrderByCreatedAtDesc();
        }
        return channels.stream().map(this::toSummary).toList();
    }

    @Transactional(readOnly = true)
    public ChannelResponse get(UUID id) {
        Channel c = channelRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Canal no encontrado"));
        return toResponse(c, currentUser.requireId());
    }

    @Transactional
    public ChannelResponse create(ChannelCreateRequest req) {
        UUID ownerId = currentUser.requireId();
        User owner = userRepository.findById(ownerId)
                .orElseThrow(() -> new NotFoundException("Usuario no encontrado"));

        Channel c = Channel.builder()
                .name(req.name().trim())
                .description(req.description() == null ? null : req.description().trim())
                .category(req.category())
                .owner(owner)
                .publicChannel(req.publicChannel() == null || req.publicChannel())
                .build();

        c = channelRepository.save(c);
        return toResponse(c, ownerId);
    }

    @Transactional
    public ChannelResponse update(UUID id, ChannelUpdateRequest req) {
        Channel c = channelRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Canal no encontrado"));
        assertOwnerOrAdmin(c);
        if (req.name() != null)         c.setName(req.name().trim());
        if (req.description() != null)  c.setDescription(req.description().trim());
        if (req.category() != null)     c.setCategory(req.category());
        if (req.publicChannel() != null) c.setPublicChannel(req.publicChannel());
        return toResponse(c, currentUser.requireId());
    }

    @Transactional
    public void delete(UUID id) {
        Channel c = channelRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Canal no encontrado"));
        assertOwnerOrAdmin(c);
        channelRepository.delete(c);
    }

    @Transactional(readOnly = true)
    public List<ChannelSummaryResponse> listMine() {
        return channelRepository.findByOwnerId(currentUser.requireId())
                .stream().map(this::toSummary).toList();
    }

    @Transactional(readOnly = true)
    public List<ChannelSummaryResponse> listSubscribed() {
        UUID me = currentUser.requireId();
        return subscriptionRepository.findByUserId(me).stream()
                .map(s -> toSummary(s.getChannel()))
                .toList();
    }

    private void assertOwnerOrAdmin(Channel c) {
        var me = currentUser.require();
        boolean isOwner = c.getOwner().getId().equals(me.id());
        if (!isOwner && !"ADMIN".equals(me.role())) {
            throw new ForbiddenException("Solo el propietario o un administrador puede realizar esta acción");
        }
    }

    private ChannelSummaryResponse toSummary(Channel c) {
    return new ChannelSummaryResponse(
            c.getId(),
            c.getName(),
            c.getCategory().name(),
            c.isPublicChannel(),
            c.getOwner().getDisplayName(),
            c.getOwner().getRole().name(),     // ← NUEVO
            subscriptionRepository.countByChannelId(c.getId()),
            c.getCreatedAt()
    );
}

private ChannelResponse toResponse(Channel c, UUID me) {
    boolean subscribed = subscriptionRepository.existsByUserIdAndChannelId(me, c.getId());
    return new ChannelResponse(
            c.getId(),
            c.getName(),
            c.getDescription(),
            c.getCategory().name(),
            c.isPublicChannel(),
            c.getOwner().getId(),
            c.getOwner().getDisplayName(),
            c.getOwner().getRole().name(),     // ← NUEVO
            subscriptionRepository.countByChannelId(c.getId()),
            subscribed,
            c.getCreatedAt()
    );
}
}