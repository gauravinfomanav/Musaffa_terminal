/// Locked feature keys from backend Admin → Manage features.
/// Do not rename or invent new keys on the client.
class FeatureKeys {
  FeatureKeys._();

  static const watchlists = 'watchlists';
  static const screener = 'screener';
  static const tradingIdeas = 'trading_ideas';
  static const portfolios = 'portfolios';
  static const stockSearch = 'stock_search';
  static const heatmaps = 'heatmaps';
  static const sectorDetails = 'sector_details';
  static const tickerDetails = 'ticker_details';
  static const etfDetails = 'etf_details';
  static const shariahCompliance = 'shariah_compliance';

  static const List<String> all = [
    watchlists,
    screener,
    tradingIdeas,
    portfolios,
    stockSearch,
    heatmaps,
    sectorDetails,
    tickerDetails,
    etfDetails,
    shariahCompliance,
  ];

  static String displayName(String key) {
    switch (key) {
      case watchlists:
        return 'Watchlists';
      case screener:
        return 'Stock Screener';
      case tradingIdeas:
        return 'Trading Ideas';
      case portfolios:
        return 'Portfolios';
      case stockSearch:
        return 'Stock Search';
      case heatmaps:
        return 'Market Heatmaps';
      case sectorDetails:
        return 'Sector Details';
      case tickerDetails:
        return 'Stock Details';
      case etfDetails:
        return 'ETF Details';
      case shariahCompliance:
        return 'Shariah Compliance';
      default:
        return key;
    }
  }
}
