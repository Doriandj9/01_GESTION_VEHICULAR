package com.example.gestionvehicular_mobile

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth necesita una FragmentActivity para mostrar el dialogo de la
// huella (BiometricPrompt). Con la FlutterActivity por defecto la
// autenticacion biometrica falla al abrirse.
class MainActivity : FlutterFragmentActivity()
