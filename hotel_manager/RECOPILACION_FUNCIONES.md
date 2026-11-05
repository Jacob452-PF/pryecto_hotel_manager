# Recopilación detallada de funciones e interacciones

Documento elaborado a partir del código actual de `lib/`. Describe funciones implementadas, controles, permisos y dependencias temporales. No presupone que las integraciones anunciadas en textos de pantalla ya estén conectadas.

## 1. Inicio, carga y navegación

- Al arrancar, se cargan preferencias de tema y configuración, huéspedes, habitaciones, estadías, reservas, tareas, caja y abonos. La app abre en el inicio de sesión.
- La interfaz principal mantiene las secciones en un `IndexedStack`, con navegación inferior.
- Administración y recepción ven **Inicio, Agenda, Tienda, Inventario, Historial y Perfil**. Limpieza y mantenimiento ven únicamente **Tareas y Perfil**; sus habitaciones se limitan a las asignadas.
- Las notificaciones nuevas aparecen además como aviso emergente con título, mensaje, icono según severidad y acción **Ver**. La campana muestra el número de no leídas (hasta `99+`).
- La pestaña Historial contiene su propio navegador interno para recorrer lista, detalle, factura y cierre de caja.

## 2. Acceso y usuarios

### Inicio de sesión

- Campo de usuario y contraseña, control para revelar/ocultar la contraseña y botón **Iniciar sesión**.
- Las credenciales se validan localmente contra usuarios activos. Un acceso correcto establece la sesión y pasa a la app; un acceso incorrecto se informa en pantalla.
- En una instalación sin usuarios guardados se crean cuatro cuentas de demostración: `admin01`, `recep01`, `limp01`, `mant01`; contraseña inicial común `Hotel123!`. Sus datos y contraseña son ficticios.
- **Solicitar un usuario nuevo** abre un formulario de solicitud; no es lo mismo que crear directamente una cuenta autorizada.

### Solicitud de usuario

- Captura datos personales/identificación y teléfono, cargo solicitado mediante selector, y fecha de nacimiento con selector de fecha.
- **Enviar solicitud** confirma el envío por el flujo local de la app. No hay un servicio de aprobación/backend conectado en el código examinado.

## 3. Inicio y habitaciones

- La cabecera presenta el resumen del hotel. Los indicadores cuentan habitaciones **Disponibles, Ocupadas** (incluye ocupada con limpieza pendiente), **En limpieza, Mantenimiento y Reservadas**.
- El filtro de habitaciones combina texto (número o nombre del huésped), estado y cantidad de camas. Los resultados se agrupan por piso en carruseles horizontales. Si no hay coincidencias se muestra un estado vacío.
- Al pulsar una tarjeta de habitación se abre su detalle; el detalle vuelve a consultar el estado actual del servicio.
- Administración/recepción dispone de **Nuevo huésped**. El botón abre una hoja inferior con dos caminos: **Registrar estadía** o **Crear reserva**.
- Administración/recepción tiene acceso a **Ver solicitudes y tareas**.

### Detalle de habitación

- Muestra foto si está disponible, estado y su color/icono, indicador de limpieza solicitada, tipo de cuarto, camas y piso. En habitaciones ocupadas recepción/administración también ve el huésped.
- Un técnico que no tenga asignada esa habitación recibe un mensaje de acceso no asignado.
- Según el estado y rol, se ofrecen acciones contextuales:
  - Ocupada: recepción/administración puede solicitar limpieza (si no existe una solicitud activa), abrir **Factura temporal y cargos**, o **Finalizar estadía y cobrar**. Mantenimiento está deshabilitado mientras está ocupada. Limpieza y mantenimiento no gestionan cobro.
  - Disponible: recepción/administración puede pedir limpieza o mantenimiento.
  - En limpieza: recepción/administración puede crear otra tarea de limpieza.
  - En mantenimiento: recepción/administración puede registrar una tarea de mantenimiento.
  - Reservada: no ofrece acciones en este detalle.
- Solicitar mantenimiento abre un diálogo para describir el problema; cancelar descarta y enviar crea la solicitud. Errores aparecen en un aviso.

### Registrar huésped y estadía

- Formulario de huésped/estadía recoge datos del cliente y permite seleccionar habitación disponible, tarifa/tipo y duración/horario según los controles del formulario.
- Valida datos obligatorios y selección; errores se muestran con avisos. Antes de confirmar muestra un resumen/confirmación de cobro inicial.
- Confirma el registro de huésped, ocupación de habitación y creación de cargos/factura inicial. Si la operación no se completa, se conserva la pantalla para corregir.
- La factura inicial muestra cargos y total, permite registrar abonos parciales hasta cubrir el total y volver al inicio.

### Reservas y agenda

- **Nueva reserva** permite elegir huésped, habitación disponible (filtrable por camas), fecha/hora de entrada y duración/salida calculada.
- Se impide una entrada pasada y habitaciones sin disponibilidad; se comprueban cruces con reservas y estadías y se avisa si no se puede guardar.
- Guardar crea la reserva y refleja el estado reservado cuando corresponde. Cancelar/volver abandona el formulario.
- **Agenda** cambia mes con flechas anterior/siguiente. El calendario permite tocar días del mes y lista las reservas que corresponden al día seleccionado, mostrando huésped, habitación y hora. Los días fuera del mes se distinguen y no seleccionan como parte del mes visible.

