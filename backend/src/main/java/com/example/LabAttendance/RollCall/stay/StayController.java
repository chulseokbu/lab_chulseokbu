package com.example.LabAttendance.RollCall.stay;

import com.example.LabAttendance.RollCall.Attendance.AttendanceService;
import com.example.LabAttendance.RollCall.Attendance.Dto.DailyStayDto;
import com.example.LabAttendance.RollCall.InOut.Dto.InoutDto;
import com.example.LabAttendance.RollCall.InOut.InOutService;
import com.example.LabAttendance.RollCall.global.ResponneType.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/lab/stay")
public class StayController {

    private final InOutService inOutService;
    private final AttendanceService attendanceService;

    /**
     * 최근 7일 체크인/체크아웃 조회
     */
    @GetMapping("/week")
    public ResponseEntity<ApiResponse<List<InoutDto>>> getLast7Days(
            @AuthenticationPrincipal Long memberId
    ) {
        List<InoutDto> result = inOutService.getLast7Days(memberId);

        return ResponseEntity.ok(
                ApiResponse.success(result, "최근 7일 체크인/체크아웃 조회 성공")
        );
    }

    /**
     * 최근 30일 간 하루별 총 잔류 시간 조회
     */
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
