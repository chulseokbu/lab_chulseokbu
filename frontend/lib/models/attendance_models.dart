/// 체크인 응답 DTO
class CheckInDto {
  final int checkInId;

  CheckInDto({required this.checkInId});

  factory CheckInDto.fromJson(Map<String, dynamic> json) =>
      CheckInDto(checkInId: json['checkInId'] as int);
}

/// API 공통 응답 (data 포함)
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T? Function(dynamic)? fromJsonT,
  ) =>
      ApiResponse(
        success: json['success'] as bool? ?? false,
        message: json['message'] as String?,
        data: json['data'] != null && fromJsonT != null
            ? fromJsonT(json['data'])
            : null,
      );
}

/// API 공통 응답 (data 없음)
class NoDataApiResponse {
  final bool success;
  final String? message;

  NoDataApiResponse({required this.success, this.message});

  factory NoDataApiResponse.fromJson(Map<String, dynamic> json) =>
      NoDataApiResponse(
        success: json['success'] as bool? ?? false,
        message: json['message'] as String?,
      );
}
