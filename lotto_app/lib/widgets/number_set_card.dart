import 'package:flutter/material.dart';
import 'lotto_ball.dart';

class NumberSetCard extends StatelessWidget {
  final int index;
  final List<int> numbers;
  final VoidCallback? onSave;
  final bool isSaved;

  const NumberSetCard({
    super.key,
    required this.index,
    required this.numbers,
    this.onSave,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: numbers
                    .map((n) => LottoBall(number: n, size: 38))
                    .toList(),
              ),
            ),
            if (onSave != null)
              IconButton(
                onPressed: isSaved ? null : onSave,
                icon: Icon(
                  isSaved ? Icons.check_circle : Icons.bookmark_border,
                  color: isSaved ? Colors.green : Colors.deepPurple,
                ),
                tooltip: isSaved ? '저장 완료' : '번호 저장',
              ),
          ],
        ),
      ),
    );
  }
}
