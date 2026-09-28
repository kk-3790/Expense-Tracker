/// ISO 18245 Merchant Category Codes (MCC) to Expense Category Mapping
/// and merchant name fallback keyword matcher.
class MccData {
  /// Map of 4-digit MCC code to Category name and MCC description.
  static const Map<String, (String category, String description)> mccMap = {
    // -------------------------------------------------------------
    // FOOD & GROCERY
    // -------------------------------------------------------------
    '5411': ('Food', 'Grocery Stores, Supermarkets'),
    '5422': ('Food', 'Freezer and Locker Meat Provisioners'),
    '5441': ('Food', 'Candy, Nut, and Confectionery Stores'),
    '5451': ('Food', 'Dairy Products Stores'),
    '5462': ('Food', 'Bakeries'),
    '5499': ('Food', 'Miscellaneous Food Stores, Markets & Convenience'),
    '5811': ('Food', 'Caterers'),
    '5812': ('Food', 'Eating Places, Restaurants'),
    '5813': ('Food', 'Drinking Places (Bars, Taverns, Lounges)'),
    '5814': ('Food', 'Fast Food Restaurants'),

    // -------------------------------------------------------------
    // TRANSPORTATION & FUEL
    // -------------------------------------------------------------
    '4011': ('Transport', 'Railroads - Freight'),
    '4111': ('Transport', 'Local Commuter Passenger Transportation, Ferries'),
    '4112': ('Transport', 'Passenger Railways'),
    '4121': ('Transport', 'Taxicabs, Limousines & Rideshare'),
    '4131': ('Transport', 'Bus Lines'),
    '4411': ('Transport', 'Cruise Lines'),
    '4511': ('Transport', 'Airlines, Air Carriers'),
    '4784': ('Transport', 'Tolls and Bridge Fees, FASTag'),
    '4789': ('Transport', 'Transportation Services (General)'),
    '5511': ('Transport', 'Car & Truck Dealers (Sales & Service)'),
    '5521': ('Transport', 'Automobile Dealers (Used Only)'),
    '5533': ('Transport', 'Automotive Parts and Accessories Stores'),
    '5541': ('Transport', 'Service Stations, Fuel & Petrol Pumps'),
    '5542': ('Transport', 'Automated Fuel Dispensers'),
    '7512': ('Transport', 'Automobile Rental Agency'),
    '7523': ('Transport', 'Parking Lots and Garages'),
    '7538': ('Transport', 'Auto Service & Repair Shops'),

    // -------------------------------------------------------------
    // SHOPPING & RETAIL
    // -------------------------------------------------------------
    '5094': ('Shopping', 'Precious Stones, Metals, Watches & Jewelry'),
    '5300': ('Shopping', 'Wholesale Clubs'),
    '5310': ('Shopping', 'Discount Department Stores'),
    '5311': ('Shopping', 'Department Stores'),
    '5331': ('Shopping', 'Variety Stores'),
    '5399': ('Shopping', 'General Merchandise Stores'),
    '5611': ('Shopping', 'Men\'s and Boys\' Clothing & Accessories'),
    '5621': ('Shopping', 'Women\'s Ready-to-Wear Stores'),
    '5631': ('Shopping', 'Women\'s Accessory & Specialty Stores'),
    '5641': ('Shopping', 'Children\'s and Infant\'s Wear Stores'),
    '5651': ('Shopping', 'Family Clothing Stores'),
    '5661': ('Shopping', 'Shoe Stores'),
    '5691': ('Shopping', 'Men\'s and Women\'s Clothing Stores'),
    '5699': ('Shopping', 'Miscellaneous Apparel & Accessories'),
    '5712': ('Shopping', 'Furniture & Home Furnishings'),
    '5722': ('Shopping', 'Household Appliance Stores'),
    '5732': ('Shopping', 'Electronics Sales'),
    '5734': ('Shopping', 'Computer Software Stores'),
    '5941': ('Shopping', 'Sporting Goods Stores'),
    '5944': ('Shopping', 'Jewelry Stores, Clocks & Silverware'),
    '5945': ('Shopping', 'Hobby, Toy, and Game Shops'),
    '5946': ('Shopping', 'Camera & Photographic Supply Stores'),
    '5947': ('Shopping', 'Gift, Novelty, and Souvenir Shops'),
    '5948': ('Shopping', 'Luggage and Leather Goods Stores'),
    '5977': ('Shopping', 'Cosmetic Stores'),
    '5999': ('Shopping', 'Miscellaneous Retail & Specialty Stores'),

    // -------------------------------------------------------------
    // BILLS & UTILITIES
    // -------------------------------------------------------------
    '4812': ('Bills', 'Telecommunications Equipment'),
    '4814': ('Bills', 'Telecommunication & Mobile Services'),
    '4899': ('Bills', 'Cable, Broadband & Pay TV Services'),
    '4900': ('Bills', 'Electric, Gas, Water & Sanitary Utilities'),
    '6300': ('Bills', 'Insurance Underwriting & Premiums'),
    '9311': ('Bills', 'Tax Payments'),
    '9399': ('Bills', 'Government Services'),

    // -------------------------------------------------------------
    // ENTERTAINMENT
    // -------------------------------------------------------------
    '7832': ('Entertainment', 'Motion Picture Theaters, Cinema'),
    '7911': ('Entertainment', 'Dance Halls, Studios, and Schools'),
    '7922': ('Entertainment', 'Theatrical Producers & Ticket Agencies'),
    '7929': ('Entertainment', 'Bands, Orchestras & Entertainers'),
    '7932': ('Entertainment', 'Billiards & Pool Establishments'),
    '7933': ('Entertainment', 'Bowling Alleys'),
    '7941': ('Entertainment', 'Commercial Sports & Stadiums'),
    '7991': ('Entertainment', 'Tourist Attractions & Exhibits'),
    '7996': ('Entertainment', 'Amusement Parks, Carnivals & Arcades'),
    '7997': ('Entertainment', 'Clubs, Gyms & Athletic Fields'),
    '7999': ('Entertainment', 'Recreation & Gaming Services'),

    // -------------------------------------------------------------
    // HEALTH & MEDICAL
    // -------------------------------------------------------------
    '5912': ('Health', 'Drug Stores & Pharmacies'),
    '8011': ('Health', 'Doctors and Physicians'),
    '8021': ('Health', 'Dentists and Orthodontists'),
    '8031': ('Health', 'Osteopaths'),
    '8041': ('Health', 'Chiropractors'),
    '8042': ('Health', 'Optometrists and Ophthalmologists'),
    '8043': ('Health', 'Opticians, Optical Goods & Eyeglasses'),
    '8049': ('Health', 'Podiatrists and Chiropodists'),
    '8050': ('Health', 'Nursing & Personal Care Facilities'),
    '8062': ('Health', 'Hospitals'),
    '8071': ('Health', 'Medical and Dental Laboratories'),
    '8099': ('Health', 'Medical Services & Health Practitioners'),

    // -------------------------------------------------------------
    // EDUCATION
    // -------------------------------------------------------------
    '5942': ('Education', 'Book Stores'),
    '8211': ('Education', 'Elementary and Secondary Schools'),
    '8220': ('Education', 'Colleges, Universities & Professional Schools'),
    '8241': ('Education', 'Correspondence Schools'),
    '8244': ('Education', 'Business and Secretarial Schools'),
    '8249': ('Education', 'Vocational and Technical Schools'),
    '8299': ('Education', 'Educational Services & Tuitions'),
  };

