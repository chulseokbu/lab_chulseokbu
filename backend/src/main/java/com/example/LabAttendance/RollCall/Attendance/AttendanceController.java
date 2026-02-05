package com.example.LabAttendance.RollCall.Attendance;

import com.example.LabAttendance.RollCall.InOut.Dto.CheckInDto;
import com.example.LabAttendance.RollCall.global.Exception.AlreadyCheckInException;
import com.example.LabAttendance.RollCall.global.Exception.AlreadyCheckOutException;
import com.example.LabAttendance.RollCall.global.Exception.NotAttendanceTodayException;
import com.example.LabAttendance.RollCall.global.ResponneType.ApiResponse;
import com.example.LabAttendance.RollCall.global.ResponneType.NoDataApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@Tag(
        name = "Lab Attendance",
        description = """
                실험실 출석 관리 API

                - 인증된 사용자(memberId)를 기준으로 출석을 관리합니다.
                - 체크인: 오늘 날짜 기준 입실 기록을 생성합니다.
                - 체크아웃: 특정 체크인 기록(checkInId)에 대해 퇴실을 처리합니다.
                """
)
@RestController
@RequiredArgsConstructor
@RequestMapping("/lab/attendance")
public class AttendanceController {

    private final AttendanceService attendanceService;

    @Operation(
            summary = "체크인 (입실)",
            description = """
                    오늘 날짜 기준으로 실험실 **체크인(입실)** 을 수행합니다.

                    ### 처리 흐름
                    1. 인증된 사용자 ID(memberId)를 SecurityContext에서 가져옵니다.
                    2. 오늘 체크인 기록이 없다면 새로운 체크인 기록을 생성합니다.
                    3. 생성된 체크인 ID를 `CheckInDto`로 감싸 반환합니다.

                    ### 실패 조건
                    - 이미 오늘 체크인을 완료한 경우 체크인이 거부됩니다.
                    """,
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "200",
                            description = "체크인 성공",
                            content = @Content(
                                    mediaType = "application/json",
                                    schema = @Schema(implementation = ApiResponse.class),
                                    examples = @ExampleObject(
                                            name = "check-in-success",
                                            summary = "체크인 성공 응답",
                                            value = """
                                                    {
                                                      "success": true,
                                                      "message": "체크인 되었습니다.",
                                                      "data": {
                                                        "checkInId": 15
                                                      }
                                                    }
                                                    """
                                    )
                            )
                    ),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "400",
                            description = "이미 체크인한 상태",
                            content = @Content(
                                    mediaType = "application/json",
                                    schema = @Schema(implementation = ApiResponse.class),
                                    examples = @ExampleObject(
                                            name = "already-checked-in",
                                            summary = "중복 체크인 실패",
                                            value = """
                                                    {
                                                      "success": false,
                                                      "message": "이미 체크인 되어 있습니다.",
                                                      "data": null
                                                    }
                                                    """
                                    )
                            )
                    )
            }
    )
    @PostMapping("/in")
    public ResponseEntity<ApiResponse<CheckInDto>> checkIn(
            @Parameter(
                    name = "memberId",
                    description = """
                            인증된 사용자 식별자  
                            - JWT 또는 세션 인증 후 SecurityContext에서 주입됩니다.
                            - 요청 바디나 쿼리 파라미터로 전달되지 않습니다.
                            """,
                    in = ParameterIn.HEADER,
                    required = true,
                    example = "101"
            )
            @AuthenticationPrincipal Long memberId
    ) {
        try {
            return ResponseEntity.status(200)
                    .body(ApiResponse.success(
                            new CheckInDto(attendanceService.checkInLab(memberId)),
                            "체크인 되었습니다."
                    ));
        } catch (AlreadyCheckInException e) {
            return ResponseEntity.status(400)
                    .body(ApiResponse.failure(e.getMessage()));
        }
    }

    @Operation(
            summary = "체크아웃 (퇴실)",
            description = """
                    체크인 기록(checkInId)에 대해 실험실 **체크아웃(퇴실)** 을 수행합니다.

                    ### 처리 흐름
                    1. 인증된 사용자 ID(memberId)를 확인합니다.
                    2. 전달된 checkInId가 오늘의 체크인 기록인지 검증합니다.
                    3. 정상적인 경우 체크아웃 시간을 기록합니다.

                    ### 실패 조건
                    - 오늘 체크인 기록이 없는 경우
                    - 이미 체크아웃이 완료된 경우
                    - checkInId가 존재하지 않는 경우
                    """,
            parameters = {
                    @Parameter(
                            name = "inout_id",
                            description = "체크아웃 처리할 체크인 ID",
                            required = true,
                            in = ParameterIn.PATH,
                            example = "15"
                    )
            },
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "200",
                            description = "체크아웃 성공",
                            content = @Content(
                                    mediaType = "application/json",
                                    schema = @Schema(implementation = NoDataApiResponse.class),
                                    examples = @ExampleObject(
                                            name = "check-out-success",
                                            summary = "체크아웃 성공 응답",
                                            value = """
                                                    {
                                                      "success": true,
                                                      "message": "체크아웃 되었습니다"
                                                    }
                                                    """
                                    )
                            )
                    ),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "400",
                            description = "체크아웃 불가 (체크인 없음 또는 중복 처리)",
                            content = @Content(
                                    mediaType = "application/json",
                                    schema = @Schema(implementation = NoDataApiResponse.class),
                                    examples = {
                                            @ExampleObject(
                                                    name = "no-checkin-today",
                                                    summary = "오늘 체크인 기록 없음",
                                                    value = """
                                                            {
                                                              "success": false,
                                                              "message": "체크인 먼저 진행해주세요"
                                                            }
                                                            """
                                            ),
                                            @ExampleObject(
                                                    name = "already-checked-out",
                                                    summary = "이미 체크아웃됨",
                                                    value = """
                                                            {
                                                              "success": false,
                                                              "message": "이미 처리된 출석 기록입니다."
                                                            }
                                                            """
                                            )
                                    }
                            )
                    ),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "404",
                            description = "체크인 기록 없음",
                            content = @Content(
                                    mediaType = "application/json",
                                    schema = @Schema(implementation = NoDataApiResponse.class),
                                    examples = @ExampleObject(
                                            name = "checkin-not-found",
                                            summary = "존재하지 않는 checkInId",
                                            value = """
                                                    {
                                                      "success": false,
                                                      "message": "해당 기록을 찾을 수 없습니다."
                                                    }
                                                    """
                                    )
                            )
                    )
            }
    )
    @PostMapping("/out/{inout_id}")
    public ResponseEntity<NoDataApiResponse> checkOut(
            @AuthenticationPrincipal Long memberId,
            @PathVariable(name = "inout_id") Long inoutId
    ) {
        try {
            attendanceService.checkOutLab(memberId, inoutId);
            return ResponseEntity.status(200)
                    .body(NoDataApiResponse.success("체크아웃 되었습니다"));
        } catch (NotAttendanceTodayException e) {
            return ResponseEntity.status(400)
                    .body(NoDataApiResponse.failure("체크인 먼저 진행해주세요"));
        } catch (AlreadyCheckOutException e) {
            return ResponseEntity.status(400)
                    .body(NoDataApiResponse.failure(e.getMessage()));
        } catch (EntityNotFoundException e) {
            return ResponseEntity.status(404)
                    .body(NoDataApiResponse.failure(e.getMessage()));
        }
    }
}
