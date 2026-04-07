package com.example.LabAttendance.RollCall.Member.DTO;

public record MemberProfileResponseDto(
        Long id,
        Long memberId,
        String nickname,
        String email,
        String phone
) {
}
