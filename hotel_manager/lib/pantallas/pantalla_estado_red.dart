import 'package:flutter/material.dart';
import '../servicios/servicio_conexion.dart';
import '../tema/colores_app.dart';
import '../tema/estilos_texto.dart';
import '../widgets/fila_informacion.dart';
import '../widgets/tarjeta_seccion.dart';

/// Muestra si el teléfono tiene internet y si el servidor del hotel responde.
class PantallaEstadoRed extends StatefulWidget {
  const PantallaEstadoRed({super.key});

  @override
  State<PantallaEstadoRed> createState() => _EstadoPantallaEstadoRed();
}

class _EstadoPantallaEstadoRed extends State<PantallaEstadoRed> {
  bool _comprobando = true;
  bool? _hayInternet;
  bool? _servidorDisponible; // null = sin configurar

  @override
  void initState() {
    super.initState();
    _comprobar();
  }

  Future<void> _comprobar() async {
    final internet = await ServicioConexion.hayInternet();
    final servidor = await ServicioConexion.servidorDisponible();
    if (!mounted) return;
    setState(() {
      _hayInternet = internet;
      _servidorDisponible = servidor;
      _comprobando = false;
    });
  }

  void _volverAComprobar() {
    setState(() => _comprobando = true);
    _comprobar();
  }

  @override
  Widget build(BuildContext context) {
    final String textoInternet;
    final Color? colorInternet;
    if (_comprobando) {
      textoInternet = 'Comprobando…';
      colorInternet = null;
    } else if (_hayInternet == true) {
      textoInternet = 'Conectado a internet';
      colorInternet = ColoresApp.disponible;
    } else {
      textoInternet = 'Sin conexión a internet';
      colorInternet = ColoresApp.cancelar;
    }

    final String textoServidor;
    final Color? colorServidor;
    if (_comprobando) {
      textoServidor = 'Comprobando…';
      colorServidor = null;
    } else if (_servidorDisponible == null) {
      textoServidor = 'Sin configurar';
      colorServidor = ColoresApp.limpieza;
    } else if (_servidorDisponible == true) {
      textoServidor = 'Disponible';
      colorServidor = ColoresApp.disponible;
    } else {
      textoServidor = 'No responde';
      colorServidor = ColoresApp.cancelar;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Estado de la red')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TarjetaSeccion(
              titulo: 'Conexión',
              icono: Icons.network_check,
              hijo: Column(
                children: [
                  FilaInformacion(
                    icono: (!_comprobando && _hayInternet == false)
                        ? Icons.wifi_off
                        : Icons.wifi,
                    etiqueta: 'Internet',
                    valor: textoInternet,
                    colorValor: colorInternet,
                  ),
                  const Divider(height: 1),
                  FilaInformacion(
                    icono: Icons.storage,
                    etiqueta: 'Servidor del hotel (base de datos)',
                    valor: textoServidor,
                    colorValor: colorServidor,
                  ),
                ],
              ),
            ),
            if (!_comprobando && _servidorDisponible == null)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'El servidor se comprobará cuando la app se conecte con la API.',
                  style: EstilosTexto.textoVacio,
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _comprobando ? null : _volverAComprobar,
              icon: const Icon(Icons.refresh),
              label: const Text('Volver a comprobar'),
            ),
          ],
        ),
      ),
    );
  }
} 