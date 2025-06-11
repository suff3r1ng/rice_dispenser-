// Demo runner to test the app functionality
import 'lib/main.dart' as app;
import 'lib/services/logger_service.dart';

void main() {
  LoggerService.info('🌾 Starting Smart Rice Container Demo...');
  LoggerService.info('📱 Features available:');
  LoggerService.info('   • Professional UI with enhanced design');
  LoggerService.info('   • Database status monitoring');
  LoggerService.info('   • Rice weight tracking');
  LoggerService.info('   • Dispense management');
  LoggerService.info('   • History and analytics');
  LoggerService.info('   • Real-time status updates');
  LoggerService.info('   • Improved error handling');
  LoggerService.info('');
  LoggerService.info('🚀 Launching app...');

  app.main();
}
