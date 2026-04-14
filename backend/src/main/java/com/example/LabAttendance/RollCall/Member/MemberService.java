package com.example.LabAttendance.RollCall.Member;

import com.example.LabAttendance.RollCall.Meeting.MeetingMemberRepository;
import com.example.LabAttendance.RollCall.Meeting.MeetingRepository;
import com.example.LabAttendance.RollCall.Member.DTO.*;
import com.example.LabAttendance.RollCall.Member.apple.AppleIdTokenVerifier;
import com.example.LabAttendance.RollCall.global.Exception.DuplicateEmailException;
import com.example.LabAttendance.RollCall.global.Exception.DuplicateMemberNumException;
import com.example.LabAttendance.RollCall.global.Exception.MemberNotFoundException;
import com.example.LabAttendance.RollCall.global.jwt.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.stereotype.Service;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Optional;
import java.util.UUID;

@RequiredArgsConstructor
@Service
@Transactional
public class MemberService {

    private final MemberRepository memberRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final MeetingMemberRepository meetingMemberRepository;
    private final MeetingRepository meetingRepository;
    private final AppleIdTokenVerifier appleIdTokenVerifier;

    public MemberResponseDto create(MemberSignupRequestDto requestDto) {

        if (memberRepository.existsByEmail(requestDto.email())) {
            throw new DuplicateEmailException("이미 존재하는 이메일입니다: " + requestDto.email());
        }

        String hashedPassword = passwordEncoder.encode(requestDto.password());


        Member member = new Member(
                null,
                requestDto.memberId(),
                requestDto.nickname(),
                hashedPassword,
                requestDto.email(),
                requestDto.phone(),
                new ArrayList<>(),
                null
        );

        memberRepository.save(member);

        // 생성자 호출 후 ID가 자동 생성되어 member 객체에 반영됨
        return new MemberResponseDto(
                member.getId(),
                member.getMemberNum(),
                member.getNickname(),
                member.getEmail()
        );
    }

    public MemberProfileResponseDto updateProfile(Long memberId, ProfileUpdateRequestDto requestDto) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new MemberNotFoundException("존재하지 않는 회원입니다."));

        if (memberRepository.existsByEmailAndIdNot(requestDto.email(), memberId)) {
            throw new DuplicateEmailException("이미 존재하는 이메일입니다: " + requestDto.email());
        }

        member.updateProfile(requestDto.nickname(), requestDto.email(), requestDto.phone());

        return new MemberProfileResponseDto(
                member.getId(),
                member.getMemberNum(),
                member.getNickname(),
                member.getEmail(),
                member.getPhone()
        );
    }

    public void withdraw(Long memberId) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new MemberNotFoundException("존재하지 않는 회원입니다."));

        meetingMemberRepository.deleteAllByMemberId(memberId);
        meetingRepository.clearCreatedByMemberId(memberId);
        memberRepository.delete(member);
    }

    public LoginResponseDto login(LoginRequestDto requestDto) {

        Member member = memberRepository.findByEmail(requestDto.email())
                .orElseThrow(() -> new MemberNotFoundException("가입되지 않은 이메일입니다."));

        if (!passwordEncoder.matches(requestDto.password(), member.getPassword())) {
            throw new BadCredentialsException("비밀번호가 일치하지 않습니다.");
        }


        return buildLoginResponse(member);
    }

    /**
     * Apple identityToken 검증 후, 동일 {@code sub}로 이미 연동된 회원이 있으면 로그인 응답.
     */
    public Optional<LoginResponseDto> loginWithApple(String identityToken) {
        String sub = appleIdTokenVerifier.verifyAndGetSubject(identityToken);
        return memberRepository.findByAppleSub(sub).map(this::buildLoginResponse);
    }

    /**
     * Apple 최초 연동: 토큰의 sub와 저장할 프로필로 회원 생성.
     */
    public LoginResponseDto completeAppleProfile(AppleCompleteRequestDto dto) {
        String sub = appleIdTokenVerifier.verifyAndGetSubject(dto.identityToken());
        if (memberRepository.findByAppleSub(sub).isPresent()) {
            throw new IllegalStateException("이미 등록된 Apple 계정입니다.");
        }
        if (memberRepository.existsByEmail(dto.email())) {
            throw new DuplicateEmailException("이미 존재하는 이메일입니다: " + dto.email());
        }
        if (memberRepository.existsByMemberNum(dto.memberId())) {
            throw new DuplicateMemberNumException("이미 사용 중인 학번입니다.");
        }
        String hashedRandom = passwordEncoder.encode(UUID.randomUUID().toString());
        Member member = new Member(
                null,
                dto.memberId(),
                dto.nickname(),
                hashedRandom,
                dto.email(),
                dto.phone(),
                new ArrayList<>(),
                sub
        );
        memberRepository.save(member);
        return buildLoginResponse(member);
    }

    private LoginResponseDto buildLoginResponse(Member member) {
        String jwtToken = jwtTokenProvider.generateToken(member.getId(), member.getEmail());
        return new LoginResponseDto(
                jwtToken,
                member.getMemberNum(),
                member.getNickname(),
                member.getPhone(),
                member.getEmail()
        );
    }
}