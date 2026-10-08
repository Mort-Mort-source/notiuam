package mx.uam.notiuam;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication
@EnableJpaAuditing
public class NotiuamApplication {
    public static void main(String[] args) {
        SpringApplication.run(NotiuamApplication.class, args);
    }
}