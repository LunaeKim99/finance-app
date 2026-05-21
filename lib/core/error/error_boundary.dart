import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _error;

  @override
  void initState() {
    super.initState();
    _setupErrorHandlers();
  }

  void _setupErrorHandlers() {
    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details);
      if (mounted) setState(() => _error = details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('[ErrorBoundary] Platform error: $error\n$stack');
      return true;
    };
  }

  @override
  void dispose() {
    FlutterError.onError = null;
    PlatformDispatcher.instance.onError = null;
    super.dispose();
  }

  void _recover() {
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildFallback(context);
    }
    return widget.child;
  }

  Widget _buildFallback(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
      ),
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 72,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Terjadi Kesalahan',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Maaf, aplikasi mengalami kesalahan yang tidak terduga.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_error?.exception is SocketException ||
                        _error?.exception is HttpException)
                      Text(
                        'Periksa koneksi internet kamu dan coba lagi.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade600,
                        ),
                      ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _recover,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba Lagi'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (kDebugMode)
                      TextButton(
                        onPressed: () => _showErrorDetails(),
                        child: const Text('Detail Error'),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showErrorDetails() {
    if (_error == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error Details'),
        content: SingleChildScrollView(
          child: SelectableText(
            '${_error!.exception}\n\n${_error!.stack}',
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
