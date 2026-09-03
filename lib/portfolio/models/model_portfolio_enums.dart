/// Model portfolio lifecycle — maps to backend `status` where applicable.
enum ModelPortfolioStatus {
  draft,
  underReview,
  published,
  active,
  archived;

  String get label {
    switch (this) {
      case ModelPortfolioStatus.draft:
        return 'Draft';
      case ModelPortfolioStatus.underReview:
        return 'Under Review';
      case ModelPortfolioStatus.published:
        return 'Published';
      case ModelPortfolioStatus.active:
        return 'Active';
      case ModelPortfolioStatus.archived:
        return 'Archived';
    }
  }

  static ModelPortfolioStatus fromApi(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return ModelPortfolioStatus.active;
      case 'published':
        return ModelPortfolioStatus.published;
      case 'under_review':
        return ModelPortfolioStatus.underReview;
      case 'archived':
        return ModelPortfolioStatus.archived;
      default:
        return ModelPortfolioStatus.draft;
    }
  }

  String toApiStatus() {
    switch (this) {
      case ModelPortfolioStatus.draft:
        return 'draft';
      case ModelPortfolioStatus.underReview:
        return 'under_review';
      case ModelPortfolioStatus.published:
      case ModelPortfolioStatus.active:
        return 'active';
      case ModelPortfolioStatus.archived:
        return 'archived';
    }
  }
}

enum ModelAssetType {
  stock,
  etf,
  bond,
  reit,
  gold,
  cash,
  commodity,
  other;

  String get label {
    switch (this) {
      case ModelAssetType.stock:
        return 'Stock';
      case ModelAssetType.etf:
        return 'ETF';
      case ModelAssetType.bond:
        return 'Bond';
      case ModelAssetType.reit:
        return 'REIT';
      case ModelAssetType.gold:
        return 'Gold';
      case ModelAssetType.cash:
        return 'Cash';
      case ModelAssetType.commodity:
        return 'Commodity';
      case ModelAssetType.other:
        return 'Other';
    }
  }

  static ModelAssetType fromLabel(String? value) {
    if (value == null) return ModelAssetType.stock;
    final lower = value.toLowerCase();
    for (final t in ModelAssetType.values) {
      if (t.label.toLowerCase() == lower || t.name == lower) return t;
    }
    return ModelAssetType.other;
  }
}

enum ModelConviction {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case ModelConviction.low:
        return 'Low';
      case ModelConviction.medium:
        return 'Medium';
      case ModelConviction.high:
        return 'High';
    }
  }

  static ModelConviction fromLabel(String? value) {
    switch (value?.toLowerCase()) {
      case 'low':
        return ModelConviction.low;
      case 'high':
        return ModelConviction.high;
      default:
        return ModelConviction.medium;
    }
  }
}

/// Nominal capital for display-side amount math in the builder UI.
const double kModelNominalCapital = 100.0;

/// Capital sent to portfolio APIs so quantity × price / capital ≈ allocation %.
/// The legacy $100 value caused the backend to recalculate % as stock price (e.g. 325%).
const double kModelApiNominalCapital = 1000000.0;

/// Marker client name for model portfolios (not customer assignments).
const String kModelPortfolioClientMarker = '__MODEL__';
