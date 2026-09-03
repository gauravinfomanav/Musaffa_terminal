import 'dart:convert';

import 'package:get/get.dart';
import 'package:musaffa_terminal/models/customer_model.dart';
import 'package:musaffa_terminal/models/portfolio_assignment_model.dart';
import 'package:musaffa_terminal/web_service.dart';

class PortfolioAssignmentController extends GetxController {
  final RxList<PortfolioAssignmentSummary> activeAssignments =
      <PortfolioAssignmentSummary>[].obs;
  final RxList<PortfolioAssignmentSummary> draftAssignments =
      <PortfolioAssignmentSummary>[].obs;
  final RxList<Customer> customers = <Customer>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString saveError = ''.obs;

  Future<void> fetchAssignments({String? status}) async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';

    try {
      if (status == null || status == 'active') {
        activeAssignments.value = await _fetchAssignmentList('active');
      }
      if (status == null || status == 'draft') {
        draftAssignments.value = await _fetchAssignmentList('draft');
      }
    } catch (e) {
      errorMessage.value = 'Error loading assignments: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<PortfolioAssignmentSummary>> _fetchAssignmentList(
    String status,
  ) async {
    final response = await WebService.callApi(
      method: HttpMethod.GET,
      path: ['api', 'portfolio-assignments'],
      params: {'status': status, 'limit': '50'},
    );

    if (response.status == ApiStatus.SUCCESS && response.data != null) {
      final jsonData = jsonDecode(response.data!);
      final data = jsonData['data'] as Map<String, dynamic>? ?? {};
      final list = data['assignments'] as List<dynamic>? ?? [];
      return list
          .map(
            (e) => PortfolioAssignmentSummary.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    errorMessage.value =
        _messageFrom(response) ?? 'Failed to load assignments';
    return [];
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final response = await WebService.callApi(
      method: HttpMethod.GET,
      path: ['api', 'customers'],
      params: {
        if (query.trim().isNotEmpty) 'search': query.trim(),
        'limit': '20',
      },
    );

    if (response.status == ApiStatus.SUCCESS && response.data != null) {
      final jsonData = jsonDecode(response.data!);
      final data = jsonData['data'] as Map<String, dynamic>? ?? {};
      final list = data['customers'] as List<dynamic>? ?? [];
      final parsed = list
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList();
      customers.value = parsed;
      return parsed;
    }

    return [];
  }

  Future<Customer?> createCustomer({
    required String fullName,
    String? email,
    String? phone,
    String currency = 'USD',
  }) async {
    final response = await WebService.callApi(
      method: HttpMethod.POST,
      path: ['api', 'customers'],
      body: {
        'full_name': fullName.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        'currency': currency,
      },
    );

    if (response.status == ApiStatus.SUCCESS && response.data != null) {
      final jsonData = jsonDecode(response.data!);
      if (jsonData['status'] == 'success' && jsonData['data'] != null) {
        final customer =
            Customer.fromJson(jsonData['data'] as Map<String, dynamic>);
        customers.insert(0, customer);
        return customer;
      }
    }

    saveError.value = _messageFrom(response) ?? 'Failed to create customer';
    return null;
  }

  Future<AssignmentPreview?> previewAssignment({
    required String modelPortfolioId,
    required double investmentAmount,
    String currency = 'USD',
  }) async {
    final response = await WebService.callApi(
      method: HttpMethod.POST,
      path: ['api', 'portfolio-assignments', 'preview'],
      body: {
        'model_portfolio_id': modelPortfolioId,
        'investment_amount': investmentAmount,
        'currency': currency,
      },
    );

    if (response.status == ApiStatus.SUCCESS && response.data != null) {
      final jsonData = jsonDecode(response.data!);
      if (jsonData['status'] == 'success' && jsonData['data'] != null) {
        return AssignmentPreview.fromJson(
          jsonData['data'] as Map<String, dynamic>,
        );
      }
    }

    saveError.value = _messageFrom(response) ?? 'Failed to preview assignment';
    return null;
  }

  Future<PortfolioAssignment?> createAssignment({
    required String modelPortfolioId,
    required String customerId,
    required double investmentAmount,
    String currency = 'USD',
    String status = 'active',
    String? analystNotes,
  }) async {
    if (isSaving.value) return null;
    isSaving.value = true;
    saveError.value = '';

    try {
      final response = await WebService.callApi(
        method: HttpMethod.POST,
        path: ['api', 'portfolio-assignments'],
        body: {
          'model_portfolio_id': modelPortfolioId,
          'customer_id': customerId,
          'investment_amount': investmentAmount,
          'currency': currency,
          'status': status,
          if (analystNotes != null && analystNotes.isNotEmpty)
            'analyst_notes': analystNotes,
        },
      );

      if (response.status == ApiStatus.SUCCESS && response.data != null) {
        final jsonData = jsonDecode(response.data!);
        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          final assignment = PortfolioAssignment.fromJson(
            jsonData['data'] as Map<String, dynamic>,
          );
          await fetchAssignments();
          isSaving.value = false;
          return assignment;
        }
      }

      saveError.value =
          _messageFrom(response) ?? 'Failed to create assignment';
      isSaving.value = false;
      return null;
    } catch (e) {
      saveError.value = 'Error creating assignment: $e';
      isSaving.value = false;
      return null;
    }
  }

  Future<PortfolioAssignment?> getAssignment(String id) async {
    final response = await WebService.callApi(
      method: HttpMethod.GET,
      path: ['api', 'portfolio-assignments', id],
    );

    if (response.status == ApiStatus.SUCCESS && response.data != null) {
      final jsonData = jsonDecode(response.data!);
      if (jsonData['status'] == 'success' && jsonData['data'] != null) {
        return PortfolioAssignment.fromJson(
          jsonData['data'] as Map<String, dynamic>,
        );
      }
    }

    errorMessage.value =
        _messageFrom(response) ?? 'Failed to load assignment';
    return null;
  }

  Future<bool> activateAssignment(String id) async {
    final response = await WebService.callApi(
      method: HttpMethod.POST,
      path: ['api', 'portfolio-assignments', id, 'activate'],
    );
    if (response.status == ApiStatus.SUCCESS) {
      await fetchAssignments();
      return true;
    }
    errorMessage.value =
        _messageFrom(response) ?? 'Failed to activate assignment';
    return false;
  }

  Future<bool> deleteAssignment(String id) async {
    final response = await WebService.callApi(
      method: HttpMethod.DELETE,
      path: ['api', 'portfolio-assignments', id],
    );
    if (response.status == ApiStatus.SUCCESS) {
      await fetchAssignments();
      return true;
    }
    errorMessage.value =
        _messageFrom(response) ?? 'Failed to archive assignment';
    return false;
  }

  String? _messageFrom(ApiResponse response) {
    if (response.data != null && response.data!.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.data!);
        if (decoded is Map && decoded['message'] is String) {
          return decoded['message'] as String;
        }
      } catch (_) {}
    }
    return response.errorMessage;
  }
}
