# Integración de Hotel Manager con la API

Este documento registra el estado de la integración móvil. Se contrastaron las
rutas con el texto de `routes/api.php` compartido por el usuario. No se recibió
el código de los controladores ni ejemplos autenticados de respuesta para
habitaciones, así que los nombres de campos interiores aún requieren validación
con una cuenta de la app.

## Base y autenticación

- Base por defecto: `https://hotel-manager-api-ttg7.onrender.com/api`.
- `API_BASE_URL` permite cambiar la base al compilar con `--dart-define`.
- `ApiClient` envía `Accept: application/json`, JSON en el cuerpo cuando
  corresponde y `Authorization: Bearer <token>` si hay token guardado.
- Login (`POST /login`) envía `device_name: flutter`, guarda el token en
  `flutter_secure_storage` y consulta `GET /me` para establecer el usuario y rol.
- Después del login se consultan habitaciones y huéspedes. Los errores quedan
  en el estado de cada servicio para permitir reintentar desde la pantalla.
- El cliente tiene timeout de 90 segundos para permitir el arranque en frío de
  Render.
- No se verificaron aún `GET /me`, cierre de sesión, expiración del token ni
  permisos por rol mediante cuentas reales.

## Matriz por módulo

| Módulo / pantalla | Origen actual | Endpoint según contrato proporcionado | Rol indicado | Estado y cambios pendientes |
|---|---|---|---|---|
| Sesión y perfil / `pantalla_login.dart`, `servicio_sesion.dart` | API al iniciar; perfil en memoria | `POST /login`, `GET /me`, `POST /logout` | Todos | Login y `/me` conectados. Falta restaurar sesión al abrir y conectar el cierre de sesión. |
| Inicio y resumen / `pantalla_inicio.dart` | Estado local de habitaciones | `GET /rooms` (summary + rooms), `GET /reports/dashboard` (admin) | Recepción; dashboard admin | No sincronizado. El resumen oficial debe venir del backend. |
| Habitaciones / inicio, detalle, tareas | `GET /rooms` después del login; fixtures quitados de la lista activa | `GET /rooms`, `PATCH /rooms/{id}/status`; admin `POST /rooms`, `PUT /rooms/{id}` | Todos leen; admin escribe catálogo; los roles operativos actualizan según autorización | Lectura conectada; respuesta esperada `{summary, rooms}`. El modelo acepta nombres en inglés y español, pero hay que validar el JSON real. Los cambios de estado siguen pendientes de endpoints de estadía/reserva/tarea. |
| Huéspedes / alta, agenda, reserva | API con paginación; el JSON local ya no se carga ni mezcla | `GET /guests?q=&per_page=`, `POST /guests`, `GET/PUT/PATCH/DELETE /guests/{id}` | Admin y recepcionista | Lectura y creación conectadas. El POST usa `name`, `document`, `phone` y `email`; falta conectar edición/archivo y validar respuesta real. Los datos previos en storage local se conservan sin mostrarse ni migrarse. |
| Reservas / agenda y nueva reserva | Servicio local y `SharedPreferences` | `GET/POST /reservations`, `GET /reservations/{id}`, `POST /reservations/{id}/cancel`, `/check-in` | Recepcionista | No sincronizado. Falta mapear respuestas/estados y mover validación de disponibilidad al servidor. |
| Estadías / nueva y finalizar estadía | Servicio local, tarifas mock, factura local | `GET/POST /stays`, `GET /stays/{id}`, `POST /stays/{id}/extend`, `/charge`, `/checkout` | Recepcionista | No sincronizado. No se debe tratar la factura local ni sus cálculos como persistencia financiera oficial. |
| Tarifas / nueva reserva y check-in | `tarifas_ejemplo.dart` | `GET /rates`; administración según contrato | Recepcionista consulta; admin administra | No sincronizado. La app calcula precios localmente; debe usar importes y reglas del servidor. |
| Tareas / limpieza y mantenimiento | `SharedPreferences`, cambios locales de habitaciones | `GET/POST /tasks`, `PATCH /tasks/{id}/assign`, `/status` | Admin asigna; limpieza/mantenimiento actualizan las asignadas | No sincronizado. El control actual de roles no reemplaza la autorización API. |
| Productos y categorías / tienda | Catálogos mock/locales | `GET /products`, `GET /categories` | Recepción consulta; admin administra | Cliente tiene métodos GET, pero la UI no los consume. |
| Tienda y ventas / carrito | Catálogo local e historial en memoria | `POST /sales`, `GET /sales`, `GET /sales/{id}`, `POST /sales/{id}/cancel` | Recepcionista; admin consulta | Métodos parciales ya existen para ventas; UI no los usa. No reintentar POST automáticamente. |
| Inventario / inventario | Productos mock y estado en memoria | `/inventory/movements`; `/purchases` | Admin | No conectado. El contrato aportado no detalla verbos, campos ni respuestas para productos, compras o ajustes. |
| Caja / apertura y cierre | `SharedPreferences` y cálculos locales | `GET /shifts/current`, `POST /shifts/open`, `/close`; admin `GET /shifts` y detalle | Recepcionista turno propio; admin consulta | Cliente tiene algunas operaciones, UI/servicio aún local. Falta usar resumen oficial de cierre. |
| Gastos / gastos de turno | Registro local o sin operación API en UI | `GET/POST /expenses` | Recepcionista; admin consulta | Cliente tiene métodos parciales; UI no los consume. |
| Historiales, facturas y cobros | Datos locales y mocks | Ventas, gastos, turnos; no hay libro de facturas/pagos parciales | Admin reportes; recepción su operación | No sincronizado. El contrato dice que no existe endpoint independiente de facturas ni pagos parciales. |
| Reportes financieros | Cálculos y mocks locales | `/reports/dashboard` y endpoints financieros disponibles | Admin | No conectado. No mostrar cifras locales como oficiales. |
| Notificaciones | Estado local en memoria | No hay endpoint push en el contrato | Según rol | No sincronizado; no presentarlas como push/API. |
| Configuración y tema | Preferencias locales | Sin endpoint indicado | Local | Tema/configuración de la app puede seguir local; no hay contrato de configuración hotelera compartida. |
| Proveedores y compras | Sin flujo remoto conectado | `/suppliers`, `/purchases` | Admin | El contrato solo nombra las rutas; faltan verbos, campos, respuestas y detalle de permisos. |

