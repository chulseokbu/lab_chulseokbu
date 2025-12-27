package com.example.LabAttendance.RollCall.InOut;

import com.example.LabAttendance.RollCall.InOut.Dto.InoutDto;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class InOutService {

    private final InOutRepository inoutRepository;

    public List<InoutDto> getLast7Days(Long memberId) {
        LocalDateTime end = LocalDateTime.now();
        LocalDateTime start = end.minusDays(7);

        return inoutRepository.findInOutLast7Days(memberId, start, end)
                .stream()
                .map(InoutDto::from)
                .toList();
    }
}

