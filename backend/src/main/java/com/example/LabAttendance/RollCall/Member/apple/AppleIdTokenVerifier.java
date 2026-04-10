package com.example.LabAttendance.RollCall.Member.apple;

import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.jwk.source.RemoteJWKSet;
import com.nimbusds.jose.proc.BadJOSEException;
import com.nimbusds.jose.proc.JWSKeySelector;
import com.nimbusds.jose.proc.JWSVerificationKeySelector;
import com.nimbusds.jose.proc.SecurityContext;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.proc.ConfigurableJWTProcessor;
import com.nimbusds.jwt.proc.DefaultJWTProcessor;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.stereotype.Component;

import java.net.URL;
import java.util.Date;

/**
 * Apple identityToken(JWS) 서명·iss·aud·exp 검증 후 {@code sub} 반환.
 */
@Component
public class AppleIdTokenVerifier {

    private static final String APPLE_ISSUER = "https://appleid.apple.com";
    private static final String APPLE_JWKS = "https://appleid.apple.com/auth/keys";

    @Value("${apple.audience}")
    private String audience;

    private ConfigurableJWTProcessor<SecurityContext> jwtProcessor;

    @PostConstruct
    void init() throws Exception {
        JWKSource<SecurityContext> keySource = new RemoteJWKSet<>(new URL(APPLE_JWKS));
        ConfigurableJWTProcessor<SecurityContext> processor = new DefaultJWTProcessor<>();
        JWSKeySelector<SecurityContext> keySelector =
                new JWSVerificationKeySelector<>(JWSAlgorithm.RS256, keySource);
        processor.setJWSKeySelector(keySelector);
        processor.setJWTClaimsSetVerifier((claims, context) -> verifyClaims(claims));
        this.jwtProcessor = processor;
    }

    private void verifyClaims(JWTClaimsSet claims) {
        try {
            if (!APPLE_ISSUER.equals(claims.getIssuer())) {
                throw new BadJOSEException("Invalid issuer");
            }
            if (claims.getAudience() == null
                    || claims.getAudience().stream().noneMatch(audience::equals)) {
                throw new BadJOSEException("Invalid audience");
            }
            Date exp = claims.getExpirationTime();
            if (exp != null && !exp.after(new Date())) {
                throw new BadJOSEException("Expired token");
            }
            if (claims.getSubject() == null || claims.getSubject().isBlank()) {
                throw new BadJOSEException("Missing sub");
            }
        } catch (BadJOSEException e) {
            throw new IllegalStateException(e.getMessage(), e);
        }
    }

    public String verifyAndGetSubject(String identityToken) {
        if (identityToken == null || identityToken.isBlank()) {
            throw new BadCredentialsException("identityToken이 비어 있습니다.");
        }
        String compact = identityToken.trim();
        long dots = compact.chars().filter(c -> c == '.').count();
        if (dots != 2) {
            throw new BadCredentialsException("Apple identityToken은 JWT(세 구간) 형식이어야 합니다.");
        }
        try {
            JWTClaimsSet claims = jwtProcessor.process(compact, null);
            return claims.getSubject();
        } catch (Exception e) {
            throw new BadCredentialsException("Apple identity 토큰 검증에 실패했습니다.", e);
        }
    }
}
