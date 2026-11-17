import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/quote.dart';

class QuotesLoader {
  Future<List<Quote>> load() async {
    final raw = await rootBundle.loadString('assets/quotes.json');
    return (jsonDecode(raw) as List)
        .map((item) => Quote.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
