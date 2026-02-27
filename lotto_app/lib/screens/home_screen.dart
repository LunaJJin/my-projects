import 'package:flutter/material.dart';
import '../models/lotto_result.dart';
import '../models/purchased_number.dart';
import '../services/cache_service.dart';
import '../services/lotto_api_service.dart';
import '../services/lotto_service.dart';
import 'history_screen.dart';
import 'analysis_screen.dart';
import 'generator_screen.dart';
import 'my_numbers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<LottoResult> _results = [];
  Map<int, int> _frequency = {};
  List<PurchasedNumber> _purchasedNumbers = [];
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await LottoApiService.fetchAllResults();
      final frequency = LottoService.calculateFrequency(results);
      final purchasedNumbers = await CacheService.loadPurchasedNumbers();
      setState(() {
        _results = results;
        _frequency = frequency;
        _purchasedNumbers = purchasedNumbers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '데이터를 불러오지 못했습니다.\n인터넷 연결을 확인해주세요.\n\n$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _savePurchasedNumber(List<int> numbers) async {
    final now = DateTime.now();
    final purchased = PurchasedNumber(
      id: now.millisecondsSinceEpoch.toString(),
      numbers: numbers,
      purchasedDate:
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    );
    await CacheService.savePurchasedNumber(purchased);
    setState(() {
      _purchasedNumbers.add(purchased);
    });
  }

  Future<void> _deletePurchasedNumber(String id) async {
    await CacheService.deletePurchasedNumber(id);
    setState(() {
      _purchasedNumbers.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('행운의 로또번호'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: '데이터 새로고침',
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '이력',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: '분석',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.casino),
            label: '생성',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: '내 번호',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurple),
            SizedBox(height: 16),
            Text('당첨번호 데이터 로딩 중...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    switch (_currentIndex) {
      case 0:
        return HistoryScreen(results: _results);
      case 1:
        return AnalysisScreen(
          frequency: _frequency,
          totalRounds: _results.length,
        );
      case 2:
        return GeneratorScreen(
          frequency: _frequency,
          onSave: _savePurchasedNumber,
        );
      case 3:
        return MyNumbersScreen(
          purchasedNumbers: _purchasedNumbers,
          onDelete: _deletePurchasedNumber,
          onAdd: _savePurchasedNumber,
        );
      default:
        return HistoryScreen(results: _results);
    }
  }
}
