import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  runApp(const WeatherNewsApp());
}

class WeatherNewsApp extends StatelessWidget {
  const WeatherNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather News App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const HomeScreen(),
    );
  }
}

// ========== HOME SCREEN ==========
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  static final List<Widget> _screens = [
    const WeatherScreen(),
    const NewsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Weather News',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF2C3E50),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF3498DB),
        unselectedItemColor: const Color(0xFF95A5A6),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud, size: 26),
            label: 'Weather',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper, size: 26),
            label: 'News',
          ),
        ],
      ),
    );
  }
}

// ========== WEATHER SCREEN ==========
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final String _weatherApiKey = '901f489d2ba0713c396e736815f153e5';
  
  Map<String, dynamic>? _currentWeather;
  List<dynamic>? _forecast;
  bool _isLoading = true;
  String _error = '';
  bool _isRefreshing = false;
  
  final List<String> _cities = [
    'Chennai', 'London', 'New York', 'Tokyo', 
    'Paris', 'Sydney', 'Mumbai', 'Dubai'
  ];
  String _selectedCity = 'Chennai';

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    if (!_isRefreshing) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final currentWeatherUrl = 
          'https://api.openweathermap.org/data/2.5/weather?q=$_selectedCity&appid=$_weatherApiKey&units=metric';
      
      final forecastUrl = 
          'https://api.openweathermap.org/data/2.5/forecast?q=$_selectedCity&appid=$_weatherApiKey&units=metric';
      
      final [currentResponse, forecastResponse] = await Future.wait([
        http.get(Uri.parse(currentWeatherUrl)),
        http.get(Uri.parse(forecastUrl)),
      ]);

      if (currentResponse.statusCode == 200 && forecastResponse.statusCode == 200) {
        setState(() {
          _currentWeather = json.decode(currentResponse.body);
          final forecastData = json.decode(forecastResponse.body);
          _forecast = forecastData['list'];
        });
      } else {
        final errorData = json.decode(currentResponse.body);
        setState(() {
          _error = errorData['message']?.toString() ?? 'Failed to load weather data';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Please check your connection.';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchWeatherData();
  }

  Widget _getWeatherIcon(String condition, {double size = 60}) {
    final conditionLower = condition.toLowerCase();
    
    if (conditionLower.contains('clear')) {
      return Icon(Icons.wb_sunny, size: size, color: const Color(0xFFFFB74D));
    } else if (conditionLower.contains('cloud')) {
      return Icon(Icons.cloud, size: size, color: const Color(0xFF90A4AE));
    } else if (conditionLower.contains('rain')) {
      return Icon(Icons.beach_access, size: size, color: const Color(0xFF42A5F5));
    } else if (conditionLower.contains('snow')) {
      return Icon(Icons.ac_unit, size: size, color: const Color(0xFFB3E5FC));
    } else if (conditionLower.contains('thunderstorm')) {
      return Icon(Icons.flash_on, size: size, color: const Color(0xFF7E57C2));
    } else if (conditionLower.contains('mist') || conditionLower.contains('fog')) {
      return Icon(Icons.blur_on, size: size, color: const Color(0xFF78909C));
    } else {
      return Icon(Icons.cloud, size: size, color: const Color(0xFF90A4AE));
    }
  }

  Color _getWeatherGradient(String condition) {
    final conditionLower = condition.toLowerCase();
    
    if (conditionLower.contains('clear')) {
      return const Color(0xFFFFF3E0);
    } else if (conditionLower.contains('cloud')) {
      return const Color(0xFFECEFF1);
    } else if (conditionLower.contains('rain')) {
      return const Color(0xFFE3F2FD);
    } else if (conditionLower.contains('snow')) {
      return const Color(0xFFE0F7FA);
    } else {
      return const Color(0xFFECEFF1);
    }
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          height: 100,
          child: Shimmer.fromColors(
            baseColor: const Color(0xFFE0E0E0),
            highlightColor: const Color(0xFFF5F5F5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 250,
          child: Shimmer.fromColors(
            baseColor: const Color(0xFFE0E0E0),
            highlightColor: const Color(0xFFF5F5F5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF3498DB),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // ===== CITY SELECTOR CARD =====
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3498DB), Color(0xFF2C3E50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3498DB).withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'SELECT CITY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _cities.length,
                      itemBuilder: (context, index) {
                        final city = _cities[index];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              city,
                              style: TextStyle(
                                fontSize: 13,
                                color: _selectedCity == city ? Colors.white : const Color(0xFF3498DB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            selected: _selectedCity == city,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCity = city;
                                  _isLoading = true;
                                });
                                _fetchWeatherData();
                              }
                            },
                            selectedColor: const Color(0xFFE74C3C),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (_isLoading)
              _buildShimmerLoading()
            else if (_error.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8D7DA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 50, color: Color(0xFFE74C3C)),
                    const SizedBox(height: 16),
                    Text(
                      _error,
                      style: const TextStyle(
                        color: Color(0xFF721C24),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _fetchWeatherData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE74C3C),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(140, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
            else if (_currentWeather != null)
              Column(
                children: [
                  // ===== CURRENT WEATHER CARD =====
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getWeatherGradient(_currentWeather!['weather'][0]['main']),
                          Colors.white,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // City and Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedCity,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2C3E50),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('EEEE, MMMM d').format(DateTime.now()),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF7F8C8D),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _getWeatherIcon(_currentWeather!['weather'][0]['main'], size: 50),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Temperature
                        Column(
                          children: [
                            Text(
                              '${_currentWeather!['main']['temp'].round()}°',
                              style: const TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3498DB),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                (_currentWeather!['weather'][0]['description'] as String)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Feels like ${_currentWeather!['main']['feels_like'].round()}°',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF34495E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // ===== PERFECT GRID LAYOUT =====
                        Column(
                          children: [
                            // First row of grid (Min/Max & Humidity)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildWeatherDetailCard(
                                    Icons.thermostat,
                                    '${_currentWeather!['main']['temp_min'].round()}°/${_currentWeather!['main']['temp_max'].round()}°',
                                    'Min/Max',
                                    const Color(0xFFFF9800),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildWeatherDetailCard(
                                    Icons.water_drop,
                                    '${_currentWeather!['main']['humidity']}%',
                                    'Humidity',
                                    const Color(0xFF2196F3),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Second row of grid (Wind & Pressure)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildWeatherDetailCard(
                                    Icons.air,
                                    '${_currentWeather!['wind']['speed'].round()} m/s',
                                    'Wind Speed',
                                    const Color(0xFF00BCD4),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildWeatherDetailCard(
                                    Icons.compress,
                                    '${_currentWeather!['main']['pressure']} hPa',
                                    'Pressure',
                                    const Color(0xFF9C27B0),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // ===== FORECAST HEADER =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFF2C3E50), size: 20),
                        const SizedBox(width: 10),
                        const Text(
                          '5-DAY FORECAST',
                          style: TextStyle(
                            color: Color(0xFF2C3E50),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('MMM d').format(DateTime.now()),
                          style: const TextStyle(
                            color: Color(0xFF7F8C8D),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ===== FORECAST LIST =====
                  if (_forecast != null)
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _forecast!.length > 5 ? 5 : _forecast!.length,
                        itemBuilder: (context, index) {
                          final forecast = _forecast![index];
                          final date = DateTime.parse(forecast['dt_txt']);
                          final temp = forecast['main']['temp'].round();
                          final condition = forecast['weather'][0]['main'];
                          
                          return Container(
                            width: 110,
                            margin: EdgeInsets.only(
                              right: index == 4 ? 0 : 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('EEE').format(date),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('d/M').format(date),
                                    style: const TextStyle(
                                      color: Color(0xFF7F8C8D),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _getWeatherIcon(condition, size: 35),
                                  const SizedBox(height: 10),
                                  Text(
                                    '$temp°',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    condition.length > 8 ? '${condition.substring(0, 7)}..' : condition,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF7F8C8D),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  
                  const SizedBox(height: 40),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetailCard(IconData icon, String value, String label, Color color) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF7F8C8D),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ========== NEWS SCREEN ==========
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final String _newsApiKey = '1468162317104ca48db7449c5fae40d8';
  
  List<dynamic> _news = [];
  bool _isLoading = true;
  String _error = '';
  bool _isRefreshing = false;
  
  final List<String> _categories = [
    'general', 'business', 'entertainment', 
    'health', 'science', 'sports', 'technology'
  ];
  String _selectedCategory = 'general';

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    if (!_isRefreshing) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final url = 
          'https://newsapi.org/v2/top-headlines?country=us&category=$_selectedCategory&apiKey=$_newsApiKey';
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _news = data['articles'] ?? [];
          if (_news.isEmpty) {
            _error = 'No news available for this category.';
          }
        });
      } else {
        setState(() {
          _error = 'Failed to load news. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Please check your connection.';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshNews() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchNews();
  }

  Widget _buildNewsShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: const Color(0xFFE0E0E0),
            highlightColor: const Color(0xFFF5F5F5),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category Selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2C3E50).withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.category, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'NEWS CATEGORIES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          category[0].toUpperCase() + category.substring(1),
                          style: TextStyle(
                            fontSize: 12,
                            color: _selectedCategory == category
                                ? Colors.white
                                : const Color(0xFF2C3E50),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = category;
                              _isLoading = true;
                            });
                            _fetchNews();
                          }
                        },
                        selectedColor: const Color(0xFFE74C3C),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        // News List
        Expanded(
          child: _isLoading
              ? _buildNewsShimmer()
              : _error.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 60, color: Color(0xFFE74C3C)),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                _error,
                                style: const TextStyle(
                                  color: Color(0xFF721C24),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _fetchNews,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE74C3C),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(140, 45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _news.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.newspaper, size: 60, color: Color(0xFFBDC3C7)),
                                const SizedBox(height: 16),
                                const Text(
                                  'No news available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF7F8C8D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Try another category',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF95A5A6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _refreshNews,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3498DB),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(120, 45),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text('Refresh'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF3498DB),
                          backgroundColor: Colors.white,
                          onRefresh: _refreshNews,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _news.length,
                            itemBuilder: (context, index) {
                              final article = _news[index];
                              return NewsCard(article: article);
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

// ========== NEWS CARD ==========
class NewsCard extends StatelessWidget {
  final Map<String, dynamic> article;

  const NewsCard({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Opening: ${article['title']?.toString().substring(0, 25)}...',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                backgroundColor: const Color(0xFF3498DB),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source Chip
                if (article['source']['name'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3498DB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      article['source']['name']?.toString() ?? 'News',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // Title
                Text(
                  article['title']?.toString() ?? 'No Title Available',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Image
                if (article['urlToImage'] != null && article['urlToImage'].toString().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      article['urlToImage'],
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECEFF1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF3498DB),
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECEFF1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.photo,
                              color: Color(0xFF90A4AE),
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEFF1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.article,
                        color: Color(0xFF90A4AE),
                        size: 40,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // Description
                if (article['description'] != null && article['description'].toString().isNotEmpty)
                  Text(
                    article['description'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF34495E),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                const SizedBox(height: 12),
                
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: Color(0xFF7F8C8D)),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(article['publishedAt']),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7F8C8D),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3498DB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Read',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward, size: 12, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Recent';
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inHours < 1) {
        return 'Now';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d').format(date);
      }
    } catch (e) {
      return 'Recent';
    }
  }
}