import 'package:flutter/material.dart';

import '../../themes/dimens.dart';

/// Barra corta verde que encabeza cada tarjeta o sección, tomada del mockup.
/// Es el sello visual de la marca y se repite en toda la app.
class BarraAcento extends StatelessWidget {
  const BarraAcento({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Dimens.anchoAcento,
      height: Dimens.altoAcento,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(Dimens.altoAcento),
      ),
    );
  }
}
