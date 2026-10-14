class BaseFirmas {
  const BaseFirmas([this._hashesConocidos = const <String>{}]);

  final Set<String> _hashesConocidos;

  bool esMalwareConocido(String sha256) {
    return _hashesConocidos.contains(sha256.toLowerCase());
  }
}