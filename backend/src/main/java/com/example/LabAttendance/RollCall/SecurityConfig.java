package com.example.LabAttendance.RollCall;

import com.example.LabAttendance.RollCall.global.jwt.JwtAuthenticationFilter;
import com.example.LabAttendance.RollCall.global.jwt.JwtTokenProvider;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.boot.autoconfigure.security.servlet.PathRequest;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtTokenProvider jwtTokenProvider;

    // JwtTokenProvider를 주입받아 사용합니다.
    public SecurityConfig(JwtTokenProvider jwtTokenProvider) {
        this.jwtTokenProvider = jwtTokenProvider;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                // JWT를 사용하므로 CSRF 보호를 비활성화합니다.
                .csrf(AbstractHttpConfigurer::disable)

                // JWT를 사용하므로 세션을 사용하지 않고 STATELESS로 설정
                .sessionManagement(session -> session
                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                )

                // H2 콘솔 접근을 위한 설정
                .headers(headers -> headers
                        .frameOptions(frameOptions -> frameOptions.disable())
                )

                // 요청에 대한 접근 권한 설정
                .authorizeHttpRequests(authorize -> authorize
                        // H2 Console 경로 허용
                        .requestMatchers(PathRequest.toH2Console()).permitAll()
                        .requestMatchers(PathRequest.toStaticResources().atCommonLocations()).permitAll()


                        // 회원가입 및 로그인 경로는 인증 없이 접근 허용
                        .requestMatchers(
                                "/lab/users/sign",
                                "/lab/users/login",
                                "/swagger-ui.html",
                                "/swagger-ui/**",
                                "/v3/api-docs/**"
                                ).permitAll()

                        // 그 외 모든 요청은 인증 필요
                        .anyRequest().authenticated()
                )

                // JWT 인증 필터를 UsernamePasswordAuthenticationFilter 이전에 등록합니다.
                .addFilterBefore(
                        new JwtAuthenticationFilter(jwtTokenProvider),
                        UsernamePasswordAuthenticationFilter.class
                );

        return http.build();
    }
}