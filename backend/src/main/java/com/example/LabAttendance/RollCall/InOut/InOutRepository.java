package com.example.LabAttendance.RollCall.InOut;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface InOutRepository extends JpaRepository<InOut, Long> {

    @Query("""
        SELECT i
        FROM InOut i
        WHERE i.attendance.member.id = :memberId
        AND i.startTime BETWEEN :start AND :end
        ORDER BY i.startTime DESC
    """)
    List<InOut> findInOutLast7Days(
            @Param("memberId") Long memberId,
            @Param("start") LocalDateTime start,
            @Param("end") LocalDateTime end
    );

}
