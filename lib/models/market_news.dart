class MarketNews {
  String? category;
  int? datetime;
  String? headline;
  int? iD;
  String? image;
  String? source;
  String? summary;
  String? uRL;
  String? id;

  MarketNews({
    this.category,
    this.datetime,
    this.headline,
    this.iD,
    this.image,
    this.source,
    this.summary,
    this.uRL,
    this.id,
  });

  MarketNews.fromJson(Map<String, dynamic> json) {
    category = json['Category'];
    datetime = json['Datetime'];
    headline = json['Headline'];
    iD = json['ID'];
    image = json['Image'];
    source = json['Source'];
    summary = json['Summary'];
    uRL = json['URL'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Category'] = category;
    data['Datetime'] = datetime;
    data['Headline'] = headline;
    data['ID'] = iD;
    data['Image'] = image;
    data['Source'] = source;
    data['Summary'] = summary;
    data['URL'] = uRL;
    data['id'] = id;
    return data;
  }
}
