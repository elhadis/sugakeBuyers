const Map<String, String> countryToCurrency = {
  'Saudi Arabia': 'SAR',
  'UAE': 'AED',
  'Qatar': 'QAR',
  'Kuwait': 'KWD',
  'Turkey': 'TRY',
  'Egypt': 'EGP',
  'Sudan': 'SDG',
  'Morocco': 'MAD',
  'Kenya': 'KES',
  'Uganda': 'UGX',
  'Ethiopia': 'ETB',
  'Rwanda': 'RWF',
  'UK': 'GBP',
  'France': 'EUR',
  'Germany': 'EUR',
  'Netherlands': 'EUR',
  'Italy': 'EUR',
  'Spain': 'EUR',
  'USA': 'USD',
  'Canada': 'CAD',
  'India': 'INR',
  'Libya': 'LYD',
};

List<String> getCountryNamesSorted() {
  final names = countryToCurrency.keys.toList()..sort();
  return names;
}

String currencyCodeForCountry(String country) {
  return countryToCurrency[country] ?? 'USD';
}
