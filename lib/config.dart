const bool kUseMockData = true;
const String kBaseUrl = 'http://localhost:8000';

const List<Map<String, dynamic>> kZones = [
  {
    'label': 'Hebbal, Bengaluru', 'zone': 'Hebbal', 'city': 'Bengaluru',
    'tier': 'high', 'premium': 120.0, 'coverage': 2500.0, 'riskScore': 0.78,
    'rec': 'Indiranagar', 'boost': '+25%', 'boostReason': 'Higher order density',
    'city_key': 'Bengaluru', 'lat': 13.0450, 'lng': 77.5965,
  },
  {
    'label': 'Koramangala, Bengaluru', 'zone': 'Koramangala', 'city': 'Bengaluru',
    'tier': 'high', 'premium': 120.0, 'coverage': 2500.0, 'riskScore': 0.75,
    'rec': 'HSR Layout', 'boost': '+18%', 'boostReason': 'Better roads during rain',
    'city_key': 'Bengaluru', 'lat': 12.9352, 'lng': 77.6245,
  },
  {
    'label': 'Indiranagar, Bengaluru', 'zone': 'Indiranagar', 'city': 'Bengaluru',
    'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'riskScore': 0.55,
    'rec': 'Koramangala', 'boost': '+15%', 'boostReason': 'Stable corridor',
    'city_key': 'Bengaluru', 'lat': 12.9784, 'lng': 77.6408,
  },
  {
    'label': 'Whitefield, Bengaluru', 'zone': 'Whitefield', 'city': 'Bengaluru',
    'tier': 'low', 'premium': 60.0, 'coverage': 2000.0, 'riskScore': 0.32,
    'rec': null, 'boost': null, 'boostReason': null,
    'city_key': 'Bengaluru', 'lat': 12.9698, 'lng': 77.7499,
  },
  {
    'label': 'Kurla, Mumbai', 'zone': 'Kurla', 'city': 'Mumbai',
    'tier': 'high', 'premium': 115.0, 'coverage': 2460.0, 'riskScore': 0.80,
    'rec': 'Bandra', 'boost': '+22%', 'boostReason': 'Less waterlogging',
    'city_key': 'Mumbai', 'lat': 19.0728, 'lng': 72.8826,
  },
  {
    'label': 'Dharavi, Mumbai', 'zone': 'Dharavi', 'city': 'Mumbai',
    'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'riskScore': 0.55,
    'rec': 'Lower Parel', 'boost': '+15%', 'boostReason': 'Stable corridors',
    'city_key': 'Mumbai', 'lat': 19.0437, 'lng': 72.8540,
  },
  {
    'label': 'Andheri, Mumbai', 'zone': 'Andheri', 'city': 'Mumbai',
    'tier': 'low', 'premium': 60.0, 'coverage': 2000.0, 'riskScore': 0.30,
    'rec': null, 'boost': null, 'boostReason': null,
    'city_key': 'Mumbai', 'lat': 19.1136, 'lng': 72.8697,
  },
  {
    'label': 'Secunderabad, Hyderabad', 'zone': 'Secunderabad', 'city': 'Hyderabad',
    'tier': 'medium', 'premium': 85.0, 'coverage': 2240.0, 'riskScore': 0.52,
    'rec': 'Banjara Hills', 'boost': '+20%', 'boostReason': 'Heat-resilient zone',
    'city_key': 'Hyderabad', 'lat': 17.4399, 'lng': 78.4983,
  },
  {
    'label': 'Banjara Hills, Hyderabad', 'zone': 'Banjara Hills', 'city': 'Hyderabad',
    'tier': 'low', 'premium': 60.0, 'coverage': 2000.0, 'riskScore': 0.34,
    'rec': null, 'boost': null, 'boostReason': null,
    'city_key': 'Hyderabad', 'lat': 17.4156, 'lng': 78.4347,
  },
  {
    'label': 'HITEC City, Hyderabad', 'zone': 'HITEC City', 'city': 'Hyderabad',
    'tier': 'low', 'premium': 60.0, 'coverage': 2000.0, 'riskScore': 0.36,
    'rec': null, 'boost': null, 'boostReason': null,
    'city_key': 'Hyderabad', 'lat': 17.4435, 'lng': 78.3772,
  },
  {
    'label': 'Kukatpally, Hyderabad', 'zone': 'Kukatpally', 'city': 'Hyderabad',
    'tier': 'medium', 'premium': 85.0, 'coverage': 2240.0, 'riskScore': 0.51,
    'rec': 'Banjara Hills', 'boost': '+14%', 'boostReason': 'Less flood-prone roads',
    'city_key': 'Hyderabad', 'lat': 17.4849, 'lng': 78.3995,
  },
  {
    'label': 'Tambaram, Chennai', 'zone': 'Tambaram', 'city': 'Chennai',
    'tier': 'low', 'premium': 60.0, 'coverage': 2000.0, 'riskScore': 0.32,
    'rec': null, 'boost': null, 'boostReason': null,
    'city_key': 'Chennai', 'lat': 12.9249, 'lng': 80.1000,
  },
  {
    'label': 'Anna Nagar, Chennai', 'zone': 'Anna Nagar', 'city': 'Chennai',
    'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'riskScore': 0.50,
    'rec': 'Guindy', 'boost': '+12%', 'boostReason': 'Steady order flow',
    'city_key': 'Chennai', 'lat': 13.0850, 'lng': 80.2101,
  },
  {
    'label': 'Guindy, Chennai', 'zone': 'Guindy', 'city': 'Chennai',
    'tier': 'low', 'premium': 60.0, 'coverage': 2000.0, 'riskScore': 0.35,
    'rec': null, 'boost': null, 'boostReason': null,
    'city_key': 'Chennai', 'lat': 13.0067, 'lng': 80.2206,
  },
  {
    'label': 'Velachery, Chennai', 'zone': 'Velachery', 'city': 'Chennai',
    'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'riskScore': 0.56,
    'rec': 'Guindy', 'boost': '+10%', 'boostReason': 'Faster arterial route access',
    'city_key': 'Chennai', 'lat': 12.9815, 'lng': 80.2180,
  },
  {
    'label': 'Dwarka, Delhi', 'zone': 'Dwarka', 'city': 'Delhi',
    'tier': 'low', 'premium': 60.0, 'coverage': 2000.0, 'riskScore': 0.33,
    'rec': null, 'boost': null, 'boostReason': null,
    'city_key': 'Delhi', 'lat': 28.5921, 'lng': 77.0460,
  },
  {
    'label': 'Rohini, Delhi', 'zone': 'Rohini', 'city': 'Delhi',
    'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'riskScore': 0.52,
    'rec': 'Dwarka', 'boost': '+9%', 'boostReason': 'Better weather resilience',
    'city_key': 'Delhi', 'lat': 28.7383, 'lng': 77.0822,
  },
  {
    'label': 'Karol Bagh, Delhi', 'zone': 'Karol Bagh', 'city': 'Delhi',
    'tier': 'high', 'premium': 120.0, 'coverage': 2500.0, 'riskScore': 0.77,
    'rec': 'Dwarka', 'boost': '+17%', 'boostReason': 'Fewer closure events',
    'city_key': 'Delhi', 'lat': 28.6518, 'lng': 77.1909,
  },
  {
    'label': 'Saket, Delhi', 'zone': 'Saket', 'city': 'Delhi',
    'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'riskScore': 0.50,
    'rec': 'Dwarka', 'boost': '+11%', 'boostReason': 'Lower disruption index',
    'city_key': 'Delhi', 'lat': 28.5245, 'lng': 77.2066,
  },
  {
    'label': 'Kothrud, Pune', 'zone': 'Kothrud', 'city': 'Pune',
    'tier': 'low', 'premium': 60.0, 'coverage': 2000.0, 'riskScore': 0.31,
    'rec': null, 'boost': null, 'boostReason': null,
    'city_key': 'Pune', 'lat': 18.5074, 'lng': 73.8077,
  },
  {
    'label': 'Hinjawadi, Pune', 'zone': 'Hinjawadi', 'city': 'Pune',
    'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'riskScore': 0.53,
    'rec': 'Kothrud', 'boost': '+8%', 'boostReason': 'More sheltered routes',
    'city_key': 'Pune', 'lat': 18.5912, 'lng': 73.7389,
  },
  {
    'label': 'Shivajinagar, Pune', 'zone': 'Shivajinagar', 'city': 'Pune',
    'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'riskScore': 0.49,
    'rec': 'Kothrud', 'boost': '+10%', 'boostReason': 'Stable central-zone demand',
    'city_key': 'Pune', 'lat': 18.5308, 'lng': 73.8474,
  },
  {
    'label': 'Hadapsar, Pune', 'zone': 'Hadapsar', 'city': 'Pune',
    'tier': 'high', 'premium': 120.0, 'coverage': 2500.0, 'riskScore': 0.74,
    'rec': 'Shivajinagar', 'boost': '+16%', 'boostReason': 'Lower monsoon closures',
    'city_key': 'Pune', 'lat': 18.5089, 'lng': 73.9260,
  },
  {
    'label': 'Salt Lake, Kolkata', 'zone': 'Salt Lake', 'city': 'Kolkata',
    'tier': 'low', 'premium': 60.0, 'coverage': 2000.0, 'riskScore': 0.34,
    'rec': null, 'boost': null, 'boostReason': null,
    'city_key': 'Kolkata', 'lat': 22.5867, 'lng': 88.4173,
  },
  {
    'label': 'Park Street, Kolkata', 'zone': 'Park Street', 'city': 'Kolkata',
    'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'riskScore': 0.55,
    'rec': 'Salt Lake', 'boost': '+13%', 'boostReason': 'More stable demand mix',
    'city_key': 'Kolkata', 'lat': 22.5535, 'lng': 88.3521,
  },
  {
    'label': 'Howrah, Kolkata', 'zone': 'Howrah', 'city': 'Kolkata',
    'tier': 'high', 'premium': 120.0, 'coverage': 2500.0, 'riskScore': 0.79,
    'rec': 'Salt Lake', 'boost': '+19%', 'boostReason': 'Lower flood incidence',
    'city_key': 'Kolkata', 'lat': 22.5958, 'lng': 88.2636,
  },
  {
    'label': 'Garia, Kolkata', 'zone': 'Garia', 'city': 'Kolkata',
    'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'riskScore': 0.52,
    'rec': 'Park Street', 'boost': '+9%', 'boostReason': 'Faster corridor access',
    'city_key': 'Kolkata', 'lat': 22.4594, 'lng': 88.3913,
  },
  {
    'label': 'Navrangpura, Ahmedabad', 'zone': 'Navrangpura', 'city': 'Ahmedabad',
    'tier': 'low', 'premium': 60.0, 'coverage': 2000.0, 'riskScore': 0.30,
    'rec': null, 'boost': null, 'boostReason': null,
    'city_key': 'Ahmedabad', 'lat': 23.0375, 'lng': 72.5601,
  },
  {
    'label': 'Maninagar, Ahmedabad', 'zone': 'Maninagar', 'city': 'Ahmedabad',
    'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'riskScore': 0.50,
    'rec': 'Navrangpura', 'boost': '+11%', 'boostReason': 'Steadier traffic profile',
    'city_key': 'Ahmedabad', 'lat': 22.9951, 'lng': 72.6040,
  },
  {
    'label': 'Bopal, Ahmedabad', 'zone': 'Bopal', 'city': 'Ahmedabad',
    'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'riskScore': 0.54,
    'rec': 'Navrangpura', 'boost': '+10%', 'boostReason': 'Lower heat-disruption risk',
    'city_key': 'Ahmedabad', 'lat': 23.0326, 'lng': 72.4636,
  },
  {
    'label': 'Naroda, Ahmedabad', 'zone': 'Naroda', 'city': 'Ahmedabad',
    'tier': 'high', 'premium': 120.0, 'coverage': 2500.0, 'riskScore': 0.76,
    'rec': 'Bopal', 'boost': '+15%', 'boostReason': 'More protected routes nearby',
    'city_key': 'Ahmedabad', 'lat': 23.0701, 'lng': 72.6738,
  },
];

