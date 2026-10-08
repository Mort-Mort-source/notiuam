package mx.uam.notiuam.service;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class UnreadCounterService {

    private static final String KEY_PREFIX = "notiuam:unread:";

    private final StringRedisTemplate redis;

    public UnreadCounterService(StringRedisTemplate redis) {
        this.redis = redis;
    }

    public void increment(UUID userId, UUID channelId) {
        redis.opsForHash().increment(KEY_PREFIX + userId, channelId.toString(), 1);
    }

    public long getCount(UUID userId, UUID channelId) {
        Object v = redis.opsForHash().get(KEY_PREFIX + userId, channelId.toString());
        return v == null ? 0L : Long.parseLong(v.toString());
    }

    public Map<String, Long> getAllCounts(UUID userId) {
        Map<Object, Object> raw = redis.opsForHash().entries(KEY_PREFIX + userId);
        return raw.entrySet().stream().collect(Collectors.toMap(
                e -> e.getKey().toString(),
                e -> Long.parseLong(e.getValue().toString())
        ));
    }

    public void reset(UUID userId, UUID channelId) {
        redis.opsForHash().delete(KEY_PREFIX + userId, channelId.toString());
    }
}