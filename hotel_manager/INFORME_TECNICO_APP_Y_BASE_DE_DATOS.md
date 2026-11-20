# Informe técnico de Hotel Manager

**Fecha:** 18 de noviembre de 2026  
**Alcance:** revisión estática del código Flutter de `lib/`, sus modelos, pantallas y servicios. No se verificó el estado operativo de los servidores ni se ejecutó una prueba integral.

## 1. Resumen ejecutivo

Hotel Manager es una aplicación Flutter para administrar la operación de un hotel: habitaciones y estadías, huéspedes, reservas, limpieza y mantenimiento, venta de productos, inventario, caja, pagos, historial y configuración. La interfaz está organizada en pantallas reutilizables y servicios que contienen las reglas de negocio.

La conexión con API ya está iniciada: existe un `ApiClient` dirigido a `https://hotel-manager-api-ttg7.onrender.com/api`, con autenticación Bearer, almacenamiento seguro del token, manejo de errores y métodos para productos, turnos, ventas y gastos. **Sin embargo, en el código de la app el único método que se invoca es el inicio de sesión (`POST /login`).** El resto de operaciones expuestas por el cliente todavía no están conectadas a las pantallas/servicios. Por ello, habitaciones, huéspedes, reservas, estadías, tareas, caja y abonos no se sincronizan mediante esa API.

Los datos locales usan JSON en `SharedPreferences`; inventario, carrito, notificaciones e historial tienen además partes en memoria o datos de demostración. Esta combinación no garantiza una fuente única de verdad ni sincronización entre dispositivos. La recomendación es desarrollar la API como capa de acceso central y una base de datos relacional transaccional para las operaciones hoteleras.

## 2. Estructura y arquitectura observada

- **`lib/pantallas/`**: acceso, contenedor principal, inicio, agenda, habitaciones, huéspedes, reservas, tareas, facturas, cobros, caja, perfil, configuración y notificaciones.
- **`lib/tienda/`**: tienda, lista/catálogo, carrito y selección de huésped.
- **`lib/inventario/`**: productos, compras, ajustes y movimientos de stock.
- **`lib/historial/`**: historial de cajas, detalle de cierres, facturas de clientes y resumen de turnos.
- **`lib/modelos/` y modelos de módulos**: entidades serializables y estados del dominio.
- **`lib/servicios/`**: reglas y estado de aplicación. Muchos servicios notifican cambios a widgets con `ChangeNotifier`.
- **`lib/widgets/` y temas/utilidades**: componentes visuales, formularios, diálogos, filtros y formato.

El inicio carga preferencias, configuración, huéspedes, habitaciones, estadías, reservas, tareas, cajas y abonos antes de mostrar el login. La navegación principal conserva secciones en un `IndexedStack`; el acceso a secciones y acciones varía según rol. En los modelos hay identificadores y relaciones útiles, pero varias relaciones se guardan como texto o no están respaldadas por restricciones de base de datos.

## 3. Vistas y funciones principales

### Acceso, usuarios y perfiles

- **Login:** correo/usuario y contraseña, validación de campos, estado de carga y mensajes de error. Llama a la API y convierte el rol recibido en los roles de interfaz (admin, recepción, limpieza y mantenimiento).
- **Solicitud de usuario:** captura datos para pedir un usuario; el flujo de aprobación no está implementado como operación API en la app.
- **Perfil:** muestra usuario, rol y opciones contextuales de caja, preferencias, tema y cierre de sesión.
- **Permisos:** recepción/administración cuentan con funciones operativas; limpieza y mantenimiento se limitan a tareas y habitaciones asignadas.

### Habitaciones, huéspedes, estadías y reservas

- **Inicio:** indicadores de habitaciones por estado, búsqueda/filtros y agrupación por piso; abre el detalle de habitación.
- **Detalle de habitación:** presenta tipo, camas, piso, estado, huésped y acciones según estado/rol; permite solicitar limpieza o mantenimiento y consultar/cobrar una estadía.
- **Nuevo huésped/estadía:** registra datos de huésped, selecciona habitación y tarifa, calcula el cobro inicial y genera la factura inicial.
- **Agenda y nueva reserva:** calendario mensual, selección de fecha/hora, tipo de habitación/duración, comprobación local de cruces y listado de reservas del día.
- **Ciclo de estadía:** la app representa entrada, cargos, abonos, saldo y cierre; al cerrar libera la habitación.

