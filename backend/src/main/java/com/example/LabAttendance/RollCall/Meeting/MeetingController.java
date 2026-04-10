package com.example.LabAttendance.RollCall.Meeting;

import com.example.LabAttendance.RollCall.Meeting.Dto.*;
import com.example.LabAttendance.RollCall.global.Exception.AlreadyInMeetingException;
import com.example.LabAttendance.RollCall.global.ResponneType.ApiResponse;
import com.example.LabAttendance.RollCall.global.ResponneType.NoDataApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.persistence.EntityNotFoundException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.validation.BindingResult;
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
        } catch (AlreadyInMeetingException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ApiResponse.failure(e.getMessage()));
        }
    }

    @Operation(summary = "모임 상세", description = "참여 중인 구성원만 조회합니다. 초대 코드는 모임장에게만 포함됩니다.")
    @GetMapping("/{meetingId}")
    public ResponseEntity<ApiResponse<MeetingDetailResponseDto>> getMeeting(
            @AuthenticationPrincipal Long memberId,
            @PathVariable Long meetingId
    ) {
        try {
            return ResponseEntity.ok(ApiResponse.success(
                    meetingService.getMeetingDetail(memberId, meetingId),
                    "모임 상세 조회 성공"
            ));
        } catch (EntityNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.failure(e.getMessage()));
        }
    }

    @Operation(summary = "모임 탈퇴", description = "모임장이 나가면 가장 먼저 가입한 구성원이 모임장이 됩니다. 남은 사람이 없으면 모임이 삭제됩니다.")
    @PostMapping("/{meetingId}/leave")
    public ResponseEntity<?> leaveMeeting(
            @AuthenticationPrincipal Long memberId,
            @PathVariable Long meetingId
    ) {
        try {
            meetingService.leaveMeeting(memberId, meetingId);
            return ResponseEntity.ok(NoDataApiResponse.success("모임에서 탈퇴했습니다."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.failure(e.getMessage()));
        } catch (EntityNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.failure(e.getMessage()));
        }
    }

    @Operation(summary = "모임 삭제", description = "모임장(생성자)만 전체 모임을 삭제할 수 있습니다.")
    @DeleteMapping("/{meetingId}")
    public ResponseEntity<?> deleteMeeting(
            @AuthenticationPrincipal Long memberId,
            @PathVariable Long meetingId
    ) {
        try {
            meetingService.deleteMeeting(memberId, meetingId);
            return ResponseEntity.ok(NoDataApiResponse.success("모임이 삭제되었습니다."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ApiResponse.failure(e.getMessage()));
        } catch (EntityNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.failure(e.getMessage()));
        }
    }

    @Operation(summary = "모임장 위임", description = "모임장이 다른 구성원에게 생성자 권한을 넘깁니다.")
    @PostMapping("/{meetingId}/delegate")
    public ResponseEntity<?> delegateLeadership(
            @AuthenticationPrincipal Long memberId,
            @PathVariable Long meetingId,
            @Valid @RequestBody DelegateLeaderRequestDto request,
            BindingResult bindingResult
    ) {
        if (bindingResult.hasErrors()) {
            return ResponseEntity.badRequest().body(bindingResult.getFieldErrors());
        }
        try {
            meetingService.delegateLeadership(memberId, meetingId, request.newLeaderMemberId());
            return ResponseEntity.ok(NoDataApiResponse.success("모임장 권한이 위임되었습니다."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.failure(e.getMessage()));
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

