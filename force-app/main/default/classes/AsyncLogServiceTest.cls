/**
 * Created by David Martinka on 05.10.2022.
 * Mooza Inspire s.r.o.
 */
@IsTest(SeeAllData=false)
public with sharing class AsyncLogServiceTest {
    @IsTest
    private static void should_PublishPlatformEvent_When_MandatoryFieldsPopulated() {
        String exceptionMessage = null;
        try {
            new AsyncLogService.LogBuilder()
                    .setMandatoryFields(AsyncLogService.TYPE_DEBUG, AsyncLogServiceTest.class.getName(), 'should_PublishPlatformEvent_When_MandatoryFieldsPopulated')
                    .log();
        } catch (Exception e) {
            exceptionMessage = e.getMessage();
        }

        System.assertEquals(null, exceptionMessage, 'Exception was not thrown');
    }

    @IsTest
    private static void should_PublishPlatformEvent_When_RecordIdPopulated() {
        String exceptionMessage = null;
        try {
            new AsyncLogService.LogBuilder()
                    .setRecordId('2F01I3G000000FZcy')
                    .log();
        } catch (Exception e) {
            exceptionMessage = e.getMessage();
        }

        System.assertEquals(null, exceptionMessage, 'Exception was not thrown');
    }

    @IsTest
    private static void should_PublishPlatformEvent_When_InfoLogPopulated() {
        String exceptionMessage = null;
        try {
            new AsyncLogService.LogBuilder()
                    .setMandatoryFields(AsyncLogService.TYPE_INFO, AsyncLogServiceTest.class.getName(), 'should_PublishPlatformEvent_When_MandatoryFieldsPopulated')
                    .setDebugInfoLog('Testing debug and info log')
                    .log();
        } catch (Exception e) {
            exceptionMessage = e.getMessage();
        }

        System.assertEquals(null, exceptionMessage, 'Exception was not thrown');
    }

    @IsTest
    private static void should_PublishPlatformEvent_When_ErrorLogFieldsPopulated() {
        String exceptionMessage = null;
        try {
            new AsyncLogService.LogBuilder()
                    .setMandatoryFields(AsyncLogService.TYPE_ERROR, AsyncLogServiceTest.class.getName(), 'should_PublishPlatformEvent_When_MandatoryFieldsPopulated')
                    .setErrorFields('Error happened when publishing platform event.', 'Test Error Message', 'Error Stack Trace')
                    .log();
        } catch (Exception e) {
            exceptionMessage = e.getMessage();
        }

        System.assertEquals(null, exceptionMessage, 'Exception was not thrown');
    }

    @IsTest
    private static void should_PublishPlatformEvent_When_HttpRequestFieldsPopulated() {
        String exceptionMessage = null;
        try {
            new AsyncLogService.LogBuilder()
                    .setHttpRequestFields('http request body', 'www.test.com/endpoint')
                    .log();
        } catch (Exception e) {
            exceptionMessage = e.getMessage();
        }

        System.assertEquals(null, exceptionMessage, 'Exception was not thrown');
    }

    @IsTest
    private static void should_PublishPlatformEvent_When_HttpResponseFieldsPopulated() {
        String exceptionMessage = null;
        try {
            new AsyncLogService.LogBuilder()
                    .setHttpResponseFields('http response body', 400)
                    .log();
        } catch (Exception e) {
            exceptionMessage = e.getMessage();
        }

        System.assertEquals(null, exceptionMessage, 'Exception was not thrown');
    }

    @IsTest
    private static void should_PublishPlatformEvent_When_MultipleFieldsPopulated() {
        String exceptionMessage = null;
        try {
            new AsyncLogService.LogBuilder()
                    .setMandatoryFields(AsyncLogService.TYPE_INFO, AsyncLogServiceTest.class.getName(), 'should_PublishPlatformEvent_When_MandatoryFieldsPopulated')
                    .setRecordId('2F01I3G000000FZcy')
                    .setDebugInfoLog('Testing debug and info log')
                    .setErrorFields('Error happened when publishing platform event.', 'Test Error Message', 'Error Stack Trace')
                    .setHttpRequestFields('http request body', 'www.test.com/endpoint')
                    .setHttpResponseFields('http response body', 400)
                    .log();
        } catch (Exception e) {
            exceptionMessage = e.getMessage();
        }

        System.assertEquals(null, exceptionMessage, 'Exception was not thrown');
    }

    @IsTest
    private static void should_ReturnLogEvent_When_Requested() {
        String exceptionMessage = null;
        try {
            new AsyncLogService.LogBuilder()
                    .setMandatoryFields(AsyncLogService.TYPE_INFO, AsyncLogServiceTest.class.getName(), 'should_PublishPlatformEvent_When_MandatoryFieldsPopulated')
                    .setRecordId('2F01I3G000000FZcy')
                    .setDebugInfoLog('Testing debug and info log')
                    .setErrorFields('Error happened when publishing platform event.', 'Test Error Message', 'Error Stack Trace')
                    .setHttpRequestFields('http request body', 'www.test.com/endpoint')
                    .setHttpResponseFields('http response body', 400)
                    .getLogEvent();
        } catch (Exception e) {
            exceptionMessage = e.getMessage();
        }

        System.assertEquals(null, exceptionMessage, 'Exception was not thrown');
    }
}