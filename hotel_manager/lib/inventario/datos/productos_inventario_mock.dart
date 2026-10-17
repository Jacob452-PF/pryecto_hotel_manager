import '../modelos/producto_inventario.dart';

/// Datos de prueba. Después se reemplaza por la base de datos.
const List<ProductoInventario> productosInventarioMock = [
  ProductoInventario(
    id: 'inv-1',
    nombre: 'Coca Cola',
    precio: 1.50,
    categoria: CategoriaInventario.bebidas,
    stock: 48,
    stockMaximo: 50,
  ),
  ProductoInventario(
    id: 'inv-2',
    nombre: 'Pepsi',
    precio: 1.00,
    categoria: CategoriaInventario.bebidas,
    stock: 30,
    stockMaximo: 50,
  ),
  ProductoInventario(
    id: 'inv-3',
    nombre: 'Agua purificada',
    precio: 0.75,
    categoria: CategoriaInventario.bebidas,
    stock: 8,
    stockMaximo: 50,
  ),
  ProductoInventario(
    id: 'inv-4',
    nombre: 'Jugo',
    precio: 1.00,
    categoria: CategoriaInventario.bebidas,
    stock: 25,
    stockMaximo: 50,
  ),
  ProductoInventario(
    id: 'inv-5',
    nombre: 'Papas fritas',
    precio: 1.00,
    categoria: CategoriaInventario.alimentos,
    stock: 5,
    stockMaximo: 50,
  ),
  ProductoInventario(
    id: 'inv-6',
    nombre: 'Oreo',
    precio: 1.00,
    categoria: CategoriaInventario.alimentos,
    stock: 40,
    stockMaximo: 50,
  ),
];
