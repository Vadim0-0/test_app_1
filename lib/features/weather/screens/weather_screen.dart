import '../widgets/weather_search_field.dart';

import 'package:flutter/material.dart';

import '../models/weather_models.dart';

import '../controllers/weather_controller.dart';
import '../dialogs/city_actions_sheet.dart';

import '../widgets/city_weather_card.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _controller = WeatherController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.loadFavorites();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _showMessage(String? message) {
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refreshWeather() async {
    _showMessage(await _controller.refreshWeather());
  }

  // Открытие меню города при длительном нажатии
  Future<void> _showCityActions(WeatherCity city) async {
    if (_controller.isSavingFavorites ||
        _controller.isLoadingFavorites ||
        _controller.favoritesError != null) {
      return;
    }

    final favorite = _controller.isFavorite(city);

    final shouldToggle = await showCityActionsSheet(
      context,
      city,
      favorite: favorite,
    );

    if (!mounted || shouldToggle != true) return;

    _showMessage(await _controller.toggleFavorite(city));
  }

  // Очищение поля
  void _clearSearch() {
    _searchController.clear();
    _controller.onSearchChanged('');
  }

  // Общий виджет сообщения по центру экрана
  Widget _centerMessage(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildContent() {
    if (_controller.isLoadingFavorites) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.favoritesError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_controller.favoritesError!),
            TextButton(
              onPressed: _controller.loadFavorites,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_controller.isSearchMode && _controller.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.isSearchMode && _controller.searchError != null) {
      return _centerMessage(_controller.searchError!);
    }

    final cities = _controller.isSearchMode
        ? _controller.searchResults
        : _controller.favorites;

    if (cities.isEmpty) {
      if (!_controller.isSearchMode) {
        return _centerMessage(
          'Избранных городов нет, '
          'введите в поиске нужный город',
        );
      }

      return _centerMessage(
        _controller.searchError == null && !_controller.hasSubmittedSearch
            ? 'Нажмите поиск на клавиатуре или кнопку справа'
            : 'Города не найдены',
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshWeather,
      child: ListView.builder(
        // Позволяет потянуть список даже с одной карточкой.
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: cities.length,
        itemBuilder: (context, index) {
          final city = cities[index];

          return CityWeatherCard(
            key: ValueKey(_controller.cityKey(city)),
            city: city,
            request: _controller.weatherFor(city),
            onRetry: () => _controller.retry(city),
            onLongPress: () => _showCityActions(city),
            highlightFavorite:
                _controller.isSearchMode && _controller.isFavorite(city),
          );
        },
      ),
    );
  }

  // Освобождение ресурса
  @override
  void dispose() {
    // Освобождает ресурсы контроллера текстового поля
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _searchController.dispose();
    // Вызывает реализацию очистки из родительского класса State
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _controller.isSearchMode ? 'Поиск городов' : 'Избранные города',
        ),
      ),
      body: Column(
        children: [
          WeatherSearchField(
            controller: _searchController,
            loading: _controller.isLoadingFavorites,
            error: _controller.favoritesError,
            searchMode: _controller.isSearchMode,
            onSubmitted: _controller.search,
            onChanged: _controller.onSearchChanged,
            onClear: _clearSearch,
          ),
          if (_controller.isSavingFavorites) const LinearProgressIndicator(),
          Expanded(child: _buildContent()),
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 20, left: 16, right: 16),
            child: Text(
              'Данные о погоде: Open-Meteo.com (CC BY 4.0)',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
