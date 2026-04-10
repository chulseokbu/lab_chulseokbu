package com.example.LabAttendance.RollCall;

import com.example.LabAttendance.RollCall.global.jwt.JwtAuthenticationFilter;
import com.example.LabAttendance.RollCall.global.jwt.JwtTokenProvider;
import com.example.LabAttendance.RollCall.global.jwt.TokenBlacklistService;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.boot.autoconfigure.security.servlet.PathRequest;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtTokenProvider jwtTokenProvider;
    private final TokenBlacklistService tokenBlacklistService;

    public SecurityConfig(JwtTokenProvider jwtTokenProvider, TokenBlacklistService tokenBlacklistService) {
        this.jwtTokenProvider = jwtTokenProvider;
        this.tokenBlacklistService = tokenBlacklistService;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                // CORS 허용 (Flutter Web / 로컬 개발 연결)
                .cors(Customizer.withDefaults())
                // JWT를 사용하므로 CSRF 보호를 비활성화합니다.
                .csrf(AbstractHttpConfigurer::disable)

                // JWT를 사용하므로 세션을 사용하지 않고 STATELESS로 설정
                .sessionManagement(session -> session
                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                )

                // 요청에 대한 접근 권한 설정
                .authorizeHttpRequests(authorize -> authorize
                        // Spring Boot 기본 에러 엔드포인트 (validation 등)
                        .requestMatchers("/error").permitAll()
                        // Preflight(OPTIONS) 요청 허용
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
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
                        new JwtAuthenticationFilter(jwtTokenProvider, tokenBlacklistService),
                        UsernamePasswordAuthenticationFilter.class
                );

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        // 모바일/데스크톱 Flutter는 CORS 영향이 없지만, Web에선 필요합니다.
        config.setAllowedOriginPatterns(List.of("*"));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setExposedHeaders(List.of("Authorization"));
        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}