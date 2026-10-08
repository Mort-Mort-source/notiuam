package mx.uam.notiuam.repository;

import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import mx.uam.notiuam.domain.Post;

public interface PostRepository extends JpaRepository<Post, UUID> {
    Page<Post> findByChannelIdOrderByCreatedAtDesc(UUID channelId, Pageable pageable);
}