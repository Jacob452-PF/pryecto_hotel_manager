import '../modelos/articulo_tienda.dart';

/// Datos de prueba. Después se reemplaza por la consulta a la base de datos.
const List<ArticuloTienda> articulosMock = [
  // Habitaciones
  ArticuloTienda(
    id: 'hab-1',
    nombre: 'Habitación familiar',
    precio: 20,
    seccion: SeccionTienda.habitaciones,
  ),
  ArticuloTienda(
    id: 'hab-2',
    nombre: 'Habitación matrimonial',
    precio: 20,
    seccion: SeccionTienda.habitaciones,
  ),
  // Servicio
  ArticuloTienda(
    id: 'srv-1',
    nombre: 'Limpieza',
    precio: 20,
    seccion: SeccionTienda.servicio,
    categoria: CategoriaTienda.aseo,
  ),
  ArticuloTienda(
    id: 'srv-2',
    nombre: 'Servicio de lavandería',
    precio: 20,
    seccion: SeccionTienda.servicio,
    categoria: CategoriaTienda.lenceria,
  ),
  // Productos del hotel
  ArticuloTienda(
    id: 'prd-1',
    nombre: 'Coca Cola',
    precio: 1.50,
    seccion: SeccionTienda.productos,
    categoria: CategoriaTienda.bebidas,
  ),
  ArticuloTienda(
    id: 'prd-2',
    nombre: 'Pepsi',
    precio: 1.00,
    seccion: SeccionTienda.productos,
    categoria: CategoriaTienda.bebidas,
  ),
  ArticuloTienda(
    id: 'prd-3',
    nombre: 'Agua purificada',
    precio: 0.75,
    seccion: SeccionTienda.productos,
    categoria: CategoriaTienda.bebidas,
  ),
  ArticuloTienda(
    id: 'prd-4',
    nombre: 'Jugo',
    precio: 1.00,
    seccion: SeccionTienda.productos,
    categoria: CategoriaTienda.bebidas,
  ),
  ArticuloTienda(
    id: 'prd-5',
    nombre: 'Papas fritas',
    precio: 1.00,
    seccion: SeccionTienda.productos,
    categoria: CategoriaTienda.alimentos,
  ),
  ArticuloTienda(
    id: 'prd-6',
    nombre: 'Oreo',
    precio: 1.00,
    seccion: SeccionTienda.productos,
    categoria: CategoriaTienda.alimentos,
  ),
];
