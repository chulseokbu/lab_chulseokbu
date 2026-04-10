package com.example.LabAttendance.RollCall.Attendance;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface AttendanceRepository extends JpaRepository<Attendance, Long> {

    @Query("""
    select a
    from Attendance a
    where a.member.id = :memberId
      and a.date = :date
    """)
    Optional<Attendance> findByMemberIdAndDate(Long memberId, LocalDate date);

    List<Attendance> findByMemberIdAndDateBetweenOrderByDateAsc(
            Long memberId,
            LocalDate start,
            LocalDate end
    );

    // 특정 기간동안의 출석 정보를 가져오는 쿼리
    @Query("""
    select a
    from Attendance a
    where a.member.id = :memberId
      and a.date between :startDate and :endDate
    order by a.date desc
    """)
    List<Attendance> findLast7Days(
            Long memberId,
            LocalDate startDate,
            LocalDate endDate
    );

    @Query("""
    select distinct a
    from Attendance a
    left join fetch a.inOuts io
    where a.member.id in :memberIds
      and a.date between :startDate and :endDate
    """)
    List<Attendance> findByMemberIdsAndDateBetweenWithInOuts(
            @Param("memberIds") List<Long> memberIds,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );

    @Query("""
    select a
    from Attendance a
    where a.member.id in :memberIds
      and a.date between :startDate and :endDate
    order by a.member.id asc, a.date asc
    """)
    List<Attendance> findByMemberIdsAndDateBetween(
            @Param("memberIds") List<Long> memberIds,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );




}

