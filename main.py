items = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50]


# linear search function
# explanation: linear search is a simple search algorithm that checks each element in the list one by one until it finds the target 
# value or reaches the end of the list. It has a time complexity of O(n), where n is the number of elements in the list.
def linear_search(arr, target):
    for i in range(len(arr)):
        if arr[i] == target:
            print(f"Found {target} at index {i}")
            return i
        print(f"Checked index {i}, value {arr[i]} - not a match")
    print(f"{target} not found in the list")
    return -1


# binary search function
# explanation: binary search is a more efficient search algorithm that works on sorted lists. It repeatedly 
# divides the search interval in half, comparing the target value to the middle element of the list. 
# If the target is less than the middle element, it continues searching in the left half; otherwise, 
# it searches in the right half. It has a time complexity of O(log n), where n is the number of elements in the list.
def binary_search(arr, target):
    left, right = 0, len(arr) - 1

    while left <= right:
        mid = left + (right - left) // 2

        if arr[mid] == target:
            print(f"Found {target} at index {mid}")
            return mid
        elif arr[mid] < target:
            left = mid + 1
            print(f"Checked index {mid}, value {arr[mid]} - not a match")
        else:
            right = mid - 1
            print(f"Checked index {mid}, value {arr[mid]} - not a match")

    print(f"{target} not found in the list")
    return -1


# An algorithm to calculate the time complexity of the linear search and binary search functions
import time

def measure_time(func, *args):
    start_time = time.time()
    result = func(*args)
    end_time = time.time()
    print(f"Time taken by {func.__name__}: {end_time - start_time:.6f} seconds")
    return result

# Example usage
target_value = 25
measure_time(linear_search, items, target_value)
measure_time(binary_search, items, target_value)

