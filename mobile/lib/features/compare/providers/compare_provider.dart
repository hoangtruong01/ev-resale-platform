import 'package:flutter_riverpod/flutter_riverpod.dart';


class CompareState {
  final List<dynamic> items; // Can be BatteryModel or VehicleModel
  final String type; // 'battery' or 'vehicle'

  CompareState({this.items = const [], this.type = 'battery'});

  CompareState copyWith({List<dynamic>? items, String? type}) {
    return CompareState(
      items: items ?? this.items,
      type: type ?? this.type,
    );
  }
}

class CompareNotifier extends StateNotifier<CompareState> {
  CompareNotifier() : super(CompareState());

  void setType(String type) {
    if (state.type != type) {
      state = CompareState(type: type, items: []);
    }
  }

  void addItem(dynamic item) {
    if (state.items.length >= 3) return;
    if (state.items.any((i) => i.id == item.id)) return;
    state = state.copyWith(items: [...state.items, item]);
  }

  void removeItem(String id) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
    );
  }

  void clear() {
    state = state.copyWith(items: []);
  }
}

final compareProvider = StateNotifierProvider<CompareNotifier, CompareState>((ref) {
  return CompareNotifier();
});
