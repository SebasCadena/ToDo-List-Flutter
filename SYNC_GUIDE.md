# Guía de Sincronización - PASO 2 Completado

## ✅ Implementado:

### 1. **Tabla de Cola de Sincronización**
- Nueva tabla `queue_operations` en SQLite
- Almacena operaciones pendientes: CREATE, UPDATE, DELETE, RESTORE

### 2. **Encolamiento Automático**
Todas las operaciones CRUD ahora se encolan automáticamente:
- ✅ **Crear tarea**: Se guarda en local y encola operación CREATE
- ✅ **Actualizar tarea**: Se actualiza en local y encola UPDATE
- ✅ **Marcar completada**: Se actualiza en local y encola UPDATE
- ✅ **Eliminar tarea**: Soft delete local y encola DELETE
- ✅ **Restaurar tarea**: Restaura en local y encola RESTORE

### 3. **Sincronización Manual**
- Botón de sincronización (ícono de sync) en el AppBar
- Procesa todas las operaciones pendientes en la cola
- Muestra mensajes de éxito/error
- Actualiza tareas locales con las del servidor (Last-Write-Wins)

## 🧪 Cómo Probar:

### Prueba 1: Crear tarea offline
1. **Desactiva tu WiFi/datos**
2. Crea una nueva tarea "Tarea Offline 1"
3. La tarea aparece inmediatamente en la lista (guardada en SQLite)
4. **Activa la conexión**
5. Presiona el botón de sincronización (⟳)
6. Verás mensaje "✅ X operaciones sincronizadas"
7. La tarea ahora está en el servidor

### Prueba 2: Editar tarea offline
1. Desactiva conexión
2. Edita una tarea existente
3. Marca otra como completada
4. Activa conexión y sincroniza
5. Los cambios se envían al servidor

### Prueba 3: Eliminar y restaurar
1. Elimina una tarea (sin conexión)
2. Ve a tareas eliminadas
3. Restaura una tarea
4. Sincroniza
5. Ambas operaciones se envían al servidor

### Prueba 4: Verificar cola
Para ver las operaciones pendientes en la base de datos:
```dart
final ops = await DBService.getPendingOperations();
print('Operaciones pendientes: ${ops.length}');
```

## 📋 Próximos Pasos (PASO 3):
- Sincronización automática al detectar conexión
- Listener de conectividad
- Reintentos con backoff exponencial
- Indicadores visuales de estado de sync

## 🔍 Logs útiles:
En la consola verás mensajes como:
- `✅ Operación encolada: CREATE task 123`
- `✅ Sincronizado: UPDATE #5`
- `❌ Error sincronizando: DELETE #8 - Exception...`
