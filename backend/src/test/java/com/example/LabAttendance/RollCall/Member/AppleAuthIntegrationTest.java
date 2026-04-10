package com.example.LabAttendance.RollCall.Member;

import com.example.LabAttendance.RollCall.Member.apple.AppleIdTokenVerifier;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Apple 로그인 최초 플로우: auth → needsProfile → complete → auth 성공.
 * 실제 Apple 토큰/JWKS 없이 {@link AppleIdTokenVerifier}만 모킹합니다.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AppleAuthIntegrationTest {

    private static final String STABLE_APPLE_SUB = "e2e-apple-sub-001";

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @MockBean
    AppleIdTokenVerifier appleIdTokenVerifier;

    @Test
    @DisplayName("애플 최초 로그인: 428 needsProfile → complete 201 → 다시 로그인 200")
    void appleFirstLogin_fullFlow() throws Exception {
        when(appleIdTokenVerifier.verifyAndGetSubject(anyString())).thenReturn(STABLE_APPLE_SUB);

        String dummyToken = "header.payload.sig";
        long suffix = System.nanoTime();
        long memberNum = 20240000L + (Math.abs(suffix) % 100000);
        String email = "apple-e2e-" + suffix + "@test.local";
        String nickname = "AppleOnboardingE2E";
        String bodyComplete = """
                {
                  "identityToken": "%s",
                  "memberId": %d,
                  "nickname": "%s",
                  "email": "%s",
                  "phone": "010-9999-8888",
                  "gender": "MALE"
                }
                """.formatted(dummyToken, memberNum, nickname, email);

        // 1) 미가입 → 428 Precondition Required + needsProfile
        mockMvc.perform(
                        post("/lab/users/auth/apple")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"identityToken\":\"" + dummyToken + "\"}"))
                .andExpect(status().isPreconditionRequired())
                .andExpect(jsonPath("$.needsProfile").value(true));

        // 2) 온보딩 완료
        MvcResult created = mockMvc.perform(
                        post("/lab/users/auth/apple/complete")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(bodyComplete))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.accessToken").exists())
                .andExpect(jsonPath("$.memberId").value(memberNum))
                .andExpect(jsonPath("$.email").value(email))
                .andReturn();

        JsonNode root = objectMapper.readTree(created.getResponse().getContentAsString());
        assertThat(root.path("accessToken").asText()).isNotBlank();
        assertThat(root.path("username").asText()).isEqualTo(nickname);

        // 3) 기존 연동 회원 로그인
        mockMvc.perform(
                        post("/lab/users/auth/apple")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"identityToken\":\"" + dummyToken + "\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").exists())
                .andExpect(jsonPath("$.memberId").value(memberNum))
                .andExpect(jsonPath("$.email").value(email));
    }
}