### Operación, inventario y venta

- **Tareas:** creación, asignación y cambios de estado para limpieza y mantenimiento; se reflejan cambios relacionados en el estado de habitación y se generan notificaciones internas.
- **Inventario:** búsqueda/categorías, nivel y umbral de stock, altas, compras/reposiciones, ajustes, motivos y movimientos. Los datos se inicializan desde un catálogo mock y el servicio actual mantiene cambios en memoria.
- **Tienda y carrito:** filtra artículos, permite cantidades, huésped objetivo y total. La lógica actual prevé validar stock y cargar los productos a una estadía, aunque no hay operación de API que persista estas ventas desde la pantalla.

### Facturación, caja e historial

- **Factura temporal/final:** resume tarifa, productos, importes, pagos previos y saldo; admite abonos parciales y cobro al finalizar.
- **Apertura/cierre de caja:** fondo inicial, conteo por denominaciones, esperado, diferencia y nota de cierre.
- **Historial:** cierres, detalle de turno y factura por huésped; el servicio mezcla cierres locales con datos de ejemplo y trabaja en memoria.

### Configuración, notificaciones y ayuda

- Configuración de tolerancias de reservas/estadías y canal/plantilla de aviso; tema seleccionable y guardado localmente.
- Notificaciones internas para cambios operativos, tareas y stock. No se encontró integración push.
- El aviso al huésped es un stub; no se conecta a proveedor de correo/WhatsApp.
- Estado de red prueba conectividad a Internet, pero el chequeo de disponibilidad del servidor devuelve `null`; no equivale a una comprobación del API.

## 4. Integración con API y persistencia actual

### Cliente API encontrado

El cliente central está en [`lib/servicios/api_client.dart`](lib/servicios/api_client.dart). Define la URL base, añade `Accept` y `Content-Type`, agrega `Authorization: Bearer <token>`, usa un timeout de 90 segundos, interpreta JSON y errores HTTP, limpia el token ante 401 y llama a una función de retorno al login. El token se guarda con `flutter_secure_storage`.

Métodos actualmente declarados:

| Área | Operaciones API definidas | Uso detectado desde pantallas/servicios |
|---|---|---|
| Sesión | `POST /login`, `POST /logout`, `GET /me` | Login sí invoca `/login`; no se detectó uso de `/logout` ni `/me` |
| Catálogo | `GET /categories`, `GET /products?q=` | Ninguno detectado |
| Caja/turnos | `GET /shifts/current`, `POST /shifts/open`, `POST /shifts/close` | Ninguno detectado |
| Ventas | `POST /sales`, `GET /sales?page=`, `POST /sales/{id}/cancel` | Ninguno detectado |
| Gastos | `GET /expenses?page=`, `POST /expenses` | Ninguno detectado |

La aplicación sigue usando `ServicioSesion` para el usuario activo, y no se observa restauración de sesión desde el token al arrancar. Aunque se configure un callback de 401, sólo tendrá efecto en las llamadas que realmente pasen por el `ApiClient`.

### Persistencia actual por tipo

- **`SharedPreferences` + JSON:** preferencias/configuración y colecciones principales de huéspedes, habitaciones, estadías, reservas, tareas, caja y abonos.
- **Memoria/mock:** inventario, historial/cierres de ejemplo, catálogo de tienda, algunos cargos y notificaciones.
- **Seguro local:** token de acceso de API.
- **Sin persistencia remota desde la app:** las operaciones hoteleras centrales no tienen endpoints invocados en el flujo de UI revisado.

`SharedPreferences` es adecuado para preferencias pequeñas, no para servir como base transaccional de reservas, pagos, inventario o caja. Tiene límites de concurrencia, auditoría, respaldo, consulta, consistencia y sincronización.

## 5. Elementos que debe llevar la base de datos

Se recomienda una base relacional (por ejemplo PostgreSQL) y que la API valide permisos, reglas y transacciones. Esta lista parte de los modelos y acciones reales de la aplicación.

### Tablas esenciales

