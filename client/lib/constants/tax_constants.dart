/// Static tax categories and subcategories for the tax form dropdowns.
const List<String> taxCategories = [
  'Consumption Taxes',
  'Excise & Special Product Tax',
  'TRADE TAXES (Cross-Border)',
  'ENVIRONMENTAL & REGULATORY TAXES',
  'DIGITAL & MODERN PRODUCT TAXES',
  'Other',
];

/// Subcategories per category (key = category string).
/// Empty list means no subcategory; use a placeholder when displaying.
const Map<String, List<String>> taxSubCategoriesByCategory = {
  'Consumption Taxes': [
    'Value Added Tax (VAT)',
    'Goods & Services Tax (GST)',
    'Sales Tax',
    'Turnover Tax',
  ],
  'Excise & Special Product Tax': [
    'Alcohol Taxes',
    'Tobacco Taxes',
    'Fuel & Energy Taxes',
    'Luxury Taxes',
    'Carbon & Environmental Consumption',
  ],
  'TRADE TAXES (Cross-Border)': [
    'Import Duties',
    'Export Duties',
    'Protective Duties',
  ],
  'ENVIRONMENTAL & REGULATORY TAXES': [
    'Carbon Tax',
    'Plastic Tax',
    'Environmental Levy',
    'Regulatory Fee',
    'Other',
  ],
  'DIGITAL & MODERN PRODUCT TAXES': [], // no subcategory
  'Other': ['Other'],
};
