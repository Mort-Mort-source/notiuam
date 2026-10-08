package mx.uam.notiuam.exception;

import java.time.Instant;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleIllegalArgument(IllegalArgumentException e) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                "timestamp", Instant.now().toString(),
                "status", 400,
                "error", "Bad Request",
                "message", e.getMessage()
        ));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException e) {
        String message = e.getBindingResult().getFieldErrors().stream()
                .map(err -> err.getField() + ": " + err.getDefaultMessage())
                .reduce((a, b) -> a + "; " + b)
                .orElse("Error de validación");
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                "timestamp", Instant.now().toString(),
                "status", 400,
                "error", "Validation Failed",
                "message", message
        ));
    }
    @ExceptionHandler(NotFoundException.class)
public ResponseEntity<Map<String, Object>> handleNotFound(NotFoundException e) {
    return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
            "timestamp", Instant.now().toString(),
            "status", 404,
            "error", "Not Found",
            "message", e.getMessage()
    ));
}

@ExceptionHandler(ForbiddenException.class)
public ResponseEntity<Map<String, Object>> handleForbidden(ForbiddenException e) {
    return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of(
            "timestamp", Instant.now().toString(),
            "status", 403,
            "error", "Forbidden",
            "message", e.getMessage()
    ));
}
}