import '../modelos/tarifa.dart';

// Precios de ejemplo: reemplázalos por las tarifas reales del hotel.
// Cada tarifa tiene un precio por cantidad de camas (a más camas, más caro).
// Matrimonial e individual tienen 1 cama; las familiares, 2, 3 o 4.
const tarifasEjemplo = <Tarifa>[
  Tarifa(TipoTarifa.porHora, {1: 5.00, 2: 8.00, 3: 11.00, 4: 14.00}),
  Tarifa(TipoTarifa.porNoche, {1: 25.00, 2: 40.00, 3: 55.00, 4: 70.00}),
];
