package mx.uam.notiuam.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Duration;

@Service
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);

    private static final String CODE_PREFIX = "notiuam:email-code:";
    private static final String VERIFIED_PREFIX = "notiuam:email-verified:";

    private final StringRedisTemplate redis;
    private final JavaMailSender mailSender;
    private final SecureRandom random = new SecureRandom();

    @Value("${notiuam.email.enabled:false}")
    private boolean emailEnabled;

    @Value("${notiuam.email.from:no-reply@cua.uam.mx}")
    private String fromAddress;

    @Value("${notiuam.email.code-ttl-minutes:10}")
    private int codeTtlMinutes;

    @Value("${notiuam.email.verified-ttl-minutes:15}")
    private int verifiedTtlMinutes;

    public EmailService(StringRedisTemplate redis, JavaMailSender mailSender) {
        this.redis = redis;
        this.mailSender = mailSender;
    }

    public void sendVerificationCode(String email) {
        String code = String.format("%06d", random.nextInt(1_000_000));
        redis.opsForValue().set(
                CODE_PREFIX + email,
                code,
                Duration.ofMinutes(codeTtlMinutes));

        if (!emailEnabled) {
            log.warn("=== [DEV] Codigo de verificacion para {}: {} ===", email, code);
            return;
        }

        try {
            SimpleMailMessage msg = new SimpleMailMessage();
            msg.setFrom(fromAddress);
            msg.setTo(email);
            msg.setSubject("NotiUAM - Codigo de verificacion");
            msg.setText("Hola,\n\nTu codigo de verificacion para NotiUAM es:\n\n    " + code + "\n\nEste codigo expira en " + codeTtlMinutes + " minutos.\n\n- Equipo NotiUAM");
            mailSender.send(msg);
            log.info("Correo de verificacion enviado a {}", email);
        } catch (Exception e) {
            log.error("Error enviando correo a {}: {}", email, e.getMessage());
            throw new RuntimeException("No se pudo enviar el correo de verificacion");
        }
    }

    public boolean verifyCode(String email, String code) {
        String stored = redis.opsForValue().get(CODE_PREFIX + email);
        if (stored == null || !stored.equals(code)) {
            return false;
        }

        redis.delete(CODE_PREFIX + email);
        redis.opsForValue().set(
                VERIFIED_PREFIX + email,
                "true",
                Duration.ofMinutes(verifiedTtlMinutes));
        return true;
    }

    public boolean isVerified(String email) {
        return Boolean.TRUE.equals(redis.hasKey(VERIFIED_PREFIX + email));
    }

    public void consumeVerification(String email) {
        redis.delete(VERIFIED_PREFIX + email);
    }
}
