import '../entities/usage.dart';

abstract class UsageRepository {
  Future<Usage> load();
  Future<void> save(Usage usage);
}
