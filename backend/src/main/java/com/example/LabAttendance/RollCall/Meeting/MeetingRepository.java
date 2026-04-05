package com.example.LabAttendance.RollCall.Meeting;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface MeetingRepository extends JpaRepository<Meeting, Long> {

    Optional<Meeting> findByInviteCode(String inviteCode);

    boolean existsByInviteCode(String inviteCode);
}
