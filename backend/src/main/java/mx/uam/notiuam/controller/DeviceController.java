package mx.uam.notiuam.controller;

import jakarta.validation.Valid;
import mx.uam.notiuam.dto.device.RegisterDeviceRequest;
import mx.uam.notiuam.service.DeviceTokenService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/me/device")
public class DeviceController {

    private final DeviceTokenService deviceTokenService;

    public DeviceController(DeviceTokenService deviceTokenService) {
        this.deviceTokenService = deviceTokenService;
    }

    @PostMapping
    public ResponseEntity<Map<String, String>> register(
            @Valid @RequestBody RegisterDeviceRequest req) {
        deviceTokenService.register(req.token(), req.platform());
        return ResponseEntity.ok(Map.of("status", "registered"));
    }

    @DeleteMapping
    public ResponseEntity<Void> unregister(@RequestParam String token) {
        deviceTokenService.unregister(token);
        return ResponseEntity.noContent().build();
    }
}