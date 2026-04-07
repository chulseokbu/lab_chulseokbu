package com.example.LabAttendance.RollCall.InOut;

import com.example.LabAttendance.RollCall.InOut.Dto.InoutDto;
import com.example.LabAttendance.RollCall.global.KoreaTime;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class InOutService {

    private final InOutRepository inOutRepository;

    public List<InoutDto> getLast7Days(Long memberId) {
        LocalDate end = KoreaTime.today();
        LocalDate start = end.minusDays(6);

        return inOutRepository.findLast7DaysInOuts(memberId, start, end)
                .stream()
                .map(InoutDto::from)
                .toList();
    }
}

