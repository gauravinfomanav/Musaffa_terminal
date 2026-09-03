import 'package:musaffa_terminal/portfolio/models/model_portfolio_holding.dart';
import 'package:musaffa_terminal/services/company_enrichment_cache.dart';

/// Fetches logo, sector, and market cap from Typesense (same source as ticker detail).
Future<void> enrichModelPortfolioHoldings(
  Iterable<ModelPortfolioHolding> holdings,
) async {
  if (holdings.isEmpty) return;

  final searchable = holdings.where(
    (h) => ModelPortfolioHolding.isSearchableAsset(h.assetType),
  );
  if (searchable.isEmpty) return;

  await CompanyEnrichmentCache.ensureForHoldings(searchable);
  for (final holding in searchable) {
    final enrichment = CompanyEnrichmentCache.getCached(holding.ticker);
    if (enrichment != null) {
      holding.applyEnrichment(enrichment);
    }
  }
}
