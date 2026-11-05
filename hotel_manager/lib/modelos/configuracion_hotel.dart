enum CanalAvisoHuesped { whatsapp, correo, ambos }

class ConfiguracionHotel {
  final int toleranciaVencimientoReservaHoras;
  final int margenDesocupacionLimpiezaHoras;
  final int toleranciaCheckoutMin;
  final int repeticionAvisoEstadiaMin;
  final CanalAvisoHuesped canalAvisoHuesped;
  final String plantillaMensajeVencimiento;
  final double margenGananciaProducto;

  const ConfiguracionHotel({
    this.toleranciaVencimientoReservaHoras = 4,
    this.margenDesocupacionLimpiezaHoras = 3,
    this.toleranciaCheckoutMin = 5,
    this.repeticionAvisoEstadiaMin = 5,
    this.canalAvisoHuesped = CanalAvisoHuesped.whatsapp,
    this.plantillaMensajeVencimiento = 'Su reserva ha vencido.',
    this.margenGananciaProducto = .20,
  });

  ConfiguracionHotel copyWith({
    int? toleranciaVencimientoReservaHoras,
    int? margenDesocupacionLimpiezaHoras,
    int? toleranciaCheckoutMin,
    int? repeticionAvisoEstadiaMin,
    CanalAvisoHuesped? canalAvisoHuesped,
    String? plantillaMensajeVencimiento,
    double? margenGananciaProducto,
  }) => ConfiguracionHotel(
    toleranciaVencimientoReservaHoras:
        toleranciaVencimientoReservaHoras ??
        this.toleranciaVencimientoReservaHoras,
    margenDesocupacionLimpiezaHoras:
        margenDesocupacionLimpiezaHoras ?? this.margenDesocupacionLimpiezaHoras,
    toleranciaCheckoutMin: toleranciaCheckoutMin ?? this.toleranciaCheckoutMin,
    repeticionAvisoEstadiaMin:
        repeticionAvisoEstadiaMin ?? this.repeticionAvisoEstadiaMin,
    canalAvisoHuesped: canalAvisoHuesped ?? this.canalAvisoHuesped,
    plantillaMensajeVencimiento:
        plantillaMensajeVencimiento ?? this.plantillaMensajeVencimiento,
    margenGananciaProducto:
        margenGananciaProducto ?? this.margenGananciaProducto,
  );

  Map<String, dynamic> toJson() => {
    'toleranciaVencimientoReservaHoras': toleranciaVencimientoReservaHoras,
    'margenDesocupacionLimpiezaHoras': margenDesocupacionLimpiezaHoras,
    'toleranciaCheckoutMin': toleranciaCheckoutMin,
    'repeticionAvisoEstadiaMin': repeticionAvisoEstadiaMin,
    'canalAvisoHuesped': canalAvisoHuesped.name,
    'plantillaMensajeVencimiento': plantillaMensajeVencimiento,
    'margenGananciaProducto': margenGananciaProducto,
  };

  factory ConfiguracionHotel.fromJson(Map<String, dynamic> j) =>
      ConfiguracionHotel(
        toleranciaVencimientoReservaHoras:
            j['toleranciaVencimientoReservaHoras'] as int? ?? 4,
        margenDesocupacionLimpiezaHoras:
            j['margenDesocupacionLimpiezaHoras'] as int? ?? 3,
        toleranciaCheckoutMin: j['toleranciaCheckoutMin'] as int? ?? 5,
        repeticionAvisoEstadiaMin: j['repeticionAvisoEstadiaMin'] as int? ?? 5,
        canalAvisoHuesped: CanalAvisoHuesped.values.firstWhere(
          (e) => e.name == j['canalAvisoHuesped'],
          orElse: () => CanalAvisoHuesped.whatsapp,
        ),
        plantillaMensajeVencimiento:
            j['plantillaMensajeVencimiento'] as String? ??
            'Su reserva ha vencido.',
        margenGananciaProducto:
            (j['margenGananciaProducto'] as num?)?.toDouble() ?? .20,
      );
}
