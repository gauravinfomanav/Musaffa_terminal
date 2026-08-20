
class ApiConfig {
  const ApiConfig._();

  // ── Musaffa Terminal backend (auth, watchlists, targets, FCM, etc.) ──

  /// Local default: `http://localhost:3000`
  /// Production: `https://terminal.musaffa.us`
  static const String terminalBaseUrl = String.fromEnvironment(
    'TERMINAL_API_URL',
    defaultValue: 'https://terminal.musaffa.us',
  );

  // ── RisePython data APIs ──

  static const String risePythonBaseUrl =
      'https://risepython.infomanav.in';

  static String risePythonFinancialStatements(String symbol) =>
      '$risePythonBaseUrl/8010/financial_statements/${symbol.trim().toUpperCase()}';

  static String risePythonCompanyBasicFinancials(String symbol) =>
      '$risePythonBaseUrl/8010/company_basic_financials/${symbol.trim().toUpperCase()}';

  static const String risePythonStockCandles =
      '$risePythonBaseUrl/8009/latest_stock_candles/';

  // ── WebSocket (live prices) ──

  static const String priceWebSocketUrl =
      'ws://risepython.infomanav.in:6003/ws/price';

  // ── Typesense (legacy Musaffa) ──

  static const String typesenseUrl =
      'https://0bs2hegi5nmtad4op.a1.typesense.net';
  static const String typesenseApiKey =
      'GRhZdTOnzVKId4Ln9G1PIvuIgn1TK0fH';

  // ── Typesense (Infomanav) ──

  static const String typesenseInfomanavUrl =
      'https://typesense.infomanav.in';
  static const String typesenseInfomanavApiKey =
      'v0R3WozafhWeECu5MVuKr6HPcXI0hLPh';

  // ── Infomanav Finnhub proxy ──

  static const String infomanavFinnhubProxyUrl =
      'https://beta.infomanav.in/keep/finnhub_api_dev/Typesense/px_master.php';

  // ── Musaffa compliance APIs ──

  static const String musaffaApiBaseUrl = 'https://api.musaffa.us';

  static const String novaComplianceHistoryDetailsUrl =
      'https://novalive-api.musaffa.us/v3/api/get_compliance_history_details';
}
