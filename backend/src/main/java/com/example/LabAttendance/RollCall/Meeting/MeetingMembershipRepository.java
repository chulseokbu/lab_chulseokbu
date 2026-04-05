package com.example.LabAttendance.RollCall.Meeting;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MeetingMembershipRepository extends JpaRepository<MeetingMembership, Long> {

    Optional<MeetingMembership> findByMeeting_IdAndMember_Id(Long meetingId, Long memberId);

    boolean existsByMeeting_IdAndMember_Id(Long meetingId, Long memberId);

    List<MeetingMembership> findByMeeting_IdOrderByJoinedAtAsc(Long meetingId);

    Optional<MeetingMembership> findFirstByMeeting_IdAndRoleOrderByJoinedAtAsc(Long meetingId, MeetingRole role);

    List<MeetingMembership> findByMember_IdOrderByJoinedAtAsc(Long memberId);

    void deleteByMeeting_Id(Long meetingId);
}
