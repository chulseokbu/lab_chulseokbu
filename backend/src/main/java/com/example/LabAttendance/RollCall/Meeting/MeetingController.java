package com.example.LabAttendance.RollCall.Meeting;

import com.example.LabAttendance.RollCall.Meeting.Dto.*;
import com.example.LabAttendance.RollCall.global.ResponneType.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.persistence.EntityNotFoundException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "Meeting", description = "모임(그룹) 생성/참여 및 모임 단위 조회 API")
@RestController
@RequiredArgsConstructor
@RequestMapping("/lab/meetings")
public class MeetingController {

    private final MeetingService meetingService;

    @Operation(summary = "내 모임 목록")
    @GetMapping
    public ResponseEntity<ApiResponse<List<MeetingResponseDto>>> list(
            @AuthenticationPrincipal Long memberId
    ) {
        try {
            return ResponseEntity.ok(ApiResponse.success(
                    meetingService.listMyMeetings(memberId),
                    "내 모임 목록 조회 성공"
            ));
        } catch (EntityNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.failure(e.getMessage()));
        }
    }

    @Operation(summary = "모임 생성 (서버가 6자리 코드 생성)")
    @PostMapping
    public ResponseEntity<ApiResponse<MeetingResponseDto>> create(
            @AuthenticationPrincipal Long memberId,
            @Valid @RequestBody MeetingCreateRequestDto req
    ) {
        try {
            MeetingResponseDto created = meetingService.createMeeting(memberId, req);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success(created, "모임 생성 성공"));
        } catch (EntityNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.failure(e.getMessage()));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.failure(e.getMessage()));
        }
    }

    @Operation(summary = "모임 참여 (코드로 참여)")
    @PostMapping("/join")
    public ResponseEntity<ApiResponse<MeetingResponseDto>> join(
            @AuthenticationPrincipal Long memberId,
            @Valid @RequestBody MeetingJoinRequestDto req
    ) {
        try {
            MeetingResponseDto joined = meetingService.joinMeeting(memberId, req);
            return ResponseEntity.ok(ApiResponse.success(joined, "모임 참여 성공"));
        } catch (EntityNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.failure(e.getMessage()));
        }
    }

    @Operation(summary = "모임 구성원 잔류(출석) 현황(오늘)")
    @GetMapping("/{meetingId}/retention")
    public ResponseEntity<ApiResponse<List<MeetingMemberRetentionDto>>> retention(
            @AuthenticationPrincipal Long memberId,
            @PathVariable Long meetingId
    ) {
        try {
            return ResponseEntity.ok(ApiResponse.success(
                    meetingService.getRetention(memberId, meetingId),
                    "모임 잔류 현황 조회 성공"
            ));
        } catch (EntityNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.failure(e.getMessage()));
        }
    }

    @Operation(summary = "모임 구성원 최근 7일 체크인/체크아웃")
    @GetMapping("/{meetingId}/stay/week")
    public ResponseEntity<ApiResponse<List<MemberWeekStayDto>>> weekStay(
            @AuthenticationPrincipal Long memberId,
            @PathVariable Long meetingId
    ) {
        try {
            return ResponseEntity.ok(ApiResponse.success(
                    meetingService.getWeekStay(memberId, meetingId),
                    "모임 최근 7일 체크인/체크아웃 조회 성공"
            ));
        } catch (EntityNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.failure(e.getMessage()));
        }
    }

    @Operation(summary = "모임 구성원 최근 30일 체류 시간")
    @GetMapping("/{meetingId}/stay/month")
    public ResponseEntity<ApiResponse<List<MemberMonthStayDto>>> monthStay(
            @AuthenticationPrincipal Long memberId,
            @PathVariable Long meetingId
    ) {
        try {
            return ResponseEntity.ok(ApiResponse.success(
                    meetingService.getMonthStay(memberId, meetingId),
                    "모임 최근 30일 잔류 시간 조회 성공"
            ));
        } catch (EntityNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.failure(e.getMessage()));
        }
    }
}

