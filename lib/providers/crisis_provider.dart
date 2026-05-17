import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/crisis_models.dart';

class CrisisProvider extends ChangeNotifier {
  bool isLoading = false;
  String status = 'idle'; // idle, scanning, analyzing, done, error
  PipelineResult? result;
  String? errorMessage;

  // Live scanning feedback
  String scanMessage = '';
  List<String> scanLog = [];

  void _updateScan(String msg) {
    scanMessage = msg;
    scanLog.add(msg);
    notifyListeners();
  }

  void clearScanLog() {
    scanLog.clear();
    notifyListeners();
  }

  Future<void> analyze(List<dynamic> inputs) async {
    isLoading = true;
    status = 'analyzing';
    scanMessage = '📡 Initializing signal collection...';
    scanLog = [scanMessage];
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    scanMessage = '🔍 Signal Collector agent activated...';
    scanLog.add(scanMessage);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));
    scanMessage = '🧠 Sending signals to Crisis Detector...';
    scanLog.add(scanMessage);
    notifyListeners();

    try {
      final response = await ApiService.analyzeCrisis(inputs);
      
      scanMessage = '📋 Response Planner generating actions...';
      scanLog.add(scanMessage);
      notifyListeners();
      
      await Future.delayed(const Duration(milliseconds: 600));
      scanMessage = '⚡ Action Executor simulating response...';
      scanLog.add(scanMessage);
      notifyListeners();
      
      await Future.delayed(const Duration(milliseconds: 600));
      
      if (response.containsKey('error')) {
        errorMessage = response['error'];
        status = 'error';
        scanMessage = '❌ Analysis failed. Using demo data...';
      } else {
        result = PipelineResult.fromApiResponse(response);
        status = 'done';
        scanMessage = '✅ Crisis analysis complete.';
      }
      scanLog.add(scanMessage);
    } catch (e) {
      errorMessage = e.toString();
      status = 'error';
      scanMessage = '❌ Connection error. Check backend.';
      scanLog.add(scanMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> autoScan() async {
    isLoading = true;
    status = 'scanning';
    errorMessage = null;
    scanMessage = '';
    scanLog = [];
    notifyListeners();

    _updateScan('📡 Connecting to news feeds...');
    await Future.delayed(const Duration(milliseconds: 800));

    _updateScan('🌐 Scanning Dawn, Geo, ARY, Express Tribune...');
    await Future.delayed(const Duration(milliseconds: 1200));

    _updateScan('🔍 Signal Collector agent activated...');
    await Future.delayed(const Duration(milliseconds: 500));

    _updateScan('🧠 Calling RAHAT pipeline...');
    final response = await ApiService.autoScan();

    if (response.containsKey('error')) {
      errorMessage = response['error'];
      status = 'error';
      _updateScan('❌ Error: ${response['error']}');
    } else {
      final resStatus = response['status'];
      if (resStatus == 'crisis_detected_and_processed') {
        _updateScan('🧠 Crisis Detector analyzing patterns...');
        await Future.delayed(const Duration(milliseconds: 800));

        _updateScan('📋 Response Planner generating actions...');
        await Future.delayed(const Duration(milliseconds: 800));

        _updateScan('⚡ Action Executor simulating response...');
        await Future.delayed(const Duration(milliseconds: 800));

        try {
          final pipelineData = response['pipeline_result'] ?? {};
          result = PipelineResult.fromApiResponse(pipelineData);
          status = 'done';
          _updateScan('✅ Analysis complete. Crisis detected.');
        } catch (e) {
          errorMessage = 'Failed to parse response: ${e.toString()}';
          status = 'error';
          _updateScan('❌ Parse error: ${e.toString()}');
        }
      } else if (resStatus == 'no_crisis_found') {
        status = 'idle';
        errorMessage = 'No critical crises found during scan.';
        _updateScan('✅ Scan complete. No crisis detected.');
      } else {
        errorMessage = 'Unexpected scan status: $resStatus';
        status = 'error';
        _updateScan('❌ Unexpected status: $resStatus');
      }
    }

    isLoading = false;
    notifyListeners();
  }

  void reset() {
    result = null;
    status = 'idle';
    isLoading = false;
    scanMessage = '';
    scanLog.clear();
    errorMessage = null;
    notifyListeners();
  }
}
