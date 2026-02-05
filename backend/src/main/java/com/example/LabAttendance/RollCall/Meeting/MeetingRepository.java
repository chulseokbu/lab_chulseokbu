package com.example.LabAttendance.RollCall.Meeting;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface MeetingRepository extends JpaRepository<Meeting, Long> {
    boolean existsByCode(String code);
    Optional<Meeting> findByCode(String code);
}

