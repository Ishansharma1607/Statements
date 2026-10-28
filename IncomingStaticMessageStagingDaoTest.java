package com.citi.qlm.staticinterface.common.dao;

import java.sql.Timestamp;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.MockedConstruction;
import org.springframework.jdbc.core.JdbcTemplate;

import com.citi.qlm.staticinterface.common.exception.MlvProcessingException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockConstruction;
import static org.mockito.Mockito.verify;

class IncomingStaticMessageStagingDaoTest {

    @Test
    void preservesAndChunksRawUnicodeXmlInOrder() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        String rawXml = "a".repeat(3_999) + "😊" + "b";
        IncomingStaticMessageMetadata metadata = metadata();

        try (MockedConstruction<IncomingStaticMessageStagingProcedure> mocked =
                     mockConstruction(IncomingStaticMessageStagingProcedure.class)) {
            IncomingStaticMessageStagingDao dao =
                    new IncomingStaticMessageStagingDao(jdbcTemplate);

            dao.stage(rawXml, metadata);

            assertEquals(1, mocked.constructed().size());
            IncomingStaticMessageStagingProcedure procedure = mocked.constructed().get(0);
            ArgumentCaptor<List<String>> fragmentsCaptor = ArgumentCaptor.forClass(List.class);
            ArgumentCaptor<IncomingStaticMessageMetadata> metadataCaptor =
                    ArgumentCaptor.forClass(IncomingStaticMessageMetadata.class);

            verify(procedure).execute(fragmentsCaptor.capture(), metadataCaptor.capture());

            List<String> fragments = fragmentsCaptor.getValue();
            assertEquals(2, fragments.size());
            assertEquals("a".repeat(3_999) + "😊", fragments.get(0));
            assertEquals("b", fragments.get(1));
            assertEquals(rawXml, String.join("", fragments));
            assertSame(metadata, metadataCaptor.getValue());
        }
    }

    @Test
    void propagatesProcedureFailure() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        MlvProcessingException failure =
                new MlvProcessingException("S02-unknown branch");

        try (MockedConstruction<IncomingStaticMessageStagingProcedure> mocked =
                     mockConstruction(IncomingStaticMessageStagingProcedure.class,
                             (procedure, context) -> doThrow(failure).when(procedure)
                                     .execute(anyList(), any(IncomingStaticMessageMetadata.class)))) {
            IncomingStaticMessageStagingDao dao =
                    new IncomingStaticMessageStagingDao(jdbcTemplate);

            MlvProcessingException thrown = assertThrows(
                    MlvProcessingException.class,
                    () -> dao.stage("<flexstatic/>", metadata()));

            assertSame(failure, thrown);
            assertEquals(1, mocked.constructed().size());
        }
    }

    @Test
    void rejectsBlankXmlBeforeExecutingProcedure() {
        try (MockedConstruction<IncomingStaticMessageStagingProcedure> mocked =
                     mockConstruction(IncomingStaticMessageStagingProcedure.class)) {
            IncomingStaticMessageStagingDao dao =
                    new IncomingStaticMessageStagingDao(mock(JdbcTemplate.class));

            assertThrows(MlvProcessingException.class,
                    () -> dao.stage(" \t\r\n ", metadata()));
            assertTrue(mocked.constructed().isEmpty());
        }
    }

    @Test
    void rejectsNullXmlBeforeExecutingProcedure() {
        try (MockedConstruction<IncomingStaticMessageStagingProcedure> mocked =
                     mockConstruction(IncomingStaticMessageStagingProcedure.class)) {
            IncomingStaticMessageStagingDao dao =
                    new IncomingStaticMessageStagingDao(mock(JdbcTemplate.class));

            assertThrows(MlvProcessingException.class,
                    () -> dao.stage(null, metadata()));
            assertTrue(mocked.constructed().isEmpty());
        }
    }

    @Test
    void rejectsNullMetadataBeforeExecutingProcedure() {
        try (MockedConstruction<IncomingStaticMessageStagingProcedure> mocked =
                     mockConstruction(IncomingStaticMessageStagingProcedure.class)) {
            IncomingStaticMessageStagingDao dao =
                    new IncomingStaticMessageStagingDao(mock(JdbcTemplate.class));

            assertThrows(MlvProcessingException.class,
                    () -> dao.stage("<flexstatic/>", null));
            assertTrue(mocked.constructed().isEmpty());
        }
    }

    @Test
    void rejectsInvalidMetadataBeforeExecutingProcedure() {
        IncomingStaticMessageMetadata invalidMetadata = new IncomingStaticMessageMetadata(
                "MLV_CUSMSG_ADR", null, "I", null, "MLV", null, null, null);

        try (MockedConstruction<IncomingStaticMessageStagingProcedure> mocked =
                     mockConstruction(IncomingStaticMessageStagingProcedure.class)) {
            IncomingStaticMessageStagingDao dao =
                    new IncomingStaticMessageStagingDao(mock(JdbcTemplate.class));

            MlvProcessingException thrown = assertThrows(MlvProcessingException.class,
                    () -> dao.stage("<flexstatic/>", invalidMetadata));
            assertTrue(thrown.getMessage().contains("Invalid incoming static staging metadata"));
            assertTrue(mocked.constructed().isEmpty());
        }
    }

    @Test
    void createsFreshProcedureForEveryStagingInvocation() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        IncomingStaticMessageMetadata metadata = metadata();

        try (MockedConstruction<IncomingStaticMessageStagingProcedure> mocked =
                     mockConstruction(IncomingStaticMessageStagingProcedure.class)) {
            IncomingStaticMessageStagingDao dao =
                    new IncomingStaticMessageStagingDao(jdbcTemplate);

            dao.stage("<flexstatic id='1'/>", metadata);
            dao.stage("<flexstatic id='2'/>", metadata);

            assertEquals(2, mocked.constructed().size());
            verify(mocked.constructed().get(0))
                    .execute(anyList(), any(IncomingStaticMessageMetadata.class));
            verify(mocked.constructed().get(1))
                    .execute(anyList(), any(IncomingStaticMessageMetadata.class));
        }
    }

    private static IncomingStaticMessageMetadata metadata() {
        return new IncomingStaticMessageMetadata(
                "MLV_CUSMSG_ADR",
                "IE6",
                "I",
                null,
                "MLV",
                "715484",
                null,
                Timestamp.valueOf("2026-10-21 10:11:12.123"));
    }
}
