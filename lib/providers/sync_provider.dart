import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/sync_service.dart';

enum SyncStatus { idle, syncing, success, error }

/// Provider simple para gestionar el estado de sincronización
class SyncProvider extends ChangeNotifier {
  SyncStatus _status = SyncStatus.idle;
  String _message = '';
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isFirstConnection = true;

  SyncStatus get status => _status;
  String get message => _message;
  bool get isSyncing => _status == SyncStatus.syncing;

  /// Inicializar el listener de conectividad
  void initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results);
    });
  }

  /// Manejar cambios en la conectividad
  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    final hasConnection = results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);

    if (hasConnection) {
      // Evitar sincronización en la primera conexión (inicio de la app)
      if (_isFirstConnection) {
        _isFirstConnection = false;
        // Sincronizar después de un pequeño delay en el primer arranque
        Future.delayed(const Duration(seconds: 2), () => syncNow());
      } else {
        // Sincronizar automáticamente cuando se recupera la conexión
        print('📡 Conexión detectada, sincronizando...');
        await syncNow();
      }
    }
  }

  /// Sincronizar ahora
  Future<void> syncNow() async {
    if (_status == SyncStatus.syncing) return; // Evitar sincronizaciones simultáneas

    _status = SyncStatus.syncing;
    _message = 'Sincronizando...';
    notifyListeners();

    try {
      final result = await SyncService.fullSync();
      
      if (result['success']) {
        _status = SyncStatus.success;
        _message = result['message'];
        print('✅ Sincronización exitosa: $_message');
      } else {
        _status = SyncStatus.error;
        _message = result['message'];
        print('⚠️ Sincronización con errores: $_message');
      }
    } catch (e) {
      _status = SyncStatus.error;
      _message = 'Error: $e';
      print('❌ Error en sincronización: $e');
    }

    notifyListeners();

    // Resetear estado después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      _status = SyncStatus.idle;
      _message = '';
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