## Trabajo hecho en este cambio

- Se añadió selección de entorno para la URL base mediante `API_BASE_URL`.
- El transporte HTTP central admite `PATCH` y `DELETE`; el login consulta `/me`.
- Se añadió un normalizador para listas simples, paginación Laravel (`data`) y
  colecciones bajo una clave como `rooms`.
- Habitaciones y huéspedes se cargan desde el servidor después de autenticar;
  la pantalla de inicio permite actualizar habitaciones y muestra errores.
- Registrar un huésped busca primero por documento en la API y lo crea en el
  servidor si no existe. No se escriben datos nuevos de huéspedes en storage
  local.

Estos cambios conectan la lectura de habitaciones y lectura/creación de
huéspedes. **No declaran sincronizados** módulos cuyas operaciones siguen en
servicios locales.

## Dependencias para completar y verificar la integración

1. Compartir los controladores o JSON autenticados para confirmar los campos de
   `RoomController`, `StayController`, `TaskController`, `RateController`,
   `PurchaseController` y las respuestas de los demás endpoints.
2. Ejecutar los flujos desde el dispositivo con cuentas de prueba para admin,
   recepción, limpieza y mantenimiento. Esta sesión de desarrollo no tiene un
   token de usuario para consultar las rutas protegidas.
3. Definir la migración de huéspedes/habitaciones que ya existen en el storage
   local. No se deben borrar registros locales ni mezclarlos silenciosamente
   con la fuente remota.
4. Añadir al backend un libro de facturas/pagos parciales y auditoría si esos
   flujos deben ser compartidos; el contrato aportado no los ofrece.

