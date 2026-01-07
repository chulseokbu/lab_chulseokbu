package com.example.LabAttendance.RollCall.stay;

import com.example.LabAttendance.RollCall.Attendance.AttendanceService;
import com.example.LabAttendance.RollCall.Attendance.Dto.DailyStayDto;
import com.example.LabAttendance.RollCall.InOut.Dto.InoutDto;
import com.example.LabAttendance.RollCall.InOut.InOutService;
import com.example.LabAttendance.RollCall.global.ResponneType.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(
        name = "Lab Stay",
        description = """
                실험실 체류 시간 조회 API

                - 사용자의 출석(체크인/체크아웃) 기록을 기반으로
                  최근 체류 이력을 조회합니다.
                - 주 단위(7일), 월 단위(30일) 조회를 제공합니다.
                """
)
@RestController
@RequiredArgsConstructor
@RequestMapping("/lab/stay")
public class StayController {

    private final InOutService inOutService;
    private final AttendanceService attendanceService;

    @Operation(
            summary = "최근 7일 체크인/체크아웃 조회",
            description = """
                    최근 **7일간** 사용자의 체크인/체크아웃 기록을 조회합니다.

                    ### 조회 기준
                    - 인증된 사용자(memberId)
                    - 오늘을 기준으로 과거 7일

                    ### 반환 데이터
                    - 날짜별 체크인/체크아웃 기록 목록
                    """,
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "200",
                            description = "최근 7일 체크인/체크아웃 조회 성공",
                            content = @Content(
                                    mediaType = "application/json",
                                    schema = @Schema(implementation = ApiResponse.class),
                                    examples = @ExampleObject(
                                            name = "week-stay-success",
                                            summary = "최근 7일 조회 성공",
                                            value = """
                                                    {
                                                      "success": true,
                                                      "message": "최근 7일 체크인/체크아웃 조회 성공",
                                                      "data": [
                                                        { },
                                                        { }
                                                      ]
                                                    }
                                                    """
                                    )
                            )
                    )
            }
    )
    @GetMapping("/week")
    public ResponseEntity<ApiResponse<List<InoutDto>>> getLast7Days(
            @Parameter(
                    name = "memberId",
                    description = """
                            인증된 사용자 식별자  
                            - JWT 또는 세션 인증 이후 SecurityContext에서 주입됩니다.
                            """,
                    in = ParameterIn.HEADER,
                    required = true,
                    example = "101"
            )
            @AuthenticationPrincipal Long memberId
    ) {
        List<InoutDto> result = inOutService.getLast7Days(memberId);

        return ResponseEntity.ok(
                ApiResponse.success(result, "최근 7일 체크인/체크아웃 조회 성공")
        );
    }

    @Operation(
            summary = "최근 30일 하루별 체류 시간 조회",
            description = """
                    최근 **30일간** 하루 단위로 사용자의 총 체류 시간을 조회합니다.

                    ### 조회 기준
                    - 인증된 사용자(memberId)
                    - 하루 단위 집계 결과 반환

                    ### 반환 데이터
                    - 날짜별 총 체류 시간 목록
                    """,
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "200",
                            description = "최근 30일 체류 시간 조회 성공",
                            content = @Content(
                                    mediaType = "application/json",
                                    schema = @Schema(implementation = ApiResponse.class),
                                    examples = @ExampleObject(
                                            name = "month-stay-success",
                                            summary = "최근 30일 조회 성공",
                                            value = """
                                                    {
                                                      "success": true,
                                                      "message": "최근 30일 잔류 시간 조회 성공",
                                                      "data": [
                                                        { },
                                                        { }
                                                      ]
                                                    }
                                                    """
                                    )
                            )
                    )
            }
    )
    @GetMapping("/month")
    public ResponseEntity<ApiResponse<List<DailyStayDto>>> getLast30Days(
            @AuthenticationPrincipal Long memberId
    ) {
        List<DailyStayDto> result = attendanceService.getLast30Days(memberId);

        return ResponseEntity.ok(
                ApiResponse.success(result, "최근 30일 잔류 시간 조회 성공")
        );
    }
}
