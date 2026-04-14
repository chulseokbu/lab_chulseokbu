package com.example.LabAttendance.RollCall.global;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * 운영 DB에서 스키마가 남아 있을 때의 간단 마이그레이션.
 *
 * <p>Hibernate ddl-auto=update는 컬럼 삭제/NOT NULL 해제를 자동으로 하지 않아서,
 * 코드에서 필드를 제거하면 INSERT가 실패(500)할 수 있습니다.</p>
 */
@Component
@RequiredArgsConstructor
public class DbStartupMigrations {
    private final JdbcTemplate jdbcTemplate;

    @jakarta.annotation.PostConstruct
    void migrate() {
        // Member.gender 제거: 기존 DB에 NOT NULL gender 컬럼이 남아있으면 가입/애플온보딩 INSERT가 500으로 터진다.
        dropColumnIfExists("member", "gender");
    }

    private void dropColumnIfExists(String tableName, String columnName) {
        try {
            Boolean exists = jdbcTemplate.queryForObject(
                    """
                            select exists(
                              select 1
                              from information_schema.columns
                              where table_schema = current_schema()
                                and table_name = ?
                                and column_name = ?
                            )
                            """,
                    Boolean.class,
                    tableName, columnName
            );
            if (exists == null || !exists) return;

            // 1) NOT NULL 제약이 있으면 먼저 해제 (DROP COLUMN 전에 안전)
            try {
                jdbcTemplate.execute("alter table " + tableName + " alter column " + columnName + " drop not null");
            } catch (Exception ignored) {
                // 이미 nullable 이거나 DB에 따라 에러 메세지가 달라 무시
            }

            // 2) 컬럼 삭제
            jdbcTemplate.execute("alter table " + tableName + " drop column " + columnName);
        } catch (Exception ignored) {
            // 마이그레이션은 best-effort. (권한/스키마명 차이 등)
        }
    }
}

