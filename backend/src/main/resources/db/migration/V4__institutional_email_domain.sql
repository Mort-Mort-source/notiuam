-- Migra usuarios de prueba al dominio institucional correcto.
-- Solo aplica si existen; en una BD nueva no hace nada.
UPDATE users
SET email = REPLACE(email, '@uam.mx', '@cua.uam.mx')
WHERE email LIKE '%@uam.mx';