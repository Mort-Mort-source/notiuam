package mx.uam.notiuam.controller;

import mx.uam.notiuam.config.CurrentUser;
import mx.uam.notiuam.service.UnreadCounterService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/me")
public class MeController {

    private final CurrentUser currentUser;
    private final UnreadCounterService unreadCounters;

    public MeController(CurrentUser currentUser, UnreadCounterService unreadCounters) {
        this.currentUser = currentUser;
        this.unreadCounters = unreadCounters;
    }

    @GetMapping("/unread")
    public Map<String, Long> myUnread() {
        return unreadCounters.getAllCounts(currentUser.requireId());
    }

    @DeleteMapping("/unread/{channelId}")
    public ResponseEntity<Void> markRead(@PathVariable UUID channelId) {
        unreadCounters.reset(currentUser.requireId(), channelId);
        return ResponseEntity.noContent().build();
    }
}