## 4. Tareas de limpieza y mantenimiento

- Recepción/administración crea solicitudes desde una habitación; limpieza puede recibir solicitudes automáticas/manuales. Mantenimiento incluye una descripción del problema.
- La pantalla agrupa tareas de limpieza y mantenimiento y presenta habitación, estado, descripción y asignado.
- Administración/recepción puede asignar a un usuario técnico activo del rol apropiado; si no hay usuarios activos se informa. Las acciones válidas para el técnico son **Aceptar**, **Iniciar**, y **Marcar listo/Resolver**.
- Las transiciones actualizan tarea y estado de habitación (incluida la condición ocupada con limpieza solicitada), liberan asignaciones al completar y notifican cambios. Acciones inválidas generan aviso.
- Al finalizar limpieza se contempla descontar consumibles de limpieza, pero los artículos usados proceden de un catálogo mock.
- Para técnicos, la vista principal es esta lista de tareas; en Inicio/detalle sólo se muestran habitaciones asignadas.

## 5. Tienda y cargos a huéspedes

- La tienda reúne huéspedes derivados de habitaciones ocupadas y artículos de inventario/catálogo. Categorías y buscador filtran; **Todos** reúne el catálogo. Puede abrirse una lista completa de una sección.
- Una tarjeta agrega un artículo al carrito y muestra una confirmación breve. El botón Carrito abre una hoja con líneas, cantidades, precios, huésped objetivo y total.
- En el carrito se puede incrementar/disminuir cantidades, quitar líneas y restaurar líneas eliminadas; elegir/cambiar huésped asignado y confirmar la operación.
- Antes de confirmar se comprueba stock de productos inventariables; al confirmar se agregan los cargos a la estadía del huésped y se descuenta stock. Servicios sin stock se tratan como cargos de servicio.
- El carrito ofrece vaciar/cerrar según el estado. El cargo confirmado aparece en factura temporal y al finalizar estadía.

## 6. Inventario

- Lista productos con búsqueda y filtros por categoría; presenta cantidad disponible, umbral de stock bajo, precio y resumen de inventario (valor/cantidades y avisos de agotados o bajos).
- **Agregar producto** abre una hoja para datos de producto/categoría, unidades, stock mínimo y precios/costo; guardar lo incorpora al catálogo y puede registrar compra inicial.
- Al seleccionar producto se puede ajustar stock: reposición o ajuste, cantidad, motivo y, cuando corresponde, actualizar precio de costo. Los cambios generan movimientos y compras de turno.
- Eliminar retira el producto de la lista y muestra aviso con **Deshacer**, que restaura el producto. La venta desde tienda descuenta existencias y verifica stock suficiente.
- El inventario actual es una instancia en memoria inicializada con productos mock; la compra y movimientos se reflejan en el turno mientras corre la app.

## 7. Facturas, estadías y abonos

### Factura temporal

- Para una habitación ocupada lista cargos iniciales de estadía y cargos añadidos desde tienda, cantidades, importes, total, abonos y saldo.
- Muestra tiempos de entrada/salida y tiempo restante cuando hay horario. Si no hay productos/cargos, muestra estado vacío.
- **Registrar abono** abre formulario de importe y desglose de efectivo. Se valida monto frente al saldo; al confirmar se guarda el abono y se recalcula el saldo. No admite abonar más del saldo.

### Finalizar estadía y cobrar

- Revisa cargos y cantidades, total menos pagos previos y tiempo restante/posible excedente.
- **Confirmar pago** abre el diálogo de cobro con métodos/desglose; comprueba stock/cargos aplicables y registra el pago final. Errores muestran aviso y permiten corregir.
- Al completar se cierra la estadía, se libera habitación y se muestra confirmación; **Volver al inicio** limpia las rutas hasta la pantalla inicial.

## 8. Caja, turnos e historial

### Apertura

- Recepción/administración puede abrir una caja por usuario. La pantalla recoge el fondo inicial mediante desglose de efectivo por denominaciones, calcula total y confirma apertura.
- No permite abrir una segunda caja del mismo usuario. La caja se guarda localmente y queda vinculada a usuario/hora.

### Cierre de caja / turno

- Presenta fecha, usuario, ventas/clientes, habitaciones ocupadas, compras de inventario y total esperado (fondo inicial más neto del turno).
- Solicita conteo físico con desglose de efectivo. Si existe diferencia con lo esperado muestra el importe y exige confirmación explícita o volver a revisar.
- Permite nota de cierre. Al confirmar guarda el cierre y muestra comprobante/resumen; el botón inferior permite abrir otra caja o volver.
- Recepción no puede cerrar sesión mientras tenga caja abierta. Administración también puede operar apertura/cierre.

### Historial

