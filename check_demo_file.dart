// Simple test file to verify DemoDatabaseService works
import 'dart:io';
import 'lib/services/logger_service.dart';

void main() async {
  LoggerService.info('Testing DemoDatabaseService import...');

  // Check if file exists
  final file = File('lib/services/demo_database_service.dart');
  LoggerService.info('File exists: ${file.existsSync()}');
  LoggerService.info('File size: ${await file.length()} bytes');

  // Try to read first few lines
  final lines = await file.readAsLines();
  LoggerService.info('First 5 lines:');
  for (int i = 0; i < 5 && i < lines.length; i++) {
    LoggerService.info('  ${i + 1}: ${lines[i]}');
  }
}
