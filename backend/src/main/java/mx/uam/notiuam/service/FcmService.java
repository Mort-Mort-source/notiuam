package mx.uam.notiuam.service;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class FcmService {

    private static final Logger log = LoggerFactory.getLogger(FcmService.class);

    public boolean isEnabled() {
        return !FirebaseApp.getApps().isEmpty();
    }

    /**
     * Envia una notificacion push a un token especifico.
     * @return true si el envio fue exitoso, false en caso contrario.
     */
    public boolean sendToToken(String deviceToken,
                               String title,
                               String body,
                               Map<String, String> data) {
        if (!isEnabled()) {
            log.debug("FCM deshabilitado, simulando envio a {}", deviceToken);
            return false;
        }

        try {
            Message message = Message.builder()
                    .setToken(deviceToken)
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build())
                    .putAllData(data != null ? data : Map.of())
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            log.info("Push enviado a {}: {}", deviceToken, response);
            return true;
        } catch (FirebaseMessagingException e) {
            log.warn("Error enviando push a {}: {} ({})",
                    deviceToken, e.getMessage(), e.getMessagingErrorCode());
            return false;
        }
    }
}