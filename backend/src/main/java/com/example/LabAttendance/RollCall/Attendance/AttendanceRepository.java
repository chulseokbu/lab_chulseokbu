package com.example.LabAttendance.RollCall.Attendance;

import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface AttendanceRepository extends JpaRepository<Attendance, Long> {

    Optional<Attendance> findByIdAndDate(Long id, LocalDate date);

    List<Attendance> findByMemberIdAndDateBetweenOrderByDateAsc(
            Long memberId,
            LocalDate start,
            LocalDate end
    );

}