const List<Map<String, String>> kCities = [
  {'name': 'Mumbai', 'emoji': '🌊', 'state': 'Maharashtra'},
  {'name': 'Bengaluru', 'emoji': '🌿', 'state': 'Karnataka'},
  {'name': 'Hyderabad', 'emoji': '🏛️', 'state': 'Telangana'},
  {'name': 'Chennai', 'emoji': '🌅', 'state': 'Tamil Nadu'},
  {'name': 'Delhi', 'emoji': '🕌', 'state': 'Delhi NCR'},
  {'name': 'Pune', 'emoji': '🌄', 'state': 'Maharashtra'},
  {'name': 'Kolkata', 'emoji': '🌉', 'state': 'West Bengal'},
  {'name': 'Ahmedabad', 'emoji': '🏺', 'state': 'Gujarat'},
];

// City-level risk assignment
// Mumbai + Delhi = High
// Bengaluru + Hyderabad = Medium
// Chennai + Pune = Low
const Map<String, String> kCityTiers = {
  'Mumbai': 'high',
  'Delhi': 'high',
  'Bengaluru': 'medium',
  'Hyderabad': 'medium',
  'Chennai': 'low',
  'Pune': 'low',
  'Kolkata': 'medium',
  'Ahmedabad': 'low',
};

// City-level premiums (overrides zone-level)
const Map<String, double> kCityPremiums = {
  'Mumbai': 115.0,
  'Delhi': 120.0,
  'Bengaluru': 90.0,
  'Hyderabad': 85.0,
  'Chennai': 60.0,
  'Pune': 60.0,
  'Kolkata': 85.0,
  'Ahmedabad': 60.0,
};

const Map<String, double> kCityCoverage = {
  'Mumbai': 2460.0,
  'Delhi': 2500.0,
  'Bengaluru': 2240.0,
  'Hyderabad': 2240.0,
  'Chennai': 2000.0,
  'Pune': 2000.0,
  'Kolkata': 2240.0,
  'Ahmedabad': 2000.0,
};
