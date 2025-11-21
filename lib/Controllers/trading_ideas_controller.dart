import 'dart:convert';
import 'package:get/get.dart';
import 'package:musaffa_terminal/web_service.dart';

/// Valid recommendation actions for a trading idea
const List<String> kTradingIdeaActions = [
  'Buy',
  'Sell',
  'Hold',
  'Reduce',
  'Add',
];

/// Domain model for a trading idea entry coming from the API
class TradingIdea {
  final String id;
  final String name;
  final String title;
  final String company;
  final String ticker;
  final String action;
  final num target;
  final num current;
  final List<String> supportingReports;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TradingIdea({
    required this.id,
    required this.name,
    required this.title,
    required this.company,
    required this.ticker,
    required this.action,
    required this.target,
    required this.current,
    required this.supportingReports,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TradingIdea.fromJson(Map<String, dynamic> json) {
    return TradingIdea(
      id: json['id'] ?? '',
      name: json['name'] ?? '--',
      title: json['title'] ?? '--',
      company: json['company'] ?? '--',
      ticker: json['ticker'] ?? '--',
      action: json['action'] ?? '--',
      target: json['target'] ?? 0,
      current: json['current'] ?? 0,
      supportingReports: (json['supporting_reports'] as List<dynamic>?)
              ?.map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'company': company,
      'ticker': ticker,
      'action': action,
      'target': target,
      'current': current,
      'supporting_reports': supportingReports,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Payload used when creating a new trading idea
class CreateTradingIdeaRequest {
  final String name;
  final String title;
  final String company;
  final String ticker;
  final String action;
  final num target;
  final num current;
  final List<String> supportingReports;

  CreateTradingIdeaRequest({
    required this.name,
    required this.title,
    required this.company,
    required this.ticker,
    required this.action,
    required this.target,
    required this.current,
    required this.supportingReports,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'title': title,
      'company': company,
      'ticker': ticker,
      'action': action,
      'target': target,
      'current': current,
      'supporting_reports': supportingReports,
    };
  }
}

/// Controller responsible for fetching and creating trading ideas
class TradingIdeasController extends GetxController {
  TradingIdeasController({String? baseUrl})
      : _baseUrl = baseUrl ?? 'http://localhost:3000';

  final String _baseUrl;
  final RxList<TradingIdea> ideas = <TradingIdea>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isSubmitting = false.obs;
  final RxString submitError = ''.obs;
  final RxInt totalIdeas = 0.obs;
  final RxMap<String, IdeaTickerMeta> tickerMeta = <String, IdeaTickerMeta>{}.obs;

  /// Fetch all trading ideas from the backend
  Future<void> fetchTradingIdeas({bool force = false}) async {
    if (isLoading.value && !force) return;
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await WebService.callApi(
        method: HttpMethod.GET,
        path: ['trading-ideas'],
        baseUrl: _baseUrl,
      );

      if (response.status == ApiStatus.SUCCESS && response.data != null) {
        final decoded = jsonDecode(response.data!) as Map<String, dynamic>;
        if (decoded['status'] == 'success') {
          final List<dynamic> data = decoded['data'] ?? [];
          final fetchedIdeas =
              data.map((item) => TradingIdea.fromJson(item)).toList();
          ideas.assignAll(fetchedIdeas);
          totalIdeas.value = decoded['count'] ?? fetchedIdeas.length;
          await _fetchTickerMetadata(fetchedIdeas);
        } else {
          errorMessage.value = decoded['message'] ?? 'Unable to load ideas.';
        }
      } else {
        final decoded = _tryDecode(response.data);
        errorMessage.value = decoded?['message'] ??
            response.errorMessage ??
            'Failed to load trading ideas.';
      }
    } catch (e) {
      errorMessage.value = 'Unable to load trading ideas.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Create a new trading idea entry via the API
  Future<bool> createTradingIdea(CreateTradingIdeaRequest payload) async {
    if (!kTradingIdeaActions.contains(payload.action)) {
      submitError.value = 'Invalid action selected.';
      return false;
    }

    isSubmitting.value = true;
    submitError.value = '';

    try {
      final response = await WebService.callApi(
        method: HttpMethod.POST,
        path: ['trading-ideas'],
        body: payload.toJson(),
        baseUrl: _baseUrl,
      );

      if (response.status == ApiStatus.SUCCESS && response.data != null) {
        final decoded = jsonDecode(response.data!) as Map<String, dynamic>;
        if (decoded['status'] == 'success') {
          final idea = TradingIdea.fromJson(decoded['data']);
          ideas.insert(0, idea);
          totalIdeas.value += 1;
          await _fetchTickerMetadata([idea], append: true);
          return true;
        } else {
          submitError.value = decoded['message'] ?? 'Unable to add idea.';
        }
      } else {
        final decoded = _tryDecode(response.data);
        submitError.value =
            decoded?['message'] ?? response.errorMessage ?? 'Unable to add idea.';
      }
    } catch (e) {
      submitError.value = 'Network error while creating idea.';
    } finally {
      isSubmitting.value = false;
    }

    return false;
  }
  Map<String, dynamic>? _tryDecode(String? data) {
    if (data == null || data.isEmpty) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchTickerMetadata(List<TradingIdea> ideaList,
      {bool append = false}) async {
    final uniqueTickers = ideaList
        .map((idea) => idea.ticker)
        .where((ticker) => ticker.isNotEmpty)
        .toSet();

    if (uniqueTickers.isEmpty) return;

    final filter = uniqueTickers.map((t) => '`$t`').join(',');

    try {
      final response = await WebService.getTypesense([
        'collections',
        'company_profile_collection_new',
        'documents',
        'search'
      ], {
        'q': '*',
        'filter_by': 'id:=[${filter}]',
        'include_fields': 'id,name,company_symbol,logo',
        'per_page': uniqueTickers.length.toString(),
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final hits = decoded['hits'] as List<dynamic>? ?? [];
        final updated = Map<String, IdeaTickerMeta>.from(tickerMeta);

        for (final hit in hits) {
          final document =
              (hit['document'] as Map?)?.cast<String, dynamic>() ?? {};
          final id = document['id']?.toString() ?? '';
          if (id.isEmpty) continue;

          updated[id] = IdeaTickerMeta(
            ticker: id,
            companyName: document['name']?.toString() ??
                document['company_symbol']?.toString(),
            logo: document['logo']?.toString(),
          );
        }
        tickerMeta.assignAll(updated);
      }
    } catch (_) {
      // Silently ignore metadata errors
    }
  }
}

class IdeaTickerMeta {
  final String ticker;
  final String? companyName;
  final String? logo;

  IdeaTickerMeta({required this.ticker, this.companyName, this.logo});
}

