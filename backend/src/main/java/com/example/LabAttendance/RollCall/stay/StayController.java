package com.example.LabAttendance.RollCall.stay;
import com.example.LabAttendance.RollCall.Attendance.Dto.DailyStayDto;
import com.example.LabAttendance.RollCall.InOut.Dto.InoutDto;

import com.example.LabAttendance.RollCall.InOut.InOutService;
import com.example.LabAttendance.RollCall.Attendance.AttendanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/lab/stay")
@RequiredArgsConstructor
public class StayController {

    private final InOutService inOutService;
    private final AttendanceService attendanceService;

    /**
     * 최근 7일 체크인/체크아웃 조회
     */
    @GetMapping("/week")
    public List<InoutDto> getLast7Days(@AuthenticationPrincipal Long memberId) {
        return inOutService.getLast7Days(memberId);
    }


    /**
     * 최근 30일 간 총 잔류시간 조회
     */
    @GetMapping("/month")
    public List<DailyStayDto> getLast30Days(
            @AuthenticationPrincipal Long memberId
    ) {
        return attendanceService.getLast30Days(memberId);
    }
}

