package com.example.LabAttendance.RollCall.Meeting;

import com.example.LabAttendance.RollCall.Attendance.Attendance;
import com.example.LabAttendance.RollCall.Attendance.AttendanceStatus;
import com.example.LabAttendance.RollCall.Attendance.AttendanceRepository;
import com.example.LabAttendance.RollCall.Attendance.Dto.DailyStayDto;
import com.example.LabAttendance.RollCall.InOut.InOut;
import com.example.LabAttendance.RollCall.InOut.InOutRepository;
import com.example.LabAttendance.RollCall.InOut.Dto.InoutDto;
import com.example.LabAttendance.RollCall.Meeting.Dto.*;
import com.example.LabAttendance.RollCall.Member.Member;
import com.example.LabAttendance.RollCall.Member.MemberRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
@RequiredArgsConstructor
@Transactional
public class MeetingService {

    private final MeetingRepository meetingRepository;
    private final MeetingMemberRepository meetingMemberRepository;
    private final MeetingCodeGenerator codeGenerator;
    private final MemberRepository memberRepository;
    private final AttendanceRepository attendanceRepository;
    private final InOutRepository inOutRepository;

    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("HH:mm");

    public MeetingResponseDto createMeeting(Long memberId, MeetingCreateRequestDto req) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("로그인 먼저 진행해 주세요"));

        Meeting saved = null;
        for (int i = 0; i < 30; i++) {
            String code = codeGenerator.generate();
            try {
                saved = meetingRepository.save(new Meeting(code, req.name(), member));
                break;
            } catch (DataIntegrityViolationException e) {
                // code 유니크 충돌 시 재시도
            }
        }
        if (saved == null) {
            throw new IllegalStateException("모임 코드 생성에 실패했습니다. 잠시 후 다시 시도해주세요.");
        }

        meetingMemberRepository.save(new MeetingMember(saved, member));
        int memberCount = 1;

        return MeetingResponseDto.from(saved, memberCount);
    }

    public MeetingResponseDto joinMeeting(Long memberId, MeetingJoinRequestDto req) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("로그인 먼저 진행해 주세요"));

        String code = req.code() != null ? req.code().trim().toUpperCase() : "";
        Meeting meeting = meetingRepository.findByCode(code)
                .orElseThrow(() -> new EntityNotFoundException("모임을 찾을 수 없습니다."));

        if (!meetingMemberRepository.existsByMeeting_IdAndMember_Id(meeting.getId(), member.getId())) {
            meetingMemberRepository.save(new MeetingMember(meeting, member));
        }

        int memberCount = meetingMemberRepository.findAllByMeetingIdWithMember(meeting.getId()).size();
        return MeetingResponseDto.from(meeting, memberCount);
    }

    @Transactional(readOnly = true)
    public List<MeetingResponseDto> listMyMeetings(Long memberId) {
        List<MeetingMember> memberships = meetingMemberRepository.findAllByMemberIdWithMeeting(memberId);
        List<MeetingResponseDto> result = new ArrayList<>();
        for (MeetingMember mm : memberships) {
            Meeting m = mm.getMeeting();
            int count = meetingMemberRepository.findAllByMeetingIdWithMember(m.getId()).size();
            result.add(MeetingResponseDto.from(m, count));
        }
        return result;
    }

    @Transactional(readOnly = true)
    public List<MeetingMemberRetentionDto> getRetention(Long requesterMemberId, Long meetingId) {
        assertMemberInMeeting(requesterMemberId, meetingId);

        List<MeetingMember> meetingMembers = meetingMemberRepository.findAllByMeetingIdWithMember(meetingId);
        List<Long> memberIds = meetingMembers.stream().map(mm -> mm.getMember().getId()).toList();

        LocalDate today = LocalDate.now();
        Map<Long, Attendance> todayAttendanceByMemberId = new HashMap<>();
        for (Attendance a : attendanceRepository.findByMemberIdsAndDateBetweenWithInOuts(memberIds, today, today)) {
            todayAttendanceByMemberId.put(a.getMember().getId(), a);
        }

        List<MeetingMemberRetentionDto> result = new ArrayList<>();
        for (MeetingMember mm : meetingMembers) {
            Member mem = mm.getMember();
            Attendance todayAttendance = todayAttendanceByMemberId.get(mem.getId());

            // "잔류 중"은 오늘 출석이 있고, 아직 체크아웃(endTime)이 없는 inout이 존재하는 경우로 정의합니다.
            boolean isPresent = todayAttendance != null && hasOpenInOut(todayAttendance);
            String checkIn = null;
            String lastExit = null;
            // 잔류 시간(duration)은 프론트에서 (now - checkIn)으로 실시간 계산하도록 null로 둡니다.
            String duration = null;

            if (isPresent) {
                // 오늘 "가장 최근 체크인(현재 열려 있는 세션의 시작시간)" 기준
                checkIn = latestOpenCheckInTime(todayAttendance);
            } else {
                Optional<InOut> last = inOutRepository
                        .findTopByAttendance_Member_IdAndEndTimeIsNotNullOrderByAttendance_DateDescEndTimeDesc(mem.getId());
                if (last.isPresent() && last.get().getAttendance() != null) {
                    String date = last.get().getAttendance().getDate() != null ? last.get().getAttendance().getDate().toString() : null;
                    String time = last.get().getEndTime() != null ? last.get().getEndTime().format(TIME_FORMATTER) : null;
                    if (date != null && time != null) {
                        lastExit = date + " " + time;
                    }
                }
            }

            result.add(new MeetingMemberRetentionDto(
                    mem.getId(),
                    mem.getNickname(),
                    mem.getNickname() != null && !mem.getNickname().isBlank() ? mem.getNickname().substring(0, 1) : "",
                    isPresent,
                    checkIn,
                    lastExit,
                    duration
            ));
        }
        return result;
    }

    @Transactional(readOnly = true)
    public List<MemberWeekStayDto> getWeekStay(Long requesterMemberId, Long meetingId) {
        assertMemberInMeeting(requesterMemberId, meetingId);
        List<MeetingMember> meetingMembers = meetingMemberRepository.findAllByMeetingIdWithMember(meetingId);
        List<Long> memberIds = meetingMembers.stream().map(mm -> mm.getMember().getId()).toList();

        LocalDate end = LocalDate.now();
        LocalDate start = end.minusDays(6);

        // inout을 한 번에 가져오고, memberId별로 묶기
        List<InOut> inOuts = inOutRepository.findInOutsForMembersBetween(memberIds, start, end);
        Map<Long, List<InoutDto>> byMember = new HashMap<>();
        for (InOut io : inOuts) {
            Long mid = io.getAttendance().getMember().getId();
            byMember.computeIfAbsent(mid, k -> new ArrayList<>()).add(InoutDto.from(io));
        }

        List<MemberWeekStayDto> result = new ArrayList<>();
        for (MeetingMember mm : meetingMembers) {
            Member m = mm.getMember();
            result.add(new MemberWeekStayDto(
                    m.getId(),
                    m.getNickname(),
                    byMember.getOrDefault(m.getId(), List.of())
            ));
        }
        return result;
    }

    @Transactional(readOnly = true)
    public List<MemberMonthStayDto> getMonthStay(Long requesterMemberId, Long meetingId) {
        assertMemberInMeeting(requesterMemberId, meetingId);
        List<MeetingMember> meetingMembers = meetingMemberRepository.findAllByMeetingIdWithMember(meetingId);
        List<Long> memberIds = meetingMembers.stream().map(mm -> mm.getMember().getId()).toList();

        LocalDate end = LocalDate.now();
        LocalDate start = end.minusDays(30);

        List<Attendance> attendances = attendanceRepository.findByMemberIdsAndDateBetween(memberIds, start, end);
        Map<Long, List<DailyStayDto>> byMember = new HashMap<>();
        for (Attendance a : attendances) {
            Long mid = a.getMember().getId();
            byMember.computeIfAbsent(mid, k -> new ArrayList<>()).add(DailyStayDto.from(a));
        }

        List<MemberMonthStayDto> result = new ArrayList<>();
        for (MeetingMember mm : meetingMembers) {
            Member m = mm.getMember();
            result.add(new MemberMonthStayDto(
                    m.getId(),
                    m.getNickname(),
                    byMember.getOrDefault(m.getId(), List.of())
            ));
        }
        return result;
    }

    private void assertMemberInMeeting(Long memberId, Long meetingId) {
        if (!meetingMemberRepository.existsByMeeting_IdAndMember_Id(meetingId, memberId)) {
            throw new EntityNotFoundException("모임에 참여 중인 사용자만 조회할 수 있습니다.");
        }
    }

    private boolean hasOpenInOut(Attendance todayAttendance) {
        if (todayAttendance.getInOuts() == null) return false;
        return todayAttendance.getInOuts().stream().anyMatch(io -> io.getEndTime() == null);
    }

    private String latestOpenCheckInTime(Attendance todayAttendance) {
        if (todayAttendance.getInOuts() == null || todayAttendance.getInOuts().isEmpty()) return null;
        return todayAttendance.getInOuts().stream()
                .filter(io -> io.getEndTime() == null)
                .map(InOut::getStartTime)
                .filter(Objects::nonNull)
                .max(LocalTime::compareTo)
                .map(t -> t.format(TIME_FORMATTER))
                .orElse(null);
    }
}

