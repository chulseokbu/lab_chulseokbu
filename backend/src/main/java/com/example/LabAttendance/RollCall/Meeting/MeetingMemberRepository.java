package com.example.LabAttendance.RollCall.Meeting;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface MeetingMemberRepository extends JpaRepository<MeetingMember, Long> {

    @Modifying
    @Query("DELETE FROM MeetingMember mm WHERE mm.member.id = :memberId")
    void deleteAllByMemberId(@Param("memberId") Long memberId);

    boolean existsByMeeting_IdAndMember_Id(Long meetingId, Long memberId);

    @Query("""
    select mm
    from MeetingMember mm
    join fetch mm.meeting m
    where mm.member.id = :memberId
    order by m.createdAt desc, m.id desc
    """)
    List<MeetingMember> findAllByMemberIdWithMeeting(@Param("memberId") Long memberId);

    @Query("""
    select mm
    from MeetingMember mm
    join fetch mm.member mem
    where mm.meeting.id = :meetingId
    order by mem.nickname asc, mem.id asc
    """)
    List<MeetingMember> findAllByMeetingIdWithMember(@Param("meetingId") Long meetingId);

    Optional<MeetingMember> findByMeeting_IdAndMember_Id(Long meetingId, Long memberId);
}