| Tabla | Datos importantes |
|---|---|
| `hotels` | `id`, nombre, zona horaria, moneda, datos de contacto, estado. Incluirla desde el inicio permite separar datos por hotel. |
| `users` | `id`, `hotel_id`, nombre, correo único, hash de contraseña, rol, activo, teléfono/identificación si aplica, `created_at`, `updated_at`. Nunca guardar contraseña sin hash seguro. |
| `rooms` | `id`, `hotel_id`, número/código único por hotel, piso, tipo, camas, estado operativo, foto/URL, timestamps. El huésped activo debe relacionarse con una estadía, no duplicarse como texto. |
| `room_types` y `rates` | Tipo/capacidad y tarifas por modalidad (hora/noche), importe, vigencia, moneda, reglas de duración. No fijar la tarifa sólo en la app. |
| `guests` | `id`, `hotel_id`, nombre, documento/DUi, teléfono, correo, fecha de creación. Documento y correo con reglas de unicidad configurables según normativa/negocio. |
| `reservations` | Huésped, tipo de habitación o habitación asignada, inicio/fin, tarifa y precio acordado, total, estado (activa/cancelada/vencida/convertida), creador, timestamps. |
| `stays` | Huésped, habitación, reserva origen nullable, entrada/salida prevista y real, estado, tarifa/precio acordado, cantidad, usuario de recepción, timestamps. Debe impedir dos estadías activas incompatibles para una misma habitación. |
| `invoices` | Estadía, número, fecha, moneda, subtotal, impuestos/descuentos si aplican, total, saldo/estado calculado o controlado, estado (abierta/pagada/anulada). |
| `invoice_lines` | Factura/estadía, concepto o producto, descripción histórica, cantidad, precio unitario, importe, tipo de línea (alojamiento/producto/servicio/ajuste). Guardar el precio aplicado para preservar el historial. |
| `payments` | Factura/estadía, caja/turno, importe, método (efectivo/tarjeta/transferencia), referencia, fecha, usuario, estado y reversión/anulación. |
| `cash_shifts` | Usuario, apertura/cierre, fondo inicial, monto contado, esperado, diferencia, notas, estado y timestamps. Definir si se permite un turno abierto por usuario o por caja/hotel. |
| `cash_denominations` | Turno, momento (apertura/cierre), denominación y monto o cantidad de piezas. Elegir y documentar una unidad única; hoy el modelo guarda importes por denominación. |
| `products` | `id`, hotel, nombre, categoría, unidad, precio de venta, costo, stock, umbral mínimo, activo, URL de imagen. En la API actual existen nombre, precio, stock, `min_stock` y categoría. |
| `categories` | Hotel, nombre y tipo (inventario/servicio), estado. |
| `sales` y `sale_items` | Venta, turno, huésped/estadía nullable según tipo de venta, usuario, método, total, fecha; renglones con producto, cantidad y precio histórico. |
| `inventory_movements` | Producto, tipo (compra/venta/ajuste/consumo/retorno), cantidad con signo o dirección explícita, costo/precio, motivo, usuario, referencia a venta/compra/tarea, fecha. El historial de movimientos es esencial para auditar stock. |
| `purchases` y `purchase_items` | Proveedor opcional, turno/gasto relacionado, usuario, fecha, total; renglones con producto, unidades/paquetes, unidades por paquete, costo unitario y total. |
| `tasks` | Tipo (limpieza/mantenimiento), habitación, solicitante, asignado, descripción, estado, prioridad, creada/asignada/iniciada/finalizada, resultado/notas. |
| `notifications` | Hotel/usuario destino, título, cuerpo, severidad, referencia de entidad, leída, fecha. Para push, añadir identificadores de dispositivos en tabla separada. |
| `hotel_settings` | Hotel, clave/valor tipado o columnas explícitas, configuración de tolerancias, margen y preferencias de mensajes, timestamps. |
| `audit_logs` | Usuario, acción, entidad/id, valores anteriores/nuevos o diff, fecha, identificador de petición. Particularmente importante para pagos, caja, reservas y stock. |

### Relaciones principales

`hotels` contiene usuarios, habitaciones, tarifas y categorías. `guests` puede tener varias reservas y estadías. Una reserva puede convertirse en estadía; una estadía ocupa una habitación y tiene una factura. La factura contiene líneas y pagos. Una venta se relaciona con un turno y sus artículos; si se carga a habitación también se relaciona con huésped/estadía y factura. Movimientos de inventario apuntan al producto y, cuando corresponda, al documento origen. Las tareas apuntan a habitación y a los usuarios solicitante/asignado.

### Validaciones, índices y consistencia

