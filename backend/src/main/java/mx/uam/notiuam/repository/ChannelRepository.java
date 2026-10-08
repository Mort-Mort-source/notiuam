package mx.uam.notiuam.repository;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import mx.uam.notiuam.domain.Channel;
import mx.uam.notiuam.domain.ChannelCategory;

public interface ChannelRepository extends JpaRepository<Channel, UUID> {
    List<Channel> findByPublicChannelTrueOrderByCreatedAtDesc();
    List<Channel> findByCategoryAndPublicChannelTrue(ChannelCategory category);
    List<Channel> findByNameContainingIgnoreCaseAndPublicChannelTrue(String q);
    List<Channel> findByOwnerId(UUID ownerId);
}