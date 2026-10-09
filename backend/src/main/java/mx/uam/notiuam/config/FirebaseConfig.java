package mx.uam.notiuam.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import java.io.IOException;
import java.io.InputStream;

@Configuration
public class FirebaseConfig {

    private static final Logger log = LoggerFactory.getLogger(FirebaseConfig.class);

    @PostConstruct
    public void initialize() {
        try {
            if (!FirebaseApp.getApps().isEmpty()) {
                log.info("Firebase ya estaba inicializado");
                return;
            }

            ClassPathResource resource = new ClassPathResource("firebase/service-account.json");
            if (!resource.exists()) {
                log.warn("No se encontro firebase/service-account.json. " +
                        "Las notificaciones push quedaran deshabilitadas.");
                return;
            }

            try (InputStream serviceAccount = resource.getInputStream()) {
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .build();

                FirebaseApp.initializeApp(options);
                log.info("Firebase Admin SDK inicializado correctamente");
            }
        } catch (IOException e) {
            log.error("Error inicializando Firebase: {}", e.getMessage());
        }
    }
}