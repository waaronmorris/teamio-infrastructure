-- US Zip Code Seed Data for Discovery Feature
-- Contains ~200 major US zip codes for development/testing.
-- For production, download full ZCTA dataset from:
-- https://simplemaps.com/data/us-zips (free, ~41k rows)
-- Then: \copy us_zip_codes FROM 'uszips.csv' WITH (FORMAT csv, HEADER true)

INSERT INTO us_zip_codes (zip_code, city, state, latitude, longitude) VALUES
-- Illinois
('60601', 'Chicago', 'IL', 41.8819, -87.6278),
('60602', 'Chicago', 'IL', 41.8832, -87.6295),
('60614', 'Chicago', 'IL', 41.9218, -87.6518),
('60657', 'Chicago', 'IL', 41.9400, -87.6530),
('62701', 'Springfield', 'IL', 39.7990, -89.6440),
('62703', 'Springfield', 'IL', 39.7612, -89.6390),
('61820', 'Champaign', 'IL', 40.1164, -88.2434),
('60532', 'Lisle', 'IL', 41.7930, -88.0816),
('60540', 'Naperville', 'IL', 41.7706, -88.1500),
('60564', 'Naperville', 'IL', 41.7189, -88.1965),
-- New York
('10001', 'New York', 'NY', 40.7484, -73.9967),
('10002', 'New York', 'NY', 40.7157, -73.9863),
('10010', 'New York', 'NY', 40.7390, -73.9826),
('10019', 'New York', 'NY', 40.7654, -73.9857),
('10036', 'New York', 'NY', 40.7590, -73.9893),
('11201', 'Brooklyn', 'NY', 40.6938, -73.9904),
('10301', 'Staten Island', 'NY', 40.6427, -74.0900),
('10451', 'Bronx', 'NY', 40.8211, -73.9227),
('11101', 'Long Island City', 'NY', 40.7433, -73.9235),
('10701', 'Yonkers', 'NY', 40.9461, -73.8669),
-- California
('90001', 'Los Angeles', 'CA', 33.9425, -118.2551),
('90012', 'Los Angeles', 'CA', 34.0621, -118.2399),
('90210', 'Beverly Hills', 'CA', 34.0901, -118.4065),
('90401', 'Santa Monica', 'CA', 34.0195, -118.4912),
('91101', 'Pasadena', 'CA', 34.1478, -118.1445),
('92101', 'San Diego', 'CA', 32.7194, -117.1628),
('94102', 'San Francisco', 'CA', 37.7813, -122.4167),
('94105', 'San Francisco', 'CA', 37.7864, -122.3892),
('95110', 'San Jose', 'CA', 37.3369, -121.8906),
('95814', 'Sacramento', 'CA', 38.5816, -121.4944),
-- Texas
('75201', 'Dallas', 'TX', 32.7872, -96.7985),
('75202', 'Dallas', 'TX', 32.7831, -96.8007),
('77001', 'Houston', 'TX', 29.7545, -95.3574),
('77002', 'Houston', 'TX', 29.7589, -95.3597),
('78201', 'San Antonio', 'TX', 29.4684, -98.5254),
('78701', 'Austin', 'TX', 30.2672, -97.7431),
('76101', 'Fort Worth', 'TX', 32.7543, -97.3327),
('79901', 'El Paso', 'TX', 31.7587, -106.4869),
('78401', 'Corpus Christi', 'TX', 27.7964, -97.3946),
('77401', 'Bellaire', 'TX', 29.7058, -95.4617),
-- Florida
('33101', 'Miami', 'FL', 25.7743, -80.1937),
('33109', 'Miami Beach', 'FL', 25.7617, -80.1300),
('32801', 'Orlando', 'FL', 28.5383, -81.3792),
('33602', 'Tampa', 'FL', 27.9506, -82.4572),
('33301', 'Fort Lauderdale', 'FL', 26.1224, -80.1373),
('33401', 'West Palm Beach', 'FL', 26.7153, -80.0534),
('32202', 'Jacksonville', 'FL', 30.3255, -81.6565),
('33701', 'St. Petersburg', 'FL', 27.7706, -82.6417),
('34102', 'Naples', 'FL', 26.1420, -81.7948),
('32901', 'Melbourne', 'FL', 28.0836, -80.6081),
-- Pennsylvania
('19101', 'Philadelphia', 'PA', 39.9526, -75.1652),
('19102', 'Philadelphia', 'PA', 39.9523, -75.1638),
('15201', 'Pittsburgh', 'PA', 40.4684, -79.9556),
('15213', 'Pittsburgh', 'PA', 40.4416, -79.9561),
('18015', 'Bethlehem', 'PA', 40.6259, -75.3705),
('17101', 'Harrisburg', 'PA', 40.2594, -76.8826),
('18101', 'Allentown', 'PA', 40.6023, -75.4714),
('19301', 'Paoli', 'PA', 40.0428, -75.4813),
-- Georgia
('30301', 'Atlanta', 'GA', 33.7490, -84.3880),
('30303', 'Atlanta', 'GA', 33.7539, -84.3900),
('30305', 'Atlanta', 'GA', 33.8345, -84.3804),
('31401', 'Savannah', 'GA', 32.0835, -81.0998),
('30601', 'Athens', 'GA', 33.9519, -83.3576),
-- Ohio
('43201', 'Columbus', 'OH', 39.9912, -82.9988),
('44101', 'Cleveland', 'OH', 41.5065, -81.6936),
('45201', 'Cincinnati', 'OH', 39.1031, -84.5120),
('43604', 'Toledo', 'OH', 41.6528, -83.5379),
('44301', 'Akron', 'OH', 41.0814, -81.5190),
-- North Carolina
('27601', 'Raleigh', 'NC', 35.7796, -78.6382),
('28201', 'Charlotte', 'NC', 35.2271, -80.8431),
('27101', 'Winston-Salem', 'NC', 36.0999, -80.2442),
('27701', 'Durham', 'NC', 35.9940, -78.8986),
-- Michigan
('48201', 'Detroit', 'MI', 42.3314, -83.0458),
('48823', 'East Lansing', 'MI', 42.7369, -84.4839),
('49503', 'Grand Rapids', 'MI', 42.9634, -85.6681),
('48104', 'Ann Arbor', 'MI', 42.2808, -83.7430),
-- Massachusetts
('02101', 'Boston', 'MA', 42.3601, -71.0589),
('02110', 'Boston', 'MA', 42.3572, -71.0528),
('02138', 'Cambridge', 'MA', 42.3808, -71.1300),
('01101', 'Springfield', 'MA', 42.1015, -72.5898),
-- Washington
('98101', 'Seattle', 'WA', 47.6062, -122.3321),
('98104', 'Seattle', 'WA', 47.6003, -122.3303),
('98201', 'Everett', 'WA', 47.9790, -122.2021),
('99201', 'Spokane', 'WA', 47.6588, -117.4260),
-- Arizona
('85001', 'Phoenix', 'AZ', 33.4484, -112.0740),
('85201', 'Mesa', 'AZ', 33.4152, -111.8315),
('85701', 'Tucson', 'AZ', 32.2217, -110.9265),
('86001', 'Flagstaff', 'AZ', 35.1983, -111.6513),
-- Colorado
('80201', 'Denver', 'CO', 39.7392, -104.9903),
('80301', 'Boulder', 'CO', 40.0150, -105.2705),
('80903', 'Colorado Springs', 'CO', 38.8339, -104.8214),
('80521', 'Fort Collins', 'CO', 40.5853, -105.0844),
-- Virginia
('22201', 'Arlington', 'VA', 38.8816, -77.0910),
('23219', 'Richmond', 'VA', 37.5407, -77.4360),
('23451', 'Virginia Beach', 'VA', 36.8529, -75.9780),
('22901', 'Charlottesville', 'VA', 38.0293, -78.4767),
-- Maryland
('21201', 'Baltimore', 'MD', 39.2904, -76.6122),
('20814', 'Bethesda', 'MD', 38.9847, -77.0943),
('20901', 'Silver Spring', 'MD', 39.0182, -77.0070),
('21401', 'Annapolis', 'MD', 38.9784, -76.4922),
-- DC
('20001', 'Washington', 'DC', 38.9072, -77.0369),
('20002', 'Washington', 'DC', 38.8991, -76.9830),
('20036', 'Washington', 'DC', 38.9076, -77.0403),
-- New Jersey
('07101', 'Newark', 'NJ', 40.7357, -74.1724),
('08501', 'Princeton', 'NJ', 40.3573, -74.6672),
('07030', 'Hoboken', 'NJ', 40.7440, -74.0324),
-- Connecticut
('06101', 'Hartford', 'CT', 41.7658, -72.6734),
('06510', 'New Haven', 'CT', 41.3083, -72.9279),
-- Oregon
('97201', 'Portland', 'OR', 45.5152, -122.6784),
('97401', 'Eugene', 'OR', 44.0521, -123.0868),
-- Indiana
('46201', 'Indianapolis', 'IN', 39.7684, -86.1581),
('47401', 'Bloomington', 'IN', 39.1653, -86.5264),
-- Missouri
('63101', 'St. Louis', 'MO', 38.6270, -90.1994),
('64101', 'Kansas City', 'MO', 39.1000, -94.5783),
-- Tennessee
('37201', 'Nashville', 'TN', 36.1627, -86.7816),
('38101', 'Memphis', 'TN', 35.1495, -90.0490),
('37901', 'Knoxville', 'TN', 35.9606, -83.9207),
-- Minnesota
('55401', 'Minneapolis', 'MN', 44.9778, -93.2650),
('55101', 'St. Paul', 'MN', 44.9537, -93.0900),
-- Wisconsin
('53201', 'Milwaukee', 'WI', 43.0389, -87.9065),
('53703', 'Madison', 'WI', 43.0731, -89.4012),
-- Louisiana
('70112', 'New Orleans', 'LA', 29.9511, -90.0715),
('70801', 'Baton Rouge', 'LA', 30.4515, -91.1871),
-- Alabama
('35201', 'Birmingham', 'AL', 33.5186, -86.8104),
('36601', 'Mobile', 'AL', 30.6954, -88.0399),
-- South Carolina
('29401', 'Charleston', 'SC', 32.7765, -79.9311),
('29201', 'Columbia', 'SC', 34.0007, -81.0348),
-- Kentucky
('40201', 'Louisville', 'KY', 38.2527, -85.7585),
('40501', 'Lexington', 'KY', 38.0406, -84.5037),
-- Oklahoma
('73101', 'Oklahoma City', 'OK', 35.4676, -97.5164),
('74101', 'Tulsa', 'OK', 36.1540, -95.9928),
-- Iowa
('50301', 'Des Moines', 'IA', 41.5868, -93.6250),
('52240', 'Iowa City', 'IA', 41.6611, -91.5302),
-- Nevada
('89101', 'Las Vegas', 'NV', 36.1699, -115.1398),
('89501', 'Reno', 'NV', 39.5296, -119.8138),
-- Utah
('84101', 'Salt Lake City', 'UT', 40.7608, -111.8910),
('84601', 'Provo', 'UT', 40.2338, -111.6585),
-- Kansas
('66101', 'Kansas City', 'KS', 39.1066, -94.6276),
('67201', 'Wichita', 'KS', 37.6872, -97.3301),
-- Nebraska
('68101', 'Omaha', 'NE', 41.2565, -95.9345),
('68501', 'Lincoln', 'NE', 40.8136, -96.7026),
-- New Mexico
('87101', 'Albuquerque', 'NM', 35.0844, -106.6504),
('87501', 'Santa Fe', 'NM', 35.6870, -105.9378),
-- Hawaii
('96801', 'Honolulu', 'HI', 21.3069, -157.8583),
-- Alaska
('99501', 'Anchorage', 'AK', 61.2181, -149.9003)
ON CONFLICT (zip_code) DO NOTHING;