- Claves foráneas en todas las relaciones y borrado lógico (`deleted_at` o `active=false`) en registros contables/históricos.
- Índices por `hotel_id`, estado, fecha de entrada/salida, habitación, huésped, turno y relaciones frecuentes.
- Unicidad de número de habitación por hotel; correo de usuario por hotel o global según diseño; número de factura/venta por hotel.
- Validar en servidor horarios solapados de reservas/estadías y transiciones permitidas de estado.
- Ejecutar en una sola transacción el cobro/venta, descuento de stock, registro de movimiento, renglón de factura y actualización de saldo/turno. Evita que un error deje datos parciales.
- Usar `DECIMAL` para importes, no `float`; fijar moneda y precisión. La app usa `double`, por lo que conviene adaptar el formato de transporte/API para dinero decimal.
- Para prevenir stock negativo y doble reserva, validar con bloqueo/concurrencia en base de datos; no confiar sólo en validaciones de Flutter.
- Paginar listados e incluir filtros por estado/fechas. Añadir `created_at`, `updated_at` y, donde aplique, `created_by`/`updated_by`.

## 6. Endpoints recomendados para completar la API

Además de los ya definidos, la app necesita endpoints con contratos JSON consistentes para:

1. **Sesión y usuarios:** login, usuario actual, logout/revocación, solicitudes y administración de cuentas/roles.
2. **Catálogos:** habitaciones, tipos/tarifas, productos/categorías, configuración y disponibilidad.
3. **Huéspedes y recepción:** CRUD/búsqueda de huéspedes; crear/listar/cancelar reserva; check-in, consulta de estadía, cargos a habitación y check-out.
4. **Tareas:** crear, asignar y cambiar estado; filtrar por asignado, habitación y estado.
5. **Facturación/pagos:** crear/consultar factura, renglones, abonos, cobro final y anulaciones con motivo.
6. **Inventario:** registrar compra/ajuste, consultar movimientos y actualizar catálogo.
7. **Caja/contabilidad:** turno actual, apertura/cierre, desglose, ventas/gastos y resumen del turno; asegurar que pagos y ventas queden vinculados a turno.
8. **Notificaciones/auditoría:** bandeja, marcar leída y registro de operaciones sensibles.

La API existente de `sales` calcula el precio en servidor, lo cual es correcto para evitar que el cliente imponga el importe. Debe mantenerse ese principio también para alojamiento, descuentos, impuestos y disponibilidad.

## 7. Prioridades sugeridas

1. Definir el esquema y contratos JSON, estados, reglas de solapamiento y modelo de roles/permisos.
2. Completar backend y base para huéspedes, habitaciones, reservas y estadías; son la base operativa.
3. Persistir facturas, cargos, abonos y pagos en transacciones y vincularlos a turno de caja.
4. Migrar catálogo, ventas, compras y movimientos de inventario; después conectar tienda e inventario de la UI al API.
5. Conectar tareas, configuración y notificaciones; retirar mocks y datos semilla de producción.
6. Crear migración/carga desde datos locales sólo si esos datos deben conservarse; diseñar estrategia de conflictos y sincronización antes de habilitar múltiples dispositivos.
7. Añadir controles de seguridad: autorización por hotel/rol en el servidor, contraseñas con hash moderno, expiración y revocación de tokens, HTTPS, validación de entradas, auditoría y protección de datos personales.

## 8. Conclusión

La app cuenta con una base funcional amplia en la interfaz y con modelos que ayudan a especificar el dominio. La conexión API está en una fase parcial: el login es remoto y el resto de los módulos conserva datos localmente o usa mocks, aunque el cliente ya declare funciones de productos, caja, ventas y gastos. Para que el sistema funcione como gestor hotelero multiusuario confiable, la prioridad es construir el modelo relacional indicado, ampliar endpoints para operaciones hoteleras y mover las reglas críticas al servidor con transacciones, validaciones y permisos.

## Referencias internas

- [`lib/servicios/api_client.dart`](lib/servicios/api_client.dart)
- [`lib/servicios/servicio_storage.dart`](lib/servicios/servicio_storage.dart)
- [`lib/main.dart`](lib/main.dart)
- [`lib/pantallas/pantalla_login.dart`](lib/pantallas/pantalla_login.dart)
- [`RECOPILACION_FUNCIONES.md`](RECOPILACION_FUNCIONES.md)