- Muestra cierres en orden reciente, búsqueda por número/cajero y filtros temporales. Inicialmente muestra hasta tres y permite **ver todas/ver menos**.
- Un cierre abre su detalle; desde allí se puede abrir factura de cliente con líneas iniciales/adicionales, abonos, importes y estado de pago.
- El botón inferior cambia entre **Abrir caja** y **Cierre de caja** según caja actual.
- Los cierres reales de caja se combinan con cierres de ejemplo. El historial y datos mock son en memoria; gastos manuales no tienen pantalla de registro y el modelo del turno usa lista vacía para gastos generales.

## 9. Notificaciones

- Lista avisos con título, mensaje, fecha/hora y severidad. Las notificaciones no leídas se cuentan en la campana y la más nueva puede mostrarse como snackbar.
- La lista permite abrir/ver detalles y marcar como leídas; **marcar todas leídas** limpia el contador.
- Se generan avisos internos por eventos del hotel como tareas, reservas/estadías y estados de stock según las reglas de servicio.
- No hay envío push externo configurado. El aviso a huésped por WhatsApp/correo es un stub que sólo imprime el intento en consola.

## 10. Perfil y preferencias

- Perfil muestra usuario, cargo/rol y hora de inicio de sesión.
- Recepción/administración ve el acceso de caja contextual: **Abrir caja** o **Cerrar caja**.
- **Configuración de la app** sólo permite editar a administración. Campos: tolerancia de vencimiento de reserva (horas), margen de limpieza (horas), tolerancia de check-out (minutos), repetición de aviso de estadía (minutos), canal de aviso a huésped, plantilla del mensaje de vencimiento y margen de ganancia de producto (+20%/+30%). Los cambios se persisten localmente.
- **Estado de la red** vuelve a comprobar internet (lookup de `google.com`, timeout de 4 s) y presenta servidor del hotel como **Sin configurar**: no existe ping API implementado.
- **Tema de la app** permite elegir paleta visual y muestra una previsualización de habitación/lista; la selección se guarda y se aplica a toda la app.
- **Acerca de la app** presenta versión, soporte/contacto y grupo de programadores.
- **Cerrar sesión** pide confirmación y vuelve al login; recepción debe cerrar caja antes.

## 11. Funciones temporales, de demostración o pendientes

Estas limitaciones afectan a cómo interpretar los datos y las interacciones anteriores:

1. **Sin backend ni base de datos del hotel.** El almacenamiento general es JSON en `SharedPreferences`; está señalado en código como temporal y reemplazable por API. No hay sincronización entre dispositivos/usuarios.
2. **Autenticación de demostración.** Usuarios de prueba se inicializan localmente; hash determinista simple, sin tokens ni seguridad de producción. El formulario de usuario no equivale a flujo real de aprobación.
3. **Habitaciones y tarifas de ejemplo.** La colección inicial viene de `habitaciones_ejemplo.dart` y tarifas de `tarifas_ejemplo.dart`; varias habitaciones ocupadas de ejemplo obtienen una estadía/cargos predeterminados para que la interfaz pueda mostrarlos.
4. **Tienda parcialmente ficticia.** Catálogo combina productos del inventario mock con artículos/servicios de ejemplo; huésped se deriva de habitaciones ocupadas. En la hoja de carrito hay TODO de persistencia del cargo a base de datos.
5. **Inventario sólo en memoria.** Su catálogo base es `productosInventarioMock`; los cambios no se serializan al almacenamiento local como los principales servicios.
6. **Historial de prueba.** Hay cierres de caja mock; el servicio de historial declara vivir en memoria. Algunos datos de ejemplo no corresponden a transacciones reales de la caja actual.
7. **Avisos externos no enviados.** La clase de salida imprime el aviso en consola; el canal seleccionado y la plantilla aún no conectan proveedor WhatsApp/correo.
8. **Estado de servidor no comprobado.** La pantalla verifica internet, pero `servidorDisponible()` devuelve `null` (sin configurar).
9. **Gastos de turno incompletos.** No hay pantalla para registrar gastos generales; el turno arma esa sección vacía. Sí refleja compras de inventario realizadas durante el turno.
10. **Persistencia desigual.** Tema, configuración, huéspedes, habitaciones, estadías, reservas, tareas, caja y abonos usan almacenamiento local. Sesión es de runtime; notificaciones, inventario, carrito y servicio de historial no son una base de datos remota y algunos viven sólo en memoria.

## 12. Componentes transversales

- Tarjetas reutilizables para habitaciones, perfil, secciones, resúmenes y productos; filtros, chips de categoría/estado, selectores de fecha/hora, hojas inferiores y diálogos de confirmación.
- Formateadores centralizan presentación de dinero, fechas, texto normalizado para búsqueda y desglose de efectivo.
- Los controles y acciones varían por rol y estado. Mensajes de éxito, errores y operaciones deshabilitadas forman parte de la interacción.

## Base de revisión

Recorrido de `lib/main.dart`, `lib/pantallas/`, `lib/tienda/`, `lib/inventario/`, `lib/historial/`, `lib/servicios/` y modelos relacionados. Este inventario describe el código encontrado; no implica verificación de ejecución en cada plataforma.
