import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/cache_service.dart';
import '../services/lotto_service.dart';
import '../widgets/number_set_card.dart';

class GeneratorScreen extends StatefulWidget {
  final Map<int, int> frequency;
  final void Function(List<int> numbers)? onSave;

  const GeneratorScreen({
    super.key,
    required this.frequency,
    this.onSave,
  });

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  List<List<int>> _generatedSets = [];
  final Set<int> _savedIndices = {};
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  bool _adLoadFailed = false;
  bool _isInitialized = false;

  static const String _adUnitId = 'ca-app-pub-4257241283230022/4763903059';

  @override
  void initState() {
    super.initState();
    _initSets();
    _loadRewardedAd();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  Future<void> _initSets() async {
    final cached = await CacheService.loadGeneratedSets();
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _generatedSets = cached;
        _isInitialized = true;
      });
    } else {
      _generate();
    }
  }

  void _loadRewardedAd() {
    setState(() {
      _isAdLoading = true;
      _adLoadFailed = false;
    });
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
            _isAdLoading = false;
            _adLoadFailed = false;
          });
        },
        onAdFailedToLoad: (error) {
          setState(() {
            _isAdLoading = false;
            _adLoadFailed = true;
          });
        },
      ),
    );
  }

  void _generate() {
    final sets = LottoService.generateNumbers(widget.frequency, count: 5);
    setState(() {
      _generatedSets = sets;
      _savedIndices.clear();
      _isInitialized = true;
    });
    CacheService.saveGeneratedSets(sets);
  }

  void _onRegeneratePressed() {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          _loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          _loadRewardedAd();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('광고 표시에 실패했습니다. 다시 시도해주세요.')),
          );
        },
      );
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          _generate();
        },
      );
    }
  }

  void _onSave(int index) {
    widget.onSave?.call(_generatedSets[index]);
    setState(() {
      _savedIndices.add(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('저장 완료'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  String _getButtonText() {
    if (_isAdLoading) return '광고 로딩 중...';
    if (_adLoadFailed) return '광고 로드 실패 - 재시도';
    if (_rewardedAd != null) return '광고 보고 다시 뽑기';
    return '다시 뽑기';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        // 헤더
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            color: Colors.amber[50],
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.casino, color: Colors.deepOrange),
                  SizedBox(width: 8),
                  Text(
                    '빈도 기반 추천 번호 (5세트)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 번호 세트 리스트
        Expanded(
          child: ListView.builder(
            itemCount: _generatedSets.length,
            itemBuilder: (context, index) {
              return NumberSetCard(
                index: index,
                numbers: _generatedSets[index],
                onSave: widget.onSave != null ? () => _onSave(index) : null,
                isSaved: _savedIndices.contains(index),
              );
            },
          ),
        ),

        // 다시 뽑기 버튼
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isAdLoading
                  ? null
                  : _adLoadFailed
                      ? _loadRewardedAd
                      : _rewardedAd != null
                          ? _onRegeneratePressed
                          : null,
              icon: Icon(_adLoadFailed ? Icons.refresh : Icons.refresh),
              label: Text(
                _getButtonText(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // 면책 문구
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
          child: Text(
            '본 프로그램은 과거 데이터 기반 참고용이며,\n로또 당첨을 보장하지 않습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
