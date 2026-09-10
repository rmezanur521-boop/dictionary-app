sealed class Result<T> {
  const Result();
  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(String message, {Object? cause}) =
      FailureResult<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Object? cause) failure,
  }) {
    final self = this;
    if (self is Success<T>) return success(self.data);
    if (self is FailureResult<T>) return failure(self.message, self.cause);
    throw StateError('Unreachable');
  }

  bool get isSuccess => this is Success<T>;
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class FailureResult<T> extends Result<T> {
  const FailureResult(this.message, {this.cause});
  final String message;
  final Object? cause;
}
