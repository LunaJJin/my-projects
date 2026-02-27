import 'package:flutter/material.dart';
import '../models/purchased_number.dart';
import '../utils/constants.dart';
import '../widgets/lotto_ball.dart';

class MyNumbersScreen extends StatelessWidget {
  final List<PurchasedNumber> purchasedNumbers;
  final void Function(String id) onDelete;
  final void Function(List<int> numbers) onAdd;

  const MyNumbersScreen({
    super.key,
    required this.purchasedNumbers,
    required this.onDelete,
    required this.onAdd,
  });

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _NumberPickerDialog(onConfirm: onAdd),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (purchasedNumbers.isEmpty) {
      return Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '저장된 번호가 없습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  '생성 탭에서 저장하거나 직접 번호를 추가해보세요.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          _buildFab(context),
        ],
      );
    }

    final sorted = List<PurchasedNumber>.from(purchasedNumbers)
      ..sort((a, b) => b.purchasedDate.compareTo(a.purchasedDate));

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 80),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final item = sorted[index];
            return Dismissible(
              key: Key(item.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) => _confirmDelete(context),
              onDismissed: (_) => onDelete(item.id),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index == 0 ||
                      sorted[index - 1].purchasedDate != item.purchasedDate)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      child: Text(
                        item.purchasedDate,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  _buildCard(context, item, index),
                ],
              ),
            );
          },
        ),
        _buildFab(context),
      ],
    );
  }

  Widget _buildCard(BuildContext context, PurchasedNumber item, int index) {
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
                children: item.numbers
                    .map((n) => LottoBall(number: n, size: 38))
                    .toList(),
              ),
            ),
            IconButton(
              onPressed: () async {
                final confirmed = await _confirmDelete(context);
                if (confirmed == true) {
                  onDelete(item.id);
                }
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: '삭제',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제'),
        content: const Text('이 번호를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _NumberPickerDialog extends StatefulWidget {
  final void Function(List<int> numbers) onConfirm;

  const _NumberPickerDialog({required this.onConfirm});

  @override
  State<_NumberPickerDialog> createState() => _NumberPickerDialogState();
}

class _NumberPickerDialogState extends State<_NumberPickerDialog> {
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('번호 직접 선택'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '6개의 번호를 선택하세요 (${_selected.length}/6)',
              style: TextStyle(
                fontSize: 14,
                color: _selected.length == 6 ? Colors.green : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: 45,
              itemBuilder: (context, index) {
                final number = index + 1;
                final isSelected = _selected.contains(number);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selected.remove(number);
                      } else if (_selected.length < 6) {
                        _selected.add(number);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppConstants.getBallColor(number)
                          : Colors.grey[200],
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _selected.length == 6
              ? () {
                  final numbers = _selected.toList()..sort();
                  widget.onConfirm(numbers);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('추가'),
        ),
      ],
    );
  }
}
