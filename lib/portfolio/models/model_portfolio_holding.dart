import 'package:musaffa_terminal/models/portfolio_model.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_enums.dart';
import 'package:musaffa_terminal/services/company_enrichment_cache.dart';

class ModelPortfolioHolding {
  String? id;
  String ticker;
  String? company;
  String? exchange;
  String? sector;
  ModelAssetType assetType;
  double? currentPrice;
  double targetPercent;
  double? marketCap;
  ModelConviction conviction;
  String status;
  String? investmentThesis;
  String? riskNotes;
  String? bullCase;
  String? bearCase;
  DateTime? reviewDate;
  String? reasonForSelection;
  TickerModel? tickerModel;

  ModelPortfolioHolding({
    this.id,
    required this.ticker,
    this.company,
    this.exchange,
    this.sector,
    this.assetType = ModelAssetType.stock,
    this.currentPrice,
    this.targetPercent = 0,
    this.marketCap,
    this.conviction = ModelConviction.medium,
    this.status = 'Active',
    this.investmentThesis,
    this.riskNotes,
    this.bullCase,
    this.bearCase,
    this.reviewDate,
    this.reasonForSelection,
    this.tickerModel,
  });

  factory ModelPortfolioHolding.fromPortfolioHolding(PortfolioHolding h) {
    return ModelPortfolioHolding(
      id: h.id,
      ticker: h.ticker,
      company: h.company,
      exchange: h.exchange,
      sector: h.sector,
      assetType: ModelAssetType.fromLabel(h.assetType),
      currentPrice: h.currentPrice,
      targetPercent: h.allocationPercent,
      marketCap: h.marketCap,
      conviction: ModelConviction.fromLabel(h.conviction),
      status: h.holdingStatus ?? 'Active',
      investmentThesis: h.investmentThesis,
      riskNotes: h.riskNotes,
      bullCase: h.bullCase,
      bearCase: h.bearCase,
      reviewDate: h.reviewDate,
      reasonForSelection: h.reasonForSelection,
    );
  }

  PortfolioHolding toApiHolding() {
    final price = currentPrice ?? 0.0;
    final amount = (targetPercent * kModelApiNominalCapital) / 100.0;
    final qty = price > 0 ? (amount / price).round() : 0;
    final targetPrice = price > 0 ? price * 1.1 : 1.0;

    return PortfolioHolding(
      id: id,
      ticker: ticker,
      company: company,
      exchange: exchange,
      sector: sector,
      currentPrice: price > 0 ? price : 1.0,
      targetPrice: targetPrice,
      quantity: qty,
      allocationPercent: targetPercent,
      allocationAmount: amount,
      marketCap: marketCap,
      peRatio: null,
      notes: investmentThesis,
      assetType: assetType.label,
      conviction: conviction.label,
      holdingStatus: status,
      investmentThesis: investmentThesis,
      riskNotes: riskNotes,
      bullCase: bullCase,
      bearCase: bearCase,
      reviewDate: reviewDate,
      reasonForSelection: reasonForSelection,
    );
  }

  void applyTicker(TickerModel model) {
    tickerModel = model;
    ticker = model.symbol ?? model.ticker ?? ticker;
    company = model.companyName ?? model.name ?? company;
    exchange = model.exchange ?? exchange;
    sector = model.sectorname ?? sector;
    currentPrice = model.currentPrice?.toDouble();
  }

  /// Applies cached Typesense enrichment (logo, sector, market cap, price).
  void applyEnrichment(CompanyEnrichment enrichment) {
    if (enrichment.name != null &&
        (company == null || company!.trim().isEmpty)) {
      company = enrichment.name;
    }

    if (enrichment.sector != null &&
        (sector == null || sector!.trim().isEmpty)) {
      sector = enrichment.sector;
    }

    if (enrichment.currentPrice != null &&
        (currentPrice == null || currentPrice! <= 0)) {
      currentPrice = enrichment.currentPrice!.toDouble();
    }

    if (enrichment.isEtfAsset) {
      if (enrichment.aum != null &&
          (marketCap == null || marketCap! <= 0)) {
        marketCap = enrichment.aum!.toDouble();
      }
    } else if (enrichment.marketCap != null &&
        (marketCap == null || marketCap! <= 0)) {
      marketCap = enrichment.marketCap!.toDouble();
    }

    final logo = enrichment.logo;
    if (logo == null || logo.trim().isEmpty) return;

    final isEtf = assetType == ModelAssetType.etf ||
        tickerModel?.isStock == false ||
        enrichment.isEtfAsset;

    if (tickerModel == null) {
      tickerModel = TickerModel(
        symbol: ticker,
        ticker: ticker,
        companyName: company,
        logo: logo,
        isStock: !isEtf,
      );
      return;
    }

    if (tickerModel!.logo == null || tickerModel!.logo!.trim().isEmpty) {
      tickerModel!.logo = logo;
    }
  }

  static ModelPortfolioHolding fromTicker(
    TickerModel model, {
    double targetPercent = 0,
  }) {
    final symbol = model.symbol ?? model.ticker ?? '';
    final holding = ModelPortfolioHolding(
      ticker: symbol,
      targetPercent: targetPercent,
      assetType:
          model.isStock ? ModelAssetType.stock : ModelAssetType.etf,
    );
    holding.applyTicker(model);
    return holding;
  }

  static ModelPortfolioHolding manualAsset({
    required ModelAssetType type,
    required String name,
    required Iterable<ModelPortfolioHolding> existing,
    double targetPercent = 0,
  }) {
    return ModelPortfolioHolding(
      ticker: manualTickerFor(type, name, existing),
      company: name,
      assetType: type,
      targetPercent: targetPercent,
    );
  }

  static bool isSearchableAsset(ModelAssetType type) {
    return type == ModelAssetType.stock || type == ModelAssetType.etf;
  }

  static String manualTickerFor(
    ModelAssetType type,
    String name,
    Iterable<ModelPortfolioHolding> existing,
  ) {
    final prefix = switch (type) {
      ModelAssetType.cash => 'CASH',
      ModelAssetType.reit => 'REIT',
      ModelAssetType.gold => 'GOLD',
      ModelAssetType.bond => 'BOND',
      ModelAssetType.commodity => 'CMDTY',
      ModelAssetType.other => 'OTHER',
      _ => 'ASSET',
    };

    final slug = name
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    var candidate = slug.isNotEmpty ? '$prefix-$slug' : prefix;
    var suffix = 2;
    while (existing.any(
      (h) => h.ticker.trim().toUpperCase() == candidate.toUpperCase(),
    )) {
      candidate = '$prefix-$suffix';
      suffix++;
    }
    return candidate;
  }
}
