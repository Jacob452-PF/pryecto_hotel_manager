import '../modelos/caja_cierre.dart';
import '../modelos/consumo_cliente.dart';
import '../modelos/turno_caja.dart';

/// Datos de prueba. Las fechas son relativas a hoy para que los filtros
/// (Hoy / Esta semana / Este mes) tengan algo que mostrar.
/// Después se reemplaza por la base de datos.
List<CajaCierre> crearCajasMock(DateTime ahora) {
  DateTime dia(int diasAtras, int h, int m) => DateTime(
    ahora.year,
    ahora.month,
    ahora.day,
    h,
    m,
  ).subtract(Duration(days: diasAtras));

  return [
    CajaCierre(
      numero: '001',
      fecha: dia(0, 14, 15),
      cajero: 'Reinaldo Reyes',
      // Total = 168.40 (se suma desde el detalle)
      clientes: const [
        ConsumoCliente(
          cliente: 'María González',
          codigo: '#A2',
          lineas: [
            LineaConsumo('Agua mineral', 1.50),
            LineaConsumo('Snak', 2.50),
            LineaConsumo('Papas', 2.00),
            LineaConsumo('Jugo del valle', 2.00),
            LineaConsumo('Kit de aseo', 4.90),
            LineaConsumo('Habitación', 25.00, 1, TipoVenta.habitaciones),
          ],
        ),
        ConsumoCliente(
          cliente: 'Carlos Ramírez',
          codigo: '#A5',
          lineas: [
            LineaConsumo('Galletas', 3.50),
            LineaConsumo('Café', 5.00),
            LineaConsumo('Pan', 4.25),
            LineaConsumo('Habitación', 25.00, 1, TipoVenta.habitaciones),
          ],
        ),
        ConsumoCliente(
          cliente: 'Ana Rodríguez',
          codigo: '#B5',
          lineas: [
            LineaConsumo('Cereal', 5.90),
            LineaConsumo('Leche', 6.50),
            LineaConsumo('Crepa', 8.40),
            LineaConsumo('Shampoo', 35.00),
            LineaConsumo('Toallas extra', 11.95),
            LineaConsumo('Habitación', 25.00, 1, TipoVenta.habitaciones),
          ],
        ),
      ],
    ),
    CajaCierre(
      numero: '002',
      fecha: dia(1, 17, 15),
      cajero: 'Jose A.',
      totalRegistrado: 124.90,
    ),
    CajaCierre(
      numero: '003',
      fecha: dia(2, 14, 15),
      cajero: 'María H.',
      totalRegistrado: 168.40,
    ),
    CajaCierre(
      numero: '004',
      fecha: dia(20, 14, 15),
      cajero: 'Reinaldo Reyes',
      totalRegistrado: 98.30,
    ),
    CajaCierre(
      numero: '005',
      fecha: dia(45, 17, 15),
      cajero: 'Jose A.',
      totalRegistrado: 142.75,
    ),
  ];
}
