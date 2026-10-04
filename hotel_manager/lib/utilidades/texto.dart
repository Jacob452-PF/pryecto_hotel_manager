/// Pasa a minúsculas y quita tildes y la ñ, para comparar textos al buscar.
/// Así "maria" encuentra "María".
String normalizarTexto(String texto) {
  const conTilde = 'áéíóúüñ';
  const sinTilde = 'aeiouun';
  var resultado = texto.toLowerCase().trim();
  for (var i = 0; i < conTilde.length; i++) {
    resultado = resultado.replaceAll(conTilde[i], sinTilde[i]);
  }
  return resultado;
}