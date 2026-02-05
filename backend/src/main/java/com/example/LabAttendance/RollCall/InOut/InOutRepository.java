package com.example.LabAttendance.RollCall.InOut;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface InOutRepository extends JpaRepository<InOut, Long> {

    @Query("""
    select io
    from InOut io
    join io.attendance a
    where a.member.id = :memberId
      and a.date between :startDate and :endDate
    order by a.date desc, io.startTime asc
    """)
    List<InOut> findLast7DaysInOuts(
            @Param("memberId") Long memberId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );
}