  /// Returns (category, description) for a given MCC code if matched.
  static (String, String)? lookupMcc(String mcc) {
    final cleanMcc = mcc.trim();
    if (mccMap.containsKey(cleanMcc)) {
      return mccMap[cleanMcc];
    }
    return null;
  }

  /// Keyword lists for intelligent fallback when MCC code is not provided.
  static const Map<String, List<String>> keywordRules = {
    'Food': [
      'swiggy',
      'zomato',
      'restaurant',
      'cafe',
      'hotel',
      'bistro',
      'kitchen',
      'bakery',
      'food',
      'pizza',
      'burger',
      'tea',
      'coffee',
      'dhaba',
      'sweets',
      'supermarket',
      'mart',
      'grocery',
      'fruits',
      'vegetables',
      'kirana',
      'mcdonald',
      'subway',
      'domino',
      'starbucks',
      'chai',
      'biryani',
      'dining',
      'canteen',
      'snack',
      'bakers',
      'eat',
      'diner',
    ],
    'Transport': [
      'uber',
      'ola',
      'rapido',
      'metro',
      'rail',
      'irctc',
      'fuel',
      'petrol',
      'diesel',
      'gas',
      'hpcl',
      'bpcl',
      'ioc',
      'indian oil',
      'shell',
      'parking',
      'toll',
      'fastag',
      'taxi',
      'cab',
      'auto',
      'rickshaw',
      'travels',
      'transit',
    ],
    'Shopping': [
      'amazon',
      'flipkart',
      'myntra',
      'retail',
      'store',
      'cloth',
      'fashion',
      'mall',
      'shop',
      'electronics',
      'croma',
      'reliance digital',
      'zara',
      'h&m',
      'trends',
      'shopee',
      'bazaar',
      'jewel',
      'jeweller',
      'optics',
      'footwear',
      'shoes',
      'apparel',
      'outfit',
      'garments',
    ],
    'Bills': [
      'electricity',
      'bescom',
      'water',
      'broadband',
      'airtel',
      'jio',
      'vi',
      'vodafone',
      'recharge',
      'utility',
      'bill',
      'gas bill',
      'tneb',
      'cesc',
      'mahadiscom',
      'insurance',
      'lic',
      'postpaid',
      'wifi',
      'dth',
      'tatasky',
      'dish',
      'power',
    ],
    'Entertainment': [
      'cinema',
      'pvr',
      'inox',
      'movie',
      'theatre',
      'cinepolis',
      'netflix',
      'spotify',
      'game',
      'gaming',
      'club',
      'ticket',
      'amusement',
      'playstation',
      'carnival',
      'multiplex',
      'concert',
    ],
    'Health': [
      'pharmacy',
      'chemist',
      'apollo',
      'medplus',
      'hospital',
      'clinic',
      'doctor',
      'dentist',
      'lab',
      'diagnostic',
      'dr.',
      'healthcare',
      'pharma',
      'medical',
      'medicine',
      'care',
      'wellness',
    ],
    'Education': [
      'school',
      'college',
      'university',
      'classes',
      'tuition',
      'academy',
      'institute',
      'udemy',
      'coursera',
      'books',
      'stationary',
      'library',
      'coaching',
      'exam',
      'learning',
    ],
  };

  /// Fallback categorizer based on merchant name or UPI handle.
  static String? detectFromKeywords(String text) {
    final lower = text.toLowerCase();
    for (final entry in keywordRules.entries) {
      for (final kw in entry.value) {
        if (lower.contains(kw)) {
          return entry.key;
        }
      }
    }
    return null;
  }
}
