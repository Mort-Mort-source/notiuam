package mx.uam.notiuam.repository;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import mx.uam.notiuam.domain.Subscription;
import mx.uam.notiuam.domain.SubscriptionId;

public interface SubscriptionRepository extends JpaRepository<Subscription, SubscriptionId> {
    List<Subscription> findByUserId(UUID userId);
    List<Subscription> findByChannelId(UUID channelId);
    boolean existsByUserIdAndChannelId(UUID userId, UUID channelId);
    long countByChannelId(UUID channelId);
}