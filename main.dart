import 'dart:io';

// Dart equivalent of binary search and linear search for a sorted list of integers
final List<int> items = List<int>.generate(10000, (index) => index + 1);

/// Linear search function
/// Explanation: linear search is a simple search algorithm that checks each element
/// in the list one by one until it finds the target value or reaches the end of the list.
/// It has a time complexity of O(n), where n is the number of elements in the list.
int linearSearch(List<int> arr, int target) {
  for (int i = 0; i < arr.length; i++) {
    if (arr[i] == target) {
      print("Found $target at index $i");
      return i;
    }
    print("Checked index $i, value ${arr[i]} - not a match");
  }
  print("$target not found in the list");
  return -1;
}

/// Binary search function
/// Explanation: binary search is a more efficient search algorithm that works on sorted lists.
/// It repeatedly divides the search interval in half, comparing the target value to the middle
/// element of the list. If the target is less than the middle element, it continues searching
/// in the left half; otherwise, it searches in the right half.
/// It has a time complexity of O(log n), where n is the number of elements in the list.
int binarySearch(List<int> arr, int target) {
  int left = 0;
  int right = arr.length - 1;

  while (left <= right) {
    int mid = left + (right - left) ~/ 2;

    if (arr[mid] == target) {
      print("Found $target at index $mid");
      return mid;
    } else if (arr[mid] < target) {
      left = mid + 1;
      print("Checked index $mid, value ${arr[mid]} - not a match");
    } else {
      right = mid - 1;
      print("Checked index $mid, value ${arr[mid]} - not a match");
    }
  }

  print("$target not found in the list");
  return -1;
}

/// Measures the execution time of a function
void measureTime(Function func, List<int> arr, int target, String funcName) {
  final Stopwatch stopwatch = Stopwatch()..start();
  func(arr, target);
  stopwatch.stop();
  print("Time taken by $funcName: ${stopwatch.elapsedMilliseconds}ms");
}

void main() {
  // Example usage
  int targetValue = 2;
  print("=== Linear Search ===");
  measureTime(linearSearch, items, targetValue, "linearSearch");
  print("\n=== Binary Search ===");
  measureTime(binarySearch, items, targetValue, "binarySearch");
}

