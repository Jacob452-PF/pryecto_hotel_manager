import 'package:flutter_test/flutter_test.dart';

import 'package:hotel_manager/inventario/modelos/compra_inventario.dart';
import 'package:hotel_manager/inventario/servicios/servicio_inventario.dart';

void main() {
  test(
    'registra reposiciones y devoluciones con sus efectos en stock y gasto',
    () {
      final servicio = ServicioInventario.instancia;
      final producto = servicio.productos.first;
      final stockInicial = producto.stock;
      final gastoInicial = servicio.gastoDelTurno;

      servicio.reponerStock(
        producto.id,
        paquetes: 2,
        unidadesPorPaquete: 1,
        costoPaquete: 10,
        actualizarPrecio: true,
        precioVenta: 15,
      );

      expect(
        servicio.productos.firstWhere((p) => p.id == producto.id).stock,
        stockInicial + 2,
      );
      expect(
        servicio.productos.firstWhere((p) => p.id == producto.id).precio,
        15,
      );
      expect(servicio.gastoDelTurno, gastoInicial + 20);
      expect(servicio.comprasDelTurno.last.tipo, TipoMovimientoCompra.compra);

      servicio.reponerStock(
        producto.id,
        paquetes: 1,
        unidadesPorPaquete: 1,
        costoPaquete: 10,
        actualizarPrecio: false,
      );
      expect(
        servicio.productos.firstWhere((p) => p.id == producto.id).precio,
        15,
      );

      final devolucionCliente = servicio.registrarDevolucion(
        producto.id,
        cantidad: 1,
        precioUnitario: 15,
        deCliente: true,
      );
      expect(devolucionCliente, isTrue);
      expect(
        servicio.productos.firstWhere((p) => p.id == producto.id).stock,
        stockInicial + 4,
      );
      expect(servicio.gastoDelTurno, gastoInicial + 45);
      expect(
        servicio.comprasDelTurno.last.tipo,
        TipoMovimientoCompra.devolucionCliente,
      );

      final devolucionProveedor = servicio.registrarDevolucion(
        producto.id,
        cantidad: 1,
        precioUnitario: 8,
        deCliente: false,
      );
      expect(devolucionProveedor, isTrue);
      expect(
        servicio.productos.firstWhere((p) => p.id == producto.id).stock,
        stockInicial + 3,
      );
      expect(servicio.gastoDelTurno, gastoInicial + 37);
      expect(
        servicio.comprasDelTurno.last.tipo,
        TipoMovimientoCompra.devolucionProveedor,
      );
    },
  );
}
