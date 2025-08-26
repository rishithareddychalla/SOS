class CallState {
  final List<String> numbers;   // all numbers
  final int currentIndex;       // which one we are calling
  final bool isCalling;

  const CallState({
    required this.numbers,
    required this.currentIndex,
    required this.isCalling,
  });

  String? get currentNumber =>
      (currentIndex < numbers.length) ? numbers[currentIndex] : null;
}
