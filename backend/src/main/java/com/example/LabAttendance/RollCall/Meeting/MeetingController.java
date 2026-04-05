package com.example.LabAttendance.RollCall.Meeting;

import com.example.LabAttendance.RollCall.Meeting.Dto.*;
import com.example.LabAttendance.RollCall.global.Exception.*;
import com.example.LabAttendance.RollCall.global.ResponneType.ApiResponse;
import com.example.LabAttendance.RollCall.global.ResponneType.NoDataApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(
        name = "Meeting (모임)",
        description = """
                모임 생성·초대 코드 가입·구성원/모임장 권한·탈퇴·삭제·모임장 위임 API

                - 모임을 만든 사람은 모임장(LEADER), 초대 코드로 들어온 사람은 구성원(MEMBER)입니다.
                - 모임 삭제는 모임장만 가능합니다.
                - 모임장이 탈퇴하면 가입 시점이 가장 이른 구성원이 자동으로 모임장이 됩니다.
                - 모임장은 특정 구성원에게 모임장 권한을 위임할 수 있습니다.
                """
)
@RestController
@RequiredArgsConstructor
@RequestMapping("/lab/meetings")
public class MeetingController {

    private final MeetingService meetingService;

    @Operation(summary = "모임 생성", description = "인증된 회원이 모임을 만들고 모임장이 됩니다. 초대 코드가 응답에 포함됩니다.")
    @PostMapping
    public ResponseEntity<?> createMeeting(
            @AuthenticationPrincipal Long memberId,
            @Valid @RequestBody CreateMeetingRequestDto request,
            BindingResult bindingResult
    ) {
        if (bindingResult.hasErrors()) {
            return ResponseEntity.badRequest().body(bindingResult.getFieldErrors());
        }
        try {
            MeetingCreatedResponseDto data = meetingService.createMeeting(memberId, request.name());
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success(data, "모임이 생성되었습니다."));
        } catch (MemberNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ApiResponse.failure(e.getMessage()));
        }
    }

    @Operation(summary = "초대 코드로 모임 가입", description = "유효한 초대 코드로 구성원(MEMBER)으로 가입합니다.")
    @PostMapping("/join")
    public ResponseEntity<?> joinMeeting(
            @AuthenticationPrincipal Long memberId,
            @Valid @RequestBody JoinMeetingRequestDto request,
            BindingResult bindingResult
    ) {
        if (bindingResult.hasErrors()) {
            return ResponseEntity.badRequest().body(bindingResult.getFieldErrors());
        }
        try {
            MeetingSummaryResponseDto data = meetingService.joinMeeting(memberId, request.inviteCode());
            return ResponseEntity.ok(ApiResponse.success(data, "모임에 가입했습니다."));
        } catch (InvalidInviteCodeException | AlreadyInMeetingException e) {
            return ResponseEntity.badRequest().body(ApiResponse.failure(e.getMessage()));
        } catch (MemberNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ApiResponse.failure(e.getMessage()));
        }
    }

    @Operation(summary = "내 모임 목록")
    @GetMapping
    public ResponseEntity<ApiResponse<List<MeetingSummaryResponseDto>>> listMyMeetings(
            @Parameter(name = "memberId", in = ParameterIn.HEADER, required = true)
            @AuthenticationPrincipal Long memberId
    ) {
        List<MeetingSummaryResponseDto> data = meetingService.listMyMeetings(memberId);
        return ResponseEntity.ok(ApiResponse.success(data, "내 모임 목록 조회 성공"));
    }

    @Operation(summary = "모임 상세", description = "구성원만 조회 가능합니다. 초대 코드는 모임장에게만 내려갑니다.")
    @GetMapping("/{meetingId}")
    public ResponseEntity<?> getMeeting(
            @AuthenticationPrincipal Long memberId,
            @PathVariable Long meetingId
    ) {
        try {
            MeetingDetailResponseDto data = meetingService.getMeeting(memberId, meetingId);
            return ResponseEntity.ok(ApiResponse.success(data, "모임 상세 조회 성공"));
        } catch (MeetingNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ApiResponse.failure(e.getMessage()));
        } catch (NotMeetingMemberException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(ApiResponse.failure(e.getMessage()));
        }
    }

    @Operation(summary = "모임 탈퇴", description = "모임장이 탈퇴하면 가장 먼저 가입한 구성원이 모임장으로 승격됩니다. 남은 사람이 없으면 모임이 삭제됩니다.")
    @PostMapping("/{meetingId}/leave")
    public ResponseEntity<?> leaveMeeting(
            @AuthenticationPrincipal Long memberId,
            @PathVariable Long meetingId
    ) {
        try {
            meetingService.leaveMeeting(memberId, meetingId);
            return ResponseEntity.ok(NoDataApiResponse.success("모임에서 탈퇴했습니다."));
        } catch (MeetingNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ApiResponse.failure(e.getMessage()));
        } catch (NotMeetingMemberException e) {
            return ResponseEntity.badRequest().body(ApiResponse.failure(e.getMessage()));
        }
    }

    @Operation(summary = "모임 삭제", description = "모임장만 전체 모임을 삭제할 수 있습니다.")
    @DeleteMapping("/{meetingId}")
    public ResponseEntity<?> deleteMeeting(
            @AuthenticationPrincipal Long memberId,
            @PathVariable Long meetingId
    ) {
        try {
            meetingService.deleteMeeting(memberId, meetingId);
            return ResponseEntity.ok(NoDataApiResponse.success("모임이 삭제되었습니다."));
        } catch (MeetingNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ApiResponse.failure(e.getMessage()));
        } catch (NotMeetingMemberException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(ApiResponse.failure(e.getMessage()));
        } catch (NotMeetingLeaderException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(ApiResponse.failure(e.getMessage()));
        }
    }

    @Operation(summary = "모임장 위임", description = "현재 모임장이 다른 구성원에게 모임장 권한을 넘깁니다. 기존 모임장은 구성원이 됩니다.")
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
        } catch (MeetingNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ApiResponse.failure(e.getMessage()));
        } catch (NotMeetingLeaderException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(ApiResponse.failure(e.getMessage()));
        } catch (NotMeetingMemberException e) {
            return ResponseEntity.badRequest().body(ApiResponse.failure(e.getMessage()));
        }
    }
}
