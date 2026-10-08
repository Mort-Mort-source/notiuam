package mx.uam.notiuam.service;

import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import mx.uam.notiuam.config.CurrentUser;
import mx.uam.notiuam.domain.Channel;
import mx.uam.notiuam.domain.Post;
import mx.uam.notiuam.domain.ReportTargetType;
import mx.uam.notiuam.domain.User;
import mx.uam.notiuam.dto.post.PostCreateRequest;
import mx.uam.notiuam.dto.post.PostResponse;
import mx.uam.notiuam.event.PostCreatedEvent;
import mx.uam.notiuam.exception.ForbiddenException;
import mx.uam.notiuam.exception.NotFoundException;
import mx.uam.notiuam.repository.ChannelRepository;
import mx.uam.notiuam.repository.PostRepository;
import mx.uam.notiuam.repository.SubscriptionRepository;
import mx.uam.notiuam.repository.UserRepository;
import mx.uam.notiuam.event.PostCreatedEvent;
import mx.uam.notiuam.event.PostEventPublisher;
import mx.uam.notiuam.domain.Role;
import mx.uam.notiuam.domain.ReportTargetType;

@Service
public class PostService {

       private final PostRepository postRepository;
    private final ChannelRepository channelRepository;
    private final UserRepository userRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final CurrentUser currentUser;
    private final PostEventPublisher postEventPublisher;   // <-- NUEVO campo

    private final AdminLogService adminLog;

public PostService(PostRepository postRepository,
                   ChannelRepository channelRepository,
                   UserRepository userRepository,
                   SubscriptionRepository subscriptionRepository,
                   CurrentUser currentUser,
                   PostEventPublisher postEventPublisher,
                   AdminLogService adminLog) {
    this.postRepository = postRepository;
    this.channelRepository = channelRepository;
    this.userRepository = userRepository;
    this.subscriptionRepository = subscriptionRepository;
    this.currentUser = currentUser;
    this.postEventPublisher = postEventPublisher;
    this.adminLog = adminLog;
}

    @Transactional(readOnly = true)
    public Page<PostResponse> listByChannel(UUID channelId, int page, int size) {
        Channel c = channelRepository.findById(channelId)
                .orElseThrow(() -> new NotFoundException("Canal no encontrado"));

        if (!c.isPublicChannel()) {
            // En canales privados solo el owner o un suscriptor puede ver publicaciones
            UUID me = currentUser.requireId();
            boolean isOwner = c.getOwner().getId().equals(me);
            boolean isSubscribed = subscriptionRepository.existsByUserIdAndChannelId(me, channelId);
            if (!isOwner && !isSubscribed) {
                throw new ForbiddenException("No tienes acceso a este canal");
            }
        }

        Pageable pageable = PageRequest.of(Math.max(0, page), Math.min(Math.max(1, size), 50));
        return postRepository.findByChannelIdOrderByCreatedAtDesc(channelId, pageable)
                .map(this::toResponse);
    }

  @Transactional
public PostResponse create(UUID channelId, PostCreateRequest req) {
    UUID me = currentUser.requireId();
    Channel c = channelRepository.findById(channelId)
            .orElseThrow(() -> new NotFoundException("Canal no encontrado"));

    User author = userRepository.findById(me)
            .orElseThrow(() -> new NotFoundException("Usuario no encontrado"));

    Post p = Post.builder()
            .channel(c)
            .author(author)
            .content(req.content().trim())
            .build();

    p = postRepository.save(p);

    // Publicar evento a Kafka
    postEventPublisher.publishPostCreated(new PostCreatedEvent(
            p.getId(),
            c.getId(),
            c.getName(),
            author.getId(),
            author.getDisplayName(),
            p.getContent(),
            p.getCreatedAt()
    ));

    return toResponse(p);
}

@Transactional
public void delete(UUID postId) {
    Post p = postRepository.findById(postId)
            .orElseThrow(() -> new NotFoundException("Publicación no encontrada"));

    var me = currentUser.require();
    UUID myId = me.id();
    Role myRole = Role.valueOf(me.role());

    UUID authorId = p.getAuthor().getId();
    UUID channelOwnerId = p.getChannel().getOwner().getId();

    boolean isAuthor = authorId.equals(myId);
    boolean isChannelOwner = channelOwnerId.equals(myId);
    boolean isAdmin = myRole == Role.ADMIN || myRole == Role.SUPERADMIN;

    // El dueño del canal (aunque sea PROFESSOR) puede moderar sin votación
    if (!isAuthor && !isChannelOwner && !isAdmin) {
        throw new ForbiddenException(
                "Solo el autor, el dueño del canal o un moderador pueden eliminar esta publicación");
    }

    // Auditoría: registrar cuando no lo borra el propio autor
    if (!isAuthor) {
        User admin = userRepository.findById(myId).orElseThrow();
        String reason;
        if (isChannelOwner) {
            reason = "Moderación del dueño del canal";
        } else {
            reason = "Moderación administrativa";
        }
        adminLog.log(
                admin,
                "DELETE_POST",
                ReportTargetType.POST,
                postId,
                reason + ": " + p.getChannel().getName()
        );
    }

    postRepository.delete(p);
}

    private PostResponse toResponse(Post p) {
        return new PostResponse(
                p.getId(),
                p.getChannel().getId(),
                p.getChannel().getName(),
                p.getAuthor().getId(),
                p.getAuthor().getDisplayName(),
                p.getContent(),
                p.getCreatedAt()
        );
    }
 

}