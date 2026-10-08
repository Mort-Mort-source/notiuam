# NotiUAM

Plataforma distribuida de comunicación y alertas comunitarias para entornos universitarios.

## Stack
- Backend: Spring Boot 3 + Java 17
- Mensajería: Apache Kafka (KRaft)
- Persistencia: PostgreSQL 16 + Redis 7
- Móvil: Flutter
- Contenedores: Docker + Docker Compose

## Requisitos
- Docker Desktop 4.x
- Docker Compose v2
- Java 17 (para el backend)
- Flutter 3.x (para la app móvil)

## Levantar la infraestructura

```bash
cp .env.example .env
docker compose up -d