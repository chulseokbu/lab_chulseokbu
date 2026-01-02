package com.example.LabAttendance.RollCall.InOut;

import com.example.LabAttendance.RollCall.Attendance.Attendance;
import com.example.LabAttendance.RollCall.Attendance.AttendanceRepository;
import com.example.LabAttendance.RollCall.InOut.Dto.InoutDto;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class InOutService {

    private final AttendanceRepository attendanceRepository;

    public List<InoutDto> getLast7Days(Long memberId) {
        LocalDate end = LocalDate.now();
        LocalDate start = end.minusDays(6);

        List<Attendance> attendances =
                attendanceRepository.findLast7Days(memberId, start, end);

        return attendances.stream()
                .flatMap(a -> a.getInOuts().stream())
                .map(InoutDto::from)
                .toList();
    }
}

