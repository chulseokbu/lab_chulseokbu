package com.example.LabAttendance.RollCall.Meeting;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface MeetingRepository extends JpaRepository<Meeting, Long> {
    boolean existsByCode(String code);
    Optional<Meeting> findByCode(String code);

    @Modifying
    @Query("UPDATE Meeting m SET m.createdBy = null WHERE m.createdBy.id = :memberId")
    void clearCreatedByMemberId(@Param("memberId") Long memberId);
}

