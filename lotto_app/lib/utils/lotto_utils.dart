import 'constants.dart';

class LottoUtils {
  /// 날짜 → 회차 변환
  static int dateToRound(DateTime date) {
    final diff = date.difference(AppConstants.lottoStartDate);
    return diff.inDays ~/ 7 + 1;
  }

  /// 시작~끝 연도에 해당하는 회차 범위
  static (int, int) getRoundRange(int startYear, int endYear) {
    final startRound = dateToRound(DateTime(startYear, 1, 1));
    final endRound = dateToRound(DateTime(endYear, 12, 31));
    return (startRound, endRound);
  }
}
