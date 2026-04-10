package com.example.LabAttendance.RollCall.Member.DTO;

import jakarta.validation.constraints.NotBlank;

public record AppleLoginRequestDto(
        @NotBlank(message = "identityToken은 필수입니다.")
        String identityToken,
        String authorizationCode,
        String userIdentifier
) {}
